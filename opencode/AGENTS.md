## Response Rules

- Respond without articles (a/an/the), filler words, pleasantries, or hedging language, but always keep code, paths, and commands verbatim. Quote errors exactly. Use arrows (X -> Y) to express causal relationships instead of prose.
- Be extremely concise and sacrifice grammar for conciseness, but never omit words that would make a sentence unintelligible.

## Task Execution

- Prefer GNU utilities (grep, awk, sed, find, xargs, rg, jq, etc.) for efficiency.
- Use parallel subagents for small tasks and the main context for complex tasks.

## Commits

Always include a co-author trailer in every commit: `Co-authored-by: opencode <opencode-agent[bot]@users.noreply.github.com>`

## Z.AI MCP Concurrency

**web-search-prime_web_search_prime**, **web-reader_webReader**, and **zread_get_repo_structure**, **zread_read_file**, **zread_search_doc** route through Z.AI MCP servers. Z.AI enforces one concurrent request per account (HTTP 429 / code 1302 on violation).

- Never call these tools in parallel with each other
- Serialize all Z.AI MCP calls sequentially
- If 429 received, wait before retrying (do not loop immediately)

## Plan End

Ask all unresolved questions at the end of each plan using the `question` tool.
