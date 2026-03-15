# Claude Code (Alternate) — Tool-Specific Hints

## Context

This is the alternate Claude Code config (`.claudecode.md`). The primary Claude Code config is `CLAUDE.md` at the project root.

## Workflow

- Read `.agent/readme.md` for the full project overview and quick commands.
- Check `.agent/tasks/` for active tasks before starting new work.

## Key Paths

| What | Where |
|------|-------|
| Canonical rules | `directives/SOP.md` |
| Agent context | `.agent/readme.md` |
| Architecture | `.agent/system/architecture.md` |
| File map | `.agent/system/file_map.md` |

## Verification

```bash
python tools/verify_*.py    # Must pass before completing tasks
```
