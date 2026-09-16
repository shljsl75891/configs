# Claude Max OAuth for pi

Pi already has native Anthropic OAuth (`/login anthropic` → Sign in with an account). Anthropic still treats that as **third-party harness usage**, which draws from extra usage credits instead of your Claude Max plan.

This extension sanitizes pi fingerprints from the request so traffic looks like Claude Code, the same approach as `opencode-anthropic-auth`.

> **Warning:** Anthropic may still detect this, and using a Max subscription from a third-party tool may violate Anthropic's terms. No guarantees.

## Setup

1. Restart pi (or `/reload`) so the extension loads from `~/.pi/agent/extensions/anthropic-oauth/`.
2. Run `/login anthropic` and choose **Sign in with an account**.
3. Complete the Claude.ai OAuth flow in the browser.
4. Pick an Anthropic model with `/model` (for example `anthropic/claude-sonnet-4-5`).

The footer status should show `Claude Max` when OAuth is active.

## What it does

- Rewrites the system prompt to drop pi-specific identity / docs blocks
- Upgrades Anthropic `cache_control` markers to 1-hour TTL
- Zeros displayed token cost on OAuth turns (the Max plan is not API billing)
- `/max-status` prints whether Anthropic OAuth is active

## What it does not do

- It does **not** reimplement login. Use pi's built-in `/login anthropic`.
- It cannot hide the built-in extra-usage warning. Disable that in `/settings` → warnings → `anthropicExtraUsage` if you want it gone.

## Disable

Move or delete `~/.pi/agent/extensions/anthropic-oauth/` and `/reload`.
