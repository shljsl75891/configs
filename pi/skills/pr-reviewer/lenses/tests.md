# Lens: Tests

Goal: find behavior that is not proven by a test, and tests that would not catch a break.

## Method

1. **List every behavior change** in non-test hunks (new branch, new error path, changed boundary, new endpoint, changed query). For each, find the test that exercises it (`rg` the symbol in spec/test files, in and outside the diff). No test → finding.
2. **For every new or changed test, ask "would this fail if the code were broken?"** Mentally delete or invert the key line of the code under test.
3. **Compare with the closest existing test file** for the same kind of unit (shape, fixtures, DB vs. mock, naming). Differences are findings.
4. **Check `existing-comments.jsonl`** for the same path and nearby line; skip if already raised.
5. **Proven vs. question**: you searched and found no covering test → Issue/Fix. You are unsure whether another suite covers it → ❓.

## Checks

- **Missing coverage** — changed behavior with no test change; untested error/failure path; untested boundary (0, 1, empty, max, limit±1, null/undefined); no negative case for validation or authorization; new endpoint without an integration test; concurrency/idempotency path untested.
- **Tests that cannot fail** — no assertion; assertion on a mock's own return; `expect(...).toBeDefined()`/`toBeTruthy()` where a value is known; `try/catch` in a test without a failing fallback; un-awaited async assertion; `.skip`/`.only`/`xit`/`fit` left in; commented-out test; assertion inside a callback that may never run.
- **Coupled to implementation** — asserts on internal calls of your own collaborators; mocks internal modules instead of system boundaries; private-method access; snapshot of a large object that hides intent.
- **Weak assertions** — piecemeal field checks where whole-object equality is clearer; only status code checked, not body/side effects; only happy path asserted.
- **Flakiness** — real clock, `Date.now`, timezone, `Math.random`, network, shared DB state, test-order dependence, `setTimeout` waits, un-reset mocks/globals between tests.
- **Fixtures and data** — test hardcodes values that mirror the implementation (test computes expected with the same code); fixtures with real secrets/PII; shared mutable fixture.
- **Snapshots / generated** — snapshot updated wholesale with unrelated changes; snapshot churn that hides a real behavior change.
- **Test hygiene** — misleading test name; one test asserting many unrelated things; duplicated setup that should be shared; deleted tests with no replacement.

## Output

Same JSONL contract as `correctness.md`. For a missing-test finding, anchor on the changed source line and name the behavior that lacks a test; list the searches you ran in the Issue text.
