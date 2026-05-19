export const SummarizeCompactionPlugin = async ({ $, worktree }) => ({
  "experimental.session.compacting": async (_input, output) => {
    let gitStatus = "";
    try {
      const status = await $`git -C ${worktree} status --short`.text();
      if (status.trim()) {
        gitStatus = `\n## Current Git Status\n\`\`\`\n${status.trim()}\n\`\`\`\n`;
      }
    } catch {}

    output.prompt = `You are generating a handoff document for the next agent session. This is NOT a conversation summary — it must be precise, actionable instructions enabling seamless resumption with zero ambiguity for any coding agent to resume this session.
${gitStatus}
## COMPRESSION RULES

**Preserve (optimize for correct resumption, not token minimization):**
- Session intent — original user goal verbatim if short, paraphrased only if very long
- Every decision made with rationale, INCLUDING rejected options and why they were rejected
- All file paths modified, with line numbers where relevant (\`path/to/file:L123\`)
- Failed approaches and the exact reason rejected — prevents repeat work
- Unresolved bugs, blockers, open questions
- Architectural patterns and codebase conventions discovered during this session
- Concrete next steps in priority order
- Exact commands, configuration values, URLs, and error messages that matter

**Discard:**
- Pleasantries, repeated attempts, and exploration that led nowhere (note only why it failed, not the trace)
- Raw tool outputs (grep dumps, full file reads, ls listings) — replace with file-path references
- Intermediate reasoning that led to a committed decision (keep the decision + rationale, not the deliberation)
- Re-reads of the same file
- Anything reproducible by running a command

**When uncertain whether to keep information: KEEP IT**

## OUTPUT FORMAT

Produce the following Markdown document. Use the exact section headers shown. If a section has nothing to report, write \`None\` — never omit a section.

---

## Session Summary
[2-4 sentences: what was accomplished, where work stopped, what the next phase is]

## Decisions Made
| Decision | Options Considered | Rationale |
|---|---|---|
| [decision] | [options] | [why this, why others rejected] |

## Failed Approaches
- \`[approach]\` — [exact reason rejected]

## Errors & Blockers
- \`[error message]\` — [Status: resolved/open] [Resolution if applicable]

## Code Changes
- \`path/to/file:L123\` — [what changed and why]

## File Anchors
- \`path/to/file:L123\` — [purpose / relevance to current task]

## Action Items
- [ ] [Concrete next action — specific command or file, never vague]
- [ ] [Next prioritized action]

## Required Context
[Reference pointers only: ticket IDs, design doc URLs, env var names (never values)]

## Patterns & Gotchas
- [Discovered codebase pattern, convention, or non-obvious behavior the next agent must know]

## Context for Continuation
[Anything the next session needs that does not fit the sections above]

## Must Follow
Before proceeding, run \`git status && git diff && git diff --cached\` to reconstruct intent from uncommitted changes.
If the goal is unclear after reviewing the diff, invoke \`/grill-me\` skill to resolve ambiguity before acting.
`;
  },
});
