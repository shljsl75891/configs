# Brief: Reviewer Brief

Adapted from the `pr` skill in mattpocock/skills (credit: Dex Horthy, Humanlayer, `show-me`). That skill helps an author write a PR body. This one writes a REVIEWER's view, from the code and diff only. Never read the PR title or description.

Write `$STATE_DIR/brief.md`. Skip preambles; keep prose brief. Read `$STATE_DIR/src` freely.

## Output shape

````markdown
<!-- pr-reviewer:brief -->
## Reviewer brief

### Summary
<smallest view that makes the key point>

### Evidence
<table: behavior change | test that proves it ✅ or ⚠️ no test>

### Merge Danger
**Door:** <One-way or Two-way> (<reason, with `path:line`>)
**Blast Radius:** <one word>. <who or what is hit>

**Credit:** Pi
<!-- /pr-reviewer:brief -->
````

## Summary

Pick the smallest view. Use a `diff` block when the shape already exists and the point is what changes:

- logic or algorithm → pseudocode
- runtime control flow → call tree
- UI structure → component tree (state and module boundaries that matter)
- file responsibility or broad refactor → shallow file tree
- component or data interaction → mermaid
- mostly-new code → show the whole block

Keep only calls, files, props, states and boundaries the reader needs. Do not overwhelm.

## Evidence

List each behavior change in the non-test hunks. For each, name the test that proves it (`rg` spec/test files, in and outside the diff) with ✅, or write ⚠️ when no test covers it. Test results from the author are NOT evidence here — you cannot run them or read the PR body.

## Merge Danger

- **Door**: one-way if it is hard or impossible to walk back after merge. Include one-way DATA changes: bulk rewrites, `noAudit`, destructive migrations, dropped columns, changed persisted formats, published events, removed public exports. Reverting the code must undo the change for a two-way door.
- **Blast Radius**: one word (narrow, moderate, wide) plus who or what is hit: consumers of shared packages, generated services, every tenant, layout shift, mobile, public API.

Write in Simplified Technical English (ASD-STE100).
