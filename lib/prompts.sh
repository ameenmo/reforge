#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  Interactive prompts — confirm, select, input
#  Respects global FLAG_YES to skip confirmations.
# ══════════════════════════════════════════════════════════════════

# confirm "Do something?" [default_yes]
# Returns 0 if yes, 1 if no
confirm() {
    local prompt="$1"
    local default="${2:-Y}"

    if [ "${FLAG_YES:-false}" = true ]; then
        return 0
    fi

    local hint
    if [[ "$default" =~ ^[Yy] ]]; then
        hint="[Y/n]"
    else
        hint="[y/N]"
    fi

    read -rp "  ${prompt} ${hint}: " answer
    answer="${answer:-$default}"
    [[ "$answer" =~ ^[Yy] ]]
}

# select_option "Prompt" option1 option2 option3 ...
# Sets SELECT_RESULT to the chosen option
select_option() {
    local prompt="$1"
    shift
    local options=("$@")
    local i

    echo ""
    echo -e "  ${prompt}"
    for i in "${!options[@]}"; do
        echo "    $((i + 1))) ${options[$i]}"
    done
    echo ""

    local choice
    read -rp "  Select [1-${#options[@]}] (default: 1): " choice
    choice="${choice:-1}"

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
        SELECT_RESULT="${options[$((choice - 1))]}"
    else
        SELECT_RESULT="${options[0]}"
    fi
}

# input_with_default "Prompt" "default_value"
# Sets INPUT_RESULT
input_with_default() {
    local prompt="$1"
    local default="$2"

    read -rp "  ${prompt} (default: ${default}): " INPUT_RESULT
    INPUT_RESULT="${INPUT_RESULT:-$default}"
}
