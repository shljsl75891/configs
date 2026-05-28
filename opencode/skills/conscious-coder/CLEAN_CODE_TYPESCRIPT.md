# Clean Code TypeScript

## Variables

- Use meaningful, descriptive names — reader should know what it is without context
- Use same vocabulary for the same concept: `getUser()` not `getUserInfo/getUserDetails/getUserData`
- Use named constants, not magic numbers/strings

```ts
// bad
setTimeout(restart, 86400000);
// good
const MILLISECONDS_PER_DAY = 24 * 60 * 60 * 1000;
setTimeout(restart, MILLISECONDS_PER_DAY);
```

- Use explanatory variables: destructure to named vars instead of indexing
- Avoid mental mapping — explicit over implicit (`user` not `u`)
- No redundant context: `Car.make` not `Car.carMake`
- Use default params instead of short-circuit conditionals: `count = 10` not `count || 10`
- Use enums to document intent for sets of related values

## Functions

- ≤2 params ideally; use an options object for >2

```ts
// bad
function createMenu(title: string, body: string, buttonText: string, cancellable: boolean) {}
// good
function createMenu(options: { title: string; body: string; buttonText: string; cancellable: boolean }) {}
```

- Do one thing only — if you can describe a function with "and", split it
- Name functions by what they do: `addMonthToDate` not `addToDate`
- One level of abstraction per function — split low-level details into sub-functions
- No duplicate code — extract shared logic, but don't create cross-domain dependencies
- No flag params — split into two functions instead

```ts
// bad
function createFile(name: string, temp: boolean) {}
// good
function createFile(name: string) {}
function createTempFile(name: string) {}
```

- No side effects — return results, don't mutate inputs

```ts
// bad
function addItemToCart(cart: CartItem[], item: Item): void {
  cart.push({ item, date: Date.now() });
}
// good
function addItemToCart(cart: CartItem[], item: Item): CartItem[] {
  return [...cart, { item, date: Date.now() }];
}
```

- Favor functional/declarative over imperative: use `reduce`, `filter`, `map`
- Encapsulate conditionals into named predicate functions

```ts
// bad
if (subscription.isTrial || account.balance > 0) {}
// good
function canActivateService(sub: Subscription, acct: Account) {
  return sub.isTrial || acct.balance > 0;
}
if (canActivateService(subscription, account)) {}
```

- Prefer positive conditionals: `isEmailUsed` not `isEmailNotUsed`
- Use polymorphism over switch/if-chains when each case has distinct behavior
- Remove dead code — version control preserves history

## Objects and Data Structures

- Use getters/setters for properties that need validation or encapsulation
- Use `private readonly` in constructor params

```ts
// bad
class Circle {
  radius: number;
  constructor(radius: number) { this.radius = radius; }
}
// good
class Circle {
  constructor(private readonly radius: number) {}
}
```

- Prefer immutability

```ts
// readonly properties
interface Config { readonly host: string; readonly port: string; }

// read-only arrays
const arr: ReadonlyArray<number> = [1, 3, 5];

// const assertions for literals
const config = { host: "localhost", port: 3000 } as const;
```

- `type` for unions/intersections; `interface` when using `extends`/`implements`

## Classes

- Small classes with single responsibility — one reason to change
- High cohesion, low coupling — split classes that have unrelated groups of methods/state

```ts
// bad: UserManager handles both data access and email
// good:
class UserService {
  constructor(private readonly db: Database) {}
  async getUser(id: number) { return this.db.users.findOne({ id }); }
}
class UserNotifier {
  constructor(private readonly email: EmailSender) {}
  async sendGreeting() { await this.email.send("Welcome!"); }
}
```

- Prefer composition over inheritance; use inheritance only for "is-a" relationships where base class behavior is reused
- Return `this` from mutating methods to enable method chaining

## SOLID

### SRP — Single Responsibility
One reason to change. Extract unrelated concerns into separate classes.

