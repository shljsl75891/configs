---
name: extend-pi
description: Use when the question is about pi itself, its SDK, extensions, themes, skills, or TUI. Gives the doc paths of the installed pi and how to read them.
---

# pi documentation

Path is pinned to the active Node version, so compute it:

```bash
PI_ROOT="$(readlink -f "$(dirname "$(readlink -f "$(which pi)")")/../..")"
```

- Main documentation: `$PI_ROOT/README.md`
- Additional docs: `$PI_ROOT/docs/`
- Examples: `$PI_ROOT/examples/` (extensions, custom tools, SDK)

Resolve `docs/...` under Additional docs and `examples/...` under Examples, not the current
working directory.

When asked about:

- extensions — `docs/extensions.md`, `examples/extensions/`
- themes — `docs/themes.md`
- skills — `docs/skills.md`
- prompt templates — `docs/prompt-templates.md`
- TUI components — `docs/tui.md`
- keybindings — `docs/keybindings.md`
- SDK integrations — `docs/sdk.md`
- custom providers — `docs/custom-provider.md`
- adding models — `docs/models.md`
- pi packages — `docs/packages.md`
- environment variables — `docs/environment-variables.md`

Read pi `.md` files completely and follow links to related docs before implementing.
