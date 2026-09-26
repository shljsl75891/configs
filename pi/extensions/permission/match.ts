/**
 * Pure rule matching for the permission extension (OpenCode-style config):
 * wildcard patterns, last match wins, strictest result across sub-commands.
 */
import { createRequire } from "node:module";
import * as path from "node:path";
import { Language, Parser, type Node } from "web-tree-sitter";

export type Action = "allow" | "ask" | "deny";
export type Rules = Record<string, Action>;
export type Decide = (subject: string) => Action;

const RANK: Record<Action, number> = { allow: 0, ask: 1, deny: 2 };

export function strictest(actions: Action[]): Action {
  return actions.reduce<Action>((a, b) => (RANK[b] > RANK[a] ? b : a), "allow");
}

function expandHome(p: string, home: string): string {
  if (p === "~") return home;
  if (p.startsWith("~/")) return path.join(home, p.slice(2));
  if (p.startsWith("$HOME/")) return path.join(home, p.slice(6));
  return p;
}

/** `*` = any chars (incl. `/` and newlines), `?` = one char; a trailing ` *` also matches the bare command. */
function wildcard(pattern: string): RegExp {
  const optionalArgs = pattern.endsWith(" *");
  const body = optionalArgs ? pattern.slice(0, -2) : pattern;
  const re = body
    .replace(/[.+^${}()|[\]\\]/g, "\\$&")
    .replace(/\*/g, ".*")
    .replace(/\?/g, ".");
  return new RegExp(`^${re}${optionalArgs ? "( .*)?" : ""}$`, "s");
}

/** Last matching pattern wins; null when none match. */
export function matchRule(rules: Rules, subject: string, home: string): Action | null {
  let action: Action | null = null;
  for (const [pattern, value] of Object.entries(rules)) {
    if (wildcard(expandHome(pattern, home)).test(subject)) action = value;
  }
  return action;
}

/** A path as given, absolute, and cwd-relative, so `src/*` and `/abs/*` patterns both work. */
export function pathSubjects(p: string, cwd: string, home: string): string[] {
  const given = expandHome(p, home);
  const abs = path.resolve(cwd, given);
  return [...new Set([given, abs, path.relative(cwd, abs) || "."])];
}

let parserPromise: Promise<Parser> | undefined;

function parser(): Promise<Parser> {
  parserPromise ??= (async () => {
    try {
      await Parser.init();
      const wasm = createRequire(import.meta.url).resolve("tree-sitter-bash/tree-sitter-bash.wasm");
      const p = new Parser();
      p.setLanguage(await Language.load(wasm));
      return p;
    } catch (err) {
      parserPromise = undefined; // don't poison every future call with a permanently-rejected promise
      throw err;
    }
  })();
  return parserPromise;
}

const SHELLS = new Set(["bash", "sh", "zsh", "dash"]);
/** Bounds `bash -c "bash -c ..."` recursion; deeper nesting is not a real workflow. */
const MAX_SHELL_NESTING = 3;

function unquote(n: Node): string {
  return n.type === "string" || n.type === "raw_string" ? n.text.slice(1, -1) : n.text;
}

/**
 * sudo/env flags that take a following argument, so the argument isn't
 * mistaken for the command name (not exhaustive - covers common short and
 * long forms). Other wrappers (command, exec, nice, xargs, find -exec, ...)
 * are accepted gaps, same as opaque interpreters (python -c etc.).
 */
const ARG_FLAGS: Record<string, Set<string>> = {
  sudo: new Set(["-u", "--user", "-g", "-C", "-D", "-p"]),
  env: new Set(["-u", "--unset", "-C"]),
};

/** ARG_FLAGS entry for a wrapper word, basenamed so a full path (eg. /usr/bin/sudo) is recognized too. */
function wrapperFlags(word: Node | undefined): Set<string> | undefined {
  return word && ARG_FLAGS[path.basename(word.text)];
}

/** Leading `VAR=x`, `sudo [-flags [arg]]`, `env [-flags [arg]] [VAR=x]` stripped. */
function unwrap(words: Node[]): Node[] {
  let i = 0;
  while (words[i]?.type === "variable_assignment") i++;
  let argFlags: Set<string> | undefined;
  while ((argFlags = wrapperFlags(words[i]))) {
    i++;
    /* A clustered short flag (eg. `-Eu`) takes an argument when its last char, alone, does - the only position getopt allows one in. */
    const takesArg = (f: string): boolean => argFlags!.has(f) || (/^-[A-Za-z]{2,}$/.test(f) && argFlags!.has(`-${f.at(-1)}`));
    while (words[i] && /^(-|\w+=)/.test(words[i].text)) i += takesArg(words[i].text) ? 2 : 1;
  }
  return words.slice(i);
}

const WRITE_OPS = new Set([">", ">>", "&>", "&>>", ">|", ">&"]);
const NULL_DEVICES = /^\/dev\/(null|stdout|stderr|tty)$/;

/** File a redirect writes to; undefined for reads, fd dups/closes (`2>&1`, `>&-`), and /dev/null. */
function writeTarget(redirect: Node): string | undefined {
  const op = redirect.children.find((c) => c && !c.isNamed)?.type;
  const dest = redirect.childForFieldName("destination");
  if (!op || !WRITE_OPS.has(op) || !dest) return undefined;
  /* `>&` is dual-purpose: `2>&1` duplicates a fd (dest parses as a `number` node), `cmd >& file` writes a file (dest parses as `word`/string). */
  if (op === ">&" && (dest.type === "number" || dest.text === "-")) return undefined;
  const target = unquote(dest);
  return NULL_DEVICES.test(target) ? undefined : target;
}

/**
 * Checks every simple command (incl. inside `$()`, backticks, `bash -c`),
 * each as written and unwrapped, plus each file-write redirect as `> target`.
 * Parse error → at least ask.
 */
export async function decideBash(command: string, decide: Decide, depth = 0): Promise<Action> {
  const tree = (await parser()).parse(command);
  if (!tree) return "ask";
  try {
    const results: Action[] = tree.rootNode.hasError ? ["ask"] : [];
    for (const redirect of tree.rootNode.descendantsOfType("file_redirect")) {
      const target = redirect && writeTarget(redirect);
      if (target) results.push(decide(`> ${target}`));
    }
    for (const cmd of tree.rootNode.descendantsOfType("command")) {
      if (!cmd) continue;
      const words = cmd.namedChildren.filter((n): n is Node => !!n && !/redirect|herestring/.test(n.type));
      const raw = words.map((w) => w.text).join(" ");
      results.push(decide(raw));
      const inner = unwrap(words);
      // Basename the head word too, so `/bin/rm x` is checked as `rm x`.
      const unwrapped = inner.length ? [path.basename(inner[0].text), ...inner.slice(1).map((w) => w.text)].join(" ") : "";
      if (unwrapped && unwrapped !== raw) results.push(decide(unwrapped));
      const shell = inner[0];
      if (shell && depth < MAX_SHELL_NESTING && SHELLS.has(path.basename(shell.text))) {
        // The `-c` flag isn't always second (`bash -x -c '...'`, `bash -o pipefail -c '...'`).
        const flagIdx = inner.findIndex((w, k) => k > 0 && /^-\w*c$/.test(w.text));
        const script = flagIdx > 0 ? inner[flagIdx + 1] : undefined;
        if (script) results.push(await decideBash(unquote(script), decide, depth + 1));
      }
    }
    return strictest(results);
  } finally {
    tree.delete();
  }
}
