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

1. In the target repo, run `/skill:ralph-artifacts` in pi. Give tasks and project rules in raw
   language. The skill writes `TODO.md` and `PROMPT.md` from the templates in
   `<dotfiles>/pi/skills/ralph-artifacts/templates/`.
2. Ensure any MCP servers the prompt needs (Jira, GitHub, etc.) are declared in
   `<dotfiles>/pi/mcp.json`, all lazy by default.

## Run

```sh
cd /path/to/target-repo
<dotfiles>/ralph-loop/ralph.sh
```

- Always operates on `$PWD`. No target-repo argument.
- Loop stops on its own once `TODO.md` has no `QUEUED` row left, or on `Ctrl+C`.
- Logs to `ralph.log` in the target repo.
