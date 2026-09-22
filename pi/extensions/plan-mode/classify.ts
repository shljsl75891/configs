/**
 * Bash write-gating backstop for plan mode: classifies commands so the
 * tool_call hook (index.ts) can block writes even under context pressure,
 * scoped to cwd writes (files, vcs, installs) matching what the system
 * prompt promises. Head-only matching (not substring) so `grep -rn "mv" .`
 * doesn't trip the gate on its own search text.
 */
const WRITE_COMMAND_HEADS = new Set([
  "rm",
  "rmdir",
  "mv",
  "cp",
  "mkdir",
  "touch",
  "chmod",
  "chown",
  "ln",
  "tee",
  "truncate",
  "dd",
  "sudo",
  /**
   * unzip/patch/rsync default to writing (extract/apply/sync) with no
   * flag at all — the opposite shape from curl/tar's SUBCOMMAND_MUTATION
   * patterns below (which require an explicit write flag) — so they stay
   * head-blocked by default. SAFE_READONLY_OVERRIDES below rescues their
   * explicit list/dry-run/test forms before this set is ever checked.
   */
  "unzip",
  "patch",
  "rsync",
  // wget writes to cwd by default (curl instead defaults to stdout — see
  // the flag-gated curl pattern below). Always blocked: there's no
  // read-only form of "fetch this URL to a file".
  "wget",
  // npx/bunx: single-word fetch-and-run commands, head-matched the same
  // way as rm/mv. Always blocked: there's no safe read-only form of
  // "fetch and run arbitrary code".
  "npx",
  "bunx",
]);

/**
 * These need more than the command name to judge (`git status` is fine,
 * `git commit` isn't), so they stay substring checks — coarser (a quoted
 * `>` can still trip it), but the head set above already removes the
 * common false-positive source of plain search/read commands.
 */
const REDIRECT_PATTERN = /(^|[^<])>(?!>)/;
const APPEND_REDIRECT_PATTERN = />>/;

/**
 * Tool-level flags between the tool name and subcommand (`git -C dir
 * commit`) would otherwise let `git -C . commit -m x` slip past a
 * flagless-only pattern. Only engages when the next word starts with
 * `-`, so subcommand-first forms (`git log --oneline`) are unaffected.
 */
const TOOL_FLAGS = String.raw`(?:-\S+(?:\s+\S+)?\s+)*`;

/**
 * State-mutating subcommands with no filesystem path — a redirect
 * elsewhere in the command (`git commit -m x 2>/dev/null`) never makes
 * these safe.
 */
