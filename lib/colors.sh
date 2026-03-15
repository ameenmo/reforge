#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  Color constants + print helpers
# ══════════════════════════════════════════════════════════════════

if [ -t 1 ]; then
    BOLD='\033[1m'
    DIM='\033[2m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    CYAN='\033[0;36m'
    RED='\033[0;31m'
    MAGENTA='\033[0;35m'
    WHITE='\033[1;37m'
    RESET='\033[0m'
else
    BOLD='' DIM='' GREEN='' YELLOW='' CYAN='' RED='' MAGENTA='' WHITE='' RESET=''
fi

info()    { echo -e "${CYAN}  [i]${RESET} $*"; }
warn()    { echo -e "${YELLOW}  [!]${RESET} $*"; }
error()   { echo -e "${RED}  [✗]${RESET} $*"; }
success() { echo -e "${GREEN}  [✓]${RESET} $*"; }
header()  { echo -e "\n${BOLD}${WHITE}  $*${RESET}"; }
