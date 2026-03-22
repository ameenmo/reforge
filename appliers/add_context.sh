#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  Applier: Add AI context layer (prestart templates)
# ══════════════════════════════════════════════════════════════════

APPLIER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REFORGE_DIR="$(dirname "$APPLIER_DIR")"

# shellcheck source=../lib/colors.sh
source "$REFORGE_DIR/lib/colors.sh"
# shellcheck source=../lib/prompts.sh
source "$REFORGE_DIR/lib/prompts.sh"
# shellcheck source=../lib/fs.sh
source "$REFORGE_DIR/lib/fs.sh"

run_add_context() {
    local project_dir="${1:-.}"

    # ── Determine template source ──
    local template_dir=""
    if [ -d "$HOME/.prestart/templates" ]; then
        template_dir="$HOME/.prestart/templates"
        info "Using prestart templates from ~/.prestart"
    elif [ -d "/root/prestart/templates" ]; then
        template_dir="/root/prestart/templates"
        info "Using prestart templates from /root/prestart"
    elif [ -d "$REFORGE_DIR/templates/context/common" ]; then
        template_dir="$REFORGE_DIR/templates/context"
        info "Using bundled templates"
    else
        error "No templates found. Install prestart or ensure bundled templates exist."
        return 1
    fi

    # ── Check if context layer already exists ──
    if [ -d "$project_dir/directives" ] && [ -f "$project_dir/directives/SOP.md" ] && \
       [ -d "$project_dir/.agent" ] && [ -d "$project_dir/.claude" ]; then
        warn "AI context layer already exists. Skipping to avoid overwriting."
        CONTEXT_ADDED=false
        return 0
    fi

    # ── Detect/confirm values ──
    local project_name="${PROJECT_NAME:-$(basename "$(cd "$project_dir" && pwd)")}"
    local project_type="${PROJECT_TYPE:-app}"
    local domain="${project_type//-/_}"
    local tech_stack="${STACK_LABEL:-Not specified}"

    header "AI Context Layer Configuration"
    echo ""
    echo "    Project:    ${project_name}"
    echo "    Type:       ${project_type}"
    echo "    Domain:     ${domain}"
    echo "    Tech Stack: ${tech_stack}"
    echo ""

    if [ "${FLAG_YES:-false}" != true ]; then
        if ! confirm "Apply with these settings?"; then
            # Let user override
            input_with_default "Project name" "$project_name"
            project_name="$INPUT_RESULT"

            select_option "Project type:" "app" "agent" "api" "data-pipeline"
            project_type="$SELECT_RESULT"
            domain="${project_type//-/_}"

            input_with_default "Tech stack" "$tech_stack"
            tech_stack="$INPUT_RESULT"
        fi
    fi

    # ── Copy common template ──
    header "Copying common template..."
    if [ -d "$template_dir/common" ]; then
        # Copy non-hidden
        cp -rn "$template_dir/common/"* "$project_dir/" 2>/dev/null || true
        # Copy hidden dirs
        for hidden in .agent .claude; do
            if [ -d "$template_dir/common/$hidden" ] && [ ! -d "$project_dir/$hidden" ]; then
                cp -r "$template_dir/common/$hidden" "$project_dir/"
            elif [ -d "$template_dir/common/$hidden" ]; then
                # Merge: copy files that don't exist
                cp -rn "$template_dir/common/$hidden/"* "$project_dir/$hidden/" 2>/dev/null || true
            fi
        done
        success "Common template applied"
    fi

    # ── Copy archetype template ──
    local archetype_dir="$template_dir/$project_type"
    if [ -d "$archetype_dir" ]; then
        header "Applying ${project_type} archetype..."
        cp -rn "$archetype_dir/"* "$project_dir/" 2>/dev/null || true
        for hidden in .claude .agent; do
            if [ -d "$archetype_dir/$hidden" ]; then
                mkdir -p "$project_dir/$hidden"
                cp -rn "$archetype_dir/$hidden/"* "$project_dir/$hidden/" 2>/dev/null || true
            fi
        done

        # Append archetype SOP sections
        if [ -f "$project_dir/directives/SOP-sections.md" ]; then
            cat "$project_dir/directives/SOP-sections.md" >> "$project_dir/directives/SOP.md.tmpl" 2>/dev/null || true
            rm -f "$project_dir/directives/SOP-sections.md"
        fi

        # Rename verify script to use domain
        for verify_tmpl in "$project_dir/tools"/verify_*.py.tmpl; do
            [ -f "$verify_tmpl" ] || continue
            local domain_verify="$project_dir/tools/verify_${domain}.py.tmpl"
            if [ "$verify_tmpl" != "$domain_verify" ]; then
                mv "$verify_tmpl" "$domain_verify"
            fi
            break
        done

        success "${project_type} archetype applied"
    else
        warn "Archetype '${project_type}' not found, using common only"
    fi

    # ── Replace placeholders in .tmpl files ──
    header "Replacing placeholders..."
    local tmpl_count=0
    while IFS= read -r -d '' tmpl_file; do
        sed -i "s/{{PROJECT_NAME}}/${project_name}/g" "$tmpl_file"
        sed -i "s/{{DOMAIN}}/${domain}/g" "$tmpl_file"
        sed -i "s/{{TECH_STACK}}/${tech_stack}/g" "$tmpl_file"

        # Remove .tmpl extension
        local new_name="${tmpl_file%.tmpl}"
        mv "$tmpl_file" "$new_name"
        tmpl_count=$((tmpl_count + 1))
    done < <(find "$project_dir" -name "*.tmpl" -not -path '*/.git/*' -print0 2>/dev/null)
    success "${tmpl_count} template files processed"

    # ── Run sync_configs.py if available ──
    if [ -f "$project_dir/tools/sync_configs.py" ]; then
        header "Running config sync..."
        local python_cmd=""
        if command -v python3 &>/dev/null; then
            python_cmd="python3"
        elif command -v python &>/dev/null; then
            python_cmd="python"
        fi

        if [ -n "$python_cmd" ]; then
            (cd "$project_dir" && $python_cmd tools/sync_configs.py) && \
                success "Config sync complete" || \
                warn "Config sync had issues — run manually: python tools/sync_configs.py"
        else
            warn "Python not found — skipping config sync"
        fi
    fi

    # ── Symlink gstack if available ──
    local gstack_global="$HOME/.claude/skills/gstack"
    if [ -d "$gstack_global" ] && [ ! -e "$project_dir/.claude/skills/gstack" ]; then
        mkdir -p "$project_dir/.claude/skills"
        ln -sf "$gstack_global" "$project_dir/.claude/skills/gstack"
        local gstack_skills=("benchmark" "browse" "canary" "careful" "codex" "design-consultation" "design-review" "document-release" "freeze" "gstack-upgrade" "guard" "investigate" "land-and-deploy" "office-hours" "plan-ceo-review" "plan-design-review" "plan-eng-review" "qa" "qa-only" "retro" "review" "setup-browser-cookies" "setup-deploy" "ship" "unfreeze")
        for skill in "${gstack_skills[@]}"; do
            if [ -d "$gstack_global/$skill" ] && [ ! -e "$project_dir/.claude/skills/$skill" ]; then
                ln -sf "$gstack_global/$skill" "$project_dir/.claude/skills/$skill"
            fi
        done
        success "gstack skills linked"
    fi

    CONTEXT_ADDED=true
}
