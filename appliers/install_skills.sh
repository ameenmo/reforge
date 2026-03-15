#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  Applier: Install global skills to ~/.claude/skills/
# ══════════════════════════════════════════════════════════════════

APPLIER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REFORGE_DIR="$(dirname "$APPLIER_DIR")"

# shellcheck source=../lib/colors.sh
source "$REFORGE_DIR/lib/colors.sh"
# shellcheck source=../lib/prompts.sh
source "$REFORGE_DIR/lib/prompts.sh"
# shellcheck source=../lib/fs.sh
source "$REFORGE_DIR/lib/fs.sh"

SKILLS_INSTALLED=()

run_install_skills() {
    local global_dir="$HOME/.claude/skills"

    # ── Define available skills ──
    local skill_names=("autoresearch" "self-improve" "context-hub" "visualize" "gstack")
    local skill_descs=(
        "Autonomous modify-test-evaluate loop for metric optimization"
        "Observe-inspect-amend-evaluate loop for skill evolution"
        "chub CLI wrapper for versioned documentation from context.dev"
        "SVG/HTML diagram generation for architecture and data flow"
        "8 specialist workflow skills: plan-ceo-review, plan-eng-review, review, ship, qa, browse, retro, setup-browser-cookies"
    )

    # ── Filter out already-installed skills ──
    local avail_names=() avail_descs=()
    local already=()
    for i in "${!skill_names[@]}"; do
        local name="${skill_names[$i]}"
        if [ -d "$global_dir/$name" ]; then
            already+=("$name")
        else
            avail_names+=("$name")
            avail_descs+=("${skill_descs[$i]}")
        fi
    done

    # Report already-installed
    for name in "${already[@]}"; do
        info "$name already installed, skipping"
    done

    # If nothing to install, done
    if [ ${#avail_names[@]} -eq 0 ]; then
        success "All global skills already installed"
        return 0
    fi

    # ── Present checklist (respects FLAG_YES) ──
    local checklist_args=()
    for i in "${!avail_names[@]}"; do
        checklist_args+=("${avail_names[$i]}" "${avail_descs[$i]}")
    done
    checklist "Select global skills to install:" "${checklist_args[@]}"

    if [ ${#CHECKLIST_RESULT[@]} -eq 0 ]; then
        info "No skills selected, skipping"
        return 0
    fi

    # ── Install selected skills ──
    mkdir -p "$global_dir"

    for skill in "${CHECKLIST_RESULT[@]}"; do
        if [ "$skill" = "gstack" ]; then
            _install_gstack "$global_dir"
        else
            _install_bundled_skill "$skill" "$global_dir"
        fi
    done
}

_install_bundled_skill() {
    local name="$1"
    local global_dir="$2"
    local src="$REFORGE_DIR/templates/skills/$name/SKILL.md"
    local dest_dir="$global_dir/$name"
    local dest="$dest_dir/SKILL.md"

    if [ ! -f "$src" ]; then
        warn "Source not found for $name, skipping"
        return
    fi

    if [ -f "$dest" ]; then
        info "$name already exists, skipping"
        return
    fi

    mkdir -p "$dest_dir"
    cp -f "$src" "$dest"
    success "Installed: $name"
    SKILLS_INSTALLED+=("$name")
}

_install_gstack() {
    local global_dir="$1"
    local gstack_dir="$global_dir/gstack"

    if [ -d "$gstack_dir" ]; then
        info "gstack already installed"
        return
    fi

    if ! command -v git &>/dev/null; then
        warn "git not found — install gstack manually:"
        echo "      git clone https://github.com/garrytan/gstack $gstack_dir"
        return
    fi

    info "Cloning gstack from GitHub..."
    if git clone https://github.com/garrytan/gstack "$gstack_dir" 2>/dev/null; then
        success "Installed: gstack"
        SKILLS_INSTALLED+=("gstack")

        # Run setup if available
        if [ -f "$gstack_dir/setup" ]; then
            info "Running gstack setup..."
            (
                cd "$gstack_dir" || return
                chmod +x setup
                if command -v bun &>/dev/null; then
                    bun install 2>/dev/null || true
                elif command -v npm &>/dev/null; then
                    npm install 2>/dev/null || true
                fi
                ./setup 2>/dev/null || true
            ) || warn "gstack setup had issues — you may need to run it manually"
        fi
    else
        warn "Failed to clone gstack — install manually:"
        echo "      git clone https://github.com/garrytan/gstack $gstack_dir"
    fi
}
