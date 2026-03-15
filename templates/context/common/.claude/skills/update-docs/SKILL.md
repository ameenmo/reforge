---
name: update-docs
description: Update all project documentation after structural changes.
user-invocable: false
allowed-tools: Bash, Read, Write, Edit, Glob
---

## Steps

1. Scan the current directory structure.
2. Update `.agent/system/file_map.md` with current file layout.
3. Update `.agent/system/architecture.md` if architecture changed.
4. Update `.agent/readme.md` quick commands section.
5. Run `python tools/sync_configs.py` to regenerate AI configs.
6. Stage and commit documentation changes.
