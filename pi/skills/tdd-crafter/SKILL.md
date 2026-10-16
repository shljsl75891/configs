---
name: tdd-crafter
description: |
  Writes a Technical Design Document (TDD), a design doc (not test-driven
  development). Always asks first for a template or a reference TDD. Makes a
  kickstart doc for review: a PDF with rendered Mermaid diagrams, or a
  Confluence page when asked.
disable-model-invocation: true
---

# TDD Crafter

A TDD here is a kickstart doc. It records the decisions that start the work, and the code can change after the review. It has no code blocks, and it never goes into git.

## Process

### 0. Get the template or a reference TDD — hard gate

Before anything else, ask the user for a template, a reference TDD, or both. A file path, a Confluence page or a pasted outline are all fine. Read each one fully.

- A template sets the sections and their order.
- A reference TDD sets the tone and the depth. If the user gives only a reference TDD, use its sections.
- Show the section list and get the user's confirmation. Don't invent new sections.

Do not continue without a template or a reference TDD.

### 1. Frame the doc — first `wayfinder` round

Ask these together, before any detail question:

- Code of record: the repo, package and version that the design changes. Cite `path:line` only from it.
- Reach: one product, or a library or tool for any project. For any project, use no product or repo names.
- Reviewers: who reviews, what they must decide, and which channel each one can open (PDF, Confluence).
- Inputs: an older TDD of the component, a standard with targets, research notes. Read them before you draft.
- Size: the expected number of pages (see step 9).
- Spike: does the design need one (see step 3)?

Defaults, unless the user says otherwise: author Sahil Jassal, reviewers Team Lead and Architect, one doc.

### 2. Research

Before you ask about decisions, explore the code and search the web in parallel (`explore` and `web-research-expert` subagents). Turn the findings into options with trade-offs. Back every claim about code with `path:line` from the code of record.

### 3. Spike — optional, ask the user

Ask if a risky part of the design needs a spike. Run it only when the user says yes.

- Run it in `/tmp`, never in the repo. Throw the code away after.
- Record in the TDD what the spike proved or disproved: the setup, the versions, the date and the numbers.

### 4. Interrogate the details — invoke `wayfinder` skill

Run the `wayfinder` skill to interrogate the user. Resolve, area by area, breadth-first:

- the raw requirement/idea → map into goals + high-level requirements
- which template sections to keep vs. drop for this feature
- depth of explanation expected (quick reviewers vs. newcomers)
- open architectural decisions that need the user's judgment — never infer these

Do not draft until wayfinder confirms shared understanding. That confirmation is a hard stop-gate.

### 5. Draft section by section

Use the section list from step 0 as the skeleton, in order. For each section:

- Fill it in only if it applies. Drop sections that don't apply — never leave "N/A" as filler. If omitting a section might surprise a reviewer, say why in one line instead of a heading.
- Write decisions, not steps. "We use Postgres logical replication for X" — not "first we connect, then we query, then we close."
- Prefer a table over a paragraph for comparisons (trade-offs, options, schema fields).
- Keep one section == one idea. Don't blend architecture and testing in the same paragraph.
- No code blocks. Show an API as a table of names, options and defaults. Mermaid diagrams and `path:line` references are fine.
- End Purpose with the kickstart line: "This document starts the work. The code can change after the review."
- Open the technical decisions section with a `Decision | Choice | Why` table: one row for each decision that the reviewers must confirm or overturn. It is not a new section.

Fill rules for any template:

- Every table has a real header row.
- The table of contents is numbered, and each entry links to its section.
- If the template has these sections: Scope lists in scope, later (with the reason) and out of scope. Intended audience says who decides what. Issues lists the decisions wanted from the reviewers, the risks and the assumptions.

### 6. Diagrams — one is the default, two is the ceiling

- Default: **one** diagram for the whole doc. Add a second only if the design has two genuinely distinct concerns (e.g. architecture AND data flow both need a picture).
- Never more than two. More than that overwhelms the reviewer — cut, don't add.
- Use **Mermaid**:
  - `flowchart` / `graph` — architecture or data flow
  - `sequenceDiagram` — request/response, multi-service interaction
  - `erDiagram` — data model
- Pick whichever fits the section it lives in. Don't force a diagram type that doesn't match.
- Skip the diagram entirely if the change has no meaningful flow or architecture worth drawing (e.g. a config tweak). Don't pad.

