---
name: conscious-coder
description: Activate this skill before you design a solution, select a library or dependency, or make the first code change in a task. This includes writing, editing, and reviewing code, and it includes the moment directly after a plan is approved.
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

Use the ladder after you understand the problem. Do not use it in place of
understanding. Read the task and the code that it touches, trace the real flow, then
use the ladder.

Correct the cause of a bug, not the symptom. Find all callers of the function that you
change, then correct the shared path one time.

Do not remove these items to make the code smaller: input validation at trust
boundaries, error handling that prevents data loss, security controls, accessibility
basics, and anything that the user requested.

If a senior engineer calls this too complex, make it simple. Do not add anything beyond what the user asked for.

## Surgical Changes

- Touch only what is needed — every changed line must trace back to the user's request
- Do not improve adjacent code, comments, or formatting; it increases diff size and review time
- Do not suppress type errors with `any` or `unknown` unless explicitly asked
- Use dedicated types; only define abstract classes or interfaces when one or more classes implement them
- Comments default to none — add only for a non-obvious WHY; to the point, crisp and crystal clear, never WHAT
- A comment explaining self explanatory code is a smell; remove it completely.
- Never write comments that narrate this session's history; every comment must stand on its own to a reader who has not seen this conversation.

## Testing

Test Driven Development is the default workflow. Follow it unless the user explicitly opts out.

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

#### Testability

Mock at **system boundaries only**: external APIs, databases (prefer test DB), time/randomness, file system. Never mock your own classes/modules or anything you control.

Accept dependencies, don't create them. Return results, don't produce side effects. Prefer SDK-style interfaces — specific functions per operation (`getUser(id)`, `createOrder(data)`), not a generic `fetch(endpoint, options)` — so each is independently mockable.

#### Deep Modules

**Deep module = small interface + lots of implementation.** Hide complexity inside; expose minimal surface.

Avoid shallow modules that just pass through. When designing interfaces ask:

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

## Pre-Finish Self-Audit

Before declaring a task done, re-scan the diff once for over-engineering and remove them:

- Any abstraction with only one call site? or any parameter/flag with only one use?
- Any code path added "for later" that no test or requirement needs?
- Any comments those explain the obvious things, session coupled and WHAT for self explanatory code?
