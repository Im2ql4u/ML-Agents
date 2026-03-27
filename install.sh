#!/usr/bin/env bash
# =============================================================================
# ML-Agents installer
# =============================================================================
# Run from the root of the project repo you want to install the workflow into.
#
# Usage:
#   From a local clone of ML-Agents:
#     bash /path/to/ML-Agents/install.sh
#
#   Directly from GitHub (no clone needed):
#     bash <(curl -fsSL https://raw.githubusercontent.com/Im2ql4u/ML-Agents/main/install.sh)
#
# What it does:
#   - Installs Cursor and/or VS Code prompt/rules files into your project repo
#   - Installs log templates (SESSION_LOG.md etc.) if they don't already exist
#   - If a file would be overwritten, moves the existing file to
#     .agentic-backup/YYYY-MM-DD_HH-MM/ before installing the new one
#   - Never deletes anything
#   - Never overwrites live log files (SESSION_LOG, DECISIONS, JOURNAL, ARCHIVE)
#   - Adds .agentic-backup/ to .gitignore automatically
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve where this script lives (works whether run locally or via curl)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# If run via curl/pipe, SCRIPT_DIR will be /dev/fd or similar — detect this
# and require a local clone in that case
if [[ "$SCRIPT_DIR" == /dev/fd* ]] || [[ "$SCRIPT_DIR" == /proc/* ]]; then
  echo ""
  echo "ERROR: This script must be run from a local clone of ML-Agents."
  echo "       The curl pipe method requires --local flag workaround."
  echo ""
  echo "To use directly from GitHub, clone the repo first:"
  echo "  git clone https://github.com/Im2ql4u/ML-Agents.git"
  echo "  bash ML-Agents/install.sh"
  echo ""
  exit 1
fi

SOURCE_DIR="$SCRIPT_DIR"
TARGET_DIR="$(pwd)"
BACKUP_BASE="$TARGET_DIR/.agentic-backup"
TIMESTAMP="$(date +%Y-%m-%d_%H-%M)"
BACKUP_DIR="$BACKUP_BASE/$TIMESTAMP"

# ---------------------------------------------------------------------------
# Colour output
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

header()  { echo -e "\n${BOLD}${BLUE}=== $* ===${RESET}"; }
success() { echo -e "  ${GREEN}✓${RESET}  $*"; }
backup()  { echo -e "  ${YELLOW}⟳${RESET}  $*"; }
skip()    { echo -e "  ${CYAN}–${RESET}  $*"; }
warn()    { echo -e "  ${RED}!${RESET}  $*"; }

# ---------------------------------------------------------------------------
# Counters
# ---------------------------------------------------------------------------
COUNT_INSTALLED=0
COUNT_BACKED_UP=0
COUNT_SKIPPED=0

# ---------------------------------------------------------------------------
# Core install function
# ---------------------------------------------------------------------------
# install_file <source_relative_to_SOURCE_DIR> <dest_relative_to_TARGET_DIR> [no-overwrite]
#
# no-overwrite: if set, skip silently if dest already exists (for live logs)
# ---------------------------------------------------------------------------
install_file() {
  local src_rel="$1"
  local dst_rel="$2"
  local no_overwrite="${3:-}"

  local src="$SOURCE_DIR/$src_rel"
  local dst="$TARGET_DIR/$dst_rel"

  if [[ ! -f "$src" ]]; then
    warn "Source not found, skipping: $src_rel"
    return
  fi

  # Ensure destination directory exists
  mkdir -p "$(dirname "$dst")"

  if [[ -f "$dst" ]]; then
    if [[ "$no_overwrite" == "no-overwrite" ]]; then
      skip "Already exists, keeping yours: $dst_rel"
      ((COUNT_SKIPPED++)) || true
      return
    fi

    # Check if files are identical — no need to back up if so
    if cmp -s "$src" "$dst"; then
      skip "Already up to date:           $dst_rel"
      ((COUNT_SKIPPED++)) || true
      return
    fi

    # Back up the existing file, preserving its directory structure
    local backup_path="$BACKUP_DIR/$dst_rel"
    mkdir -p "$(dirname "$backup_path")"
    mv "$dst" "$backup_path"
    backup "Backed up to .agentic-backup/$TIMESTAMP/$dst_rel"
    ((COUNT_BACKED_UP++)) || true
  fi

  cp "$src" "$dst"
  success "Installed: $dst_rel"
  ((COUNT_INSTALLED++)) || true
}

# ---------------------------------------------------------------------------
# Gitignore helper
# ---------------------------------------------------------------------------
ensure_gitignored() {
  local pattern="$1"
  local gitignore="$TARGET_DIR/.gitignore"

  if [[ ! -f "$gitignore" ]]; then
    echo "$pattern" > "$gitignore"
    success "Created .gitignore with $pattern"
    return
  fi

  if ! grep -qF "$pattern" "$gitignore"; then
    echo "" >> "$gitignore"
    echo "# ML-Agents installer backups" >> "$gitignore"
    echo "$pattern" >> "$gitignore"
    success "Added $pattern to .gitignore"
  fi
}

# ---------------------------------------------------------------------------
# Welcome
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}ML-Agents installer${RESET}"
echo -e "Installing into: ${CYAN}$TARGET_DIR${RESET}"
echo -e "Source:          ${CYAN}$SOURCE_DIR${RESET}"
echo ""

# Confirm we are in a project repo (not the workflow repo itself)
if [[ "$TARGET_DIR" == "$SOURCE_DIR" ]]; then
  warn "You appear to be running this inside the ML-Agents repo itself."
  warn "Run this from the root of the project repo you want to install into."
  exit 1
fi

# ---------------------------------------------------------------------------
# Choose editor setup
# ---------------------------------------------------------------------------
header "Editor setup"
echo ""
echo "  Which editor setup do you want to install?"
echo "  1) Cursor only"
echo "  2) VS Code only"
echo "  3) Both Cursor and VS Code"
echo ""
read -r -p "  Enter 1, 2, or 3 [3]: " EDITOR_CHOICE
EDITOR_CHOICE="${EDITOR_CHOICE:-3}"

INSTALL_CURSOR=false
INSTALL_VSCODE=false

case "$EDITOR_CHOICE" in
  1) INSTALL_CURSOR=true ;;
  2) INSTALL_VSCODE=true ;;
  3) INSTALL_CURSOR=true; INSTALL_VSCODE=true ;;
  *) warn "Invalid choice. Defaulting to both."; INSTALL_CURSOR=true; INSTALL_VSCODE=true ;;
esac

# ---------------------------------------------------------------------------
# Install shared orchestration artifacts
# ---------------------------------------------------------------------------
header "Shared orchestration artifacts"
install_file "EXECUTION_KERNEL.md" ".agentic/EXECUTION_KERNEL.md"
install_file "core/orchestrator.md" ".agentic/core/orchestrator.md"
install_file "tools/INTERFACES.md" ".agentic/tools/INTERFACES.md"

# ---------------------------------------------------------------------------
# Install Cursor files
# ---------------------------------------------------------------------------
if [[ "$INSTALL_CURSOR" == true ]]; then
  header "Cursor — rules"
  install_file "cursor/rules/core.mdc" ".cursor/rules/core.mdc"

  header "Cursor — prompts"
  for prompt in session-open session-close brainstorm implement review diagnose explain; do
    install_file "cursor/prompts/${prompt}.md" ".cursor/prompts/${prompt}.md"
  done

  header "Cursor — expert prompts"
  for expert in architecture framing training data evaluation codebase prioritization operations; do
    install_file "cursor/prompts/experts/${expert}.md" ".cursor/prompts/experts/${expert}.md"
  done
fi

# ---------------------------------------------------------------------------
# Install VS Code files
# ---------------------------------------------------------------------------
if [[ "$INSTALL_VSCODE" == true ]]; then
  header "VS Code — always-active rules"
  install_file "vscode/copilot-instructions.md" ".github/copilot-instructions.md"

  header "VS Code — prompts"
  for prompt in session-open session-close brainstorm implement review diagnose explain; do
    install_file "vscode/prompts/${prompt}.prompt.md" ".github/prompts/${prompt}.prompt.md"
  done

  header "VS Code — expert prompts"
  for expert in architecture framing training data evaluation codebase prioritization operations; do
    install_file "vscode/prompts/experts/${expert}.prompt.md" ".github/prompts/experts/${expert}.prompt.md"
  done
fi

# ---------------------------------------------------------------------------
# Install log templates — never overwrite live logs
# ---------------------------------------------------------------------------
header "Log templates (skipped if already exist)"
for log in SESSION_LOG DECISIONS JOURNAL ARCHIVE; do
  install_file "templates/${log}.md" "${log}.md" "no-overwrite"
done

# ---------------------------------------------------------------------------
# Gitignore the backup directory
# ---------------------------------------------------------------------------
header "Gitignore"
ensure_gitignored ".agentic-backup/"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
header "Summary"
echo ""
echo -e "  ${GREEN}Installed:${RESET}  $COUNT_INSTALLED files"
echo -e "  ${YELLOW}Backed up:${RESET}  $COUNT_BACKED_UP files  →  .agentic-backup/$TIMESTAMP/"
echo -e "  ${CYAN}Skipped:${RESET}    $COUNT_SKIPPED files (already up to date or protected)"
echo ""

if [[ $COUNT_BACKED_UP -gt 0 ]]; then
  echo -e "  ${YELLOW}Note:${RESET} Your previous files are in .agentic-backup/$TIMESTAMP/"
  echo -e "        Review them with:"
  echo -e "        ${CYAN}diff .agentic-backup/$TIMESTAMP/<file> <installed_file>${RESET}"
  echo ""
fi

echo -e "  ${BOLD}Done.${RESET} Start your first session with ${CYAN}@session-open${RESET} in Composer."
echo ""
