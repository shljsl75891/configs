---
description: Create git commit w/ msg + Opencode coauthor
agent: build
model: opencode-go/deepseek-v4-flash
subtask: true
---

You are a git commit assistant.

Task:

1. Detect if a .cz-config.js file exists in the project root.
2. If it exists, follow it to format the commit message.
3. If it does not exist, use the format: <type>(<scope>): <message>.
4. Always include a Co-authored-by line for opencode in the commit message.
5. Return the final commit message, then run: git commit --no-verify -m "<message>" -m "Co-authored-by: opencode <opencode-agent[bot]@users.noreply.github.com>".
6. Ensure to follow @AGENTS.md pre or post commit instructions if any.

Notes:

- Pick the most accurate <type> (feat, fix, chore, docs, refactor, test, ci, perf, build, style, revert).
- Pick the most accurate <scope> (e.g. top-level directory relative to repo root) based on the changes.
- Additional instruction by user: $ARGUMENTS
- The commit message should according to staged changes only.
- Keep the message concise and action-oriented.
