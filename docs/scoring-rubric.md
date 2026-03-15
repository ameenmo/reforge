# Reforge Scoring Rubric

## Overview

Reforge analyzes projects across 4 categories, scoring 0-100 total, then maps to an A-F letter grade.

## Categories

### Structure (0-25 points)

Evaluates how well-organized the project's file layout is.

| Check | Deduction | Condition |
|-------|-----------|-----------|
| Flatness (high) | -10 | >80% source files in root, total >5 files |
| Flatness (moderate) | -5 | >50% source files in root, total >5 files |
| No src/lib directory | -5 | Neither src/ nor lib/ exists, total >5 files |
| No test directory | -5 | No test/tests/__tests__/spec directory |
| Very shallow | -5 | Max depth <=2 with >10 files |

### Large Files (0-20 points)

Flags monolithic source files that should be split.

| Check | Deduction | Condition |
|-------|-----------|-----------|
| Very large file | -5 | Source file >800 lines |
| Large file | -3 | Source file >500 lines |
| Oversized file | -2 | Source file >300 lines |

Function count estimates are provided for context (grep-based, approximate).

### Essentials (0-25 points)

Checks for project hygiene files.

| Check | Deduction | Missing |
|-------|-----------|---------|
| .gitignore | -3 | No .gitignore file |
| .env.example | -3 | No .env.example/.env.sample/.env.template |
| README | -3 | No README.md/readme.md |
| Tests | -5 | No test directory or test files |
| Linting config | -4 | No ESLint/Prettier/Ruff/etc. config |
| CI config | -4 | No GitHub Actions/GitLab CI/etc. |
| LICENSE | -3 | No LICENSE file |

### Secrets (0-30 points)

Detects potential hardcoded secrets and credentials.

| Check | Deduction | Pattern |
|-------|-----------|---------|
| API key patterns | -5 each | sk-, ghp_, AKIA, Bearer ey, etc. |
| Hardcoded credentials | -5 each | password=, api_key=, secret= in source |
| .env tracked by git | -10 | .env in git index |

## Grade Scale

| Grade | Score Range | Interpretation |
|-------|-------------|----------------|
| A | 90-100 | Excellent — well-structured project |
| B | 75-89 | Good — minor improvements possible |
| C | 60-74 | Fair — several issues to address |
| D | 40-59 | Poor — significant restructuring needed |
| F | 0-39 | Critical — major structural problems |
