# Reforge Analysis Checks

## Stack Detection

Reforge auto-detects the tech stack using these signals (in priority order):

### Language Detection
1. **Lock files**: package-lock.json/yarn.lock/pnpm-lock.yaml (Node.js), poetry.lock/Pipfile.lock (Python), go.mod (Go), Cargo.toml (Rust), Gemfile (Ruby), build.gradle/pom.xml (Java), composer.json (PHP)
2. **Config files**: tsconfig.json upgrades Node.js to TypeScript
3. **File extension counts**: Fallback — counts .js/.ts/.py/.go/.rs/.rb files

### Framework Detection
- **Node.js**: next.config.* (Next.js), nuxt.config.* (Nuxt), svelte.config.js (SvelteKit), vite.config.* (Vite), package.json deps (Express, Fastify, React, Vue)
- **Python**: manage.py (Django), requirements.txt/pyproject.toml deps (FastAPI, Flask, Streamlit)
- **Ruby**: config/routes.rb (Rails), Gemfile deps (Sinatra)
- **Go**: go.mod deps (Gin, Echo, Fiber)
- **PHP**: artisan (Laravel), composer.json deps (Symfony)

### Project Type Detection
1. **Directory names**: pipeline/etl/dags → data-pipeline, agents/agent → agent, routes/endpoints/api → api
2. **Framework inference**: Express/FastAPI/Django → api, Next.js/React/Vue → app
3. **Import patterns**: langchain/openai/anthropic → agent, pandas/spark/airflow → data-pipeline
4. **Default**: app

## Structure Checks

- **Flatness ratio**: Percentage of source files in root directory vs subdirectories
- **Standard directories**: Checks for src/, lib/, test/tests/__tests__/spec
- **Directory depth**: Maximum nesting depth of source files
- Excludes: node_modules, .git, .venv, venv, __pycache__, dist, build, .next, .reforge

## Large File Checks

- Scans all source files (.js, .ts, .jsx, .tsx, .py, .go, .rs, .rb, .java, .php)
- Flags files >300 lines
- Estimates function count using grep patterns: `function`, `def`, `class`, `const x = (`, `pub fn`, `func`

## Essentials Checks

- **.gitignore**: Exact file check
- **.env.example**: Also accepts .env.sample, .env.template
- **README**: Accepts README.md, readme.md, README
- **Tests**: Checks for test directories AND test file patterns (*.test.*, *.spec.*, test_*, *_test.*)
- **Linting**: Checks ESLint (.eslintrc*, eslint.config.*), Prettier (.prettierrc*), Python (setup.cfg, .flake8, .pylintrc, ruff.toml), Ruby (.rubocop.yml), Go (.golangci.yml), plus pyproject.toml [tool.*] and package.json "eslintConfig"
- **CI**: GitHub Actions (.github/workflows/), GitLab CI, CircleCI, Jenkins, Travis, Bitbucket Pipelines
- **LICENSE**: Accepts LICENSE, LICENSE.md, LICENCE

## Secrets Checks

### High-confidence patterns (regex)
- OpenAI keys: `sk-[a-zA-Z0-9]{20,}`
- Anthropic keys: `sk-ant-[a-zA-Z0-9-]{20,}`
- GitHub PATs: `ghp_[a-zA-Z0-9]{36}`
- GitHub OAuth: `gho_[a-zA-Z0-9]{36}`
- AWS access keys: `AKIA[A-Z0-9]{16}`
- JWT tokens: `Bearer ey[a-zA-Z0-9._-]+`
- Slack tokens: `xoxb-`, `xoxp-`

### Medium-confidence patterns
- `password = "..."`, `api_key = "..."`, `secret = "..."`
- Excludes: lock files, example files, markdown, .env.example

### Git tracking check
- Warns if .env file is tracked in git index
