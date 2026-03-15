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

# checklist "Prompt" name1 desc1 name2 desc2 ...
# Sets CHECKLIST_RESULT as an array of selected names
# Respects FLAG_YES (selects all when true)
checklist() {
    local prompt="$1"
    shift

    # Parse name/description pairs
    local names=() descs=()
    while [ $# -ge 2 ]; do
        names+=("$1"); descs+=("$2"); shift 2
    done

    if [ "${FLAG_YES:-false}" = true ]; then
        CHECKLIST_RESULT=("${names[@]}")
        return
    fi

    echo ""
    echo -e "  ${prompt}"
    echo ""
    for i in "${!names[@]}"; do
        echo "    $((i + 1))) ${names[$i]} — ${descs[$i]}"
    done
    echo ""
    echo "    A) All"
    echo "    S) Skip all"
    echo ""

    local answer
    read -rp "  Select (e.g. 1,3,5 or A or S) [default: A]: " answer
    answer="${answer:-A}"

    CHECKLIST_RESULT=()
    if [[ "$answer" =~ ^[Aa] ]]; then
        CHECKLIST_RESULT=("${names[@]}")
    elif [[ "$answer" =~ ^[Ss] ]]; then
        CHECKLIST_RESULT=()
    else
        IFS=',' read -ra selections <<< "$answer"
        for sel in "${selections[@]}"; do
            sel="$(echo "$sel" | tr -d ' ')"
            if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -le "${#names[@]}" ]; then
                CHECKLIST_RESULT+=("${names[$((sel - 1))]}")
            fi
        done
    fi
}
