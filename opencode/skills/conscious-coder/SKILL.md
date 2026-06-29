---
name: conscious-coder
description: Comprehensive guidelines for writing clean, minimal, well-tested code. Activate when writing code, implementing features, fixing bugs, refactoring, or starting to execute any plan involving a programming task.
---

# Mindset

## Think Before Coding

- State assumptions explicitly; if uncertain, ask the user
- If multiple interpretations exist, present all — never pick one silently
- Name what is confusing and ask rather than guessing
- If a simpler approach exists, say so; push back when warranted

## Simplicity First

- Do not add features, abstractions, flexibility, or error handling beyond what was asked
- No abstractions for single-use code
- No error handling for impossible scenarios
- If the same outcome can be achieved with significantly less code, always prefer it — failing to do so is grounds for rejection without review
- If you write 200 lines and it could be 50, rewrite it
- If a senior engineer would call it over-complicated, simplify it

## Surgical Changes

- Touch only what is needed — every changed line must trace back to the user's request
- Do not improve adjacent code, comments, or formatting; it increases diff size and review time
- Match existing style, even if you'd do it differently
- If you notice unrelated dead code, mention it — don't delete it
- Remove imports/variables/functions YOUR changes made unused
- Don't remove pre-existing dead code unless asked
- Do not suppress type errors with `any` or `unknown` unless explicitly asked
- Use dedicated types; only define abstract classes or interfaces when one or more classes implement them

## Goal-Driven Execution

Define success criteria. Loop until verified.

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan with per-step verify checks:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
```

Strong success criteria enable independent looping. Weak criteria ("make it work") require constant clarification.

## Testing

Test Driven Development is the default workflow. Follow it unless the user explicitly opts out.

#### Workflow

1. **Plan**: list behaviors to test; confirm with user, get approval
2. **Tracer bullet**: one test → minimal impl; proves end-to-end path
3. **Loop**: repeat one test → one impl; never anticipate future tests
4. **Refactor**: after GREEN only (see Design > Refactor Candidates); run tests after each step

#### Good vs Bad Tests

Test behavior through public interfaces, not implementation details:

```ts
// GOOD - tests public interface, uses it and should
it("should check user can checkout with valid cart", async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe("confirmed");
});

// BAD — coupled to internals and not using it and should
test("checkout calls paymentService.process", async () => {
  const mockPayment = jest.mock(paymentService);
  await checkout(cart, payment);
  expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});
```

Red flags: mocking internal collaborators, testing private methods, verifying via DB queries instead of the interface.

#### Testability

Mock at **system boundaries only**: external APIs, databases (prefer test DB), time/randomness, file system. Never mock your own classes/modules or anything you control.

Accept dependencies, don't create them. Return results, don't produce side effects. Prefer SDK-style interfaces — specific functions per operation, not generic fetchers — so each is independently mockable.

```ts
// GOOD: each function independently mockable, one return shape per mock
const api = {
  getUser: (id) => fetch(`/users/${id}`),
  getOrders: (userId) => fetch(`/users/${userId}/orders`),
  createOrder: (data) => fetch("/orders", { method: "POST", body: data }),
};

// BAD: mocking requires conditional logic inside the mock
const api = {
  fetch: (endpoint, options) => fetch(endpoint, options),
};
```

#### Deep Modules

**Deep module = small interface + lots of implementation.** Hide complexity inside; expose minimal surface.

Avoid shallow modules that just pass through. When designing interfaces ask:

- Can I reduce the number of methods?
- Can I simplify the parameters?
- Can I hide more complexity inside?

#### Refactor Candidates

After each cycle, look for:

- **Duplication** → extract function/class
- **Long methods** → break into private helpers
- **Shallow modules** → combine or deepen
- **Feature envy** → move logic to where data lives
- **Primitive obsession** → introduce value objects
- **Existing code** the new code reveals as problematic

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

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
