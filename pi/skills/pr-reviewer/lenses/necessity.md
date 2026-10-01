# Lens: Necessity, Naming and Comments

Goal: find code that should not exist as written — because it is not needed, or because its name or comment does not tell the truth about what it does.

## Method

1. **List every new symbol** introduced by the hunks in your group: functions, methods, classes, types, constants, component inputs/outputs, flags/booleans.
2. **For each, count its uses** (`rg` the name across the whole worktree, not just the diff). Ask: does this need to exist as its own thing?
   - A method with exactly one caller that does nothing but call another method, or make one API call.
   - A boolean/flag parameter that could instead be two call sites, or a derived value.
   - A parameter that is always passed the same value everywhere it is called.
   - A check or condition that duplicates one already done by a caller or by the framework.
   - A branch that can never be reached given the types or the callers.
   - A value stored that could instead be computed on read from the values it derives from.
   - An endpoint, DTO, or test that covers nothing the PR's other tests/endpoints do not already cover.
3. **Code judo**: is there a smaller change — often one that deletes code — that reaches the same behavior? Name it if so.
4. **Naming**: for each new/changed symbol, read a call site cold. Does the name say what the code actually does? Flag a vague verb (`process`, `handle`, `update` with no object), a name that promises more or less than the implementation does, and two names used inconsistently for the same concept.
5. **Comments**: flag a comment that only restates the line under it (say it should be deleted, or name the rename that removes the need for it), and a comment that no longer matches the code beside it. A comment that explains a real WHY (a business rule, a workaround, a non-obvious constraint) is correct and must not be flagged.
6. **Also flag**: a comment or JSDoc that disagrees with the code (signature, behavior, edge case, complexity claim); a TODO/FIXME with no issue link, or one already done; a magic number or string with no named constant; nested ternaries; nesting deeper than 3 levels; a function doing more than one job; dead code, unused import/export/param, commented-out code; a file or function grown large by this PR; a PR that mixes unrelated changes.
7. **Before writing a finding, check `existing-comments.jsonl`** for the same path and a nearby line; skip it if already raised there.
8. **Decide proven vs. question yourself.** You counted the call sites yourself with `rg` → Issue/Fix format. You are guessing at intent (e.g. "might be a planned extension point") → ❓ question format.

## Output

Same JSONL contract as `correctness.md`. Name the use-count you found in the body's Issue text, e.g. "rg found 1 call site: src/foo.ts:40." Prefix finding `id`s with the ID prefix you were given.
