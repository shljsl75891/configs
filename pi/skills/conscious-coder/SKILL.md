---
name: conscious-coder
description: Load before you design a solution, select a library or dependency, or write or edit code. Also load immediately after plan approval like "Go Ahead".
---

## The Ladder

Stop at the first rule that applies.

1. Do you need this? If you do not need it, do not write it. (YAGNI)
2. Does this codebase have it? Use the existing code. Do not write it again.
3. Does the standard library do it? Use the standard library.
4. Does the platform do it? Use the native platform feature.
5. Does an installed dependency do it? Use that dependency. Do not add a new dependency.
6. Can you write it in one line? Write one line.
7. If no rule above applies, write the smallest code that operates correctly.

- Use the ladder after you understand the problem. Do not use it in place of understanding. Read the task and the code that it touches, trace the real flow, then use the ladder.
- Correct the cause of a bug, not the symptom. Find all callers of the function that you change, then correct the shared path one time.
- Do not remove these items to make the code smaller: input validation at trust boundaries, error handling that prevents data loss, security controls, accessibility basics, and anything that the user requested.

If a senior engineer calls this too complex, make it simple. Do not add anything beyond what the user asked for.

## Think Before Coding

- State assumptions explicitly; if uncertain, ask the user
- If multiple interpretations exist, present all — never pick one silently
- Name what is confusing and ask rather than guessing
- If a simpler approach exists, say so; push back when warranted

## Ubiquitous Language

One concept, one word — in code, tests, comments, and commits.

- Before you name a domain concept, find the project's vocabulary. Search for any source: glossary or context docs, domain or knowledge graphs, ADRs, design docs, pointers in `AGENTS.md`/`README`, and the names already in dominant use in the code. Do not assume a path.
- Use the canonical term. Never use a known synonym for it. Generic tech words (timeout, repository, DTO) are not domain terms.
- Ask the user with the `question` tool, before you write the name, when: (1) two words name one concept, (2) one word may mean two concepts, (3) the concept has no term yet — propose a name that fits nearby terms, (4) the code contradicts a documented domain rule, or (5) you find no source at all.
- When the user resolves a term and the repo already has a vocabulary file, offer to add the term. Do not create a new file.

## Surgical Changes

- Touch only what is needed — every changed line must trace back to the user's request
- Do not improve adjacent code, comments, or formatting; it increases diff size and review time
- Do not suppress type errors with `any` or `unknown` unless explicitly asked
- Use dedicated types; only define abstract classes or interfaces when one or more classes implement them

## Comments

- Try to make the comment unnecessary first: rename the variable/function, extract a helper, or restructure the condition. Do this before writing any comment.
- Write a comment only when the code still cannot show a WHY that reading it will not reveal — a business rule, external constraint, tradeoff, or workaround for a bug/API quirk. Never write a WHAT comment, never restate self-explanatory code, and never narrate this session's history.
- Use JSDoc (`/** */`) for anything a reader may hover: functions, variables, types, classes. Use a single-line `//` only for a one-line note on business logic. Never stack multiple `//` lines for a multi-line note — use JSDoc or a `/* */` block instead.
- Write every comment in Simplified Technical English (ASD-STE100).

## Testing

Test Driven Development is the default workflow. Follow it unless the user explicitly opts out. If `SPEC.md` exists in the ticket's `.pi/specs/` directory, test only at the seams it lists. Otherwise pick the highest existing seam and confirm it with the user. Do not refactor inside the red/green loop; refactor at review.

Cadence: run the typecheck and the single test you work on often. Run the full suite once per slice. Write only enough code to pass the current test.

#### Good vs Bad Tests

Test behavior through public interfaces, not implementation details:

```ts
// GOOD - through the public interface
it("checks user can checkout with valid cart", async () => {
  cart.add(product);
  expect((await checkout(cart, paymentMethod)).status).toBe("confirmed");
});

// BAD - coupled to internals
test("checkout calls paymentService.process", async () => {
  expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});
```

Red flags: mocking internal collaborators, testing private methods, verifying via DB queries instead of the interface.

#### Writing Tests

- The public interface is the test surface. Replace old tests that cover the same behavior; do not layer new ones on top.
- A test name says WHAT the behavior is, not how the code works.
- One logical assertion per test.
- Do not assert call counts.

#### Testability

Mock at **system boundaries only**: external APIs, databases (prefer test DB), time/randomness, file system. Never mock your own classes/modules or anything you control.

Accept dependencies, don't create them. Return results, don't produce side effects. Prefer SDK-style interfaces — specific functions per operation (`getUser(id)`, `createOrder(data)`), not a generic `fetch(endpoint, options)` — so each is independently mockable.

#### Deep Modules

**Deep module = small interface + lots of implementation.** Hide complexity inside; expose minimal surface.

Avoid shallow modules that just pass through. Deletion test: if deleting a module makes its complexity vanish, it was a pass-through. One adapter is a guess at a seam; two make it real. When designing interfaces ask:

- Can I reduce the number of methods?
- Can I simplify the parameters?
- Can I hide more complexity inside?

#### Anti-Pattern: Tautological Tests

A test whose expected value is recomputed the same way the code computes it passes by construction and gives zero confidence. Expected values must come from an independent source of truth, not the implementation's own logic.

```ts
// BAD - tautological: recomputes the same formula the code uses
it("calculates total", () => {
  const items = [
    { price: 10, qty: 2 },
    { price: 5, qty: 3 },
  ];
  const expected = items.reduce((sum, i) => sum + i.price * i.qty, 0);
  expect(calculateTotal(items)).toBe(expected);
});

// GOOD - expected value is an independently known constant
it("calculates total", () => {
  const items = [
    { price: 10, qty: 2 },
    { price: 5, qty: 3 },
  ];
  expect(calculateTotal(items)).toBe(35);
});
```

Distinct from implementation-coupling (testing internals) — this is about the _assertion_, not the _access path_.

#### Anti-Pattern: Horizontal Slices

**Never write all tests first, then all implementation.**

```
WRONG (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT (vertical):
  RED→GREEN: test1→impl1
  RED→GREEN: test2→impl2
  RED→GREEN: test3→impl3
  ...
```

Bulk tests guess at behavior before you understand the implementation — they test _shape_, not behavior.

## Slice Gate

Build one task as one vertical slice. Before you start a slice, the previous slice must have a green test run. After each slice, run the tests, mark its todo done, then start the next. A red test inside the slice (the RED step) is fine.

## Debug Loop

Build a fast loop that shows the bug first. Do not guess-fix. Follow [DEBUG.md](DEBUG.md).

See [RED-FLAGS.md](RED-FLAGS.md) when you feel like skipping a test or a step.

## Review Hand-Off

After the last todo, load the `code-review` skill in this session and follow it. It launches the lens subagents. Fix findings or report them.

## Pre-Finish Self-Audit

Before declaring a task done, read `SPEC.md` in the ticket's `.pi/specs/` directory if it exists and check every constraint and Developer AC item. Then re-scan the diff once for over-engineering and remove them:

- Any abstraction with only one call site? or any parameter/flag with only one use?
- Any code path added "for later" that no test or requirement needs?
- Every new domain name canonical, or approved by the user?
- Re-check every comment against the Comments rules above; fix or delete any that fail.
