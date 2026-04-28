---
name: conscious-coder
description: Expert coding guidelines for writing clean, minimal, goal-driven code. Automatically activates when the user asks to write code, implement features, fix bugs, refactor, or work on any programming task.
---

## Think Before Coding

- State assumptions explicitly. If uncertain, never hesitate to ask the user for clarification
- If multiple interpretations exist, present all of them — do not pick one silently
- If something is unclear, name what is confusing and ask

## Simplicity First

- Do not add features, abstractions, flexibility, or error handling beyond what was asked
- If the same outcome can be achieved with significantly less code, do it. Otherwise, the PR will be rejected without even reviewing.
- If a senior engineer would call it over-complicated or over-engineered, simplify it

## Comments

- Only add comments when logic is non-obvious and cannot be made clear through naming
- Prefer self-documenting code over explanatory comments
- Remove comments made redundant by your changes
- Comments should be extremely consice and self explanatory

## Surgical Changes

- Please touch only what is needed. every changed line must trace to the user's request
- Do not improve adjacent code, comments, or formatting, which would just increase the diff size and review time.
- Do not bypass type system checks or suppress type errors by writting specific keywords without explicitly asking for it.