### 7. Humanize each section as you write it

After drafting a section, invoke the `humanizer` skill on it before moving to the next section. Don't wait until the whole doc is done.

### 8. Language rules — Simplified Technical English (ASD-STE100)

- Short sentences. One idea per sentence.
- Active voice: "the service validates the token" not "the token is validated by the service."
- Plain, approved words over jargon. Define a term once if the audience needs it; don't make them guess.
- No filler: cut "it's worth noting that," "in order to," "leverage," "utilize" — see humanizer word-swap list.

### 9. Length discipline

- Target 1–3 pages for a typical feature. 10–20 pages only for large cross-team systems.
- Keep one doc. If it goes over 3 pages, end Purpose with a "Read first" line that names the sections a busy reviewer needs.
- Reread the whole draft once as a busy reviewer. Cut anything that doesn't earn its place.

### 10. Save location — never in git

Save to `docs/<feature-name>/<feature-name>-tdd.md` in the target project repo. Keep the rendered files (PNG, PDF) in the same folder. Never commit any of them. Add the folder to the local exclude file of the repo (this also works in a worktree):

```bash
echo "/docs/<feature-name>/" >> "$(git rev-parse --path-format=absolute --git-path info/exclude)"
```

### 11. Deliver — PDF, or Confluence when asked

Use the channel that each reviewer can open (step 1).

**PDF.** Build it with `scripts/build-pdf.cjs` from this skill's folder. It draws each Mermaid block as a PNG in the same place, and writes `<feature-name>-tdd.pdf` next to the doc (A4, linked table of contents, bookmarks, page numbers):

```bash
npx -y -p @mermaid-js/mermaid-cli@11 -p marked@4 node <skill-dir>/scripts/build-pdf.cjs docs/<feature-name>/<feature-name>-tdd.md
```

Look at the page images before you send the file (for example `pdftoppm -png -r 45`). Build it again after each change to the doc.

**Confluence.** Only do this when the user explicitly asks to publish.

- Confirm the target space and parent page with the user first — don't guess placement.
- Confluence does not render Mermaid natively. Render any diagram locally to PNG (`npx @mermaid-js/mermaid-cli`, add `-p` with a `{"args":["--no-sandbox"]}` puppeteer config file if running headless) and save it into `docs/<feature-name>/` alongside the doc. Prefer `flowchart TD` (vertical) over `LR` — narrower, more readable, and a smaller file. Render once at the smallest legible size; don't iterate through scales live.
- The `jira` MCP server (Confluence/Jira, `mcp-atlassian`) runs in a local Docker container with no access to your filesystem unless `.mcp.json` mounts it in. Check that repo's `.mcp.json` for a `jira` server entry with `-v <repo>/docs:/app/workspace:ro` in its args.
  - If the mount exists: upload via `file_path: "/app/workspace/<feature-name>/<file>"`. No encoding needed.
  - If it doesn't: tell the user the exact line to add to their `.mcp.json`, scoped to that repo's `docs/` folder only — never the whole repo root. Then stop and wait; don't silently edit their MCP config, and don't fall back to any other upload path.
  - Editing `.mcp.json` doesn't take effect on `mcp connect` alone — pi caches server launch args at session start. The user needs to fully restart their pi session after adding or changing the mount.
- After uploading, fetch the real attachment ID/download URL (`jira_confluence_get_attachments`) and wire it into the page body — don't guess the URL shape. Verify by re-fetching the page afterward.

## Checklist before delivering

- [ ] spike done in `/tmp` and its results are in the doc, or the user said no spike
- [ ] wayfinder interrogation done, user confirmed shared understanding
- [ ] every section in the doc is either filled with real content or removed — no "N/A"
- [ ] no code blocks; at most 2 diagrams, in Mermaid, each earning its place
- [ ] every section passed through humanizer
- [ ] ASD-STE100: short sentences, active voice, no jargon left unexplained
- [ ] over 3 pages: Purpose ends with a "Read first" line
- [ ] saved to `docs/<feature-name>/<feature-name>-tdd.md`, folder in the local git exclude, nothing committed
- [ ] delivered: PDF built and checked, or published to Confluence (diagram rendered locally, uploaded via the mounted `file_path` (mount confirmed present, session restarted if it was just added), page verified after publish)
