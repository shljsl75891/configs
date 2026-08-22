export const SummarizeCompactionPlugin = async ({ $, worktree }) => ({
  "experimental.session.compacting": async (input, output) => {
    // --- Git context (best-effort) ---
    let git = "";
    try {
      const branch = (
        await $`git -C ${worktree} branch --show-current`.text()
      ).trim();
      const head = (
        await $`git -C ${worktree} log -1 --format=%h%x20%s`.text()
      ).trim();
      const status = (await $`git -C ${worktree} status --short`.text()).trim();
      const stat = (await $`git -C ${worktree} diff --stat`.text()).trim();
      git = `\n## Git Context\nBranch: ${branch || "?"}\nHEAD: ${head || "?"}\n`;
      if (status) git += `\n\`\`\`\n${status}\n\`\`\`\n`;
      if (stat) git += `\n\`\`\`\n${stat}\n\`\`\`\n`;
    } catch {}

    // --- Verbatim user directives (no model recall) ---
    let directives = "";
    try {
      const msgs = input?.messages ?? [];
      const lines = msgs
        .filter((m) => m.role === "user")
        .map((m) =>
          typeof m.content === "string"
            ? m.content
            : (m.content ?? []).map((p) => p.text ?? "").join(" "),
        )
        .filter((t) =>
          /\b(don'?t|do not|never|always|must|only|prefer|avoid|no |stop|use )\b/i.test(
            t,
          ),
        )
        .map((t) => `- ${t.replace(/\s+/g, " ").trim().slice(0, 300)}`);
      if (lines.length) {
        directives = `\n## Raw User Directives (verbatim)\n${lines.join("\n")}\n`;
      }
    } catch {}

    output.prompt = `Write a handoff document. It lets a new session continue the work with no ambiguity. It is not a conversation summary.
${git}${directives}
## COMPRESSION RULES

**Keep:**
- Session intent. Use exact words if short. Paraphrase if long.
- Each explicit user instruction, rule, or preference. Use exact words. Keep it even if the user said it once.
- Each decision and its reason. Include rejected options and why you rejected them.
- Each changed file path with symbol name and line hint (\`path/file.ts:fnName ~L123\`).
- Each failed approach and the exact reason it failed.
- Open bugs, blockers, and open questions.
- Architecture patterns and code conventions you found.
- Build, test, lint, and run commands.
- Test results and the last known-good state.
- Next steps in priority order.
- All items from a previous handoff document in this context. Merge them. Do not drop them.

**Remove:**
- Pleasantries and exploration that gave no result.
- Raw tool output (grep, full file reads, ls). Use file path references.
- Reasoning behind decisions that are already final.
- Repeated file reads and commands that you can run again.

**If not sure, keep it.**

**Size:** Target 2000–4000 tokens. User Constraints and Decisions have no limit.

## OUTPUT FORMAT
Use these exact headers. Omit empty sections.
---
## Session Summary
[2–4 sentences: what is done, where work stopped, what comes next]

## User Constraints
- [Rule from user, exact words]
- [DO NOT instruction]
- [Style, tone, or workflow preference]

## In-Flight State
- [Step that was in progress at compaction: file, command, partial change]
- [What is complete in that step. What is not complete.]

## Environment
- Branch: [name]  Base: [commit]
- Build: \`[cmd]\`  Test: \`[cmd]\`  Lint: \`[cmd]\`  Run: \`[cmd]\`
- Pkg mgr / runtime / env vars: [values]

## Skills Used
- [skill-name] — [why used, what it gave]

## Decisions Made
| Decision | Options Considered | Reason |
|---|---|---|
| [decision] | [options] | [why this, why not the others] |

## Errors & Blockers
- \`[error message]\` — [Status: resolved/open] [Fix, if any]

## Verified State
- [Tests that pass. Tests that fail.]
- [Last known-good commit or state]

## File Anchors
- \`path/file:symbol ~L123\` — [purpose, relation to task]
- [Files read but not changed that matter: configs, interfaces]

## Pending Asks
- [Unanswered user question]
- [Assumption not yet confirmed by user]

## Action Items
- [ ] [Exact next action: command or file. Not vague.]
- [ ] [Next action by priority]

## Must Follow
1. Obey all User Constraints before each action. Do not break one to finish an Action Item.
2. Run \`git status && git diff && git diff --cached\`. Rebuild intent from uncommitted changes.
3. Do not redo completed Action Items.
4. Confirm each File Anchor exists before you edit it.
5. If the goal is not clear after the diff review, ask the user.
`;
  },
});
