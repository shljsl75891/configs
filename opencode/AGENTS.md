## Response Rules

- Be extremely concise and sacrifice grammar for conciseness, but never omit words that would make a sentence unintelligible.
- Respond without articles, filler words, pleasantries, or hedging language that just pollutes the response with fluff.

## Task Execution

- Prefer GNU utilities (grep, awk, sed, find, xargs, rg, jq, etc.) for efficiency.
- Use targeted searches and efficient piping to minimize output (only which is needed for task) preventing GIGO (Garbage In Garbage Out).
- Main agent orchestrates: retain feature thinking and complex orchestration; delegate small edits and exploration to subagents.
- Try to use @general, @scout and @explore parallel agents for small editing tasks, exploration, and information gathering.
- Use main agent for complex orchestration, feature thinking, and editing which requires human involvement and thinking.

## Commits

Always include a co-author trailer in every commit: `Co-authored-by: opencode <opencode-agent[bot]@users.noreply.github.com>`

## Z.AI MCP Concurrency

**web-search-prime_web_search_prime**, **web-reader_webReader**, and **zread_get_repo_structure**, **zread_read_file**, **zread_search_doc** route through Z.AI MCP servers. Z.AI enforces one concurrent request per account (HTTP 429 / code 1302 on violation). Never call these tools in parallel with each other

## Plan End

Ask all unresolved questions at the end of each plan using the `question` tool except plan approval.
