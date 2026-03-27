#!/usr/bin/env bash
set -euo pipefail

# Run from repo root or anywhere inside the repo.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

PAIRS=(
  "cursor/prompts/session-open.md:vscode/prompts/session-open.prompt.md"
  "cursor/prompts/session-close.md:vscode/prompts/session-close.prompt.md"
  "cursor/prompts/brainstorm.md:vscode/prompts/brainstorm.prompt.md"
  "cursor/prompts/implement.md:vscode/prompts/implement.prompt.md"
  "cursor/prompts/review.md:vscode/prompts/review.prompt.md"
  "cursor/prompts/diagnose.md:vscode/prompts/diagnose.prompt.md"
  "cursor/prompts/explain.md:vscode/prompts/explain.prompt.md"
  "cursor/prompts/experts/architecture.md:vscode/prompts/experts/architecture.prompt.md"
  "cursor/prompts/experts/framing.md:vscode/prompts/experts/framing.prompt.md"
  "cursor/prompts/experts/training.md:vscode/prompts/experts/training.prompt.md"
  "cursor/prompts/experts/data.md:vscode/prompts/experts/data.prompt.md"
  "cursor/prompts/experts/evaluation.md:vscode/prompts/experts/evaluation.prompt.md"
  "cursor/prompts/experts/codebase.md:vscode/prompts/experts/codebase.prompt.md"
  "cursor/prompts/experts/prioritization.md:vscode/prompts/experts/prioritization.prompt.md"
  "cursor/prompts/experts/operations.md:vscode/prompts/experts/operations.prompt.md"
  "cursor/rules/core.mdc:vscode/copilot-instructions.md"
)

mismatch_count=0
missing_count=0

normalize_file() {
  local src="$1"
  local dst="$2"

  # Normalize only structural wrapper differences between Cursor and VS Code files.
  # Keep substantive prompt content untouched for comparison.
  awk '
    BEGIN { in_yaml = 0; yaml_done = 0; prev_blank = 0; first_nonempty_seen = 0; frontmatter_allowed = 0; emitted_any = 0 }
    {
      line = $0
      gsub(/\r/, "", line)

      if (first_nonempty_seen == 0 && line !~ /^[[:space:]]*$/) {
        first_nonempty_seen = 1
        if (line ~ /^---[[:space:]]*$/) {
          frontmatter_allowed = 1
        }
      }

      # Drop YAML frontmatter blocks entirely.
      if (frontmatter_allowed == 1 && line ~ /^---[[:space:]]*$/) {
        if (yaml_done == 0) {
          in_yaml = !in_yaml
          if (in_yaml == 0) {
            yaml_done = 1
          }
          next
        }
      }
      if (in_yaml == 1) {
        next
      }
      sub(/[[:space:]]+$/, "", line)

      # Drop VS Code input placeholders that do not exist in Cursor files.
      if (line ~ /^\$\{input:[^}]+\}[[:space:]]*$/) {
        next
      }

      # Normalize known wrapper-level wording differences.
      gsub(/Run before closing VS Code\./, "Run before closing Cursor.", line)
      gsub(/^mode:[[:space:]]*agent[[:space:]]*$/, "", line)
      gsub(/^agent:[[:space:]]*agent[[:space:]]*$/, "", line)

      # Collapse multiple blank lines.
      if (line ~ /^[[:space:]]*$/) {
        if (emitted_any == 0) {
          next
        }
        if (prev_blank == 1) {
          next
        }
        prev_blank = 1
      } else {
        prev_blank = 0
        emitted_any = 1
      }

      print line
    }
  ' "$src" > "$dst"
}

echo "Checking Cursor <-> VS Code prompt parity..."

for pair in "${PAIRS[@]}"; do
  left="${pair%%:*}"
  right="${pair##*:}"

  if [[ ! -f "$left" || ! -f "$right" ]]; then
    echo "MISSING: $left or $right"
    ((missing_count++)) || true
    continue
  fi

  left_tmp="$(mktemp)"
  right_tmp="$(mktemp)"

  normalize_file "$left" "$left_tmp"
  normalize_file "$right" "$right_tmp"

  if ! diff -u "$left_tmp" "$right_tmp" > /dev/null; then
    echo "DRIFT: $left != $right"
    echo "  Show diff with: diff -u $left $right"
    ((mismatch_count++)) || true
  fi

  rm -f "$left_tmp" "$right_tmp"
done

if [[ $missing_count -gt 0 || $mismatch_count -gt 0 ]]; then
  echo ""
  echo "Parity check failed: $mismatch_count drift pair(s), $missing_count missing pair(s)."
  exit 1
fi

echo "Parity check passed: all prompt pairs are aligned."
