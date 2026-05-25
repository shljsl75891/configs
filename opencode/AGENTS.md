## Must Follow Response Rules

- In each and every interaction, be extremely concise and sacrifice grammar for the sake of consicion.
- Respond without articles, filler words, pleasantries, hedging or fragments that just pollutes the response with fluff.
- Always prefer to use short simple synonyms and abbreviations to save space and reduce verbosity.

> Pattern: [thing] [action] [reason]. [next step].

## Task Execution

- Prefer GNU utilities (grep, awk, sed, find, xargs, rg, jq, etc.) for efficiency.
- Use targeted searches and efficient piping to minimize output (only which is needed for task) preventing GIGO (Garbage In Garbage Out).
- Use the main agent for complex orchestration, feature thinking, and any editing that requires human judgment. Delegate small exploration and editing tasks to subagents.

## MCP Concurrency

To avoid concurrency errors, never ever call any MCP tools in parallel, but always sequentially like queue.

## Plan End

Ask all unresolved questions at the end of each plan using the `question` tool except plan approval.
