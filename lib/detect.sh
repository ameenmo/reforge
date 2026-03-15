#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  Tech stack + project type detection
# ══════════════════════════════════════════════════════════════════

# detect_stack — sets STACK_LANG, STACK_FRAMEWORK, STACK_PKGMGR
detect_stack() {
    local project_dir="${1:-.}"
    STACK_LANG=""
    STACK_FRAMEWORK=""
    STACK_PKGMGR=""

    # ── Package manager / language detection via lock files ──
    if [ -f "$project_dir/package-lock.json" ] || [ -f "$project_dir/package.json" ]; then
        STACK_LANG="Node.js"
        STACK_PKGMGR="npm"
    fi
    if [ -f "$project_dir/yarn.lock" ]; then
        STACK_LANG="Node.js"
        STACK_PKGMGR="yarn"
    fi
    if [ -f "$project_dir/pnpm-lock.yaml" ]; then
        STACK_LANG="Node.js"
        STACK_PKGMGR="pnpm"
    fi
    if [ -f "$project_dir/bun.lockb" ] || [ -f "$project_dir/bun.lock" ]; then
        STACK_LANG="Node.js"
        STACK_PKGMGR="bun"
    fi
    if [ -f "$project_dir/requirements.txt" ] || [ -f "$project_dir/setup.py" ] || [ -f "$project_dir/pyproject.toml" ]; then
        STACK_LANG="Python"
        STACK_PKGMGR="pip"
    fi
    if [ -f "$project_dir/poetry.lock" ]; then
        STACK_LANG="Python"
        STACK_PKGMGR="poetry"
    fi
    if [ -f "$project_dir/Pipfile.lock" ] || [ -f "$project_dir/Pipfile" ]; then
        STACK_LANG="Python"
        STACK_PKGMGR="pipenv"
    fi
    if [ -f "$project_dir/go.mod" ]; then
        STACK_LANG="Go"
        STACK_PKGMGR="go modules"
    fi
    if [ -f "$project_dir/Cargo.toml" ]; then
        STACK_LANG="Rust"
        STACK_PKGMGR="cargo"
    fi
    if [ -f "$project_dir/Gemfile" ] || [ -f "$project_dir/Gemfile.lock" ]; then
        STACK_LANG="Ruby"
        STACK_PKGMGR="bundler"
    fi
    if [ -f "$project_dir/build.gradle" ] || [ -f "$project_dir/build.gradle.kts" ] || [ -f "$project_dir/pom.xml" ]; then
        STACK_LANG="Java"
        if [ -f "$project_dir/build.gradle" ] || [ -f "$project_dir/build.gradle.kts" ]; then
            STACK_PKGMGR="gradle"
        else
            STACK_PKGMGR="maven"
        fi
    fi
    if [ -f "$project_dir/composer.json" ]; then
        STACK_LANG="PHP"
        STACK_PKGMGR="composer"
    fi

    # ── Fallback: detect by file extension counts ──
    if [ -z "$STACK_LANG" ]; then
        local js_count py_count go_count rs_count rb_count
        js_count=$(find "$project_dir" -maxdepth 3 -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" 2>/dev/null | grep -v node_modules | wc -l)
        py_count=$(find "$project_dir" -maxdepth 3 -name "*.py" 2>/dev/null | grep -v __pycache__ | wc -l)
        go_count=$(find "$project_dir" -maxdepth 3 -name "*.go" 2>/dev/null | wc -l)
        rs_count=$(find "$project_dir" -maxdepth 3 -name "*.rs" 2>/dev/null | wc -l)
        rb_count=$(find "$project_dir" -maxdepth 3 -name "*.rb" 2>/dev/null | wc -l)

        local max_count=0 max_lang=""
        for lang_name in "Node.js:$js_count" "Python:$py_count" "Go:$go_count" "Rust:$rs_count" "Ruby:$rb_count"; do
            local name="${lang_name%%:*}"
            local count="${lang_name##*:}"
            if [ "$count" -gt "$max_count" ]; then
                max_count="$count"
                max_lang="$name"
            fi
        done
        STACK_LANG="${max_lang:-unknown}"
    fi

    # ── Framework detection ──
    if [ "$STACK_LANG" = "Node.js" ]; then
        if [ -f "$project_dir/next.config.js" ] || [ -f "$project_dir/next.config.mjs" ] || [ -f "$project_dir/next.config.ts" ]; then
            STACK_FRAMEWORK="Next.js"
        elif [ -f "$project_dir/nuxt.config.ts" ] || [ -f "$project_dir/nuxt.config.js" ]; then
            STACK_FRAMEWORK="Nuxt"
        elif [ -f "$project_dir/svelte.config.js" ]; then
            STACK_FRAMEWORK="SvelteKit"
        elif [ -f "$project_dir/remix.config.js" ] || [ -f "$project_dir/remix.config.ts" ]; then
            STACK_FRAMEWORK="Remix"
        elif [ -f "$project_dir/astro.config.mjs" ] || [ -f "$project_dir/astro.config.ts" ]; then
            STACK_FRAMEWORK="Astro"
        elif [ -f "$project_dir/vite.config.ts" ] || [ -f "$project_dir/vite.config.js" ]; then
            STACK_FRAMEWORK="Vite"
        elif grep -q '"express"' "$project_dir/package.json" 2>/dev/null; then
            STACK_FRAMEWORK="Express"
        elif grep -q '"fastify"' "$project_dir/package.json" 2>/dev/null; then
            STACK_FRAMEWORK="Fastify"
        elif grep -q '"react"' "$project_dir/package.json" 2>/dev/null; then
            STACK_FRAMEWORK="React"
        elif grep -q '"vue"' "$project_dir/package.json" 2>/dev/null; then
            STACK_FRAMEWORK="Vue"
        fi

        # Check for TypeScript
        if [ -f "$project_dir/tsconfig.json" ]; then
            STACK_LANG="TypeScript"
        fi
    fi

    if [ "$STACK_LANG" = "Python" ]; then
        if [ -f "$project_dir/manage.py" ]; then
            STACK_FRAMEWORK="Django"
        elif grep -q 'fastapi' "$project_dir/requirements.txt" 2>/dev/null || \
             grep -q 'fastapi' "$project_dir/pyproject.toml" 2>/dev/null; then
            STACK_FRAMEWORK="FastAPI"
        elif grep -q 'flask' "$project_dir/requirements.txt" 2>/dev/null || \
             grep -q 'flask' "$project_dir/pyproject.toml" 2>/dev/null; then
            STACK_FRAMEWORK="Flask"
        elif grep -q 'streamlit' "$project_dir/requirements.txt" 2>/dev/null; then
            STACK_FRAMEWORK="Streamlit"
        fi
    fi

    if [ "$STACK_LANG" = "Ruby" ]; then
        if [ -f "$project_dir/config/routes.rb" ]; then
            STACK_FRAMEWORK="Rails"
        elif grep -q 'sinatra' "$project_dir/Gemfile" 2>/dev/null; then
            STACK_FRAMEWORK="Sinatra"
        fi
    fi

    if [ "$STACK_LANG" = "Go" ]; then
        if grep -q 'gin-gonic' "$project_dir/go.mod" 2>/dev/null; then
            STACK_FRAMEWORK="Gin"
        elif grep -q 'labstack/echo' "$project_dir/go.mod" 2>/dev/null; then
            STACK_FRAMEWORK="Echo"
        elif grep -q 'gofiber' "$project_dir/go.mod" 2>/dev/null; then
            STACK_FRAMEWORK="Fiber"
        fi
    fi

    if [ "$STACK_LANG" = "PHP" ]; then
        if [ -f "$project_dir/artisan" ]; then
            STACK_FRAMEWORK="Laravel"
        elif [ -d "$project_dir/symfony" ] || grep -q 'symfony' "$project_dir/composer.json" 2>/dev/null; then
            STACK_FRAMEWORK="Symfony"
        fi
    fi
}

# detect_project_type — sets PROJECT_TYPE (app, api, agent, data-pipeline)
detect_project_type() {
    local project_dir="${1:-.}"
    PROJECT_TYPE="app"

    # Check directory names
    if [ -d "$project_dir/pipeline" ] || [ -d "$project_dir/pipelines" ] || \
       [ -d "$project_dir/etl" ] || [ -d "$project_dir/dags" ]; then
        PROJECT_TYPE="data-pipeline"
        return
    fi

    if [ -d "$project_dir/agents" ] || [ -d "$project_dir/agent" ]; then
        PROJECT_TYPE="agent"
        return
    fi

    # Check for API patterns
    if [ -d "$project_dir/routes" ] || [ -d "$project_dir/endpoints" ] || \
       [ -d "$project_dir/api" ]; then
        PROJECT_TYPE="api"
        return
    fi

    # Check framework-specific patterns
    if [ -n "$STACK_FRAMEWORK" ]; then
        case "$STACK_FRAMEWORK" in
            Express|Fastify|FastAPI|Flask|Django|Rails|Sinatra|Gin|Echo|Fiber|Laravel|Symfony)
                PROJECT_TYPE="api"
                ;;
            Next.js|Nuxt|SvelteKit|Remix|React|Vue|Astro|Streamlit)
                PROJECT_TYPE="app"
                ;;
        esac
        return
    fi

    # Check import patterns in source files
    if grep -rqlE 'langchain|openai|anthropic|llama_index|autogen' "$project_dir" \
       --include="*.py" --include="*.ts" --include="*.js" 2>/dev/null; then
        PROJECT_TYPE="agent"
        return
    fi

    if grep -rqlE 'pandas|spark|airflow|prefect|dagster|dbt' "$project_dir" \
       --include="*.py" 2>/dev/null; then
        PROJECT_TYPE="data-pipeline"
        return
    fi
}

