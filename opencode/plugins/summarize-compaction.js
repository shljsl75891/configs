export const SummarizeCompactionPlugin = async ({ $, worktree }) => ({
  "experimental.session.compacting": async (_input, output) => {
    try {
      const status = await $`git -C ${worktree} status --short`.text();
      if (status.trim())
        output.context.push(
          `## Current Git Status\n\`\`\`\n${status.trim()}\n\`\`\``,
        );
    } catch {}

    output.context.push(`
Create a handoff prompt for the next agent. This is NOT a conversation summary — it must be precise, actionable instructions.

## COMPRESSION RULES
- Remove: pleasantries, repeated attempts, and exploration that led nowhere (but note why it failed)
- Preserve: exact commands that worked, configuration values, URLs, and error messages
- Format: Use XML structure with Markdown content inside tags
- Target length: Approximately 40% of the original context
- When uncertain about whether to keep information: KEEP IT

## OUTPUT FORMAT
\`\`\`xml
<handoff>
  <session_summary>
  [describing what was accomplished, and what is the next phase or action to accomplished]
  </session_summary>

  <decisions>
  - [Decision 1]: [Rationale for why this decision was made]
  - [Decision 2]: [Rationale for why this decision was made] .. and so on
  </decisions>

  <errors_and_blockers>
  - [Error message]: [Status: resolved or open] [Resolution if applicable]
  </errors_and_blockers>

  <code_changes>
  - \`path/to/file:L123\` — [What changed and why it changed]
  </code_changes>

  <action_items>
  - [ ] [Prioritized concrete next actions]
  - [ ] [Next prioritized action]
  - [ ] [Next phase of the plan being executed]
  </action_items>

  <required_context>
  [Reference pointers only: JIRA ticket ID, design doc URL]
  </required_context>

  <context_for_continuation>
  [Any information the next session needs to know that doesn't fit in the sections above]
  </context_for_continuation>

  <must_follow>
  Before proceeding, run \`git status && git diff && git diff --cached\` to reconstruct intent from uncommitted changes.
  If the goal is unclear after reviewing the diff, invoke \`/grill-me\` skill to resolve ambiguity before acting.
  </must_follow>
</handoff>
\`\`\`
`);
  },
});
