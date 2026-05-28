# Design Principles

## Interface Design for Testability

Good interfaces make testing natural:

**Accept dependencies, don't create them:**
```typescript
// Testable
function processOrder(order, paymentGateway) {}

// Hard to test
function processOrder(order) {
  const gateway = new StripeGateway();
}
```

**Return results, don't produce side effects:**
```typescript
// Testable
function calculateDiscount(cart): Discount {}

// Hard to test
function applyDiscount(cart): void {
  cart.total -= discount;
}
```

**Small surface area** — fewer methods = fewer tests needed, fewer params = simpler test setup.

## Deep Modules

From "A Philosophy of Software Design": **deep module = small interface + lots of implementation**.

```
┌─────────────────────┐
│   Small Interface   │  ← Few methods, simple params
├─────────────────────┤
│                     │
│  Deep Implementation│  ← Complex logic hidden inside
│                     │
└─────────────────────┘
```

Avoid **shallow modules** (large interface, thin implementation — just passes through).

When designing interfaces, ask:
- Can I reduce the number of methods?
- Can I simplify the parameters?
- Can I hide more complexity inside?

## Refactor Candidates

After each TDD cycle, look for:

- **Duplication** → extract function/class
- **Long methods** → break into private helpers (keep tests on public interface)
- **Shallow modules** → combine or deepen
- **Feature envy** → move logic to where data lives
- **Primitive obsession** → introduce value objects
- **Existing code** the new code reveals as problematic
