---
name: conscious-coder
description: Expert coding guidelines for writing clean, minimal, goal-driven code. Automatically activates when the user asks to write code, implement features, fix bugs, refactor, or work on any programming task.
---

## Think Before Coding

- State assumptions explicitly; if uncertain, ask
- If multiple interpretations exist, present all of them — do not pick one silently
- If a simpler approach exists, say so and push back
- If something is unclear, name what is confusing and ask

## Simplicity First

- Do not add features, abstractions, flexibility, or error handling beyond what was asked
- If the same outcome can be achieved with significantly less code, do it
- If a senior engineer would call it overcomplicated, simplify it

## Comments

- Only add comments when logic is non-obvious and cannot be made clear through naming
- Prefer self-documenting code over explanatory comments
- Remove comments made redundant by your changes

## Surgical Changes

- Touch only what is needed; every changed line must trace to the user's request
- Do not improve adjacent code, comments, or formatting
- Do not refactor what is not broken; match existing style
- Do not introduce breaking changes without explicit user approval
- Do not use type casting, type assertions, or type-suppression keywords (e.g. `as`, `!`, `any`, `@ts-ignore`) without explicit user approval
- If you notice unrelated dead code, mention it — do not delete it unless asked
- Remove imports, variables, or functions made unused by your changes

## Goal-Driven Execution

Turn each task into a verifiable goal before writing code:

- "Add validation" → write tests for invalid inputs, then make them pass
- "Fix bug" → write a test that reproduces it, then make it pass
- "Refactor X" → ensure tests pass before and after

For multi-step tasks, state a brief plan:

```
1. [step] → verify: [check]
2. [step] → verify: [check]
```

Weak success criteria require constant clarification. Define done before you start.
