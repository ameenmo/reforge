#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  Analyzer: Secrets — hardcoded API keys, passwords, URLs
#  Score: 0-30 points
# ══════════════════════════════════════════════════════════════════

run_secrets_analysis() {
    local project_dir="${1:-.}"

    SECRETS_SCORE=30
    SECRETS_FINDINGS=()
    SECRETS_COUNT=0

    # Secret patterns to grep for
    local patterns=(
        'sk-[a-zA-Z0-9]{20,}'           # OpenAI API keys
        'sk-ant-[a-zA-Z0-9-]{20,}'      # Anthropic API keys
        'ghp_[a-zA-Z0-9]{36}'           # GitHub PATs
        'gho_[a-zA-Z0-9]{36}'           # GitHub OAuth
        'github_pat_[a-zA-Z0-9_]{20,}'  # GitHub fine-grained PATs
        'AKIA[A-Z0-9]{16}'              # AWS access keys
        'Bearer ey[a-zA-Z0-9._-]+'      # JWT tokens
        'xoxb-[0-9]+-[a-zA-Z0-9]+'      # Slack bot tokens
        'xoxp-[0-9]+-[a-zA-Z0-9]+'      # Slack user tokens
    )

    # Simple string patterns (less likely false positives)
    local string_patterns=(
        "password\s*=\s*['\"][^'\"]{4,}"
        "api_key\s*=\s*['\"][^'\"]{8,}"
        "apiKey\s*=\s*['\"][^'\"]{8,}"
        "secret\s*=\s*['\"][^'\"]{8,}"
        "API_KEY\s*=\s*['\"][^'\"]{8,}"
        "SECRET_KEY\s*=\s*['\"][^'\"]{8,}"
    )

    # Search source files only
    local search_args=(
        --include='*.js' --include='*.ts' --include='*.jsx' --include='*.tsx'
        --include='*.py' --include='*.go' --include='*.rs' --include='*.rb'
        --include='*.java' --include='*.php' --include='*.sh' --include='*.yaml'
        --include='*.yml' --include='*.json' --include='*.toml' --include='*.cfg'
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.venv
        --exclude-dir=venv --exclude-dir=__pycache__ --exclude-dir=dist
        --exclude-dir=build --exclude-dir=.next --exclude-dir=.reforge
    )

    # Check each pattern
    for pattern in "${patterns[@]}"; do
        local matches
        matches=$(grep -rnE "$pattern" "$project_dir" "${search_args[@]}" 2>/dev/null | head -5 || true)
        if [ -n "$matches" ]; then
            while IFS= read -r match; do
                if [ -z "$match" ]; then continue; fi
                local file_line="${match%%:*}"
                # Get relative path
                local rel="${match#"$project_dir"/}"
                local location="${rel%%:*}"
                # Get just file:line
                local rest="${rel#*:}"
                local line_num="${rest%%:*}"
                SECRETS_FINDINGS+=("Possible secret: ${location}:${line_num}")
                SECRETS_COUNT=$((SECRETS_COUNT + 1))
            done <<< "$matches"
        fi
    done

    # Check string patterns
    for pattern in "${string_patterns[@]}"; do
        local matches
        matches=$(grep -rnE "$pattern" "$project_dir" "${search_args[@]}" \
            --exclude='*.lock' --exclude='*.example' --exclude='*.sample' \
            --exclude='*.template' --exclude='*.md' --exclude='.env.example' \
            2>/dev/null | head -3 || true)
        if [ -n "$matches" ]; then
            while IFS= read -r match; do
                if [ -z "$match" ]; then continue; fi
                local rel="${match#"$project_dir"/}"
                local location="${rel%%:*}"
                local rest="${rel#*:}"
                local line_num="${rest%%:*}"
                SECRETS_FINDINGS+=("Possible hardcoded credential: ${location}:${line_num}")
                SECRETS_COUNT=$((SECRETS_COUNT + 1))
            done <<< "$matches"
        fi
    done

    # Check if .env is git-tracked
    if [ -d "$project_dir/.git" ] && [ -f "$project_dir/.env" ]; then
        if git -C "$project_dir" ls-files --error-unmatch .env &>/dev/null; then
            SECRETS_FINDINGS+=(".env file is tracked by git!")
            SECRETS_COUNT=$((SECRETS_COUNT + 1))
            SECRETS_SCORE=$((SECRETS_SCORE - 10))
        fi
    fi

    # Deduct points based on findings
    local deduction=$((SECRETS_COUNT * 5))
    SECRETS_SCORE=$((SECRETS_SCORE - deduction))

    # Floor at 0
    if [ "$SECRETS_SCORE" -lt 0 ]; then SECRETS_SCORE=0; fi
}
