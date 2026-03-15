#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  Applier: Add missing configs — .gitignore, .env.example, .editorconfig
# ══════════════════════════════════════════════════════════════════

APPLIER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REFORGE_DIR="$(dirname "$APPLIER_DIR")"

# shellcheck source=../lib/colors.sh
source "$REFORGE_DIR/lib/colors.sh"
# shellcheck source=../lib/fs.sh
source "$REFORGE_DIR/lib/fs.sh"

run_add_configs() {
    local project_dir="${1:-.}"
    local stack_lang="${STACK_LANG:-unknown}"

    CONFIGS_ADDED=()
    CONFIGS_SKIPPED=()

    # ── .gitignore ──
    if [ ! -f "$project_dir/.gitignore" ]; then
        # Pick stack-specific template
        local gitignore_template=""
        case "$stack_lang" in
            Node.js|TypeScript)
                gitignore_template="$REFORGE_DIR/templates/gitignore/node.gitignore"
                ;;
            Python)
                gitignore_template="$REFORGE_DIR/templates/gitignore/python.gitignore"
                ;;
            Go)
                gitignore_template="$REFORGE_DIR/templates/gitignore/go.gitignore"
                ;;
            *)
                gitignore_template="$REFORGE_DIR/templates/gitignore/generic.gitignore"
                ;;
        esac

        if [ -f "$gitignore_template" ]; then
            cp "$gitignore_template" "$project_dir/.gitignore"
            CONFIGS_ADDED+=(".gitignore (${stack_lang})")
        fi
    else
        # Merge missing entries from generic template
        local generic="$REFORGE_DIR/templates/gitignore/generic.gitignore"
        if [ -f "$generic" ]; then
            local added
            added=$(merge_gitignore "$generic" "$project_dir/.gitignore")
            if [ "${added:-0}" -gt 0 ]; then
                CONFIGS_ADDED+=(".gitignore (+${added} entries merged)")
            else
                CONFIGS_SKIPPED+=(".gitignore (already complete)")
            fi
        else
            CONFIGS_SKIPPED+=(".gitignore (exists)")
        fi
    fi

    # ── .env.example ──
    if [ ! -f "$project_dir/.env.example" ] && [ ! -f "$project_dir/.env.sample" ] && [ ! -f "$project_dir/.env.template" ]; then
        local env_template="$REFORGE_DIR/templates/env/.env.example"
        if [ -f "$env_template" ]; then
            cp "$env_template" "$project_dir/.env.example"
            CONFIGS_ADDED+=(".env.example")
        fi
    else
        CONFIGS_SKIPPED+=(".env.example (exists)")
    fi

    # ── .editorconfig ──
    if [ ! -f "$project_dir/.editorconfig" ]; then
        cat > "$project_dir/.editorconfig" << 'EDITORCONFIG'
root = true

[*]
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
charset = utf-8

[*.{js,ts,jsx,tsx,json,yml,yaml,css,scss,html}]
indent_style = space
indent_size = 2

[*.{py,rs,go,java,rb,php}]
indent_style = space
indent_size = 4

[Makefile]
indent_style = tab

[*.md]
trim_trailing_whitespace = false
EDITORCONFIG
        CONFIGS_ADDED+=(".editorconfig")
    else
        CONFIGS_SKIPPED+=(".editorconfig (exists)")
    fi

    # ── Print results ──
    if [ ${#CONFIGS_ADDED[@]} -gt 0 ]; then
        for config in "${CONFIGS_ADDED[@]}"; do
            success "Added: ${config}"
        done
    fi
    if [ ${#CONFIGS_SKIPPED[@]} -gt 0 ]; then
        for config in "${CONFIGS_SKIPPED[@]}"; do
            info "Skipped: ${config}"
        done
    fi
}
