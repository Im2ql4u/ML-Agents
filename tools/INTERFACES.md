# Tool Interfaces

You must use these interfaces when invoking reusable agent capabilities.

## Design Rules

- Inputs and outputs are explicit.
- Output is structured and easy to parse in prompts.
- Tools report uncertainty and failure reasons directly.
- Tools do not make product decisions; experts/modes do.

## Dispatch Convention

These interfaces are behavior contracts, not direct API endpoints.

They must be mapped to editor-native capabilities (search, file edit, task/test run, diff inspection, etc.) while preserving the same input/output semantics.

Whenever a tool contract is invoked in prompt-driven execution, report it in this compact form:

```
Tool: <name>
Input: <key fields>
Action: <what was executed via editor-native tools>
Output: <structured result using this interface schema>
```

If an expected output field is unavailable, set it to `unknown` and state why.

## navigate

Input:
- query: string
- scope: entire_codebase | current_file | tests_only | docs_only
- max_results: integer

Output:
- results: list of {file, line, snippet, relevance}
- notes: optional assumptions or search limitations

## edit_atomic

Input:
- target_file: string
- intent: string
- change_unit: string
- acceptance_check: string

Output:
- applied: boolean
- diff_summary: string
- changed_lines_estimate: integer
- follow_up_check: string
- failure_reason: optional string

## test_quick

Input:
- command: string
- timeout_seconds: integer
- expected_signal: optional string

Output:
- passed: boolean
- key_output: string
- duration_seconds: number
- failure_signature: optional string

## verify_intent

Input:
- stated_intent: string
- observed_diff: string
- observed_behavior: string

Output:
- alignment: high | medium | low
- mismatches: list
- recommendation: accept | iterate | escalate

## evaluate_risk

Input:
- claim: string
- baseline_context: string
- evidence_summary: string

Output:
- risk_level: low | medium | high
- claim_validity: supported | weakly_supported | unsupported
- uncertainty: low | medium | high
- recommendation: ship | iterate | rollback

## codebase_impact

Input:
- changed_files: list
- dependency_context: string

Output:
- boundaries_touched: list
- debt_risk: low | medium | high
- safe_sequence: list
- recommendation: commit_now | split_change | refactor_first

## prioritize_next

Input:
- candidate_actions: list
- constraints: string

Output:
- ranked_actions: list of {action, impact, effort, confidence, risk}
- top_recommendation: string
- defer_list: list

## reproduce

Input:
- commit_ref: string
- config_ref: string
- environment_notes: string

Output:
- reproducible: boolean
- missing_requirements: list
- state_health: healthy | degraded | unknown
- recommendation: proceed | repair_environment | stop
