# Execution Kernel Policy

You must follow this execution contract for all direct requests and prompt-invoked workflows.

## Principles

- Atomicity: one semantic concern per change unit.
- Observability: every change unit must produce evidence.
- Reversibility: changes should be easy to undo without broad rollback.
- Clarity: diffs must communicate intent.
- Integrity: claims must be tied to explicit checks.

## Hard Constraints

- Atomic unit target: one concern, typically about 5-25 changed lines.
- Validation cadence: run the smallest relevant check after each atomic unit.
- Diff hygiene: avoid unrelated refactors and whitespace churn.
- Retry strategy: smallest corrective follow-up, not full rewrites.
- Stop condition: if two retries fail on the same unit, escalate to diagnosis.

## Universal Loop

1. Plan: state intent and acceptance check for the next unit.
2. Act: apply the smallest viable change.
3. Observe: run check, capture output, inspect diff.
4. Reflect: decide continue, retry, split, or escalate.

## Decision Gates

Gate A: Atomicity
- Is this unit one concern?
- If no, split before applying.

Gate B: Evidence
- Did a relevant check run and produce output?
- If no, do not claim progress.

Gate C: Intent Match
- Does diff behavior match stated intent?
- If uncertain, route to review or evaluation.

Gate D: Safety
- Are boundaries/dependencies affected beyond scope?
- If yes, route to codebase expert.

## Escalation Rules

- Repeated failure on same symptom: route to diagnose.
- Result claim with non-trivial uncertainty: route to evaluation.
- Cross-module impact or debt risk: route to codebase.
- Competing next steps: route to prioritization.
- Reproducibility/resume concerns: route to operations.

## Required Output Shape For Every Task

- Intent: what was attempted.
- Evidence: command/check + key output.
- Delta: files changed and why.
- Decision: continue, retry, split, escalate, done.
- Uncertainty: what is not yet confirmed.
