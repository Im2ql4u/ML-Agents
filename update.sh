#!/usr/bin/env bash
# =============================================================================
# agentic-workflow updater
# =============================================================================
# Run from the root of the project repo that already has the workflow installed.
# Pulls latest changes from the workflow repo and re-runs the installer.
#
# Usage:
#   bash /path/to/agentic-workflow/update.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo ""
echo -e "${BOLD}agentic-workflow updater${RESET}"
echo ""

# Pull latest in the workflow repo
echo -e "Pulling latest from workflow repo..."
cd "$SCRIPT_DIR"
git pull --ff-only
cd - > /dev/null

echo -e "${GREEN}✓${RESET}  Workflow repo updated"
echo ""

# Re-run the installer from the project directory
bash "$SCRIPT_DIR/install.sh"
