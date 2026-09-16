# ralph-loop

Generic [Ralph Wiggum technique](https://ghuntley.com/ralph/) runner for pi: a bash loop
that repeatedly feeds `PROMPT.md` to `pi -p`, each iteration a fresh context window.
State persists across loops via files in the target repo (`TODO.md`, `AGENTS.md`), not chat history.

Runs unattended against the same `~/.pi/agent` config used interactively. `ask` rules
fail closed with no UI attached (`confirmation_unavailable` — blocked, not a hang), so
destructive bash (`rm *`, `git push *`, `docker volume rm *`, etc.) stays blocked in the
loop exactly as it does interactively; `yoloMode: true` only bypasses synthetic
wrapper-floor asks (`xargs`, `sudo`, `env`, ...), not configured rules.

## Setup (per target repo)

1. Copy the task ledger and prompt:
   ```sh
   cp <dotfiles>/ralph-loop/TODO.md ./TODO.md
   cp <dotfiles>/ralph-loop/PROMPT.md ./PROMPT.md
   ```
2. Add tasks to `TODO.md`, one row per task, status `QUEUED`. Note the source (Jira key, GitHub
   issue, free-form) in the "Task" column.
3. Edit `PROMPT.md` if the repo needs conventions beyond "select a task, fix it, close it out"
   (test commands, code style, worktree isolation, etc.).
4. Ensure any MCP servers the prompt needs (Jira, GitHub, etc.) are declared in
   `<dotfiles>/pi/mcp.json`, all lazy by default.

## Run

```sh
cd /path/to/target-repo
<dotfiles>/ralph-loop/ralph.sh
```

- Always operates on `$PWD`. No target-repo argument.
- Loop stops on its own once `TODO.md` has no `QUEUED` row left, or on `Ctrl+C`.
- Logs to `ralph.log` in the target repo.
