#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  Analyzer: Missing essentials — .gitignore, tests, linting, CI, etc.
#  Score: 0-25 points
# ══════════════════════════════════════════════════════════════════

run_missing_essentials_analysis() {
    local project_dir="${1:-.}"

    ESSENTIALS_SCORE=25
    ESSENTIALS_PRESENT=()
    ESSENTIALS_MISSING=()

    # .gitignore (3 points)
    if [ -f "$project_dir/.gitignore" ]; then
        ESSENTIALS_PRESENT+=(".gitignore")
    else
        ESSENTIALS_MISSING+=(".gitignore")
        ESSENTIALS_SCORE=$((ESSENTIALS_SCORE - 3))
    fi

    # .env.example (3 points)
    if [ -f "$project_dir/.env.example" ] || [ -f "$project_dir/.env.sample" ] || [ -f "$project_dir/.env.template" ]; then
        ESSENTIALS_PRESENT+=(".env.example")
    else
        ESSENTIALS_MISSING+=(".env.example")
        ESSENTIALS_SCORE=$((ESSENTIALS_SCORE - 3))
    fi

    # README (3 points)
    if [ -f "$project_dir/README.md" ] || [ -f "$project_dir/readme.md" ] || [ -f "$project_dir/README" ]; then
        ESSENTIALS_PRESENT+=("README.md")
    else
        ESSENTIALS_MISSING+=("README.md")
        ESSENTIALS_SCORE=$((ESSENTIALS_SCORE - 3))
    fi

    # Tests (5 points)
    local has_tests=false
    for test_dir in test tests __tests__ spec src/test src/tests; do
        if [ -d "$project_dir/$test_dir" ]; then has_tests=true; break; fi
    done
    # Also check for test files in any location
    if [ "$has_tests" = false ]; then
        local test_file_count
        test_file_count=$(find "$project_dir" -type f \( -name '*.test.*' -o -name '*.spec.*' -o -name 'test_*' -o -name '*_test.*' \) \
            -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | wc -l)
        if [ "$test_file_count" -gt 0 ]; then has_tests=true; fi
    fi

    if [ "$has_tests" = true ]; then
        ESSENTIALS_PRESENT+=("Tests")
    else
        ESSENTIALS_MISSING+=("Tests")
        ESSENTIALS_SCORE=$((ESSENTIALS_SCORE - 5))
    fi

    # Linting config (4 points)
    local has_linting=false
    for lint_file in .eslintrc .eslintrc.js .eslintrc.json .eslintrc.cjs .eslintrc.yml \
                     eslint.config.js eslint.config.mjs eslint.config.cjs \
                     .prettierrc .prettierrc.js .prettierrc.json .prettierrc.yml \
                     setup.cfg .flake8 .pylintrc .ruff.toml ruff.toml \
                     .rubocop.yml .golangci.yml .golangci.yaml; do
        if [ -f "$project_dir/$lint_file" ]; then has_linting=true; break; fi
    done
    # Check pyproject.toml for ruff/black/flake8 config
    if [ "$has_linting" = false ] && [ -f "$project_dir/pyproject.toml" ]; then
        if grep -qE '\[tool\.(ruff|black|flake8|pylint|isort)\]' "$project_dir/pyproject.toml" 2>/dev/null; then
            has_linting=true
        fi
    fi
    # Check package.json for eslint config
    if [ "$has_linting" = false ] && [ -f "$project_dir/package.json" ]; then
        if grep -q '"eslintConfig"' "$project_dir/package.json" 2>/dev/null; then
            has_linting=true
        fi
    fi

    if [ "$has_linting" = true ]; then
        ESSENTIALS_PRESENT+=("Linting config")
    else
        ESSENTIALS_MISSING+=("Linting config")
        ESSENTIALS_SCORE=$((ESSENTIALS_SCORE - 4))
    fi

    # CI config (4 points)
    local has_ci=false
    if [ -d "$project_dir/.github/workflows" ]; then has_ci=true; fi
    if [ -f "$project_dir/.gitlab-ci.yml" ]; then has_ci=true; fi
    if [ -f "$project_dir/.circleci/config.yml" ]; then has_ci=true; fi
    if [ -f "$project_dir/Jenkinsfile" ]; then has_ci=true; fi
    if [ -f "$project_dir/.travis.yml" ]; then has_ci=true; fi
    if [ -f "$project_dir/bitbucket-pipelines.yml" ]; then has_ci=true; fi

    if [ "$has_ci" = true ]; then
        ESSENTIALS_PRESENT+=("CI config")
    else
        ESSENTIALS_MISSING+=("CI config")
        ESSENTIALS_SCORE=$((ESSENTIALS_SCORE - 4))
    fi

    # LICENSE (3 points)
    if [ -f "$project_dir/LICENSE" ] || [ -f "$project_dir/LICENSE.md" ] || [ -f "$project_dir/LICENCE" ]; then
        ESSENTIALS_PRESENT+=("LICENSE")
    else
        ESSENTIALS_MISSING+=("LICENSE")
        ESSENTIALS_SCORE=$((ESSENTIALS_SCORE - 3))
    fi

    # Floor at 0
    if [ "$ESSENTIALS_SCORE" -lt 0 ]; then ESSENTIALS_SCORE=0; fi
}
