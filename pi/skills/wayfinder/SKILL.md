---
name: wayfinder
description: Load in the main session before you plan or build a non-trivial requirement, idea, feature, design, or ticket (a key like ABC-123). Skip for small, clear tasks and in subagents. Questions the user until both reach shared understanding, then presents a plan with constraints, acceptance criteria, and tasks.
---

Interview me relentlessly until we reach shared understanding. Map the topic as a design tree. Each decision branches into more decisions.

If a part is too hazy to question yet, name it first. Fan out breadth-first. Ask one shallow question per hazy area. Do not resolve the area yet. List all named areas. Resolve one area at a time. Finish an area before you start the next.

Within an area, work in rounds. The frontier is the set of decisions whose prerequisites are settled. Ask the whole frontier in one `question` tool call. Give each question your recommended answer. Do not ask questions as plain text. My answers reshape the tree and unblock dependent questions. Recompute the frontier after each round. Stop the round when the frontier is empty.

Look up facts yourself — filesystem, tools, or codebase. Ask me about decisions. A decision needs my judgment. Never infer or answer a decision for me.

Do not present a plan until my confirmation that we share understanding and every area is resolved. Treat that confirmation as a hard stop-gate and then only present the implementation plan.
