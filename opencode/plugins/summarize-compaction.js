export const SummarizeCompactionPlugin = async ({ $, worktree }) => ({
  "experimental.session.compacting": async (input, output) => {
    try {
      const status = await $`git -C ${worktree} status --short`.text();
      if (status.trim())
        output.context.push(
          `## Current Git Status\n\`\`\`\n${status.trim()}\n\`\`\``,
        );
    } catch {}

    output.context.push(`
Your task: Write a handoff prompt for the next agent. This is NOT a conversation summary — it is a precise, actionable prompt that tells the next agent exactly what to do next.

The handoff prompt must begin with this block, copied exactly as-is:
---
Before proceeding, run \`git status && git diff && git diff --cached\` to reconstruct intent from uncommitted changes.
If the goal is unclear after reviewing the diff, invoke \`/grill-me\` to resolve ambiguity before acting.
---

Then include ONLY the following sections, omitting any that are empty:

### Next Steps
Prioritized, concrete actions the next agent must execute, in order.

### Required Context
Reference pointers only — do not reproduce content that already exists elsewhere. Only include references you directly observed in the conversation. Do not infer or fabricate any identifiers:
- JIRA ticket → ticket ID
- Design doc / TDD → file path or URL
- Relevant code → file:line
- PR or commit → URL or SHA

### Open Questions / Blockers
Issues that would prevent or meaningfully ambiguate the next steps.

### Key Decisions
Architectural or approach decisions already made that the next agent must not revisit or reverse.

Omit any information that does not directly serve the next steps.
`);
  },
});