const SUBCOMMAND_MUTATION_PATTERNS = [
  /**
   * Includes the common short aliases (npm/pnpm: i, un, rm, r, up)
   * alongside the long forms. Trailing \b required, since "i" alone would
   * otherwise match the start of unrelated words like "info".
   */
  new RegExp(
    String.raw`\b(npm|yarn|pnpm|bun)\s+${TOOL_FLAGS}(i|in|install|add|remove|rm|r|un|uninstall|update|up|ci|link|publish)\b`,
    "i",
  ),
  /**
   * pip3, pipx, uv (pip/add/remove/sync) and `python -m pip` all install
   * packages the same way plain `pip install` does.
   */
  /\b(pip3?|pipx|uv)\s+(install|uninstall|add|remove|sync)/i,
  /\bpython3?\s+-m\s+pip\s+(install|uninstall)/i,
  // pnpm's fetch-and-run form is two words, unlike npx/bunx above.
  /\bpnpm\s+dlx\b/i,
  /\b(cargo\s+(add|install|remove)|go\s+(get|install)|gem\s+install)\b/i,
  /\b(poetry|composer)\s+(add|install|remove|update)\b/i,
  // System package managers.
  /\b(brew|apt|apt-get|dnf|yum|apk|pacman)\s+(install|add|remove|upgrade|-S)\b/i,
  /**
   * find is read-only until an action flag makes it write/execute — bare
   * `find . -name x` must stay allowed.
   */
  /\bfind\s+.*\s-(delete|exec|execdir|fprint|fls)\b/,
  /**
   * Trailing \b required: without it "git configx"/"git initialize" would
   * match on the "config"/"init" prefix alone. submodule/remote/sparse-
   * checkout are two-word subcommands that write to the repo the same way
   * the one-word ones do (`git submodule add` fetches+writes, `git remote
   * add` mutates repo config).
   */
  new RegExp(
    String.raw`\bgit\s+${TOOL_FLAGS}(add|commit|push|pull|merge|rebase|reset|restore|switch|checkout|clean|rm|mv|apply|am|config|worktree|stash|cherry-pick|revert|tag|init|clone|branch\s+-[dD]|submodule\s+(add|update|deinit|sync)|remote\s+(add|remove|rm|set-url)|sparse-checkout\s+set)\b`,
    "i",
  ),
  /**
   * In-place edit: rewrites the target file directly, no redirect needed.
   * Matches a standalone -i, -i.bak, and short-flag bundling (-pi, -ni),
   * the more common one-liner form for both tools.
   */
  /\b(sed|perl)\s+(-[a-zA-Z]*\s+)*(--in-place\b|-[a-zA-Z]*i[a-zA-Z0-9.]*\b)/,
  // curl defaults to stdout (read-only); only an explicit output flag
  // makes it a write.
  /\bcurl\s+(-[a-zA-Z]*[oO]\b|--output\b|--remote-name\b)/i,
  /**
   * tar, unlike unzip/patch/rsync below, always requires an explicit mode
   * flag (it errors with none) — so "does this flag imply a write" is a
   * clean positive match, same shape as curl's -o above. -t/-d (list/diff)
   * are read-only and intentionally excluded.
   */
  /\btar\s+(?:\S+\s+)*(-[a-zA-Z]*[cxruA][a-zA-Z]*\b|--(create|extract|append|update|concatenate|delete)\b)/i,
];

/**
 * unzip/patch/rsync default to writing (extract/apply/sync) with no flag
 * at all, the opposite shape from curl/tar above — so they can't be
 * expressed as "this flag makes it a write". Checked once, up front in
 * isWriteCommand, before the head-block above would otherwise catch them
 * unconditionally: a command matching one of these is read-only regardless
 * of what else is on the line.
 */
const SAFE_READONLY_OVERRIDES = [
  // -l/--list, -v (verbose listing), -p (pipe to stdout), -t (test archive).
  /\bunzip\s+(?:\S+\s+)*(-[a-zA-Z]*[lvpt][a-zA-Z]*\b|--list\b)/i,
  /\bpatch\s+(?:\S+\s+)*(--dry-run\b|-C\b|--check\b)/i,
  /\brsync\s+(?:\S+\s+)*(-[a-zA-Z]*n[a-zA-Z]*\b|--dry-run\b)/i,
];

const WRITE_SUBCOMMAND_PATTERNS = [
  REDIRECT_PATTERN,
  APPEND_REDIRECT_PATTERN,
  ...SUBCOMMAND_MUTATION_PATTERNS,
];

/**
 * Strips leading `VAR=value` assignments from a token list so the real
 * command word is what gets matched, eg. "FOO=1 rm -rf x" -> ["rm","-rf","x"].
 */
function stripLeadingAssignments(words: string[]): string[] {
  let i = 0;
  while (i < words.length && /^[A-Za-z_][A-Za-z0-9_]*=/.test(words[i])) i++;
  return words.slice(i);
}

/**
 * Wrapper commands that pass their remaining arguments through to a real
 * command untouched (`timeout 5 rm -rf x`, `find . | xargs rm`). Peeled
 * before head-matching so the gate sees "rm", not "timeout"/"xargs", even
 * for a single wrapped command outside of `&&`/`|` chaining, which
 * commandHeads() already splits on. `sudo` is deliberately not here; it's
 * already head-blocked above, and `bash -c "..."`/`sh -c "..."` are a
 * known, accepted gap: parsing their quoted script content would need
 * real shell quoting support this classifier doesn't have anywhere else
 * either.
 */
