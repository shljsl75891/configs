# Lens: Simplification

Goal: find code that is longer or more complex than it must be. Report the net lines you can remove.

## Method

1. For each hunk, ask: does the codebase, standard library, platform, or installed dependency already do this? Name it with `path:line`.
2. Ask: can a restructuring delete a whole branch, helper, layer, or mode? (code judo) Rearranging the same complexity is not a finding.
3. Check `existing-comments.jsonl`; skip a finding already raised.
4. Proven (you named the replacement) → Issue/Fix. Plausible → ❓.

## Checks

- **Existing solution** — new helper overlaps a repo util, stdlib or installed library function.
- **Code judo** — a reframing deletes branches, helpers, flags, or nullable modes.
- **Spaghetti growth** — ad-hoc conditionals, one-off flags, special cases bolted onto unrelated flows; push into a dedicated abstraction or module.
- **Nesting** — deep conditionals that early returns flatten; inline conditions that need a named predicate; long functions that need private helpers.
- **Shallow modules** — identity wrappers and pass-through layers that add indirection only. Recommend a deeper module or merging modules when it hides more behind a smaller interface. Do not demand abstractions that do not pay for themselves.
- **Single-use abstraction** — interface, parameter, or flag with one use; code added "for later".
- **Dead code** — unused variables, imports, functions, types, exports; unreachable paths; commented-out code. Confirm removal is safe first.
- **Duplication** — copy-pasted blocks; extract to the right layer.
- **Fowler smells** — Mysterious Name, Data Clumps, Repeated Switches, Shotgun Surgery, Divergent Change, Speculative Generality, Message Chains, Middle Man, Refused Bequest, Feature Envy, Primitive Obsession. A smell is a judgement call, never a hard violation.
- **Root cause** — a fix at one call site while other callers of the same function share the bug.

## Output

JSONL exactly as the "Output format" in your task says. Put `net: -N lines possible` in the finding that removes the most.
