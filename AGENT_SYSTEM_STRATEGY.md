# Agent System Strategy for ML-Agents

## Purpose

This document turns external agent-system inspiration into practical design choices for this repository.

It focuses on three questions:

1. Which ideas from top agent systems are genuinely useful for this workflow?
2. Which experts and tools should exist here (and which should not)?
3. How do we keep the system easy, practical, and structured for real users?

The goal is not to maximize prompt count. The goal is reliable progress per hour.

---

## Current Baseline (What We Are Optimizing)

Current core flow:

1. `session-open`
2. built-in planner (editor-native)
3. `implement`
4. `review` / `diagnose` when needed
5. `session-close`

Current strengths:

- Clear session lifecycle.
- Strong implementation discipline.
- Explicit logs (`SESSION_LOG`, `DECISIONS`, `JOURNAL`, `ARCHIVE`).
- Good cross-editor parity checks.

Current risks:

- Too many prompts can raise cognitive load.
- Plan-to-implementation drift can still happen.
- Evaluation quality can be inconsistent across projects.
- Long-run operations and reproducibility are not always first-class.

---

## What Similar Systems Actually Teach

This section explains, in plain language, what each major inspiration is and why it matters for this repository.

## 1) SWE-agent / mini-SWE-agent

These projects are focused on a very concrete problem: take a real issue in a real repository, make the fix, and prove it with tests. The key idea is not "add more agent personalities." The key idea is to give the agent a good working interface to files, tests, and commands so it can act reliably.

Why this applies here: your workflow should reward execution quality, not role complexity. In practice, this means keeping the main loop simple and making verification non-optional.

Practical lesson for us: fewer moving parts, stronger execution gates.

---

## 2) Aider

Aider is basically a disciplined coding loop wrapped around git: edit, run tests, inspect diff, repeat. It behaves well in existing repos because it stays close to the code and keeps changes small and reviewable.

Why this applies here: your implementer should behave like a careful teammate, not a one-shot code generator. The highest leverage behavior is tight edit-test-fix cycles with auditable changes.

Practical lesson for us: small deltas, frequent validation, clear history.

---

## 3) LangGraph and AutoGen

These frameworks treat orchestration as its own layer. In other words, they separate workflow/state management from the individual agent prompt behavior. They also emphasize long-running reliability, resumability, and human interrupts.

Why this applies here: your built-in planner and your implementer should stay separate. Planning defines direction; implementation executes. If long runs matter, resumability and state contracts must be explicit.

Practical lesson for us: separate layers cleanly, keep state intentional.

---

## 4) MetaGPT

MetaGPT popularized SOP-style handoffs, where different "roles" produce structured intermediate artifacts. The useful part is structure and consistency. The risky part is overhead from too many roles.

Why this applies here: you do benefit from structured outputs, but you do not need to simulate a full company every time. Most of the value can be captured with strict output formats and clear handoff rules.

Practical lesson for us: keep SOP discipline, avoid role theater.

---

## 5) ReAct and Reflexion

ReAct showed that reasoning works better when it is interleaved with action and observation, not done in isolation. Reflexion showed that short, evidence-based self-correction across attempts can improve outcomes.

Why this applies here: your agents should not just think or just execute. They should do small actions, check feedback, adjust, and continue. Reflection should be tied to concrete failures and evidence, not generic prose.

Practical lesson for us: action-feedback loops beat abstract reasoning loops.

---

## 6) SWE-bench and SWE-bench Verified

SWE-bench is a benchmark for real-world software issue resolution. SWE-bench Verified is a cleaner subset created because many original tasks were underspecified or had problematic tests. The big takeaway is that evaluation quality can dramatically change measured performance.

Why this applies here: "good score" is meaningless if the evaluation setup is weak. For this repo, result claims need protocol checks: leakage safety, baseline parity, and uncertainty reporting.

Practical lesson for us: trustworthy evaluation is part of the system, not an afterthought.

---

## Design Principle for This Repo

Use a "lean core + optional specialists" model.

- Core always used: session-open, built-in planner, implement, review/diagnose, session-close.
- Specialists invoked only for real failure modes or high-stakes decisions.

This preserves speed while allowing depth when needed.

---

## Expert Strategy: What Fits Best Here

## Existing experts that already fit well

1. `experts/architecture`
- Good for structural model decisions.
- Keep.

2. `experts/data`
- Essential for leakage-safe and correlation-respecting pipelines.
- Keep.

3. `experts/training`
- Strong for optimization and stability design.
- Keep.

4. `experts/framing`
- Helps avoid solving the wrong problem.
- Keep.

## Gaps in current expert coverage

1. Evaluation integrity gap
- Today, quality of conclusions can vary.
- Need a dedicated protocol for claim trustworthiness.

2. Codebase quality gap
- Script sprawl and integration debt grow silently.
- Need explicit guardrails for module boundaries and cleanup timing.

3. Prioritization gap
- Teams often spend effort on low-ROI improvements.
- Need explicit decision support on what to do next.

4. Run operations gap (optional)
- Long-running experiments need resume, checkpoint, and reproducibility contracts.
- This is high-value for research-heavy workflows, optional for short loops.

---

## Proposed Expert Set (Practical and Minimal)

If adding experts, use this order and stop early if value plateaus.

## Tier 1 (highest value, lowest complexity)

1. `experts/evaluation`
- Purpose: validate whether results are trustworthy.
- Core output: ship / iterate / rollback recommendation with evidence.
- Why it applies: this repo is ML-oriented; wrong conclusions are expensive.
- Usability: high (clear rubric, immediate decision value).

