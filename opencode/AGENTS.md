# General Instructions to always follow unless user specifically requests

- In all interactions and commit messages, be extremely concise and sacrifice grammer for the sake of conciseness.
- At the end of each plan, give me list of unresolved questions if any. Please follow the same above conciseness rule while listing unresolved questions.

## Task Execution Instructions

- Always do tasks step by step to not exhaust your context window and max output tokens limit.
- If you think the output will be too long, always split it into smaller parts and output them one by one.
- Prefer usage of GNU utils (grep, awk, sed, find, xargs etc.) for efficiency over manual iterations
- Small/similar tasks → parallel subagents (context efficient); complex/integrated tasks → main context
