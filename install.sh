#!/usr/bin/env bash
set -euo pipefail

# ══════════════════════════════════════════════════════════════════
#  reforge installer
#
#  Usage:
#    Flow A (git clone):
#      git clone https://github.com/ameenmo/reforge ~/.reforge
#      ~/.reforge/install.sh
#
#    Flow B (curl one-liner):
#      curl -fsSL https://raw.githubusercontent.com/ameenmo/reforge/main/install.sh | bash
# ══════════════════════════════════════════════════════════════════

# Colors
if [ -t 1 ]; then
    BOLD='\033[1m' GREEN='\033[0;32m' YELLOW='\033[0;33m'
    RED='\033[0;31m' RESET='\033[0m'
else
    BOLD='' GREEN='' YELLOW='' RED='' RESET=''
fi

INSTALL_DIR="${REFORGE_INSTALL_DIR:-$HOME/.reforge}"

echo -e "${BOLD}reforge installer${RESET}"
echo ""

# ── Determine source ────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null)" && pwd 2>/dev/null || echo "")"

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/reforge.sh" ]; then
    # Flow A: running from a cloned repo
    INSTALL_DIR="$SCRIPT_DIR"
    echo "  Detected cloned repo at: $INSTALL_DIR"
else
    # Flow B: piped from curl — clone the repo
    if [ -d "$INSTALL_DIR/.git" ]; then
        echo "  Existing installation found at $INSTALL_DIR — updating..."
        cd "$INSTALL_DIR" && git pull --ff-only
    else
        echo "  Cloning reforge to $INSTALL_DIR..."
        if ! command -v git &>/dev/null; then
            echo -e "${RED}Error: git is required. Install git and try again.${RESET}"
            exit 1
        fi
        git clone https://github.com/ameenmo/reforge "$INSTALL_DIR"
    fi
fi

# ── Verify installation ────────────────────────────────────────

if [ ! -f "$INSTALL_DIR/reforge.sh" ]; then
    echo -e "${RED}Error: reforge.sh not found in $INSTALL_DIR${RESET}"
    exit 1
fi

chmod +x "$INSTALL_DIR/reforge.sh"

# ── Create symlink ──────────────────────────────────────────────

LINK_CREATED=false

# Try /usr/local/bin first
if [ -d /usr/local/bin ]; then
    if ln -sf "$INSTALL_DIR/reforge.sh" /usr/local/bin/reforge 2>/dev/null; then
        echo -e "  ${GREEN}Linked: /usr/local/bin/reforge${RESET}"
        LINK_CREATED=true
    elif sudo ln -sf "$INSTALL_DIR/reforge.sh" /usr/local/bin/reforge 2>/dev/null; then
        echo -e "  ${GREEN}Linked: /usr/local/bin/reforge (via sudo)${RESET}"
        LINK_CREATED=true
    fi
fi

# Fall back to ~/.local/bin
if [ "$LINK_CREATED" = false ]; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$INSTALL_DIR/reforge.sh" "$HOME/.local/bin/reforge"
    echo -e "  ${GREEN}Linked: ~/.local/bin/reforge${RESET}"

    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo ""
        echo -e "  ${YELLOW}Note: ~/.local/bin is not in your PATH.${RESET}"
        echo "  Add this to your shell profile (~/.bashrc or ~/.zshrc):"
        echo ""
        echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
    fi
fi

# ── Done ────────────────────────────────────────────────────────

VERSION="$(cat "$INSTALL_DIR/VERSION" 2>/dev/null || echo "unknown")"

echo ""
echo -e "${BOLD}${GREEN}reforge v${VERSION} installed successfully!${RESET}"
echo ""
echo "  Get started:"
echo "    cd your-messy-project"
echo "    reforge analyze    # Diagnostic report + grade"
echo "    reforge apply      # Add AI context layer + configs"
echo ""
echo "  Other commands:"
echo "    reforge help        Show all commands"
echo "    reforge upgrade     Update to latest version"
echo "    reforge uninstall   Remove reforge"
echo ""
