#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  Command: install-skills — install global AI skills
# ══════════════════════════════════════════════════════════════════

CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REFORGE_DIR="$(dirname "$CMD_DIR")"

# shellcheck source=../lib/colors.sh
source "$REFORGE_DIR/lib/colors.sh"
# shellcheck source=../lib/prompts.sh
source "$REFORGE_DIR/lib/prompts.sh"
# shellcheck source=../lib/fs.sh
source "$REFORGE_DIR/lib/fs.sh"

run_install_skills_cmd() {
    echo ""
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════╗"
    echo "  ║   REFORGE INSTALL-SKILLS                 ║"
    echo "  ╚══════════════════════════════════════════╝"
    echo -e "${RESET}"

    source "$REFORGE_DIR/appliers/install_skills.sh"
    run_install_skills

    echo ""
    if [ ${#SKILLS_INSTALLED[@]} -gt 0 ]; then
        echo -e "  ${BOLD}Installed:${RESET}"
        for skill in "${SKILLS_INSTALLED[@]}"; do
            echo "    + ${skill}"
        done
    else
        info "No new skills installed."
    fi
    echo ""
}
