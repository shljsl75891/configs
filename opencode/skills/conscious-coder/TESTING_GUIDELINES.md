# Testing Guidelines

## Good vs Bad Tests

**Good tests** are integration-style: verify behavior through public interfaces, not implementation details.

```typescript
// GOOD: Tests observable behavior
test("user can checkout with valid cart", async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe("confirmed");
});
```

Characteristics:
- Tests behavior callers care about
- Uses public API only
- Survives internal refactors
- Describes WHAT, not HOW

**Bad tests** are coupled to implementation:

```typescript
// BAD: Tests implementation details
test("checkout calls paymentService.process", async () => {
  const mockPayment = jest.mock(paymentService);
  await checkout(cart, payment);
  expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});
```

Red flags:
- Mocking internal collaborators
- Testing private methods
- Test breaks on refactor without behavior change
- Verifying through external means (e.g. querying DB directly)

```typescript
// BAD: Bypasses interface
test("createUser saves to database", async () => {
  await createUser({ name: "Alice" });
  const row = await db.query("SELECT * FROM users WHERE name = ?", ["Alice"]);
  expect(row).toBeDefined();
});

// GOOD: Verifies through interface
test("createUser makes user retrievable", async () => {
  const user = await createUser({ name: "Alice" });
  const retrieved = await getUser(user.id);
  expect(retrieved.name).toBe("Alice");
});
```

## When to Mock

Mock at **system boundaries only**:
- External APIs (payment, email, etc.)
- Databases (prefer test DB when possible)
- Time / randomness
- File system

**Never mock**: your own classes/modules, internal collaborators, anything you control.

## Designing for Mockability

**Use dependency injection** — pass external deps in, don't create them internally:

```typescript
// Easy to mock
function processPayment(order, paymentClient) {
  return paymentClient.charge(order.total);
}

// Hard to mock
function processPayment(order) {
  const client = new StripeClient(process.env.STRIPE_KEY);
  return client.charge(order.total);
}
```

**Prefer SDK-style interfaces** — specific functions per operation, not generic fetchers:

```typescript
// GOOD: Each function independently mockable
const api = {
  getUser: (id) => fetch(`/users/${id}`),
  createOrder: (data) => fetch('/orders', { method: 'POST', body: data }),
};

// BAD: Mock requires conditional logic
const api = {
  fetch: (endpoint, options) => fetch(endpoint, options),
};
```
