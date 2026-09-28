# Lens: Conformance

Goal: find code that does not follow the patterns already established in this codebase — a bug class the codebase already solved somewhere else, solved again a different (worse, inconsistent, or subtly wrong) way.

## Method

1. **For every new or substantially changed file, find its 2 closest existing analogs** — same role (another repository class, another facade, another Angular feature component), usually in the same directory or a sibling feature's directory. Read them.
2. **Compare structure, not just behavior**: base class / superclass, mixins, decorators, dependency-injection pattern, validation approach, error handling, logging, caching, test shape, and (frontend) component style (standalone vs. module, template syntax, state management). Every difference from the analogs is a finding unless the diff shows a reason the new file is a genuinely different kind of thing.
3. **For every new helper, utility, constant, or import, search first** (`rg`) for an existing equivalent in the repo, and for what the repo's OTHER files use for the same purpose. A new one-off when an existing shared one would do is a finding — name the existing one.
4. **Check the architectural layer.** Does this logic sit where the codebase's own layering puts that kind of logic (e.g. validation, orchestration, persistence), matching what the analogs do?
5. **Check whether a new endpoint, file, or module duplicates something an existing one could be extended to cover instead.**
6. **If house rules were given** (`house-rules.md`), check every hunk against them. House rules describe what the code itself cannot show you — team preferences, business rules, naming conventions specific to this repo. Apply them the same way as the rest of this method, not as a separate pass.
7. **Before writing a finding, check `existing-comments.jsonl`** for the same path and a nearby line; skip it if already raised there.
8. **Decide proven vs. question yourself.** You named the exact sibling file and the exact difference → Issue/Fix format. You suspect a deviation but can't point to a specific sibling that does it differently → ❓ question format.

## Output

Same JSONL contract as `correctness.md`: one `"type":"file"` line per file you read, `"type":"finding"` lines whose `body` names the sibling file(s) you compared against in the Issue text, e.g. "...unlike `src/repositories/order.repository.ts:8`, which extends `BaseAuditRepository`." Prefix finding `id`s with the ID prefix you were given.
