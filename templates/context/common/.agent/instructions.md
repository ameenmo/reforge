# Unified Context

## Index First

**Before any implementation work, read `.agent/readme.md`.**

## Canonical Source

All project rules live in `directives/SOP.md`. This is the single source of truth.
Never auto-modify it. All AI tool configs are assembled from it by `tools/sync_configs.py`.

## Mandatory Verification

Before marking any code task as complete, run the project verifier:

    python tools/verify_*.py

A non-zero exit code means the task is **not done**.

## File Ownership

| Path | Owner | Notes |
|------|-------|-------|
| `directives/SOP.md` | Human | Canonical rules — never auto-modify |
| `.agent/instructions.md` | Human | This file |
| `.agent/hints/*` | Human | Tool-specific hints |
| `.agent/readme.md` | Any agent | Master index |
| `.agent/system/*` | Any agent | Architecture docs |
| `.agent/tasks/*` | Any agent | Task tracking |
| `CLAUDE.md` | Generated | Do not hand-edit |
| `AGENT.md` | Generated | Do not hand-edit |
| `GEMINI.md` | Generated | Do not hand-edit |
| `.cursorrules` | Generated | Do not hand-edit |
| `.claudecode.md` | Generated | Do not hand-edit |

## Handoff Protocol

When one tool finishes a subtask for another tool to continue:

1. Update the task file in `.agent/tasks/` with findings and next steps
2. Set `Status: handoff` and `Next Owner: {tool}`
3. Run `python tools/sync_configs.py` to ensure context is current
4. The receiving tool reads the task file to pick up where the previous left off

## Task Lifecycle

    draft → active → handoff → active → complete
                        ↑                    │
                        └────────────────────┘  (if rework needed)
