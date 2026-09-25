---
name: ralph-artifacts
description: Create TODO.md and PROMPT.md for a Ralph loop from raw user input.
disable-model-invocation: true
---

# Ralph Artifacts

Create `TODO.md` and `PROMPT.md` in the current working directory. The Ralph loop (`ralph.sh`) reads them.

Templates are in `templates/` next to this file. Read both before you start.

Write all output in Simplified Technical English (ASD-STE100).

## 1. Collect raw input

Make one `question` tool call with two questions:

- Header `TODO`: "Write your tasks in raw language." Option: `None`.
- Header `PROMPT`: "Write project rules for the loop (test commands, style, constraints) in raw language." Option: `None (base rules only)`.

The user types the raw text in the free-text field. If the TODO answer is empty or `None`, stop and tell the user that a task list is necessary.

## 2. Clarify tasks

- Split the raw TODO text into atomic tasks. Each task must be one unit of work that one loop iteration can complete and verify.
- Keep the user's order.
- Find vague tasks (unclear scope, missing target, no way to verify). Ask about all of them in one `question` call. Put your recommended interpretation first.
- Repeat until no task is vague.
- Do not ask about the PROMPT text.

## 3. Write TODO.md

- Start from `templates/TODO.md`.
- Add one row per task. Status is always `QUEUED`.
- "Task": a short imperative sentence. Include the source (Jira key, issue URL) if the user gave one.
- "Additional Notes": acceptance criteria and useful details from the raw text. Leave empty if none.
- Escape `|` in cell text as `\|`. `ralph.sh` greps the `| QUEUED |` pattern.
- Overwrite the file if it exists.

## 4. Write PROMPT.md

- Start from `templates/PROMPT.md`. Keep its text exactly.
- If the user gave PROMPT text, insert a `## 2. Project rules` section between "Select the task" and "Close out". Change "Close out" to `## 3. Close out`.
- Write the project rules as short bullets. Keep every command, path, and name exactly as the user wrote it.
- Overwrite the file if it exists.

## 5. Report

Show the paths of both files and the number of tasks. Do not start the loop.
