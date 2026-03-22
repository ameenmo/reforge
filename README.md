# Reforge

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.1.0-brightgreen.svg)](VERSION)

**Fix messy projects for AI-native development.** Reforge analyzes, diagnoses, and upgrades existing projects with proper structure, configs, and the full AI context layer.

## Install

### Option 1: Claude Code (recommended)

Copy and paste this into [Claude Code](https://docs.anthropic.com/en/docs/claude-code):

```
Clone https://github.com/ameenmo/reforge to ~/.reforge and run ~/.reforge/install.sh to install it. Then cd into my current project and run reforge analyze to show me the diagnostic report.
```

### Option 2: One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/ameenmo/reforge/main/install.sh | bash
```

### Option 3: Manual

```bash
git clone https://github.com/ameenmo/reforge ~/.reforge
~/.reforge/install.sh
```

## Usage

```bash
cd your-project
reforge analyze          # Get a diagnostic report with A-F grade
reforge apply            # Upgrade your project (creates backup first)
reforge install-skills   # Install global AI skills
```

## What It Does

### `reforge analyze`

Scans your project and grades it A-F across four categories:

| Category | Weight | Checks |
|----------|--------|--------|
| **Secrets** | 30 pts | Hardcoded API keys, passwords, tracked .env files |
| **Structure** | 25 pts | Directory depth, flatness ratio, missing standard dirs |
| **Essentials** | 25 pts | .gitignore, tests, linting, CI, README, LICENSE |
| **Large Files** | 20 pts | Files >300 lines, function count estimates |

### `reforge apply`

Non-destructively upgrades your project:

1. **Git backup branch** — always safe to undo
2. **Missing configs** — .gitignore, .env.example, .editorconfig
3. **AI context layer** — CLAUDE.md, .agent/ context, project skills
4. **Global skills** (optional) — autoresearch, self-improve, context-hub, visualize, [gstack](https://github.com/garrytan/gstack)

### `reforge install-skills`

Install global skills to `~/.claude/skills/` without re-running the full apply. Skips already-installed skills.

## All Commands

```
reforge analyze         Diagnostic report with A-F grade
reforge apply           Backup + configs + AI context layer + skills
reforge install-skills  Install global AI skills
reforge upgrade         Self-update
reforge uninstall       Remove reforge
reforge version         Print version
reforge help            Show help
```

**Flags:** `--yes` skip confirmations, `--dry-run` preview changes, `--verbose` extra detail

## Auto-Detection

Reforge detects your stack automatically:

- **Languages** — Node.js/TypeScript, Python, Go, Rust, Ruby, Java, PHP
- **Frameworks** — Next.js, React, Vue, Express, FastAPI, Django, Rails, and more
- **Package managers** — npm, yarn, pnpm, bun, pip, poetry, cargo, etc.

## Design Principles

- **Non-destructive** — always creates a git backup branch first
- **Idempotent** — safe to run multiple times
- **Zero dependencies** — only bash, git, grep, wc

## Grading Scale

| Grade | Score | Meaning |
|-------|-------|---------|
| A | 90-100 | Excellent |
| B | 75-89 | Good, minor issues |
| C | 60-74 | Fair, several issues |
| D | 40-59 | Needs restructuring |
| F | 0-39 | Critical problems |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup and guidelines.

## License

MIT
