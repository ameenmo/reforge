# Contributing to Reforge

Thanks for your interest in contributing to Reforge! This guide will help you get started.

## Code of Conduct

Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before contributing.

## Getting Started

### Development Setup

```bash
# Clone the repo
git clone https://github.com/ameenmo/reforge ~/.reforge-dev
cd ~/.reforge-dev

# Run shellcheck on all scripts
shellcheck reforge.sh install.sh commands/*.sh lib/*.sh analyzers/*.sh appliers/*.sh

# Test against fixtures (run from inside each fixture directory)
cd tests/fixtures/messy-node && bash ../../../reforge.sh analyze && cd -
cd tests/fixtures/messy-python && bash ../../../reforge.sh analyze && cd -
cd tests/fixtures/decent-project && bash ../../../reforge.sh analyze && cd -
```

### Prerequisites

- **bash** 4.0+
- **git**
- **shellcheck** — install via `apt install shellcheck`, `brew install shellcheck`, or [github.com/koalaman/shellcheck](https://github.com/koalaman/shellcheck)

## How to Contribute

1. **Open an issue first** — Describe what you want to change and why. This avoids duplicate work and helps us align on the approach.
2. **Fork and branch** — Create a feature branch from `main` (e.g., `feat/add-ruby-detection`).
3. **Make your changes** — Follow the code conventions below.
4. **Test** — Run shellcheck and test against the fixtures.
5. **Submit a PR** — Reference the issue and describe what you changed.

## Code Conventions

All shell scripts in this project follow these conventions:

- **Strict mode**: Every script starts with `set -euo pipefail`
- **Shellcheck**: Use `# shellcheck source=` directives for sourced files
- **Colors**: Use helpers from `lib/colors.sh` (`info`, `warn`, `error`, `success`, `header`) — never raw escape codes
- **Quoting**: Always quote variables (`"$var"`, not `$var`)

### Directory Structure

| Directory | Purpose |
|-----------|---------|
| `commands/` | User-facing command handlers |
| `appliers/` | Implementation logic for `apply` steps |
| `analyzers/` | Diagnostic analysis modules |
| `lib/` | Shared utilities (colors, prompts, detection, filesystem) |
| `templates/` | Template files copied to target projects |
| `docs/` | Project documentation |
| `tests/fixtures/` | Test projects for smoke testing |

### Adding a New Analyzer

1. Create `analyzers/your_check.sh` with a function that appends findings to the report
2. Source it in `commands/analyze.sh`
3. Add scoring logic in `analyzers/scoring.sh`
4. Update `docs/analysis-checks.md` and `docs/scoring-rubric.md`

### Adding a New Language/Framework

1. Add detection logic in `lib/detect.sh`
2. Add a `.gitignore` template in `templates/gitignore/`
3. Test with a fixture project

## Testing

There are no unit tests (yet). Testing is done by running reforge against the fixture projects:

```bash
# Analyze all fixtures (reforge analyzes the current directory)
cd tests/fixtures/messy-node && bash ../../../reforge.sh analyze && cd -
cd tests/fixtures/messy-python && bash ../../../reforge.sh analyze && cd -
cd tests/fixtures/decent-project && bash ../../../reforge.sh analyze && cd -
```

If you add a new feature, consider adding a fixture project under `tests/fixtures/` that exercises it.

## PR Checklist

Before submitting your PR, make sure:

- [ ] `shellcheck` passes on all `.sh` files
- [ ] Tested against at least one fixture project
- [ ] Updated docs if you changed behavior
- [ ] Commit messages are clear and descriptive
