import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { type Action, type Rules, decideBash, matchRule, pathSubjects, strictest } from "./match.ts";

const bash: Rules = {
  "*": "allow",
  "rm *": "ask",
  "* .env *": "ask",
  "git restore *": "deny",
  "git commit *": "ask",
  "git push *": "ask",
  "HUSKY=0 git *": "ask",
};
const byRule = (s: string) => matchRule(bash, s, "/home/u") ?? "allow";

const cases: [string, Action][] = [
  ["ls > f 2>&1", "allow"],
  ["ls -la | grep x >> log 2>/dev/null", "allow"],
  ["cd x && rm y", "ask"],
  ["rm", "ask"],
  ["echo $(git push)", "ask"],
  ["echo `rm y`", "ask"],
  ["HUSKY=0 git commit -m 'a b'", "ask"],
  ["HUSKY=0 git status", "ask"],
  ["sudo rm -rf /tmp/x", "ask"],
  ["sudo -u root rm x", "ask"],
  ["sudo -D /tmp rm x", "ask"],
  ["sudo --user root rm x", "ask"],
  ["sudo -Eu root rm x", "ask"],
  ["/bin/rm x", "ask"],
  ["/usr/bin/sudo rm x", "ask"],
  ["env -i FOO=1 git restore .", "deny"],
  ["env -u FOO rm x", "ask"],
  ['bash -c "git restore ."', "deny"],
  ["sh -lc 'ls; git restore x'", "deny"],
  ["git status && git restore . && rm x", "deny"],
  ["cat <<EOF\nrm x\nEOF", "allow"],
  ["if true; then rm -rf x; fi", "ask"],
  ["cat .env", "ask"],
  ["echo 'unterminated", "ask"],
  ["grep -rn 'rm x' .", "allow"],
  ["echo k > .env", "ask"],
  ["echo k >& .env", "ask"],
  ["cmd 2>&1", "allow"],
  ["bash -x -c 'rm x'", "ask"],
];

describe("decideBash", () => {
  for (const [cmd, want] of cases) {
    it(JSON.stringify(cmd), async () => assert.equal(await decideBash(cmd, byRule), want));
  }
});

describe("paths", () => {
  const read: Rules = { "*": "allow", "*.env": "deny", "*.env.example": "allow", "~/secret/*": "deny" };
  const check = (p: string) => strictest(pathSubjects(p, "/proj", "/home/u").map((s) => matchRule(read, s, "/home/u") ?? "allow"));
  it("denies .env", () => assert.equal(check(".env"), "deny"));
  it("allows .env.example", () => assert.equal(check("a/.env.example"), "allow"));
  it("expands ~", () => assert.equal(check("/home/u/secret/k"), "deny"));
  it("allows src", () => assert.equal(check("src/a.ts"), "allow"));
});

