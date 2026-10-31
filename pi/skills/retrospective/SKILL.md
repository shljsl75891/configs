---
name: retrospective
description: Retrospective on a coding or PR-review session. Suggests fixes to the pi setup, skills, and user workflow. Run only on request.
disable-model-invocation: true
---

User asked for a **retrospective**. Goal: suggest changes to the agent **environment** and to the user's **workflow**, so future runs improve. Do not edit files. Report only.

## Steps

1. **Pick session.**
   - No argument: use the current conversation. Skip to step 3.
   - `pick` or a dir name: list recent files in `$PI_CODING_AGENT_SESSION_DIR` (`~/.local/share/pi/sessions/`). The folder is flat. Line 1 of each file is a header with `cwd`. Show time, `cwd`, and first user prompt. Filter by dir if given. User chooses with the `question` tool.
   - A path or id: use it.
2. **Digest.** Run `<this skill dir>/digest.sh SESSION.jsonl`. Never read the raw log. Delegate the digest to a `general` subagent. Give it the categories below. It returns findings with evidence.
3. **Detect targets.** From the digest, list skills and agents the session loaded or used (reads of `skills/*/SKILL.md`, subagent calls). Read those files. They are focus targets.
4. **Find candidates** in the categories below.
5. **Report** ranked by severity. Each item: category, evidence (quote or step), target file, exact fix. Ask the user which to apply.

## Categories

- **Navigation**: slow search for files or facts. Fix: a pointer in `AGENTS.md` or a doc. _Use when_ the session spent many calls finding something.
- **Automated checks**: a lint, type, test, or hook would catch the agent's mistake. Read the repo's own check scripts and CI first. An unwired or broken check is the finding. No guardrail at all is a finding.
- **Coding standards**: classify the miss. **Mechanical** (fixed pattern, banned API, import shape): build a deterministic check. **Judgement** (consistency, style): add or clarify a rule in `agents/code-reviewer.md`.
- **Steering size**: `AGENTS.md`, `SYSTEM.md`, or skill descriptions are large. Move rules to reviewer rules or checks.
- **Tool economy**: expensive calls, big reads, repeated calls, missed subagent use, token-heavy tools or MCP.
- **No-ops**: steering lines that did not change behavior.
- **Information access**: the agent lacked a crucial fact (logs, read-only service access, MCP). Fix: give access.
- **User workflow**: vague prompt, missing context, repeated steering, mid-task scope change. Fix: a better prompt, a prompt template, or a new skill.
- **Skill gaps**: the detected skills missed a step, gave a wrong rule, or were ignored. Fix: exact edit to that `SKILL.md`.

## PR-review sessions

User actions on drafted comments are the main evidence. Each maps to a `pr-reviewer` fix.

- Comment dropped: false positive. Add a rule or a filter.
- Comment rewritten: wrong wording or severity. Fix the style or severity guide.
- Comment added by user: missed issue. Add a check or house rule.
- Finding verified wrong: fix the verify step.

## Reference

- Implementation agent has high context pressure: exploring, coding, debugging. Reviewer agent gets a diff, so pressure is low. Put standards in the reviewer, not the implementer.
- `AGENTS.md`: always in context. Keep to navigation pointers.
- `agents/code-reviewer.md`: judgement rules, read at review.
- Skills: docs (description is always in context) or user commands.
- Prefer a deterministic check over a written rule.
- Pi docs: load `extend-pi` skill.
