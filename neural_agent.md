# PFC Mode Discussion: Why Add a Deep-Cognition Mode to ML-Agents

Date: 2026-04-10

## Context

ML-Agents already has a strong session lifecycle and role separation: `session-open`, `diagnose`, `brainstorm`, `plan`, `implement`, `review`, `explain`, `session-close`, plus specialist experts. That baseline is practical and productive.

The idea discussed here is not to replace this lifecycle. It is to add a **separate deep-cognition mode** (informally: "PFC mode") that can run richer reasoning loops for hard, ambiguous, or high-stakes work.

---

## Why this idea is appealing

In difficult tasks, the agent often needs to do more than execute a linear prompt:

- hold multiple hypotheses at once,
- route attention between conflicting signals,
- suppress weak directions,
- integrate evidence from different sources,
- and preserve coherent memory over longer sessions.

A brain-inspired framing is useful here as a systems metaphor:

- **attention/gating** for relevance,
- **selection/suppression** for competing actions,
- **association/fusion** for combining specialist outputs,
- **memory consolidation** for carrying forward what matters,
- **global objective modulation** for quality beyond "did it run?"

The goal is not biological realism. The goal is operationally better reasoning behavior under complex conditions.

---

## What this mode should optimize for

If this mode is worth adding, it should improve:

1. **Reliability** — fewer wrong turns accepted too early.
2. **Traceability** — clearer mapping from evidence to decisions.
3. **Coherence** — less drift across long sessions.
4. **Reuse** — lessons from prior attempts become durable and retrievable.
5. **Quality of judgment** — not only correctness, but robustness, elegance, and maintainability.

This should be measured by outcomes and reduction of repeated failure patterns, not by how sophisticated the language appears.

---

## Fit with the current repository

This concept aligns with current ML-Agents design principles:

- Lean core workflow remains the default.
- Specialists are invoked when justified, not by habit.
- Evidence and safety gates already exist.
- Session memory artifacts already exist.

So incorporation should be evolutionary, not disruptive: keep what works, add an optional deeper operating profile for harder tasks.

---

## How it could be incorporated (high-level)

A practical integration pattern is:

- Keep current behavior as **Lean mode**.
- Add an explicit **PFC mode** as an alternate execution profile.
- Reuse existing prompts and roles, but allow deeper recurrent reasoning semantics only in that mode.

In other words:

- same top-level roles,
- different depth and loop behavior,
- stronger emphasis on fusion and memory handling when deep mode is active.

This avoids role sprawl while enabling more advanced cognition when needed.

---

## Role-level interpretation in a PFC mode

The existing agents can keep their identities while taking on richer behavior:

- `session-open`: stronger context synthesis and uncertainty surfacing.
- `diagnose`: tighter hypothesis competition and root-cause discrimination.
- `brainstorm`: broader exploration with better suppression of weak ideas.
- `plan`: stronger branch evaluation and rationale quality.
- `implement`: more explicit evidence checks tied to chosen rationale.
- `review`: stricter acceptance based on integrated evidence.
- `session-close`: better consolidation of what was learned and what should be avoided.

This is mostly a change in interaction quality and state handling, not a total rewrite of roles.

---

## Potential gains

- Better behavior on ambiguous, cross-cutting, or long-horizon tasks.
- Lower chance of "surface-good" conclusions.
- Better continuity across sessions due to stronger memory use.
- More transparent decision quality and uncertainty reporting.

---

## Potential risks

- Added complexity can create slower workflows when not needed.
- More loops can increase cost if not bounded by clear stop criteria.
- More specialist activity can become noisy without strong synthesis.
- Architecture can become performative if contracts are vague.

These risks suggest this mode should be optional and intentionally invoked.

---

## What "good" looks like

A successful incorporation would feel like this:

- Normal tasks remain fast and simple.
- Hard tasks can switch into deep mode and actually improve outcomes.
- Decisions are better justified, not just more verbose.
- Memory is more useful, not just larger.
- The system remains understandable by humans maintaining the repo.

If the mode increases complexity without improving decision quality, it should be constrained or removed.

---

## Closing perspective

This idea is promising because it extends the spirit of ML-Agents rather than fighting it.

ML-Agents already values structure, evidence, and explicit lifecycle control. A separate PFC-style mode can be the "deep reasoning gear" for situations where the default workflow is not enough — while preserving the lean default path that makes the system practical.
