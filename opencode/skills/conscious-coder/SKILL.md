---
name: conscious-coder
description: Comprehensive guidelines for writing clean, minimal, well-tested code. Activate when writing code, implementing features, fixing bugs, refactoring, or starting to execute any plan involving a programming task.
---

# Mindset

## Think Before Coding

- State assumptions explicitly; if uncertain, ask the user
- If multiple interpretations exist, present all — never pick one silently
- Name what is confusing and ask rather than guessing

## Simplicity First

- Do not add features, abstractions, flexibility, or error handling beyond what was asked
- If the same outcome can be achieved with significantly less code, always prefer it — failing to do so is grounds for rejection without review
- If a senior engineer would call it over-complicated, simplify it

## Surgical Changes

- Touch only what is needed — every changed line must trace back to the user's request
- Do not improve adjacent code, comments, or formatting; it increases diff size and review time
- Do not suppress type errors with `any` or `unknown` unless explicitly asked
- Use dedicated types; only define abstract classes or interfaces when one or more classes implement them

# Code Quality for TypeScript

## Naming & Variables

- Use meaningful, descriptive names — reader should know what it is without context
- Same vocabulary for the same concept: `getUser()` not `getUserInfo/getUserData`
- Use named constants, not magic numbers: `MILLISECONDS_PER_DAY` not `86400000`
- Avoid mental mapping — explicit over implicit (`user` not `u`)
- No redundant context: `Car.make` not `Car.carMake`
- Use default params instead of short-circuit conditionals: `count = 10` not `count || 10`
- Use enums for sets of related values

## Functions

- ≤2 params ideally; use an options object for >2
- Do one thing only — if you can describe it with "and", split it
- Name by what they do: `addMonthToDate` not `addToDate`
- No flag params — split into two functions instead
- No side effects — return results, don't mutate inputs:

```ts
// good
function addItemToCart(cart: CartItem[], item: Item): CartItem[] {
  return [...cart, { item, date: Date.now() }];
}
```

- Favor `map/filter/reduce` over imperative loops
- Encapsulate conditionals into named predicate functions
- Prefer positive conditionals: `isEmailUsed` not `isEmailNotUsed`
- Use polymorphism over switch/if-chains when each case has distinct behavior
- Remove dead code — version control preserves history

## Types & Classes

- `type` for unions/intersections; `interface` when using `extends`/`implements`
- Prefer `readonly` and immutability:

```ts
interface Config {
  readonly host: string;
  readonly port: string;
}
```

- Use `private readonly` in constructor params
- Small classes with single responsibility — one reason to change
- High cohesion, low coupling — split classes with unrelated method groups
- Prefer composition over inheritance
- **SOLID in brief:**
  - **Single Responsibility**: one reason to change; extract unrelated concerns
  - **Open/Closed**: extend via new classes, not by modifying existing ones
  - **Liskov Substitution**: subtypes must be substitutable without breaking behavior
  - **Interface Segregation**: split large interfaces; don't force unused methods on clients
  - **Dependency Inversion**: depend on abstractions; inject dependencies rather than instantiating them

## Async & Errors

- Prefer `async/await` over callbacks or chained `.then()`
- Use `Promise.all` for parallel tasks; `Promise.race` for timeouts
- Always `throw new Error()`, never strings — preserves stack trace
- Never swallow caught errors — handle or log with context
- Never ignore rejected promises — use `.catch()` or `try/catch`

## Formatting & Comments

- `PascalCase`: classes, interfaces, types, enums
- `camelCase`: variables, functions, class members
- `SCREAMING_SNAKE_CASE`: module-level constants
- Place caller above callee — read top-to-bottom
- Import order: polyfills → Node builtins → external → internal → parent → sibling
- Use `import type` for type-only imports
- Use TS path aliases to avoid deep relative imports
- Only comment when logic is non-obvious and cannot be made clear through naming
- Never leave commented-out code — delete it
- No journal/changelog comments — use `git log`
- Use `// TODO:` for planned improvements only

# Testing

## Good vs Bad Tests

Test behavior through public interfaces, not implementation details:

```ts
// GOOD
test("user can checkout with valid cart", async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe("confirmed");
});

// BAD — coupled to internals
test("checkout calls paymentService.process", async () => {
  const mockPayment = jest.mock(paymentService);
  await checkout(cart, payment);
  expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});
```

A good test:

- Verifies behavior callers care about
- Uses public API only
- Survives internal refactors
- Describes WHAT, not HOW

Red flags: mocking internal collaborators, testing private methods, verifying via DB queries instead of the interface.

## When to Mock

Mock at **system boundaries only**: external APIs, databases (prefer test DB), time/randomness, file system.

**Never mock**: your own classes/modules, internal collaborators, anything you control.

## Design for Testability

Accept dependencies, don't create them:

```ts
// testable
function processPayment(order, paymentClient) {
  return paymentClient.charge(order.total);
}
```

Return results, don't produce side effects. Prefer SDK-style interfaces — specific functions per operation, not generic fetchers — so each is independently mockable.

Small surface area: fewer methods = fewer tests, fewer params = simpler setup.

# Design

## Deep Modules

**Deep module = small interface + lots of implementation.** Hide complexity inside; expose minimal surface.

Avoid shallow modules that just pass through. When designing interfaces ask:

- Can I reduce the number of methods?
- Can I simplify the parameters?
- Can I hide more complexity inside?

## Refactor Candidates

After each cycle, look for:

- **Duplication** → extract function/class
- **Long methods** → break into private helpers
- **Shallow modules** → combine or deepen
- **Feature envy** → move logic to where data lives
- **Primitive obsession** → introduce value objects
- **Existing code** the new code reveals as problematic

# Test Driven Development

Always suggest this workflow to the user and ask if they want to follow it.

If the user agrees, follow red-green-refactor:

- **RED**: write one failing test for next behavior
- **GREEN**: write minimal code to pass it
- **REFACTOR**: clean up, then repeat

Never write all tests first then all code — one test → one implementation → repeat.

Per-cycle checklist:

- [ ] Test describes behavior, not implementation
- [ ] Test uses public interface only
- [ ] Test would survive internal refactor
- [ ] Code is minimal for this test