# detect_project_name — sets PROJECT_NAME
detect_project_name() {
    local project_dir="${1:-.}"
    PROJECT_NAME=""

    # Try package.json
    if [ -f "$project_dir/package.json" ]; then
        PROJECT_NAME=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$project_dir/package.json" 2>/dev/null | head -1 | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    fi

    # Try pyproject.toml
    if [ -z "$PROJECT_NAME" ] && [ -f "$project_dir/pyproject.toml" ]; then
        PROJECT_NAME=$(grep '^name[[:space:]]*=' "$project_dir/pyproject.toml" 2>/dev/null | head -1 | sed 's/.*=[[:space:]]*"\([^"]*\)".*/\1/')
    fi

    # Try Cargo.toml
    if [ -z "$PROJECT_NAME" ] && [ -f "$project_dir/Cargo.toml" ]; then
        PROJECT_NAME=$(grep '^name[[:space:]]*=' "$project_dir/Cargo.toml" 2>/dev/null | head -1 | sed 's/.*=[[:space:]]*"\([^"]*\)".*/\1/')
    fi

    # Try go.mod
    if [ -z "$PROJECT_NAME" ] && [ -f "$project_dir/go.mod" ]; then
        PROJECT_NAME=$(head -1 "$project_dir/go.mod" 2>/dev/null | sed 's/^module[[:space:]]*//' | sed 's|.*/||')
    fi

    # Fallback: directory name
    if [ -z "$PROJECT_NAME" ]; then
        PROJECT_NAME=$(basename "$(cd "$project_dir" && pwd)")
    fi
}

# save_state — write detected state to .reforge/state.sh
save_state() {
    local project_dir="${1:-.}"
    mkdir -p "$project_dir/.reforge"
    cat > "$project_dir/.reforge/state.sh" << EOF
# Reforge detection state — auto-generated
STACK_LANG="${STACK_LANG}"
STACK_FRAMEWORK="${STACK_FRAMEWORK}"
STACK_PKGMGR="${STACK_PKGMGR}"
PROJECT_TYPE="${PROJECT_TYPE}"
PROJECT_NAME="${PROJECT_NAME}"
DETECTED_AT="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
EOF
}

# load_state — source saved state if it exists
load_state() {
    local project_dir="${1:-.}"
    if [ -f "$project_dir/.reforge/state.sh" ]; then
        # shellcheck source=/dev/null
        source "$project_dir/.reforge/state.sh"
        return 0
    fi
    return 1
}

# run_detection — full detection pipeline
run_detection() {
    local project_dir="${1:-.}"
    detect_stack "$project_dir"
    detect_project_type "$project_dir"
    detect_project_name "$project_dir"
    save_state "$project_dir"
}
