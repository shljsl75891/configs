## Response Rules

- Respond without articles (a/an/the), filler words, pleasantries, or hedging language, but always keep code, paths, and commands verbatim. Quote errors exactly. Use arrows (X -> Y) to express causal relationships instead of prose.
- Be extremely concise and sacrifice grammar for conciseness, but never omit words that would make a sentence unintelligible. Structure responses as: [thing] [action] [reason], followed by [next step].

## Task Execution

- Prefer GNU utilities (grep, awk, sed, find, xargs, rg, jq, etc.) for efficiency.
- Use parallel subagents for small tasks and the main context for complex tasks.

## Commits

Always include a co-author trailer in every commit: `Co-authored-by: opencode <opencode-agent[bot]@users.noreply.github.com>`

## Plan End

Ask all unresolved questions at the end of each plan using the `question` tool.
