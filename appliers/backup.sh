#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  Applier: Create git backup branch before changes
# ══════════════════════════════════════════════════════════════════

APPLIER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REFORGE_DIR="$(dirname "$APPLIER_DIR")"

# shellcheck source=../lib/colors.sh
source "$REFORGE_DIR/lib/colors.sh"

run_backup() {
    local project_dir="${1:-.}"

    cd "$project_dir" || return 1

    # If not a git repo, initialize one
    if [ ! -d ".git" ]; then
        info "No git repository found. Initializing..."
        git init -q
        git add -A
        git commit -q -m "Initial commit (before reforge)"
        success "Git initialized with initial commit"
    fi

    # Create backup branch
    local timestamp
    timestamp=$(date '+%Y%m%d-%H%M%S')
    local backup_branch="reforge/backup-${timestamp}"

    # Stage any uncommitted changes first
    local has_changes=false
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        has_changes=true
        git add -A
        git commit -q -m "Snapshot before reforge apply" 2>/dev/null || true
    fi

    # Create backup branch at current HEAD
    git branch "$backup_branch"
    success "Backup branch created: ${backup_branch}"

    BACKUP_BRANCH="$backup_branch"
}
