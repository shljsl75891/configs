# Task Loop Instructions

Your job: fix exactly one task from `TODO.md`, then stop.

## 1. Select the task

- Read `TODO.md`.
- Pick the first task with status `QUEUED`, top to bottom.
- Ignore every other task.
- If no task has status `QUEUED`, stop. Change nothing.
- Set its status to `IN-PROGRESS` in `TODO.md` before starting work.

## 2. Close out

- Set the task status in `TODO.md`:
  - `DONE` — fix complete, tests pass.
  - `BLOCKED` — cannot finish (missing info, unclear ticket, unrelated failing tests). Write the reason in "Additional Notes".
- Stop. Do not pick another task.
