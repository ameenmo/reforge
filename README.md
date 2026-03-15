# Reforge

Restructure existing projects for AI-native development.

**Prestart** creates new projects with proper structure. **Reforge** fixes existing ones — it analyzes, diagnoses, and upgrades messy projects with proper structure and the full AI context layer.

## Install

```bash
# Option A: Clone and install
git clone https://github.com/ameenmo/reforge ~/.reforge
~/.reforge/install.sh

# Option B: One-liner
curl -fsSL https://raw.githubusercontent.com/ameenmo/reforge/main/install.sh | bash
```

## Quick Start

```bash
cd my-messy-project
reforge analyze    # Diagnostic report + A-F grade
reforge apply      # Backup branch, add AI context layer + missing configs
```

## What It Does

### `reforge analyze`

Scans your project and produces a diagnostic report with an A-F grade across four categories:

- **Structure** (25 pts) — Directory depth, flatness ratio, missing standard dirs
- **Large Files** (20 pts) — Files >300 lines, function count estimates
- **Essentials** (25 pts) — .gitignore, tests, linting, CI, README, LICENSE
- **Secrets** (30 pts) — Hardcoded API keys, passwords, tracked .env files

### `reforge apply`

Non-destructively upgrades your project:

1. **Creates a git backup branch** — Always safe to undo
2. **Adds missing configs** — .gitignore (stack-specific), .env.example, .editorconfig
3. **Adds AI context layer** — The full prestart template system:
   - `directives/SOP.md` — Project rules and standards
   - `.agent/` — AI context (architecture, hints, SOPs)
   - `.claude/` — Claude Code config + skills
   - `tools/sync_configs.py` — Multi-tool config sync engine
   - `tools/verify_*.py` — Automated verification checks

## Commands

```
reforge analyze       Scan project, produce diagnostic report with grade
reforge apply         Create backup branch, add AI context layer + configs
reforge upgrade       Self-update (git pull)
reforge uninstall     Remove reforge
reforge version       Print version
reforge help          Show help
```

## Options

```
--yes, -y       Skip confirmations
--dry-run       Show what would change without doing it
--verbose       Extra detail
```

## How It Works

- **Non-destructive**: Always creates a git backup branch before any changes
- **Idempotent**: Safe to run multiple times; skips what already exists
- **No external deps**: Only bash, git, grep, wc, python3 (for sync_configs.py)
- **Prestart integration**: Uses prestart templates if installed (`~/.prestart`), otherwise uses bundled copies

## Auto-Detection

Reforge automatically detects:
- **Language**: Node.js/TypeScript, Python, Go, Rust, Ruby, Java, PHP
- **Framework**: Next.js, React, Vue, Express, FastAPI, Django, Rails, and more
- **Package manager**: npm, yarn, pnpm, bun, pip, poetry, cargo, etc.
- **Project type**: app, api, agent, data-pipeline

## Scoring

| Grade | Score | Meaning |
|-------|-------|---------|
| A | 90-100 | Excellent structure |
| B | 75-89 | Good, minor improvements |
| C | 60-74 | Fair, several issues |
| D | 40-59 | Poor, needs restructuring |
| F | 0-39 | Critical problems |

See [docs/scoring-rubric.md](docs/scoring-rubric.md) for details.

## License

MIT
