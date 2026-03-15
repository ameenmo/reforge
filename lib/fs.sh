#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  Filesystem helpers
# ══════════════════════════════════════════════════════════════════

# ensure_dir — create directory if it doesn't exist
ensure_dir() {
    [ -d "$1" ] || mkdir -p "$1"
}

# safe_copy — copy file only if target doesn't exist
# Returns 0 if copied, 1 if skipped
safe_copy() {
    local src="$1"
    local dst="$2"

    if [ -f "$dst" ]; then
        return 1
    fi

    ensure_dir "$(dirname "$dst")"
    cp "$src" "$dst"
    return 0
}

# safe_copy_dir — recursively copy directory contents, skip existing files
safe_copy_dir() {
    local src_dir="$1"
    local dst_dir="$2"
    local copied=0
    local skipped=0

    ensure_dir "$dst_dir"

    while IFS= read -r -d '' src_file; do
        local rel_path="${src_file#"$src_dir"/}"
        local dst_file="$dst_dir/$rel_path"

        if [ -d "$src_file" ]; then
            ensure_dir "$dst_file"
        elif safe_copy "$src_file" "$dst_file"; then
            copied=$((copied + 1))
        else
            skipped=$((skipped + 1))
        fi
    done < <(find "$src_dir" -mindepth 1 -print0 2>/dev/null)

    echo "$copied:$skipped"
}

# merge_gitignore — merge source .gitignore entries into existing one
merge_gitignore() {
    local src="$1"
    local dst="$2"

    if [ ! -f "$dst" ]; then
        cp "$src" "$dst"
        return
    fi

    # Append entries from src that don't already exist in dst
    local added=0
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        if ! grep -qxF "$line" "$dst" 2>/dev/null; then
            echo "$line" >> "$dst"
            added=$((added + 1))
        fi
    done < "$src"

    echo "$added"
}
