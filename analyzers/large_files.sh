#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  Analyzer: Large files — files >300 lines, function count estimates
#  Score: 0-20 points
# ══════════════════════════════════════════════════════════════════

run_large_files_analysis() {
    local project_dir="${1:-.}"

    LARGE_FILES_SCORE=20
    LARGE_FILES_FINDINGS=()
    LARGE_FILES_COUNT=0

    # Find source files, exclude common dirs
    local source_files
    source_files=$(find "$project_dir" -type f \
        \( -name '*.js' -o -name '*.ts' -o -name '*.jsx' -o -name '*.tsx' \
           -o -name '*.py' -o -name '*.go' -o -name '*.rs' -o -name '*.rb' \
           -o -name '*.java' -o -name '*.php' \) \
        -not -path '*/node_modules/*' \
        -not -path '*/.git/*' \
        -not -path '*/.venv/*' \
        -not -path '*/venv/*' \
        -not -path '*/__pycache__/*' \
        -not -path '*/dist/*' \
        -not -path '*/build/*' \
        -not -path '*/.next/*' \
        -not -path '*/.reforge/*' \
        2>/dev/null)

    if [ -z "$source_files" ]; then
        return
    fi

    # Check each file for line count
    while IFS= read -r file; do
        if [ -z "$file" ]; then continue; fi
        local lines
        lines=$(wc -l < "$file" 2>/dev/null)
        lines=${lines:-0}

        if [ "$lines" -gt 300 ]; then
            LARGE_FILES_COUNT=$((LARGE_FILES_COUNT + 1))

            # Estimate function/class count
            local func_count=0
            func_count=$(grep -cE '^\s*(function\s|def\s|class\s|const\s+\w+\s*=\s*\(|export\s+(default\s+)?function|async\s+function|pub\s+fn|fn\s+\w+|func\s+)' "$file" 2>/dev/null || echo 0)

            local rel_path="${file#"$project_dir"/}"
            LARGE_FILES_FINDINGS+=("${rel_path}: ${lines} lines (~${func_count} functions)")

            # Deduct points
            if [ "$lines" -gt 800 ]; then
                LARGE_FILES_SCORE=$((LARGE_FILES_SCORE - 5))
            elif [ "$lines" -gt 500 ]; then
                LARGE_FILES_SCORE=$((LARGE_FILES_SCORE - 3))
            else
                LARGE_FILES_SCORE=$((LARGE_FILES_SCORE - 2))
            fi
        fi
    done <<< "$source_files"

    # Floor at 0
    if [ "$LARGE_FILES_SCORE" -lt 0 ]; then LARGE_FILES_SCORE=0; fi
}