```ts
// bad: UserSettings also handles auth
// good:
class UserAuth { verifyCredentials() {} }
class UserSettings {
  constructor(private readonly auth: UserAuth) {}
  changeSettings(s: Settings) { if (this.auth.verifyCredentials()) {} }
}
```

### OCP — Open/Closed
Open for extension, closed for modification. Add behavior via new classes, not by modifying existing ones.

```ts
// bad: HttpRequester checks instanceof for each adapter type
// good:
abstract class Adapter { abstract request<T>(url: string): Promise<T>; }
class AjaxAdapter extends Adapter { async request<T>(url: string) { /* ... */ } }
class NodeAdapter extends Adapter { async request<T>(url: string) { /* ... */ } }
class HttpRequester {
  constructor(private readonly adapter: Adapter) {}
  async fetch<T>(url: string) { return this.adapter.request<T>(url); }
}
```

### LSP — Liskov Substitution
Subtypes must be substitutable for their base type without breaking behavior. Prefer separate classes over inheritance when behavior diverges.

```ts
// bad: Square extends Rectangle but breaks setWidth/setHeight contract
// good:
abstract class Shape { abstract getArea(): number; }
class Rectangle extends Shape {
  constructor(private readonly w: number, private readonly h: number) { super(); }
  getArea() { return this.w * this.h; }
}
class Square extends Shape {
  constructor(private readonly side: number) { super(); }
  getArea() { return this.side * this.side; }
}
```

### ISP — Interface Segregation
Don't force clients to depend on methods they don't use. Split large interfaces.

```ts
// bad: EconomicPrinter forced to implement fax() and scan()
// good:
interface Printer { print(): void; }
interface Fax { fax(): void; }
interface Scanner { scan(): void; }
class AllInOnePrinter implements Printer, Fax, Scanner { /* ... */ }
class EconomicPrinter implements Printer { print() {} }
```

### DIP — Dependency Inversion
Depend on abstractions, not concretions. Inject dependencies rather than instantiating them.

```ts
// bad: ReportReader creates XmlFormatter internally
// good:
interface Formatter { parse<T>(content: string): T; }
class ReportReader {
  constructor(private readonly formatter: Formatter) {}
  async read(path: string): Promise<ReportData> {
    const text = await readFile(path, "UTF8");
    return this.formatter.parse<ReportData>(text);
  }
}
const reader = new ReportReader(new XmlFormatter());
```

## Concurrency

- Prefer `async/await` over callbacks and chained `.then()`

```ts
// bad: callback hell or chained .then()
// good:
async function downloadPage(url: string): Promise<string> {
  const response = await get(url);
  await write("output.html", response);
  return response;
}
```

- Use `Promise.all` for parallel tasks; `Promise.race` for timeouts

## Error Handling

- Always throw `new Error()`, never strings — preserves stack trace

```ts
// bad: throw "Not implemented."
// good: throw new Error("Not implemented.")
```

- Don't ignore caught errors — handle or log with context; never swallow silently
- Don't ignore rejected promises — use `.catch()` or `try/catch` with `await`

## Formatting

- `PascalCase`: classes, interfaces, types, enums
- `camelCase`: variables, functions, class members
- `SCREAMING_SNAKE_CASE`: module-level constants
- Place caller function above callee — read top-to-bottom like a newspaper
- Import order: polyfills → Node builtins → external → internal → parent → sibling
- Use `import type` for type-only imports (erased at runtime, prevents cycles)
- Use TS path aliases to avoid deep relative imports

```ts
// bad: import { UserService } from "../../../services/UserService"
// good: import { UserService } from "@services/UserService"
// tsconfig: { "paths": { "@services/*": ["src/services/*"] } }
```

## Comments

- Prefer self-documenting code — extract to a named variable or function instead of commenting
- Never leave commented-out code — delete it, git has history
- No journal/changelog comments — use `git log`
- Use `// TODO:` for planned improvements (not an excuse for bad code)
- No visual section dividers (`////...`) — let structure speak for itself
