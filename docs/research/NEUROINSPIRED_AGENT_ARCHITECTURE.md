# Neuro-Inspired Agent Architecture Direction

Date: 2026-04-09

## Purpose

This document captures:

1. What we reviewed in the current codebase.
2. The background theory informing our design direction.
3. Why we want to evolve the current architecture.
4. Risks and likely failure modes.
5. A concrete direction for implementing this deeply (not cosmetically).

---

## 1) What We Reviewed in This Codebase

The following artifacts were reviewed to understand current behavior and limits:

- Core execution and routing contracts:
  - `EXECUTION_KERNEL.md`
  - `core/orchestrator.md`
- Prompt-mode behavior:
  - `cursor/prompts/session-open.md`
  - `cursor/prompts/plan.md`
  - `cursor/prompts/brainstorm.md`
  - `cursor/prompts/implement.md`
  - `cursor/prompts/review.md`
  - `cursor/prompts/diagnose.md`
- Specialist prompts:
  - `cursor/prompts/experts/*.md`
- System strategy docs:
  - `AGENT_SYSTEM_STRATEGY.md`
  - `INTEGRATION_PLANS.md`
  - `tools/INTERFACES.md`
- Installer/operational mechanics:
  - `install.sh`
  - `update.sh`
- Memory templates:
  - `templates/SESSION_LOG.md`
  - `templates/DECISIONS.md`
  - `templates/JOURNAL.md`
  - `templates/ARCHIVE.md`

### Current-state summary from review

- The system is **strong on policy and prompting contracts**.
- It is **not yet a hard-runtime multi-agent graph** with enforced machine-level handoffs.
- "Experts" are largely **escalation roles** rather than continuously active specialist services.
- Memory exists in logs and plans, but retrieval/compaction quality is instruction-dependent.

This is a solid foundation; however, we currently rely on prompt adherence more than enforced architecture.

---

## 2) Background Theory and Literature Anchors

Our direction is inspired by converging ideas from neuroscience, cognitive architecture, and modern ML systems.

### A. Neuroscience-inspired control loops (conceptual mapping)

- **Prefrontal cortex (PFC):** executive control and goal maintenance.
- **Thalamic gating:** selective routing/attention.
- **Basal ganglia loops:** selection/suppression among alternatives.
- **Hippocampal role:** episodic memory and context retrieval.
- **Association cortex:** multimodal fusion into coherent representations.

We are not trying to literally simulate biology. We are using these as architectural metaphors for routing, gating, memory, and coordination.

### B. AI/cognitive systems precedents

- **Blackboard systems:** specialists contribute to a shared working state.
- **Global workspace style control:** one broadcast/focus space for active reasoning.
- **Mixture-of-Experts (MoE):** specialized components with a gating mechanism.
- **Planner/executor/critic loops:** explicit decomposition of cognition into roles.
- **Memory-augmented and retrieval-augmented systems:** persistent state and selective recall.

### C. Why this matters here

Our workflow already has planner/implement/review/expert concepts. The next step is to convert this from role theater into a dependable computational contract.

---

## 3) Motivation: Why Change Now

### Problems we want to solve

1. **Token and attention waste from diffuse context usage.**
2. **Inconsistent specialist invocation and fusion quality.**
3. **Memory quality depends too much on manual prompt discipline.**
4. **Good-looking outputs can pass despite weak structural grounding.**

### Goal

Build a system that is:

- robust,
- understandable,
- auditable,
- reusable,
- and aligned with project objectives,

not merely high on superficial response quality.

---

## 4) Potential Gains

If implemented correctly, we expect:

1. **Higher reliability** via explicit gates and smaller uncertainty propagation.
2. **Lower cost** via bounded specialist activation and tighter context budgets.
3. **Better maintainability** from explicit contracts and fewer implicit assumptions.
4. **Better decision quality** from structured conflict resolution among specialists.
5. **Improved handoff quality** across sessions via memory compression and retrieval policy.

---

