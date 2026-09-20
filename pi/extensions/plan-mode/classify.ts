import { resolve } from "node:path";

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
   * tar/unzip/patch/install/rsync/shred/mkfifo: same "every arg is a path"
   * shape as rm/mv/cp, including their cp-style coarseness (a source
   * argument must resolve under /tmp too, not just the destination).
   */
  "tar",
  "unzip",
  "patch",
  "install",
  "rsync",
  "shred",
  "mkfifo",
  /**
   * wget writes to cwd by default (curl instead defaults to stdout — see
   * the flag-gated curl pattern below). Its argument is a URL, not a
   * path, so the /tmp hatch never finds a real target to rescue it.
   */
  "wget",
  /**
   * npx/bunx: single-word fetch-and-run commands, head-matched the same
   * way as rm/mv. Their args are package names, not paths, so the /tmp
   * hatch below can never rescue them — there is no safe /tmp-scoped
   * form of "fetch and run arbitrary code".
   */
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
 * State-mutating subcommands with no filesystem path that could make them
 * safe — a redirect elsewhere in the command (`git commit -m x
 * 2>/dev/null`) must never neutralize these for the /tmp hatch below.
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
 * Env-var prefixes are stripped and the head is basenamed, so "FOO=1 rm -rf
 * x" and "/bin/rm -rf x" both still match on "rm". Shared by commandHeads
 * below and isTmpOnlyCommand's own head check, so a future fix only needs
 * to land once.
 */
function commandHead(segment: string): string {
  const words = stripLeadingAssignments(
    segment.trim().split(/\s+/).filter(Boolean),
  );
  return (words[0] ?? "").replace(/^.*\//, "");
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
 * real path. isBlockedBashCommand strips these once, up front, so
 * isWriteCommand and isTmpOnlyCommand share one view of what a command
 * actually writes — without it, `rg foo . 2>/dev/null | head` would be
 * misclassified as a write with no way for the /tmp hatch to rescue it
 * (it bails on any pipe). Trailing lookahead required: without it,
 * "/dev/null" prefix-matches inside "/dev/nullx", hiding a write to that
 * real path.
 */
const THROWAWAY_REDIRECT =
  /\d*>>?\s*(?:\/dev\/(?:null|stdout|stderr)|&\d+)(?=\s|$|[;&|])/g;

function isWriteCommand(command: string): boolean {
  if (commandHeads(command).some((head) => WRITE_COMMAND_HEADS.has(head))) {
    return true;
  }
  return WRITE_SUBCOMMAND_PATTERNS.some((p) => p.test(command));
}

/**
 * Newline included: a multi-line bash command is functionally a script,
 * and commandHeads()/the /tmp hatch below only look at line one otherwise
 * — `echo hi > /tmp/x\nrm -rf /` must not slip through as "just a
 * redirect to /tmp". Bare `&` also catches `&>`/`&>>` and blocks them
 * outright rather than parsing the target, same fail-safe bucket as `&&`
 * chaining.
 */
const SHELL_METACHARS = /[;&|`\n]|\$\(/;

/**
 * Every remaining redirect target must resolve under /tmp. (Throwaway
 * targets like /dev/null and fd-dups like `2>&1` never reach here — the
 * caller already stripped them before either classifier ran.)
 */
function isWritableInPlanMode(target: string): boolean {
  // resolve(), not startsWith: "/tmp/../etc/passwd" has a literal /tmp/
  // prefix but resolves outside /tmp. A relative target resolves against
  // cwd, which correctly fails this check too.
  const abs = resolve(target);
  return abs === "/tmp" || abs.startsWith("/tmp/");
}

/**
 * Global: a command can carry more than one real redirect (`cmd > /tmp/a
 * 2> /tmp/b`), and every one needs checking, not just the first.
 */
const REDIRECT_TARGET_PATTERN = /(?:^|[^<>])(?:>>?)(?!>)\s*(\S+)/g;

/**
 * Coarse escape hatch for a single simple command — pipes, subshells, and
 * chaining are blocked outright by SHELL_METACHARS rather than risk a
 * partial match. Caller strips throwaway redirects first, so every
 * redirect seen below is a real target. `sudo` never gets this hatch;
 * SUBCOMMAND_MUTATION_PATTERNS commands (git/npm/...) mutate state with
 * no filesystem path, so no redirect can make them safe; every redirect
 * target and every WRITE_COMMAND_HEADS argument must independently
 * resolve under /tmp.
 */
function isTmpOnlyCommand(command: string): boolean {
  if (SHELL_METACHARS.test(command)) return false;
  const tokens = stripLeadingAssignments(command.trim().split(/\s+/));
  const head = commandHead(command);
  if (head === "sudo") return false;
  if (SUBCOMMAND_MUTATION_PATTERNS.some((p) => p.test(command))) return false;

  let sawFileRedirect = false;
  for (const match of command.matchAll(REDIRECT_TARGET_PATTERN)) {
    const target = match[1] ?? "";
    sawFileRedirect = true;
    if (!isWritableInPlanMode(target)) return false;
  }

  if (WRITE_COMMAND_HEADS.has(head)) {
    /**
     * `--opt=path` carries its value inline; checking only the flag would
     * let `mv --target-directory=/etc /tmp/x` pass on the /tmp-safe arg
     * alone while the real write target is the flag's value.
     */
    const args = tokens
      .slice(1)
      .filter((tok) => !tok.includes(">"))
      .flatMap((tok) => {
        if (!tok.startsWith("-")) return [tok];
        const eq = tok.indexOf("=");
        return eq === -1 ? [] : [tok.slice(eq + 1)];
      });
    return args.length > 0 && args.every(isWritableInPlanMode);
  }

  return sawFileRedirect;
}

/**
 * True if `command` performs a write in plan mode's blocked scope (cwd
 * writes, package/tool installs, vcs mutations) and isn't rescued by the
 * /tmp escape hatch. Strips throwaway redirects (`2>/dev/null`, `2>&1`)
 * once up front, so isWriteCommand and isTmpOnlyCommand share one view of
 * what the command actually writes to.
 */
export function isBlockedBashCommand(command: string): boolean {
  const significant = command.replace(THROWAWAY_REDIRECT, " ");
  if (!isWriteCommand(significant)) return false;
  return !isTmpOnlyCommand(significant);
}
