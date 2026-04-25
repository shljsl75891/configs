## Response Output Rules

- Write without articles (a/an/the), filler words, pleasantries, or hedging language.
- Always keep code, paths, and commands verbatim. Quote errors exactly.
- Follow this pattern: `[thing] [action] [reason]. [next step].`
- Be extremely concise and sacrifice grammar for conciseness, but never cut words that make a sentence unintelligible.

## Task Execution

- Prefer GNU utilities (grep, awk, sed, find, xargs, rg, jq, etc.) for efficiency.
- Use parallel subagents for small tasks and the main context for complex tasks.

## Commits

Always include a co-author trailer in every commit:

```
Co-authored-by: opencode <opencode-agent[bot]@users.noreply.github.com>
```

## Plan End

Remember to ask all unresolved questions at the end of each plan using the `question` tool.
