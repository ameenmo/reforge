#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  Scoring: Aggregate all analyzer scores into A-F grade
#
#  Structure:  0-25
#  Large Files: 0-20
#  Essentials:  0-25
#  Secrets:     0-30
#  Total:       0-100
#
#  Grade: A(90+), B(75-89), C(60-74), D(40-59), F(<40)
# ══════════════════════════════════════════════════════════════════

calculate_grade() {
    TOTAL_SCORE=$((STRUCTURE_SCORE + LARGE_FILES_SCORE + ESSENTIALS_SCORE + SECRETS_SCORE))

    if [ "$TOTAL_SCORE" -ge 90 ]; then
        GRADE="A"
        GRADE_COLOR="${GREEN}"
    elif [ "$TOTAL_SCORE" -ge 75 ]; then
        GRADE="B"
        GRADE_COLOR="${GREEN}"
    elif [ "$TOTAL_SCORE" -ge 60 ]; then
        GRADE="C"
        GRADE_COLOR="${YELLOW}"
    elif [ "$TOTAL_SCORE" -ge 40 ]; then
        GRADE="D"
        GRADE_COLOR="${YELLOW}"
    else
        GRADE="F"
        GRADE_COLOR="${RED}"
    fi
}
