#!/usr/bin/env bash
set -euo pipefail

# ══════════════════════════════════════════════════════════════════
#  reforge — CLI entrypoint for restructuring existing projects
# ══════════════════════════════════════════════════════════════════

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
    DIR="$(cd "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
done
REFORGE_DIR="$(cd "$(dirname "$SOURCE")" && pwd)"
VERSION="$(cat "$REFORGE_DIR/VERSION" 2>/dev/null || echo "unknown")"

# ── Parse global flags ────────────────────────────────────────
FLAG_YES=false
FLAG_DRY_RUN=false
FLAG_VERBOSE=false

args=()
for arg in "$@"; do
    case "$arg" in
        --yes|-y)     FLAG_YES=true ;;
        --dry-run)    FLAG_DRY_RUN=true ;;
        --verbose|-v) FLAG_VERBOSE=true ;;
        *)            args+=("$arg") ;;
    esac
done
set -- "${args[@]+"${args[@]}"}"

export FLAG_YES FLAG_DRY_RUN FLAG_VERBOSE

# Colors (if terminal supports them)
if [ -t 1 ]; then
    BOLD='\033[1m' GREEN='\033[0;32m' YELLOW='\033[0;33m'
    CYAN='\033[0;36m' RED='\033[0;31m' RESET='\033[0m'
else
    BOLD='' GREEN='' YELLOW='' CYAN='' RED='' RESET=''
fi

usage() {
    echo -e "${BOLD}reforge${RESET} v${VERSION} — restructure existing projects for AI-native development"
    echo ""
    echo "Usage: reforge <command> [options]"
    echo ""
    echo "Commands:"
    echo "  analyze       Scan project, produce diagnostic report with grade"
    echo "  apply         Create backup branch, add AI context layer + missing configs"
    echo "  upgrade       Self-update (git pull)"
    echo "  uninstall     Remove reforge"
    echo "  version       Print version"
    echo "  help          Show this help"
    echo ""
    echo "Options:"
    echo "  --yes, -y     Skip confirmations"
    echo "  --dry-run     Show what would change without doing it"
    echo "  --verbose     Extra detail"
    echo ""
    echo "Examples:"
    echo "  cd my-messy-project"
    echo "  reforge analyze    # Diagnostic report + A-F grade"
    echo "  reforge apply      # Backup branch, add context layer + missing configs"
}

cmd_analyze() {
    source "$REFORGE_DIR/commands/analyze.sh"
    run_analyze "$(pwd)"
}

cmd_apply() {
    source "$REFORGE_DIR/commands/apply.sh"
    run_apply "$(pwd)"
}

cmd_upgrade() {
    echo -e "${BOLD}Upgrading reforge...${RESET}"
    if [ ! -d "$REFORGE_DIR/.git" ]; then
        echo -e "${RED}Error: reforge directory is not a git repo. Cannot upgrade.${RESET}"
        echo "If you installed manually, re-clone from the repository."
        exit 1
    fi
    cd "$REFORGE_DIR"
    local before after
    before="$(git rev-parse HEAD)"
    git pull --ff-only
    after="$(git rev-parse HEAD)"
    if [ "$before" = "$after" ]; then
        echo -e "${GREEN}Already up to date (v${VERSION}).${RESET}"
    else
        local new_version
        new_version="$(cat "$REFORGE_DIR/VERSION" 2>/dev/null || echo "unknown")"
        echo -e "${GREEN}Updated: v${VERSION} -> v${new_version}${RESET}"
    fi
}

cmd_uninstall() {
    echo -e "${BOLD}Uninstalling reforge...${RESET}"
    echo ""

    # Remove symlink
    local removed_link=false
    for link_path in /usr/local/bin/reforge "$HOME/.local/bin/reforge"; do
        if [ -L "$link_path" ]; then
            echo "  Removing symlink: $link_path"
            if [ "$link_path" = "/usr/local/bin/reforge" ]; then
                sudo rm -f "$link_path" 2>/dev/null || rm -f "$link_path"
            else
                rm -f "$link_path"
            fi
            removed_link=true
        fi
    done
    if [ "$removed_link" = false ]; then
        echo -e "  ${YELLOW}No symlink found.${RESET}"
    fi

    # Optionally remove reforge directory
    echo ""
    read -rp "  Remove reforge directory ($REFORGE_DIR)? [y/N]: " remove_dir
    if [[ "${remove_dir:-N}" =~ ^[Yy] ]]; then
        rm -rf "$REFORGE_DIR"
        echo -e "  ${GREEN}Removed $REFORGE_DIR${RESET}"
    else
        echo "  Kept $REFORGE_DIR"
    fi

    echo ""
    echo -e "${GREEN}Uninstall complete.${RESET}"
}

cmd_version() {
    echo "reforge v${VERSION}"
}

# ── Dispatch ────────────────────────────────────────────────────

case "${1:-help}" in
    analyze)    cmd_analyze ;;
    apply)      cmd_apply ;;
    upgrade)    cmd_upgrade ;;
    uninstall)  cmd_uninstall ;;
    version|-V|--version) cmd_version ;;
    help|-h|--help) usage ;;
    *)
        echo -e "${RED}Unknown command: $1${RESET}"
        echo ""
        usage
        exit 1
        ;;
esac
