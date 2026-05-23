export const SummarizeCompactionPlugin = async ({ $, worktree }) => ({
  "experimental.session.compacting": async (_input, output) => {
    let gitStatus = "";
    try {
      const status = await $`git -C ${worktree} status --short`.text();
      if (status.trim()) {
        gitStatus = `\n## Current Git Status\n\`\`\`\n${status.trim()}\n\`\`\`\n`;
      }
    } catch {}

    output.prompt = `Generate a handoff document — precise, actionable instructions enabling seamless session resumption with zero ambiguity. Not a conversation summary.
${gitStatus}
## COMPRESSION RULES

**Preserve:**
- Session intent (verbatim if short, paraphrased if very long)
- Every decision with rationale, INCLUDING rejected options and why
- All modified file paths with line numbers (\`path/to/file:L123\`)
- Failed approaches + exact rejection reason (prevents repeat work)
- Unresolved bugs, blockers, open questions
- Architectural patterns and conventions discovered
- Concrete next steps in priority order

**Discard:**
- Pleasantries, exploration traces that led nowhere
- Raw tool outputs (grep dumps, full reads, ls listings) — use file-path references
- Intermediate deliberation behind committed decisions
- Re-reads of same file, reproducible commands

**Uncertain? KEEP IT**

## OUTPUT FORMAT

Omit empty sections. Use exact headers shown.

---

## Session Summary
[2-4 sentences: what was accomplished, where work stopped, what the next phase is]

## Decisions Made
| Decision | Options Considered | Rationale |
|---|---|---|
| [decision] | [options] | [why this, why others rejected] |

## Errors & Blockers
- \`[error message]\` — [Status: resolved/open] [Resolution if applicable]

## File Anchors
- \`path/to/file:L123\` — [purpose / relevance to current task]

## Action Items
- [ ] [Concrete next action — specific command or file, never vague]
- [ ] [Next prioritized action]

## Must Follow
Before proceeding, run \`git status && git diff && git diff --cached\` to reconstruct intent from uncommitted changes.
If the goal is unclear after reviewing the diff, invoke \`/grill-me\` skill to resolve ambiguity before acting.
`;
  },
});
