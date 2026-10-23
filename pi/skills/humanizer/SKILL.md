---
name: humanizer
description: Humanize prose the user publishes as their own. Load for docs, READMEs, posts, emails, commit/PR text, and Slack, GitHub or JIRA comments.
---

Rules, word lists and patterns live in `REFERENCE.md` (same folder). Read it first.

## Steps

1. **Pre-flight.** Name the text type: docs/README, or post/email/chat/comment. Voice rules differ (see "Voice by text type"). Leave code, YAML, tables, quotes and titles untouched.
2. **Structure.** Delete, merge, split or reorder sections before you edit sentences. Cut to the length the content needs.
3. **Sentences.** Rewrite every `[1]` pattern hit and Tier 1 word. Rewrite `[weak]` patterns and Tier 2 words only in clusters. Add no facts, numbers or quotes. Keep meaning and tone.
4. **Substance.** Apply the name-swap, reshuffle and deletion tests.
5. **Lint.** Run `bash lint.sh <file>` (in this folder) before step 2 and after step 4. Fix every hit. Skip this for text under 3 lines.
6. **Fresh reader.** For text over about 150 words, send it to a `general` subagent with no context. Ask: "List what is unclear, assumed, or reads as AI-written." Fix each finding. Skip for short chat text.
7. **Done when:** lint exits 0, every `[1]` pattern is checked, and no fact was added or dropped.
