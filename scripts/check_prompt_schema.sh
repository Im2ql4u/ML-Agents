#!/usr/bin/env bash
set -euo pipefail

# Run from repo root or anywhere inside the repo.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

fail_count=0

check_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if [[ ! -f "$file" ]]; then
    echo "MISSING FILE: $file"
    ((fail_count++)) || true
    return
  fi

  if ! grep -Fq "$pattern" "$file"; then
    echo "SCHEMA FAIL: $file"
    echo "  Missing: $label"
    ((fail_count++)) || true
  fi
}

echo "Checking prompt schema integrity..."

# Implement prompt must keep the core result sections.
for file in \
  "cursor/prompts/implement.md" \
  "vscode/prompts/implement.prompt.md"
do
  check_contains "$file" "### Plan contract status" "plan contract status section"
  check_contains "$file" "### Deviations from plan" "deviations section"
  check_contains "$file" "### Plan state update" "plan state update section"
  check_contains "$file" "## Report" "results report section"
  check_contains "$file" "## Current State" "plan current state requirement"
  check_contains "$file" "### Sanity check first" "sanity check protocol"
done

# Diagnose prompt must include all 5 hierarchy layers and hypothesis ledger.
for file in \
  "cursor/prompts/diagnose.md" \
  "vscode/prompts/diagnose.prompt.md"
do
  check_contains "$file" "Maintain a compact hypothesis ledger" "hypothesis ledger"
  check_contains "$file" "### Layer 1 — Data" "layer 1"
  check_contains "$file" "### Layer 2 — Implementation" "layer 2"
  check_contains "$file" "### Layer 3 — Architecture" "layer 3"
  check_contains "$file" "### Layer 4 — Training setup" "layer 4"
  check_contains "$file" "### Layer 5 — Hyperparameters" "layer 5"
done

# Session close must include metrics and negative/comparison journaling guidance.
for file in \
  "cursor/prompts/session-close.md" \
  "vscode/prompts/session-close.prompt.md"
do
  check_contains "$file" "### Session metrics" "session metrics section"
  check_contains "$file" "NEGATIVE format" "negative-result journaling instruction"
  check_contains "$file" "comparison entry" "comparison entry instruction"
done

# Plan prompts must include required plan scaffold.
for file in \
  "cursor/prompts/plan.md" \
  "vscode/prompts/plan.prompt.md"
do
  check_contains "$file" "Plan path convention" "plan path convention"
  check_contains "$file" "## Foundation checks (must pass before new code)" "foundation checks section"
  check_contains "$file" "## Current State" "current state section"
  check_contains "$file" "Status: draft | confirmed | in-progress | completed | abandoned" "status enum"
  check_contains "$file" "Do not execute implementation tasks in this mode" "plan-mode execution lock"
  check_contains "$file" "Do not run destructive or cleanup commands in this mode" "plan-mode destructive command ban"
done

# Cleanup prompts must enforce non-destructive safety contract.
for file in \
  "cursor/prompts/cleanup.md" \
  "vscode/prompts/cleanup.prompt.md"
do
  check_contains "$file" "## Safety Contract (non-destructive, always on)" "cleanup safety contract"
  check_contains "$file" "Never run destructive blanket commands" "destructive command ban"
  check_contains "$file" "Required approval format" "path-level approval template"
done

# Always-on core rules must include intent lock and dirty-worktree safety.
for file in \
  "cursor/rules/core.mdc" \
  "vscode/copilot-instructions.md"
do
  check_contains "$file" "Plan-generation requests: route to plan behavior only (no code changes)" "plan routing rule"
  check_contains "$file" "Intent lock:" "intent lock section"
  check_contains "$file" "Dirty-worktree threshold:" "dirty-worktree safety section"
  check_contains "$file" "Safety gate before destructive or cleanup actions" "safety gate"
done

# Kernel/orchestrator contracts must include safety and mode-lock fields.
check_contains "EXECUTION_KERNEL.md" "Gate E: Intent Lock" "execution intent gate"
check_contains "EXECUTION_KERNEL.md" "Gate F: Workspace Preservation" "workspace preservation gate"
check_contains "core/orchestrator.md" "Plan-generation -> plan (no code changes)" "orchestrator plan-mode routing"
check_contains "core/orchestrator.md" "Mode-lock rule:" "orchestrator mode lock"
check_contains "core/orchestrator.md" "requested_mode" "orchestrator state field"

if [[ $fail_count -gt 0 ]]; then
  echo ""
  echo "Schema check failed: $fail_count issue(s) found."
  exit 1
fi

echo "Schema check passed: required sections are present."
