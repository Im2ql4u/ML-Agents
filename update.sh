#!/usr/bin/env bash
# =============================================================================
# ML-Agents updater
# =============================================================================
# Run from the root of the project repo that already has the workflow installed.
# Pulls latest changes from the workflow repo and re-runs the installer.
#
# Usage:
#   bash /path/to/ML-Agents/update.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CANONICAL_REPO_URL="https://github.com/Im2ql4u/ML-Agents.git"

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RESET='\033[0m'

echo ""
echo -e "${BOLD}ML-Agents updater${RESET}"
echo ""

# Pull latest in the workflow repo
echo -e "Pulling latest from workflow repo..."
cd "$SCRIPT_DIR"

# Migrate old repo naming if needed.
CURRENT_ORIGIN_URL="$(git remote get-url origin 2>/dev/null || true)"
if [[ "$CURRENT_ORIGIN_URL" == *"ML_Agents"* ]]; then
  echo -e "${YELLOW}!${RESET}  Detected old origin URL: $CURRENT_ORIGIN_URL"
  git remote set-url origin "$CANONICAL_REPO_URL"
  echo -e "${GREEN}✓${RESET}  Updated origin to: $CANONICAL_REPO_URL"
fi

git pull --ff-only
cd - > /dev/null

echo -e "${GREEN}✓${RESET}  Workflow repo updated"
echo ""

# Re-run the installer from the project directory
bash "$SCRIPT_DIR/install.sh"
