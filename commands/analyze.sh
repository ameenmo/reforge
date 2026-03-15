#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  Command: analyze — scan project, produce diagnostic report + grade
# ══════════════════════════════════════════════════════════════════

CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REFORGE_DIR="$(dirname "$CMD_DIR")"

# shellcheck source=../lib/colors.sh
source "$REFORGE_DIR/lib/colors.sh"
# shellcheck source=../lib/detect.sh
source "$REFORGE_DIR/lib/detect.sh"
# shellcheck source=../analyzers/stack.sh
source "$REFORGE_DIR/analyzers/stack.sh"
# shellcheck source=../analyzers/structure.sh
source "$REFORGE_DIR/analyzers/structure.sh"
# shellcheck source=../analyzers/large_files.sh
source "$REFORGE_DIR/analyzers/large_files.sh"
# shellcheck source=../analyzers/missing_essentials.sh
source "$REFORGE_DIR/analyzers/missing_essentials.sh"
# shellcheck source=../analyzers/secrets.sh
source "$REFORGE_DIR/analyzers/secrets.sh"
# shellcheck source=../analyzers/scoring.sh
source "$REFORGE_DIR/analyzers/scoring.sh"

run_analyze() {
    local project_dir="${1:-.}"
    local verbose="${FLAG_VERBOSE:-false}"

    echo ""
    echo -e "${BOLD}${CYAN}  Analyzing project...${RESET}"
    echo ""

    # ── Run detection ──
    run_stack_analysis "$project_dir"

    # ── Run analyzers ──
    run_structure_analysis "$project_dir"
    run_large_files_analysis "$project_dir"
    run_missing_essentials_analysis "$project_dir"
    run_secrets_analysis "$project_dir"

    # ── Calculate grade ──
    calculate_grade

    # ── Save state ──
    save_state "$project_dir"

    # Save scores to state
    cat >> "$project_dir/.reforge/state.sh" << EOF
STRUCTURE_SCORE=${STRUCTURE_SCORE}
LARGE_FILES_SCORE=${LARGE_FILES_SCORE}
ESSENTIALS_SCORE=${ESSENTIALS_SCORE}
SECRETS_SCORE=${SECRETS_SCORE}
TOTAL_SCORE=${TOTAL_SCORE}
GRADE="${GRADE}"
EOF

    # ── Print report ──
    print_report "$project_dir"

    # ── Save report to file ──
    save_report "$project_dir"
}

