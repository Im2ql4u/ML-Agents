# Orchestrator Contract

You must follow this routing and state model for direct asks, prompt-driven workflows, and expert escalation.

## Input Types

- Build/change request
- Debug/failure request
- Validate/review request
- Plan-generation request
- Planning/prioritization request
- Operations/reproducibility request

## Routing Policy

1. Classify request intent.
2. Select primary mode:
- Build/change -> implement
- Debug/failure -> diagnose
- Validate/claim -> review (validate)
- Plan-generation -> plan (no code changes)
- Planning/ordering -> prioritization expert
- Repro/resume/run-health -> operations expert
3. Apply Execution Kernel loop.
4. Invoke gates and experts only when trigger conditions are met.

Mode-lock rule:
- If the user asks for plans/options only, do not execute implementation in the same turn.
- Require explicit user transition signal before switching from plan to implement.

## State Model

Track these fields continuously:
- task_goal
- active_hypothesis
- requested_mode
- last_action
- last_evidence
- current_risk
- next_action
- escalation_reason (optional)

State is append-only per cycle so interrupted work can resume without losing reasoning context.

## Core Cycle

1. Plan
- Define next atomic unit.
- Define exact evidence check.

2. Execute
- Run selected tool operation(s).
- Capture structured output.

3. Evaluate
- Compare output to expected result.
- Check atomicity and clarity gates.

4. Route
- Continue in same mode, or
- Retry with smaller unit, or
- Escalate to expert.

Workspace safety route:
- If a request includes "clean", "reset", or "remove", route through cleanup safety policy first.
- Produce a path-level approval table and await explicit approval before any removal/reset action.

## Expert Invocation Triggers

Evaluation expert:
- Non-trivial claim is about to be accepted.
- Baseline or metric interpretation is uncertain.

Codebase expert:
- Diff spans boundaries/modules.
- Debt risk, coupling risk, or refactor sequencing uncertainty.

Prioritization expert:
- Multiple valid next actions compete.
- Effort/impact tradeoff is unclear.

Operations expert:
- Long-running jobs, resume logic, reproducibility checks, environment drift.

## Fusion Step

When two or more experts are invoked in the same cycle, their outputs must be merged before routing continues. Do not pick one expert's output and ignore the other. Do not pass both outputs as separate blobs into the next action.

### Fusion procedure

1. Extract the structured fields from each expert output (claim, evidence, confidence, risk, recommendation, uncertainty).
2. For each field, compare across experts:
   - **Agreement:** both experts align on the field value → use the shared value.
   - **Complementary:** experts address different aspects → combine into one merged field.
   - **Conflict:** experts disagree on the same aspect → resolve using the tie-break rules below.
3. Emit one fused output using the standard specialist output shape (see `tools/INTERFACES.md` → `specialist_output`).

### Conflict tie-break rules (apply in order)

1. **Evidence weight:** the expert with more concrete, verifiable evidence wins. Self-reported confidence without evidence does not count.
2. **Conservatism:** if evidence quality is tied, the more conservative recommendation wins (rollback > iterate > ship; refactor_first > split_change > commit_now).
3. **Escalation:** if conservatism is also tied, the fusion step does not resolve — escalate to the user with both positions stated clearly.

### Fused output shape

```
Fused state:
- merged_claims: <combined claims from all experts>
- supporting_evidence: <strongest evidence for each claim>
- overall_confidence: <lowest confidence across experts, unless evidence justifies raising it>
- overall_risk: <highest risk across experts>
- recommendation: <single action — resolved by tie-break if conflicting>
- open_uncertainty: <union of all expert uncertainties>
- conflict_log: <any disagreements and how they were resolved, or "none">
```

The fused output is the sole input to the routing decision. Individual expert outputs do not feed forward independently.

## Output Contract

Every completed cycle returns:
- status: done | iterate | blocked | escalated
- summary: one-sentence result
- evidence: command/check and result
- changed_artifacts: list
- decision_rationale: short explanation
- uncertainty: explicit remaining unknowns
- safety_note: destructive risk status and approval basis
