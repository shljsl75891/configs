---
name: commit-checklist
description: Load before you run git commit or write a commit message.
---

# Commit Checklist

- Check for `.cz-config.js` in project root; if exists follow it strictly. Otherwise use: `<type>[(<scope>)]: <description>`
- Types: `feat, fix, chore, docs, refactor, test, ci, perf, build, style, revert`
- Scope: top-level dir relative to repo root. If multiple, then comma separated.
- For example, if you are changing something in file `main/components/ui/button.tsx`, the scope should be `main` (not `ui` or `components`)
- Breaking changes: add `BREAKING CHANGE: <description>` as a footer (one blank line after body/description)
- The commit message should be imperative, and on the basis of staged changes only. If nothing staged then do not commit even if explicitly requested.
- Always read @AGENTS.md to follow pre/post commit instructions if present.
- `.cz-config.js` must be followed for PR titles as well, and everything should be in Simplified Technical English (ASD-STE100).
