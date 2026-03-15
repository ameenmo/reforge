# Gemini CLI — Tool-Specific Hints

## Important

- Read `.agent/readme.md` first for the full project overview.
- The canonical project rules are in `directives/SOP.md`.
- Gemini skills are located at `.gemini/skills/` (synced from `.claude/skills/`).

## Environment

<!-- Add runtime, language, framework details here -->

## Quick Commands

```bash
python tools/verify_*.py              # Verification gate
python tools/sync_configs.py          # Regenerate AI configs
```

## Key File Locations

| What | Where |
|------|-------|
| Project rules | `directives/SOP.md` |
| Agent context | `.agent/readme.md` |
| Architecture | `.agent/system/architecture.md` |

## Verification

Always run before completing any task:

```bash
python tools/verify_*.py
```