## 5) Key Risks and Failure Modes

1. **Expert proliferation** (too many roles, low marginal value).
2. **Coordination overhead** (routing/fusion complexity outruns utility).
3. **Prompt-only coupling** (behavior seems right but is not guaranteed under stress).
4. **Memory bloat** (logs grow without effective compaction/indexing).
5. **Surface compliance** (formatting appears rigorous while epistemic quality remains weak).

---

## 6) Direction: What to Build Next (Deep, Not Cosmetic)

### Principle 1 — Bounded specialist activation

- At most 2–3 specialists active per cycle.
- Trigger only by explicit uncertainty/risk thresholds.
- Default to lean-core path for ordinary requests.

### Principle 2 — Explicit association layer

Add a dedicated "association cortex" phase between specialists and executive actions.

**Responsibilities:**
- Merge specialist outputs into one canonical working state.
- Resolve conflicts with confidence + evidence weighting.
- Emit one prioritized next action and explicit uncertainty.

Without this, specialists fragment the state and inflate cost.

### Principle 3 — Machine-readable specialist contracts

For each specialist output, require fixed fields:

- claim(s)
- evidence
- confidence
- risk
- recommended action
- open uncertainty

Free-form prose is allowed only in a bounded notes section.

### Principle 4 — Memory architecture upgrade

Treat memory as layered, not a single log stream:

1. **Episodic memory:** session events and outcomes.
2. **Semantic memory:** durable decisions and stable constraints.
3. **Working memory:** current-cycle fused state.
4. **Negative memory:** failed/inconclusive attempts and anti-patterns.

Add compaction policy and retrieval strategy by task type.

### Principle 5 — Neuromodulator-like objective signals

Use explicit optimization signals beyond "answer quality":

- robustness
- interpretability
- architectural coherence
- reuse potential
- operational safety

These should be scored and visible in final decisions.

### Principle 6 — Hard evaluation gates

Require evidence and intent alignment before accepting non-trivial claims.

No claim acceptance based solely on fluent explanation.

---

## 7) What "Correct" Implementation Looks Like

### Not correct (surface-only)

- Adding more prompts with overlapping responsibilities.
- Introducing new expert names without distinct contracts.
- Increasing verbosity without stronger evidence gates.
- Treating memory as "store everything and hope retrieval works."

### Correct (substantive)

- Distinct specialist boundaries with measurable trigger criteria.
- Explicit fusion/association stage with deterministic output shape.
- Controlled context budget and active-agent cap per cycle.
- Memory compaction + retrieval policy tested on real tasks.
- Post-hoc audits that check decision integrity, not just outputs.

---

## 8) Phased Execution Strategy

### Phase 1 — Contract hardening

- Normalize specialist IO schema.
- Define association-layer output schema.
- Define trigger thresholds and stop conditions.

### Phase 2 — Memory upgrade

- Split memory roles (episodic/semantic/negative/working).
- Add compaction and retrieval rules.
- Validate that retrieval improves decisions under constrained tokens.

### Phase 3 — Evaluation integration

- Add explicit scoring for robustness/understandability/reusability.
- Enforce evaluation gates before high-impact decisions.

### Phase 4 — Stress tests

- Run adversarial and long-horizon tasks.
- Measure failure modes, token efficiency, and correction behavior.
- Prune low-value experts and simplify routing where possible.

---

## 9) Success Criteria

We consider this direction successful when:

1. Token usage drops or remains bounded while task quality increases.
2. Decision errors caused by context confusion are reduced.
3. Specialist outputs are consistently mergeable and auditable.
4. Session handoff quality improves with less repeated rediscovery.
5. We can explain why a decision was made with explicit evidence.

---

## 10) Final Position

We are pursuing a **lean-core + bounded specialists + explicit association layer + structured memory** architecture.

The target is not biologically faithful simulation. The target is operationally reliable cognition under real constraints.

If a change only makes the system look more sophisticated without improving reliability, evidence quality, and maintainability, it should be rejected.
