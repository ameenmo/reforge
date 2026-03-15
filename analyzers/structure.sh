#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  Analyzer: Project structure — directory depth, flatness, missing dirs
#  Score: 0-25 points
# ══════════════════════════════════════════════════════════════════

run_structure_analysis() {
    local project_dir="${1:-.}"

    STRUCTURE_SCORE=25
    STRUCTURE_FINDINGS=()

    # Exclude patterns for find
    local exclude_pattern="-not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/.venv/*' -not -path '*/venv/*' -not -path '*/__pycache__/*' -not -path '*/dist/*' -not -path '*/build/*' -not -path '*/.next/*' -not -path '*/.reforge/*'"

    # Count total source files
    local total_files
    total_files=$(eval "find '$project_dir' -type f \( -name '*.js' -o -name '*.ts' -o -name '*.jsx' -o -name '*.tsx' -o -name '*.py' -o -name '*.go' -o -name '*.rs' -o -name '*.rb' -o -name '*.java' -o -name '*.php' -o -name '*.sh' \) $exclude_pattern" 2>/dev/null | wc -l)

    # Count root-level source files
    local root_files
    root_files=$(find "$project_dir" -maxdepth 1 -type f \( -name '*.js' -o -name '*.ts' -o -name '*.jsx' -o -name '*.tsx' -o -name '*.py' -o -name '*.go' -o -name '*.rs' -o -name '*.rb' -o -name '*.java' -o -name '*.php' -o -name '*.sh' \) 2>/dev/null | wc -l)

    STRUCTURE_TOTAL_FILES=$total_files
    STRUCTURE_ROOT_FILES=$root_files

    # Calculate flatness ratio
    if [ "$total_files" -gt 0 ]; then
        STRUCTURE_FLATNESS=$((root_files * 100 / total_files))
    else
        STRUCTURE_FLATNESS=0
    fi

    # Deduct for high flatness
    if [ "$STRUCTURE_FLATNESS" -gt 80 ] && [ "$total_files" -gt 5 ]; then
        STRUCTURE_SCORE=$((STRUCTURE_SCORE - 10))
        STRUCTURE_FINDINGS+=("${STRUCTURE_FLATNESS}% of source files in root directory (FLAT)")
    elif [ "$STRUCTURE_FLATNESS" -gt 50 ] && [ "$total_files" -gt 5 ]; then
        STRUCTURE_SCORE=$((STRUCTURE_SCORE - 5))
        STRUCTURE_FINDINGS+=("${STRUCTURE_FLATNESS}% of source files in root directory")
    fi

    # Check for standard directories
    local has_src=false has_test=false has_lib=false
    if [ -d "$project_dir/src" ]; then has_src=true; fi
    if [ -d "$project_dir/lib" ]; then has_lib=true; fi
    for test_dir in test tests __tests__ spec; do
        if [ -d "$project_dir/$test_dir" ]; then has_test=true; fi
    done

    if [ "$has_src" = false ] && [ "$has_lib" = false ] && [ "$total_files" -gt 5 ]; then
        STRUCTURE_SCORE=$((STRUCTURE_SCORE - 5))
        STRUCTURE_FINDINGS+=("No src/ or lib/ directory")
    fi

    if [ "$has_test" = false ]; then
        STRUCTURE_SCORE=$((STRUCTURE_SCORE - 5))
        STRUCTURE_FINDINGS+=("No test directory")
    fi

    # Check max depth
    local max_depth
    max_depth=$(eval "find '$project_dir' -type f $exclude_pattern" 2>/dev/null | awk -F/ '{print NF}' | sort -rn | head -1)
    max_depth=${max_depth:-0}
    STRUCTURE_MAX_DEPTH=$max_depth

    # Very shallow projects with many files
    if [ "$max_depth" -le 2 ] && [ "$total_files" -gt 10 ]; then
        STRUCTURE_SCORE=$((STRUCTURE_SCORE - 5))
        STRUCTURE_FINDINGS+=("Very shallow directory structure (max depth: $max_depth)")
    fi

    # Floor at 0
    if [ "$STRUCTURE_SCORE" -lt 0 ]; then STRUCTURE_SCORE=0; fi
}
