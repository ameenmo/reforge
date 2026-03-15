#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  Analyzer: Tech stack detection
#  Outputs: STACK_LANG, STACK_FRAMEWORK, STACK_PKGMGR
# ══════════════════════════════════════════════════════════════════

ANALYZER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REFORGE_DIR="$(dirname "$ANALYZER_DIR")"

# shellcheck source=../lib/detect.sh
source "$REFORGE_DIR/lib/detect.sh"

run_stack_analysis() {
    local project_dir="${1:-.}"

    detect_stack "$project_dir"
    detect_project_name "$project_dir"
    detect_project_type "$project_dir"

    # Build tech stack label
    STACK_LABEL="$STACK_LANG"
    if [ -n "$STACK_FRAMEWORK" ]; then STACK_LABEL="$STACK_LABEL / $STACK_FRAMEWORK"; fi

    # Determine if TypeScript
    HAS_TYPESCRIPT=false
    if [ -f "$project_dir/tsconfig.json" ]; then
        HAS_TYPESCRIPT=true
    fi
}
