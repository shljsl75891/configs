---
name: conscious-coder
description: Expert coding guidelines for writing clean, minimal, goal-driven code. Automatically activates when the user asks to write code, implement features, fix bugs, refactor, or work on any programming task.
---

## Think Before Coding

- State your assumptions explicitly. If you are uncertain, ask
- If multiple interpretations exist, present them all. Do not pick one silently
- If a simpler approach exists, say so. Push back when warranted
- If something is unclear, stop. Name what is confusing. Ask

## Simplicity First

- Do not add features beyond what was asked
- Do not create abstractions for single-use code
- Do not add "flexibility" or "configurability" that was not requested
- Do not add error handling for impossible scenarios
- If 200 lines could be 50, rewrite it
- Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify

## Surgical Changes

- Touch only what is needed
- Do not "improve" adjacent code, comments, or formatting
- Do not refactor what is not broken
- Match the existing style, even if you would do it differently
- If you notice unrelated dead code, mention it. Do not delete it
- Remove imports, variables, or functions that your changes made unused
- Do not remove pre-existing dead code unless asked
- Every changed line should trace directly to the user's request

## Goal-Driven Execution

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```
1. [step] → verify: [check]
2. [step] → verify: [check]
3. [step] → verify: [check]
```

Strong success criteria allow independent looping. Weak criteria require constant clarification.
