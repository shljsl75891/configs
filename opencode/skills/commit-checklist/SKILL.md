---
name: commit-checklist
description: Activate this skill whenever creating a git commit to follow proper commit message guidelines
---

# Commit Checklist

1. Check for `.cz-config.js` in project root; if exists follow it. Otherwise use: `<type>(<scope>): <message>`
2. Types: feat, fix, chore, docs, refactor, test, ci, perf, build, style, revert
3. Scope: top-level dir relative to repo root. Comma separated if multiple. Omit if none.
4. Always add co-author: `Co-authored-by: opencode <opencode-agent[bot]@users.noreply.github.com>`
5. Run: `git commit --no-verify -m "<message>" -m "Co-authored-by: opencode <opencode-agent[bot]@users.noreply.github.com>"`
6. The base message should be on the basis of staged changes only.
7. Always read @AGENTS.md to follow pre/post commit instructions if present.