print_report() {
    local project_dir="${1:-.}"
    local project_basename
    project_basename=$(basename "$(cd "$project_dir" && pwd)")

    echo -e "${BOLD}"
    echo "  ══════════════════════════════════════"
    echo "    REFORGE ANALYSIS"
    echo "  ══════════════════════════════════════"
    echo -e "${RESET}"

    echo -e "  Project:  ${BOLD}${PROJECT_NAME:-$project_basename}${RESET}"
    echo -e "  Stack:    ${STACK_LABEL:-unknown}"
    if [ -n "$STACK_PKGMGR" ]; then echo -e "  Pkg Mgr:  ${STACK_PKGMGR}"; fi
    echo -e "  Type:     ${PROJECT_TYPE} (auto-detected)"
    echo -e "  Grade:    ${BOLD}${GRADE_COLOR}${GRADE} (${TOTAL_SCORE}/100)${RESET}"

    echo -e "${DIM}  ──────────────────────────────────────${RESET}"

    # Structure section
    echo -e "\n  ${BOLD}STRUCTURE${RESET}                      ${DIM}[${STRUCTURE_SCORE}/25]${RESET}"
    if [ ${#STRUCTURE_FINDINGS[@]} -eq 0 ]; then
        echo -e "  ${GREEN}  No issues found${RESET}"
    else
        for finding in "${STRUCTURE_FINDINGS[@]}"; do
            echo -e "  ${YELLOW}  ${finding}${RESET}"
        done
    fi
    echo "    Total source files: ${STRUCTURE_TOTAL_FILES:-0}"

    # Large files section
    echo -e "\n  ${BOLD}LARGE FILES${RESET}                    ${DIM}[${LARGE_FILES_SCORE}/20]${RESET}"
    if [ ${#LARGE_FILES_FINDINGS[@]} -eq 0 ]; then
        echo -e "  ${GREEN}  No oversized files found${RESET}"
    else
        for finding in "${LARGE_FILES_FINDINGS[@]}"; do
            echo -e "  ${YELLOW}  ${finding}${RESET}"
        done
    fi

    # Essentials section
    echo -e "\n  ${BOLD}ESSENTIALS${RESET}                     ${DIM}[${ESSENTIALS_SCORE}/25]${RESET}"
    for item in "${ESSENTIALS_PRESENT[@]}"; do
        echo -e "    ${GREEN}[x]${RESET} ${item}"
    done
    for item in "${ESSENTIALS_MISSING[@]}"; do
        echo -e "    ${RED}[ ]${RESET} ${item}"
    done

    # Secrets section
    echo -e "\n  ${BOLD}SECRETS${RESET}                        ${DIM}[${SECRETS_SCORE}/30]${RESET}"
    if [ ${#SECRETS_FINDINGS[@]} -eq 0 ]; then
        echo -e "  ${GREEN}  No secrets detected${RESET}"
    else
        for finding in "${SECRETS_FINDINGS[@]}"; do
            echo -e "  ${RED}  [!] ${finding}${RESET}"
        done
    fi

    echo ""
    echo -e "${BOLD}"
    echo "  ══════════════════════════════════════"
    if [ "$TOTAL_SCORE" -lt 90 ]; then
        echo -e "  Run: ${CYAN}reforge apply${RESET}${BOLD}"
    else
        echo -e "  ${GREEN}Project is in good shape!${RESET}${BOLD}"
    fi
    echo "  ══════════════════════════════════════"
    echo -e "${RESET}"
}

save_report() {
    local project_dir="${1:-.}"
    local report_file="$project_dir/.reforge/report.md"
    local project_basename
    project_basename=$(basename "$(cd "$project_dir" && pwd)")

    mkdir -p "$project_dir/.reforge"

    cat > "$report_file" << EOF
# Reforge Analysis Report

**Project:** ${PROJECT_NAME:-$project_basename}
**Stack:** ${STACK_LABEL:-unknown}
**Package Manager:** ${STACK_PKGMGR:-none}
**Type:** ${PROJECT_TYPE} (auto-detected)
**Grade:** ${GRADE} (${TOTAL_SCORE}/100)
**Date:** $(date -u '+%Y-%m-%d %H:%M:%S UTC')

---

## Structure [${STRUCTURE_SCORE}/25]

$(if [ ${#STRUCTURE_FINDINGS[@]} -eq 0 ]; then echo "No issues found."; else for f in "${STRUCTURE_FINDINGS[@]}"; do echo "- $f"; done; fi)

- Total source files: ${STRUCTURE_TOTAL_FILES:-0}
- Root-level files: ${STRUCTURE_ROOT_FILES:-0}
- Flatness: ${STRUCTURE_FLATNESS:-0}%

## Large Files [${LARGE_FILES_SCORE}/20]

$(if [ ${#LARGE_FILES_FINDINGS[@]} -eq 0 ]; then echo "No oversized files found."; else for f in "${LARGE_FILES_FINDINGS[@]}"; do echo "- $f"; done; fi)

## Essentials [${ESSENTIALS_SCORE}/25]

$(for item in "${ESSENTIALS_PRESENT[@]}"; do echo "- [x] $item"; done)
$(for item in "${ESSENTIALS_MISSING[@]}"; do echo "- [ ] $item"; done)

## Secrets [${SECRETS_SCORE}/30]

$(if [ ${#SECRETS_FINDINGS[@]} -eq 0 ]; then echo "No secrets detected."; else for f in "${SECRETS_FINDINGS[@]}"; do echo "- ⚠️ $f"; done; fi)

---

*Generated by reforge v$(cat "$REFORGE_DIR/VERSION" 2>/dev/null || echo "unknown")*
EOF

    echo -e "  ${DIM}Report saved: .reforge/report.md${RESET}"
}
