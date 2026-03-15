#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  Command: apply — backup + add configs + add AI context layer
# ══════════════════════════════════════════════════════════════════

CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REFORGE_DIR="$(dirname "$CMD_DIR")"

# shellcheck source=../lib/colors.sh
source "$REFORGE_DIR/lib/colors.sh"
# shellcheck source=../lib/prompts.sh
source "$REFORGE_DIR/lib/prompts.sh"
# shellcheck source=../lib/detect.sh
source "$REFORGE_DIR/lib/detect.sh"
# shellcheck source=../lib/fs.sh
source "$REFORGE_DIR/lib/fs.sh"

run_apply() {
    local project_dir="${1:-.}"
    local dry_run="${FLAG_DRY_RUN:-false}"

    echo ""
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════╗"
    echo "  ║   REFORGE APPLY                          ║"
    echo "  ╚══════════════════════════════════════════╝"
    echo -e "${RESET}"

    # ── Step 1: Run analysis if not already done ──
    if ! load_state "$project_dir"; then
        info "No previous analysis found. Running analysis first..."
        echo ""
        source "$REFORGE_DIR/commands/analyze.sh"
        run_analyze "$project_dir"
        echo ""
    else
        info "Using previous analysis (grade: ${GRADE:-?}, score: ${TOTAL_SCORE:-?}/100)"
    fi

    # ── Step 2: Show what will be done ──
    header "Changes to apply:"
    echo ""
    echo "    1. Create git backup branch"
    echo "    2. Add missing configs (.gitignore, .env.example, .editorconfig)"
    echo "    3. Add AI context layer (directives, .agent, .claude, tools)"
    echo ""

    if [ "$dry_run" = true ]; then
        warn "Dry run mode — no changes will be made"
        return 0
    fi

    # ── Step 3: Confirm ──
    if ! confirm "Apply these changes?"; then
        echo ""
        info "Aborted."
        return 0
    fi

    echo ""

    # ── Step 4: Backup ──
    header "Step 1/3: Creating backup..."
    source "$REFORGE_DIR/appliers/backup.sh"
    run_backup "$project_dir"

    # ── Step 5: Add configs ──
    echo ""
    header "Step 2/3: Adding configs..."
    source "$REFORGE_DIR/appliers/add_configs.sh"
    run_add_configs "$project_dir"

    # ── Step 6: Add context layer ──
    echo ""
    header "Step 3/3: Adding AI context layer..."
    source "$REFORGE_DIR/appliers/add_context.sh"
    run_add_context "$project_dir"

    # ── Step 7: Summary ──
    echo ""
    echo -e "${BOLD}${GREEN}"
    echo "  ╔══════════════════════════════════════════╗"
    echo "  ║   REFORGE COMPLETE                       ║"
    echo "  ╚══════════════════════════════════════════╝"
    echo -e "${RESET}"
    echo ""
    echo -e "  ${BOLD}Backup:${RESET} ${BACKUP_BRANCH:-none}"
    echo ""

    if [ ${#CONFIGS_ADDED[@]} -gt 0 ]; then
        echo -e "  ${BOLD}Configs added:${RESET}"
        for config in "${CONFIGS_ADDED[@]}"; do
            echo "    + ${config}"
        done
        echo ""
    fi

    if [ "${CONTEXT_ADDED:-false}" = true ]; then
        echo -e "  ${BOLD}AI context layer:${RESET}"
        echo "    + directives/SOP.md       — Project rules (edit this!)"
        echo "    + .agent/                 — AI context layer"
        echo "    + .claude/                — Claude Code config + skills"
        echo "    + tools/sync_configs.py   — Config sync engine"
        echo ""
    fi

    echo -e "  ${BOLD}Next steps:${RESET}"
    echo "    1. Edit directives/SOP.md with your project details"
    echo "    2. Run: python tools/sync_configs.py"
    echo "    3. Run: reforge analyze  (grade should improve)"
    echo "    4. Start coding with Claude Code (or any AI tool)"
    echo ""
    echo -e "  ${DIM}To undo: git checkout ${BACKUP_BRANCH:-backup}${RESET}"
    echo ""
}
