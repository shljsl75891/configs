# ralph-loop

Generic [Ralph Wiggum technique](https://ghuntley.com/ralph/) runner for opencode: a bash loop
that repeatedly feeds `PROMPT.md` to `opencode run`, each iteration a fresh context window.
State persists across loops via files in the target repo (`TODO.md`, `AGENTS.md`), not chat history.

## Setup (per target repo)

1. Copy the task ledger and prompt:
   ```sh
   cp ~/.config/opencode/ralph-loop/TODO.md ./TODO.md
   cp ~/.config/opencode/ralph-loop/PROMPT.md ./PROMPT.md
   ```
2. Add tasks to `TODO.md`, one row per task, status `QUEUED`. Note the source (Jira key, GitHub
   issue, free-form) in the "Task" column.
3. Edit `PROMPT.md` if the repo needs conventions beyond "select a task, fix it, close it out"
   (test commands, code style, worktree isolation, etc.).
4. Ensure any MCP servers the prompt needs (Jira, GitHub, etc.) are `enabled: true` in the repo's
   `opencode.json`.

## Run

```sh
cd /path/to/target-repo
~/.config/opencode/ralph-loop/ralph.sh [agent]
```

- `agent` defaults to `build`.
- Always operates on `$PWD`. No target-repo argument.
- `--auto` auto-approves permissions for the tool calls the agent makes each iteration.
- Loop stops on its own once `TODO.md` has no `QUEUED` row left, or on `Ctrl+C`.
- Logs to `ralph.log` in the target repo.
