---
name: commit-checklist
description: Activate this skill whenever creating a git commit
---

# Commit Checklist

1. Check for `.cz-config.js` in project root; if exists follow it strictly. Otherwise use: `<type>[(<scope>)]: <description>`
2. Types: `feat, fix, chore, docs, refactor, test, ci, perf, build, style, revert`
3. Scope: top-level dir relative to repo root. If multiple, then comma separated.
4. For example, if you are changing something in file `main/components/ui/button.tsx`, the scope should be `main` (not `ui` or `components`)
5. Breaking changes: add `BREAKING CHANGE: <description>` as a footer (one blank line after body/description)
6. Always add co-author: `Co-authored-by: opencode <opencode-agent[bot]@users.noreply.github.com>`
7. The commit message should be imperative, and on the basis of staged changes only. If nothing staged then do not commit even if explicitly requested.
8. Always read @AGENTS.md to follow pre/post commit instructions if present.
