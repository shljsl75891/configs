---
name: conscious-coder
description: Expert coding guidelines for writing clean, minimal, goal-driven code using TDD. Use this when starting the execution of a plan, or the user asks to write code, implement features, fix bugs, refactor etc. any programming task.
---

Before writing any code, use the Read tool to load `~/.config/opencode/skills/conscious-coder/CLEAN_CODE_TYPESCRIPT.md` and follow it as mandatory rules.

## Think Before Coding

- State assumptions explicitly. If uncertain, never hesitate to ask the user for clarification
- If multiple interpretations exist, present all of them — do not pick one silently
- If something is unclear, name what is confusing and ask

## Simplicity First

- Do not add features, abstractions, flexibility, or error handling beyond what was asked
- If the same outcome can be achieved with significantly less code, always prefer it — failing to do so is grounds for rejection without review.
- If a senior engineer would call it over-complicated or over-engineered, simplify it

## Comments

- Only add comments when logic is non-obvious and cannot be made clear through naming
- Prefer self-documenting code over explanatory comments
- Remove comments made redundant by your changes
- Comments should be extremely concise and self-explanatory

## Surgical Changes

- You must touch only what is needed. every changed line must trace back to the user's request
- Do not improve adjacent code, comments, or formatting, as it unnecessarily increases diff size and review time.
- Do not bypass type system checks or suppress type errors by writing specific keywords such as `any`, `unknown` unless explicitly asked.
- Use dedicated types instead of abstract classes or interfaces for typing. Only define abstract classes or interfaces when one or more classes implement them.

## TDD

Implement features using test-driven development. Follow red-green-refactor:
- RED: write one failing test for next behavior
- GREEN: write minimal code to pass it
- REFACTOR: clean up, then repeat

Never write all tests first then all code — one test → one implementation → repeat.

Per-cycle checklist:
- [ ] Test describes behavior, not implementation
- [ ] Test uses public interface only
- [ ] Test would survive internal refactor
- [ ] Code is minimal for this test

Load these as needed using the Read tool:
- `~/.config/opencode/skills/conscious-coder/TESTING_GUIDELINES.md` — good/bad test examples, mocking rules
- `~/.config/opencode/skills/conscious-coder/DESIGN_PRINCIPLES.md` — testable interfaces, deep modules, refactor candidates
