# Lens: Clean Code (TypeScript/JavaScript)

Run only when the diff has TS/JS files. Base: https://github.com/labs42io/clean-code-typescript and the `conscious-coder` skill.

## Method

1. Read the hunks and the project vocabulary (glossary, ADRs, `AGENTS.md`/`README`, dominant names via `rg`).
2. Check `existing-comments.jsonl`; skip a finding already raised.
3. Proven → Issue/Fix. Unclear (fuzzy word, no vocabulary source) → ❓.

## Checks

- **Naming** — intention-revealing; one word per concept (`getUser`, not `getUserInfo`/`getUserData`); no redundant context (`Car.make`); `PascalCase` types, `camelCase` values, `SCREAMING_SNAKE_CASE` module constants; caller above callee. Ubiquitous language: a synonym for a known term, one word for two concepts, or a new concept with no term is 🟢 Low.
- **Functions** — one job; more than 2 params without an options object; flag params (split); input mutation; imperative loops where `map/filter/reduce` read better; inline conditions that need a named predicate.
- **TS idioms** — suggest `?.`, `??`, destructuring, and type narrowing where they read better. Prefer discriminated unions, generics, and utility types over repeated or loose types.
- **Types** — `any`; needless `unknown`, casts, or optionality; silent fallback hiding an unclear invariant; `readonly` where applicable; `type` for unions, `interface` for `extends/implements`; abstract classes or interfaces with no implementer.
- **Classes** — SRP, OCP, LSP, ISP, DIP; composition over inheritance; inject dependencies; high cohesion, low coupling.
- **Async & errors** — `async/await` over `.then()`; `throw new Error()`, never strings; swallowed errors, broad `catch`, ignored rejections; missing custom error types where callers must tell failures apart.
- **Magic values** — numbers and strings that need a named constant or enum.
- **Imports** — `import type` for types; deep relative imports. Never flag import order or sorting.
- **Comments** — a WHAT comment (delete or rename instead; say the comment is unneeded, and give a concrete comment or JSDoc snippet when one is needed); missing WHY for a business rule, workaround, or constraint; wrong format (hoverable items use JSDoc; multi-line notes never use stacked `//`); not ASD-STE100; journal comments; misused `TODO`.
- **Structure** — extracted code belongs in the right place (`utils/`, `hooks/`, `services/`, `shared/`); feature logic leaking into shared paths; helper duplicating a canonical utility; wrong layer; non-atomic updates leaving half-applied state.

## Output

JSONL exactly as the "Output format" in your task says.