const WRAPPER_HEADS = new Set(["timeout", "env", "nice", "nohup", "stdbuf", "xargs"]);

/**
 * Strips a leading run of wrapper words and their flags, eg. ["timeout",
 * "30", "rm", "-rf", "x"] -> ["rm", "-rf", "x"]. `timeout`'s duration is a
 * bare positional arg rather than a flag, so it needs its own skip; every
 * other `-...` token right after a wrapper head is dropped regardless of
 * whether it takes a value; being permissive here only widens what gets
 * re-classified as the real command, never narrows it to something unsafe.
 */
function peelWrappers(words: string[]): string[] {
  let rest = words;
  while (rest.length > 0) {
    const head = (rest[0] ?? "").replace(/^.*\//, "");
    if (!WRAPPER_HEADS.has(head)) break;
    rest = rest.slice(1);
    while (rest.length > 0 && rest[0].startsWith("-")) rest = rest.slice(1);
    if (head === "timeout" && rest.length > 0 && /^\d/.test(rest[0]!)) {
      rest = rest.slice(1);
    }
  }
  return rest;
}

/**
 * Env-var prefixes are stripped and the head is basenamed, so "FOO=1 rm -rf
 * x" and "/bin/rm -rf x" both still match on "rm". Wrapper words (timeout,
 * xargs, ...) are peeled the same way, so "timeout 5 rm -rf x" and "xargs
 * rm" also match on "rm".
 */
function commandHead(segment: string): string {
  const words = stripLeadingAssignments(
    segment.trim().split(/\s+/).filter(Boolean),
  );
  const peeled = peelWrappers(words);
  const head = peeled.length > 0 ? peeled : words;
  return (head[0] ?? "").replace(/^.*\//, "");
}

/**
 * Leading word of each unquoted-ish pipe/semicolon/ampersand/newline/
 * substitution segment, eg. "ls && rm -rf /" -> ["ls", "rm"], and
 * "echo $(rm -rf x)" -> ["echo", "rm"]. Does not understand quoting; a
 * literal ";" inside a quoted argument still splits, which only makes
 * this stricter.
 */
function commandHeads(command: string): string[] {
  return command
    .split(/[;&|\n]+|\$\(|[`()]/)
    .map(commandHead)
    .filter(Boolean);
}

/**
 * `2>/dev/null`, `2>&1`, `>&2` and friends write nothing and point at no
 * real path. isBlockedBashCommand strips these once, up front, so a
 * command like `rg foo . 2>/dev/null | head` isn't misclassified as a
 * write. Trailing lookahead required: without it, "/dev/null" prefix-
 * matches inside "/dev/nullx", hiding a write to that real path.
 */
const THROWAWAY_REDIRECT =
  /\d*>>?\s*(?:\/dev\/(?:null|stdout|stderr)|&\d+)(?=\s|$|[;&|])/g;

function isWriteCommand(command: string): boolean {
  if (SAFE_READONLY_OVERRIDES.some((p) => p.test(command))) return false;
  if (commandHeads(command).some((head) => WRITE_COMMAND_HEADS.has(head))) {
    return true;
  }
  return WRITE_SUBCOMMAND_PATTERNS.some((p) => p.test(command));
}

/**
 * True if `command` performs a write in plan mode's blocked scope (cwd
 * writes, package/tool installs, vcs mutations). Strips throwaway
 * redirects (`2>/dev/null`, `2>&1`) once up front so `>`/`>>` isn't
 * misread on those. No exceptions for any target (eg. /tmp) — plan mode
 * blocks every write command outright.
 */
export function isBlockedBashCommand(command: string): boolean {
  return isWriteCommand(command.replace(THROWAWAY_REDIRECT, " "));
}
