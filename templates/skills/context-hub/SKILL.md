---
name: context-hub
description: Wrapper for chub CLI — search, fetch, and annotate versioned documentation from context.dev.
user-invocable: true
argument-hint: "<action> [query] — actions: search, fetch, annotate"
allowed-tools: Bash, Read, Write
---

# Context Hub — Versioned Documentation Access

Wrapper for the `chub` CLI tool from context.dev. Provides access to versioned documentation for libraries and frameworks.

## Prerequisites

Ensure `chub` is available:
```bash
npx chub --version
```

If not installed, it will be auto-installed via npx on first use.

## Actions

### Search

Find documentation for a library or concept:
```bash
npx chub search "<query>"
```

Example: `npx chub search "react server components"`

### Fetch

Fetch specific documentation:
```bash
npx chub fetch "<package>@<version>"
```

Example: `npx chub fetch "react@19"`

### Annotate

Add context annotations to fetched docs:
```bash
npx chub annotate "<package>" --note "<annotation>"
```

## Steps

1. Parse the user's action and query from the arguments
2. Run the appropriate `chub` command
3. Present the results in a clear, readable format
4. If fetching docs for a dependency, check `package.json` or equivalent for the current version first

## Observation Log

After completing, append to `.agent/sops/skill-observations.md`:

```markdown
## [{timestamp}] context-hub

- **Task:** {action} {query}
- **Result:** success | partial | failure
- **Error:** {if any}
- **Notes:** {what was found/fetched}
```
