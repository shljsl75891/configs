---
name: wayfinder
description: Load before you plan or build any requirement, idea, feature, design, or issue-tracker ticket (a key like ABC-123). Questions the user until both reach shared understanding, then writes SPEC.md with constraints, acceptance criteria, and tasks.
---

Interview me relentlessly until we reach shared understanding. Map the topic as a design tree. Each decision branches into more decisions.

If a part is too hazy to question yet, name it first. Fan out breadth-first. Ask one shallow question per hazy area. Do not resolve the area yet. List all named areas. Resolve one area at a time. Finish an area before you start the next.

Within an area, work in rounds. The frontier is the set of decisions whose prerequisites are settled. Ask the whole frontier in one `question` tool call. Give each question your recommended answer. Do not ask questions as plain text. My answers reshape the tree and unblock dependent questions. Recompute the frontier after each round. Stop the round when the frontier is empty.

Look up facts yourself — filesystem, tools, or codebase. Ask me about decisions. A decision needs my judgment. Never infer or answer a decision for me.

Do not present a plan until my confirmation that we share understanding and every area is resolved. Treat that confirmation as a hard stop-gate.

## Spec

Always write a spec. Works with any issue tracker.

1. If I give a ticket key, fetch it with the tracker MCP or CLI that the project provides. If none exists, ask me to paste it. Its acceptance criteria are the product's. Ask only about gaps.
2. Agree the test seams with me: the public interfaces where tests attach.
3. Ask about constraints: code quality, performance limits, edge cases, compatibility. Do not ask about lint, tests, or coverage; CI checks them.
4. Find the project's `.pi` directory by walking up from cwd. Write `.pi/specs/<ticket-or-slug>/SPEC.md` there. No file paths or code in it. Sections:
   - Problem, Solution
   - User stories (numbered)
   - Implementation decisions
   - Test seams
   - Constraints (quality and performance only)
   - Acceptance criteria: **Tracker AC** (copied from the ticket, if any) and **Developer AC** (mine, including code quality)
   - Out of scope
   - Tasks
5. Tasks are tracer-bullet slices in build order: thin, demoable, complete through all layers, small enough for one context window. Each has acceptance criteria and names the tasks that block it. Put prefactor tasks first (make the change easy, then make the easy change). Use expand-contract for wide refactors.