2. `experts/codebase`
- Purpose: keep architecture clean while features land.
- Core output: boundary map, debt findings, safe refactor sequence.
- Why it applies: this workflow is used in existing repos, where integration quality matters.
- Usability: high if used on larger changes only.

## Tier 2 (add only if needed)

3. `experts/prioritization`
- Purpose: rank candidate actions by impact, confidence, effort, risk.
- Core output: recommended next milestone + explicit deprioritized items.
- Why it applies: protects against endless optimization loops.
- Usability: high for teams, medium for solo users.

4. `experts/operations`
- Purpose: reproducibility and long-run reliability.
- Core output: run contract, checkpoint policy, resume protocol.
- Why it applies: important for long training/eval runs.
- Usability: medium-high depending on workload.

## Do not add (for now)

- Generic "multi-agent manager" experts with overlapping remit.
- Experts that duplicate review/diagnose behavior.
- Experts that have no distinct output schema.

---

## Tool Strategy: What "Tools" Should Mean Here

In this context, "tools" are not just APIs. They are operational capabilities the agent can rely on consistently.

## Must-have tool classes

1. Codebase navigation tools
- Fast file search.
- Semantic search.
- Symbol/usage lookup.

Value:

- Reduces hallucinated edits.
- Improves reuse.

2. Safe editing tools
- Atomic patching.
- Clear diffs.
- Minimal unrelated churn.

Value:

- Easier review and rollback.

3. Validation tools
- Test execution.
- Lint/type checks.
- Error surfacing.

Value:

- Converts generation into verified iteration.

4. State and continuity tools
- Structured logs (`SESSION_LOG`, `DECISIONS`, `JOURNAL`, `ARCHIVE`).
- Session consistency checks.

Value:

- Better handoffs and less context loss.

5. Parity and governance tools
- Prompt parity check script.
- Non-destructive installer/backups.

Value:

- Reliable cross-editor behavior.

## Nice-to-have tool classes

6. Experiment run helpers
- Template for run IDs, config hashes, checkpoint conventions.
- Optional utility scripts for resume and report extraction.

7. Evaluation report helpers
- Standardized metric tables with confidence intervals.
- Slice-wise performance summaries.

## Tool anti-patterns

- Tools that allow wide destructive operations by default.
- Tools with vague output formats.
- Multiple tools for the same core action without clear preference.

---

## What Usability Looks Like in Practice

A system is usable when users can predict what happens next.

Usability criteria for this repo:

1. Start fast
- New user reaches first useful action in under 30 seconds.

2. Clear next step
- Every prompt ends with one explicit handoff.

3. Stable outputs
- Every expert uses a fixed output schema.

4. Bounded overhead
- Default mode remains lightweight.
- Deep modes are explicit opt-in.

5. Reversible work
- Every significant change is auditable and reversible.

---

## Quality Metrics to Track (Small, High Signal)

Track weekly. Start with these six.

1. Time-to-first-correct-run
- Median minutes from task start to first verified correct result.

2. Plan-to-implementation drift rate
- Percent of tasks with material, unapproved deviations.

3. Reproducibility pass rate
- Percent of decision-grade runs reproducible from commit + config + seed.

4. Evaluation integrity pass rate
- Percent of claims passing leakage/baseline/uncertainty checks.

5. Seven-day rollback rate
- Percent of merged agent-generated changes reverted within seven days.

6. Handoff friction
- Median clarification turns from planning output to implementation start.

Interpretation:

- Lower is better for (1), (2), (5), (6).
- Higher is better for (3), (4).

---

## Recommended Next Configuration (Balanced)

## Keep as core

- `session-open`
- built-in planner
- `implement`
- `review`
- `diagnose`
- `session-close`

## Keep as current experts

- `experts/architecture`
- `experts/data`
- `experts/training`
- `experts/framing`

## Add next (if desired)

1. `experts/evaluation`
2. `experts/codebase`

Then measure metric movement for two weeks before adding anything else.

---

## Decision Framework for Adding Any New Expert

Only add an expert if all five conditions are true:

1. It addresses a repeated failure mode in real sessions.
2. Its responsibility is not already covered.
3. Its output schema is unique and testable.
4. It reduces decision time or rework measurably.
5. It can be explained in one sentence to a new user.

If not, do not add it.

---

## Suggested Output Schemas (for Future Experts)

If new experts are added, enforce strict templates.

## Evaluation expert output

1. Claim under test
2. Protocol validity verdict
3. Metric table (with uncertainty)
4. Failure slices
5. Skeptic critique
6. Ship / iterate / rollback recommendation

## Codebase expert output

1. Boundary map
2. Structural debt list
3. Integration risks
4. Refactor sequence
5. Ready / risky / blocked verdict

These schemas keep experts useful instead of verbose.

---

## Risks and Mitigations

1. Risk: expert proliferation
- Mitigation: cap active experts, quarterly prune by utilization.

2. Risk: process overhead
- Mitigation: lightweight default mode, experts only on trigger conditions.

3. Risk: metric theater
- Mitigation: track few metrics, review trends monthly, remove vanity metrics.

4. Risk: planner-implementer disconnect
- Mitigation: mandatory implementation contract block at executor start.

---

## Final Guidance

For this repository, the best strategy is:

- Keep the core workflow lean.
- Use built-in planner as planning engine.
- Make implementer the disciplined execution layer.
- Add only experts that close high-cost failure modes.
- Measure outcomes and prune aggressively.

Complexity should be earned by measurable gains, not by architecture aesthetics.
