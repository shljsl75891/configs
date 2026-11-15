---
name: code-review
description: Load to review code, a diff, staged changes, a commit, or a file, and as the lens source for pr-reviewer. Holds the review lenses and the review output format.
---

# Code Review

Lenses live in `lenses/` next to this file. Each lens is a focused checklist.

## Lenses

- `correctness.md`, `conformance.md`, `necessity.md`, `security.md`, `reliability.md`, `tests.md`, `simplification.md`, `performance.md`: all languages.
- `clean-code-ts.md`: only when the diff has TS/JS files.

## Local review (no PR)

1. Get the diff (`git diff`, staged changes, a commit, or the named file). Review only changed code unless told otherwise.
2. Read `SPEC.md` in the ticket's `.pi/specs/` directory if it exists. Check the diff against it. Each Tracker AC and Developer AC item needs code that does it. A broken constraint is a finding.
3. Read each applicable lens. Run one `general` subagent per lens in parallel. Task template for each (ignore the lens's own "Output" section; it is for the PR flow):
   > You are a lens worker. Do not load skills. Do not launch subagents. Review this diff only through the lens below. Diff: <diff or command to get it>. SPEC: <SPEC.md path or "none">. Lens: <full lens text>. Return a plain list. Each item: `path:line`, category, severity (Critical/High/Medium/Low), current code, problem, concrete fix. Quote the SPEC line for a SPEC finding. If SPEC is "none", say "no spec available" and skip SPEC checks. Read CONTRIBUTING or coding-standard files if present; a repo standard beats the smell list. Flag scope creep beyond the SPEC.
4. Remove only exact duplicates (same location, same issue). Do not rerank or combine the rest. Keep findings grouped by lens.
5. Use the `question` tool only when an answer changes the review.

## Policy

Flag every issue. No count cap, no "nitpick" filter. Drop a finding only when you can prove it wrong. A finding you cannot prove stays as a ❓ question.

Skip what lint, the type checker, or formatters in CI already catch. Never flag import order or import sorting.

Be direct. Correctness alone is not enough to approve. Do not rubber-stamp working but messy code. Do not demand abstractions that do not pay for themselves. Calibrate for prototypes and scripts.

## Output

- **Summary**: 2–3 sentences, then `net: -N lines possible` (or `net: 0, structural issue only`).
- **Issues**: each with title, category, severity (Critical/High/Medium/Low), location, current code, problem, suggested fix. Group by lens; do not rerank across lenses. Only the Priority Action List is ranked.
- **Priority Action List**: top 3–5 changes.
- **Positives**: 1–3 things done well.
- **Verdict**: Approve or Request Changes. Presumptive blockers: structural regression, missed code-judo that deletes a category of complexity, ad-hoc branching in unrelated flows, feature logic in shared paths, thin wrapper or cast hiding the contract, duplicated canonical helper, unnecessary optionality, ignored obvious decomposition, broken `SPEC.md` constraint or AC.

Before you answer, check: every applicable lens ran, and suggestions are TS-idiomatic for TS/JS code.
