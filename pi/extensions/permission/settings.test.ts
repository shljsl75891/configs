/**
 * Contract test: the live settings.json plan.bash rules behave as intended.
 * Kept out of match.test.ts so an unrelated settings.json edit that removes
 * or reshapes permission.plan fails here, at the config, not inside the
 * matcher's own unit tests.
 */
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { describe, it } from "node:test";
import { type Action, type Rules, decideBash, matchRule } from "./match.ts";

describe("plan rules (settings.json)", () => {
  const settings = JSON.parse(readFileSync(new URL("../../settings.json", import.meta.url), "utf8"));
  const plan: Rules = settings.permission.plan.bash;
  const byPlan = (s: string) => matchRule(plan, s, "/home/u") ?? "allow";
  const cases: [string, Action][] = [
    ["ls > f", "deny"],
    ["echo x >> log", "deny"],
    ["ls 2>&1 | cat", "allow"],
    ["rg x 2>/dev/null", "allow"],
    ["cat < in", "allow"],
    ["cat <<EOF\nx\nEOF", "allow"],
    ["git log --oneline", "allow"],
    ["sed -i s/a/b/ f", "deny"],
    ["sed s/a/b/ f", "allow"],
    ["ls && rm x", "deny"],
    ["git commit -m x", "deny"],
    ["bash -c 'mkdir x'", "deny"],
    ["sudo -u root rm x", "deny"],
    ["sudo -D /tmp rm x", "deny"],
    ["sudo -Eu root rm x", "deny"],
    ["/bin/rm x", "deny"],
    ["/usr/bin/sudo rm x", "deny"],
    ["echo x >& log", "deny"],
    ["cmd 2>&1", "allow"],
    ["bash -x -c 'rm x'", "deny"],
  ];
  for (const [cmd, want] of cases) {
    it(JSON.stringify(cmd), async () => assert.equal(await decideBash(cmd, byPlan), want));
  }
});
