# Implementation Plan — Pipeline Gaps

Date: 2026-03-29
Status: Draft — awaiting review before any code is written

---

## Overview

Eight gaps were identified in the current agent pipeline. After discussion, these are the ones moving forward, with the user's intent clarified and my own assessment layered in.

---

## 1. VS Code Planner + Session State Persistence

### The user's ask
> "I like the idea of an md file being laid out in so much detail — it allows a 'stupid' bad LLM to execute correctly, since a smart LLM creates it."
> "Points 1 and 3 seem similar — which one matters most?"

### My assessment: Point 1 (state) is foundational; Point 3 (metrics) is a derivative

**Point 1 — Session state scratch file** is the load-bearing one. Without a writable, persistent location for the orchestrator's state model (`task_goal`, `active_hypothesis`, `last_action`, `last_evidence`, `current_risk`, `next_action`), the execution kernel contract exists only in the LLM's context window. Every tab switch, context overflow, or session restart wipes it. A state file gives the plan-then-execute loop *memory*.

**Point 3 — Metrics tracking** is useful but secondary. Metrics (time-to-first-correct-run, drift rate, etc.) only become meaningful after several sessions, and they naturally *derive from* session state if the state is recorded properly. A metrics section can be added to session-close without a separate artifact.

**The VS Code planner gap is the real story here.** Research shows:

- **Cursor's Plan Mode** produces a real markdown file with Overview → Approach → N atomic steps with acceptance criteria. The user clicks "Build" and the agent executes step by step. The key: the plan is a *first-class artifact on disk*, persistent and shareable.
- **VS Code Copilot's Plan Agent** (newer) stores plans in `/memories/session/plan.md` — ephemeral, lost when the conversation ends. It also lacks domain-specific structure for ML work.
- Both editors' **default Agent mode goes straight to execution** without producing a visible plan. The explicit plan step requires deliberate opt-in.
- **SWE-agent** showed that interface quality beats explicit planning for small tasks. **Aider** showed that an architect/editor split (plan with one model, execute with another) improves results on complex tasks. **Plan-and-Solve prompting** (Wang et al., 2023) showed explicit planning reduces calculation errors and missing-step errors.
- The consensus is **hybrid**: lightweight plan first, then ReAct-style loop per step. This is exactly what the Execution Kernel already describes — but has no generation prompt.

### What the current pipeline is missing

The `implement` prompt *consumes* plans well (Phase 1 contract extraction: scope in, scope out, acceptance checks, required artifacts). But nothing *generates* plans with the ML-specific structure this workflow needs. The instructions just say "use your editor's built-in planner first" — which doesn't know about evaluation protocols, data leakage checks, baseline requirements, or the diagnostic hierarchy.

### Proposed solution: `plan.md` / `plan.prompt.md` prompt pair

A new prompt that sits between `brainstorm` and `implement` in the workflow. Its job: take an objective (from session-open, brainstorm, or direct ask) and produce a detailed, ML-aware plan document that the implement prompt can consume.

**Plan artifact structure** (what the prompt generates):

```markdown
# Plan: <title>
Date: YYYY-MM-DD
Status: draft | confirmed | in-progress | completed | abandoned

## Objective
<One sentence: what this plan achieves and how we will know it worked>

## Context
<What triggered this plan — link to session-open findings, brainstorm output, or diagnose results>

## Approach
<Technical strategy in 2-4 sentences. Which patterns to follow, which to avoid, and why.>

## Foundation checks (before any new code)
- [ ] Data pipeline verified on known input → expected output
- [ ] Splits respect correlation structure (or N/A with reason)
- [ ] Baseline result exists and is understood (or will be created in step N)
- [ ] Relevant existing code read and understood

## Steps
### Step 1 — <title>
**What:** <concrete action>
**Files:** <specific files to create or modify>
**Acceptance:** <exact check that proves this step is done>
**Risk:** <what could go wrong>

### Step 2 — <title>
...

## Scope
**In:** <what this plan is allowed to change>
**Out:** <what this plan must NOT touch>

## Risks and mitigations
- <risk 1>: <mitigation>
- <risk 2>: <mitigation>

## Success criteria
<How the implementer knows the full plan is done — not just "code runs" but "results are understood">
```

**Key design choices:**
- **Steps have file-level specificity.** Research (Devin, Aider architect mode) shows that naming exact files and functions in the plan dramatically reduces executor hallucination.
- **Foundation checks are mandatory and come before steps.** This wires the diagnostic hierarchy into planning, not just diagnosis.
- **Each step has its own acceptance criterion.** This maps directly to the Execution Kernel's "state intent and acceptance check for the next unit."
- **Plan is a real file saved to the workspace**, not ephemeral chat context. Suggested location: `plans/YYYY-MM-DD_<descriptor>.md`. This gives the implement prompt something concrete to "Read the confirmed plan in full."

**Session state integration:**
The plan file doubles as the session state tracker. During implementation, step checkboxes get ticked, and a `## Current State` section at the bottom gets updated:

```markdown
## Current State
**Active step:** 3
**Last evidence:** pytest tests/test_loader.py — 4 passed, 0 failed
**Current risk:** Normalization stats computed on full dataset, not train-only
**Next action:** Fix normalization in src/data/loader.py
**Blockers:** none
```

This solves state persistence without a separate `SESSION_STATE.md` — the plan *is* the state.

**Metrics integration:**
Rather than a separate `METRICS.md`, add a lightweight metrics snapshot to the session-close output. The fields worth tracking (from the strategy doc) are derivable from session artifacts:
- Time-to-first-correct-run: can be estimated from timestamps in the plan's step completions
- Drift rate: count of material deviations logged in implement
- Evaluation integrity: did the evaluation gate run? what was the verdict?

Add a `## Session metrics` section to the session-close ARCHIVE entry template. Not a separate file — just structured data in the existing flow.

### What needs to be created/modified

| Action | File(s) |
|--------|---------|
| Create plan prompt (Cursor) | `cursor/prompts/plan.md` |
| Create plan prompt (VS Code) | `vscode/prompts/plan.prompt.md` |
| Update implement to reference plan file | `cursor/prompts/implement.md`, `vscode/prompts/implement.prompt.md` |
| Update session-close with metrics snapshot | `cursor/prompts/session-close.md`, `vscode/prompts/session-close.prompt.md` |
| Add plan pair to parity checker | `scripts/check_prompt_parity.sh` |
| Update installer to install plan prompt | `install.sh` |
| Add `plans/` convention to core rules | `cursor/rules/core.mdc`, `vscode/copilot-instructions.md` |
| Update README with plan prompt reference | `README.md` |

---

## 2. Brainstorm Rewrite — Socratic, Not Structured

### The user's ask
> "It isn't good enough about being socratic. It's too structured. It must feel more natural. It should be the ideal teacher with unlimited intelligence and knowledge. It should actively search the web, GitHub, articles. It shouldn't follow a structure getting into phase A B or C — based on my input understand when to move into them. Don't ask about it, just naturally go there. More of a conversational partner, not a planner. Heavily linked with context given by diagnoser or reviewer or session open, since it will always be called after one of those."

### My assessment

The current brainstorm prompt has the right ingredients but is organized like a manual — labeled modes (Listen, Question, Challenge, Expand, Converge) with explicit section headers. This creates two problems:

1. **The LLM treats it as a checklist.** When modes are labeled, most models will announce "I'm now in Challenge mode" and mechanically cycle through them. This kills the conversational feel.
2. **The section headers leak into output.** Agents trained on structured prompts tend to reproduce the structure in their responses — numbered lists, formal sections, etc.

The fix is not to remove the behavioral DNA (listen, question, challenge, expand, converge are the right moves) but to express it as *disposition* rather than *procedure*. The prompt should describe **who you are**, not **what steps to follow**.

**Socratic method — what actually makes it work:**
- The teacher never gives the answer directly when the student can find it
- Questions are targeted to expose the *one thing* the student hasn't examined
- The teacher genuinely engages with the student's framing before redirecting it
- There's no agenda — the conversation follows the logic, not a script
- When the student is wrong, the teacher asks a question that makes the error visible rather than stating it
- When the student is stuck, the teacher doesn't ask what they think — the teacher starts thinking out loud, offering possibilities, modeling the reasoning process

**Active research integration:**
The current prompt says "search before speculating" and lists site-specific search patterns. This is good. But the instruction should be stronger: search is not optional or preparatory — **it is part of the conversation**. When something is claimed, the brainstorm partner verifies it live. When a direction is proposed, the partner searches for failure cases and counter-evidence in real time. This should feel like having a colleague who is simultaneously reading papers while talking to you.

**Context linkage:**
The user is right that brainstorm is always called after session-open, diagnose, or review. The prompt should explicitly say: "You have context from a prior prompt invocation. Start from what is already known — do not re-ground from scratch. Read the session state, the most recent diagnose/review output, or the session-open synthesis. Begin from there."

### Proposed rewrite approach

Replace the current modal structure with:

1. **A disposition section** (who you are, how you think) — replaces labeled modes
2. **A context linkage section** (what you inherit from prior prompts) — new
3. **A research integration section** (how and when to search) — strengthened from current
4. **Behavioral guardrails** (what never to do) — kept and sharpened

The modes (Listen, Question, Challenge, Expand, Converge) become *tendencies described in prose*, not labeled sections. The rhythm section ("Short turns. One move at a time.") stays — it's already conversational.

The "When specialist territory is reached" section currently asks the user whether to switch. The user wants this to be **automatic** — the brainstorm partner should naturally transition into deeper territory when the conversation demands it, without asking permission. It should still *name* the shift ("This is really an architecture question now") but not pause for a mode-switch confirmation.

### What needs to be created/modified

| Action | File(s) |
|--------|---------|
| Rewrite brainstorm prompt (Cursor) | `cursor/prompts/brainstorm.md` |
| Rewrite brainstorm prompt (VS Code) | `vscode/prompts/brainstorm.prompt.md` |

---

## 4. Experiment Comparison Structure

### The user's ask
> "Yes I agree with this completely. And when this is imported, the existing journals, archives and logs should be restructured to fit this new method in existing repos."

### My assessment

Individual experiment entries in `JOURNAL.md` are well-structured, but there's no way to compare across experiments. When you've tried 3 architecture variants over 3 sessions, rebuilding the comparison from journal entries is manual archaeology.

**What's needed:**
A comparison table structure that gets appended to `JOURNAL.md` (or a linked file) when multiple experiments address the same question. Not a separate file per comparison — that creates sprawl. Instead, a `## Comparison` section type within the journal.

**Proposed format:**

```markdown
## Comparison: <question being answered>
Date: YYYY-MM-DD
Experiments compared: [YYYY-MM-DD entry 1], [YYYY-MM-DD entry 2], ...

| Dimension       | Experiment A         | Experiment B         | Experiment C       |
|-----------------|----------------------|----------------------|--------------------|
| Method          | <short>              | <short>              | <short>            |
| Key metric      | <value ± uncertainty>| <value ± uncertainty>| <value ± uncertainty>|
| Second metric   | <value>              | <value>              | <value>            |
| Training cost   | <GPU-hours>          | <GPU-hours>          | <GPU-hours>        |
| Failure modes   | <what went wrong>    | <what went wrong>    | <what went wrong>  |

**Winner and why:** <which approach and the specific evidence>
**What this does NOT settle:** <remaining uncertainty>
**What a skeptic would say:** <honest critique of the comparison itself>
**Recommended next experiment:** <what this comparison points toward>
```

**Re-structuring on import:**
The installer cannot automatically restructure existing journal/archive content (it would need to understand the semantic content). But the `session-open` prompt can be updated to: when reading JOURNAL.md, if multiple entries address related questions, *suggest* creating a comparison entry. This keeps the restructuring human-guided rather than automated.

The `session-close` prompt should also be updated: during Full Close, after writing a journal entry, check whether this experiment has predecessors on the same question. If so, generate a comparison entry.

### What needs to be created/modified

| Action | File(s) |
|--------|---------|
| Add comparison format to JOURNAL template | `templates/JOURNAL.md` |
| Update session-close to generate comparisons | `cursor/prompts/session-close.md`, `vscode/prompts/session-close.prompt.md` |
| Update session-open to suggest comparisons | `cursor/prompts/session-open.md`, `vscode/prompts/session-open.prompt.md` |

---

## 5. Tool Dispatch Convention

### The user's ask
> "Would this go into implement or what?"

### My assessment

The tool dispatch convention doesn't belong in `implement` alone — it belongs in `tools/INTERFACES.md` (where the schemas already live) and is *referenced* by any prompt that uses tools (implement, diagnose, review, experts).

**The gap:** `INTERFACES.md` currently defines clean input/output schemas for `navigate`, `edit_atomic`, `test_quick`, `verify_intent`, `evaluate_risk`, `codebase_impact`, `prioritize_next`, `reproduce`. But nothing tells the LLM how to actually *invoke* them — whether to emit a function call, a structured markdown block, or just describe the action.

**The reality:** In both Cursor and VS Code, tools are invoked through the editor's native tool-calling mechanisms (file edits, terminal, search, etc.). The `INTERFACES.md` schemas are not "callable functions" in the API sense — they're **behavioral contracts** that describe *what the agent should do when it reaches a decision point*. For example, `edit_atomic` means "apply one small change, run a check, inspect the diff" — which maps to the editor's built-in file edit + terminal tools.

**Proposed fix:** Add a `## Dispatch Convention` section to `tools/INTERFACES.md` that explicitly says:

1. These interfaces are behavioral contracts, not API endpoints
2. Each tool maps to editor-native capabilities (file edit, terminal, search, etc.)
3. When invoking a tool, emit a structured output block so the behavior is auditable
4. The structured block format is:

```markdown
**Tool: <name>**
Input: <key fields>
Action: <what was actually done using editor capabilities>
Output: <structured result per the schema>
```

This keeps the interfaces useful for prompt governance without pretending they're callable APIs.

### What needs to be created/modified

| Action | File(s) |
|--------|---------|
| Add dispatch convention section | `tools/INTERFACES.md` |
| Add brief reference in implement preamble | `cursor/prompts/implement.md`, `vscode/prompts/implement.prompt.md` |

---

## 6. Session-Close Default Mode Fix

### The user's ask
> "Ok I agree."

### My assessment

The current default is Quick Close, but the triggers for Full Close include "an experiment was run" and "a genuine architectural or methodological decision was made" — which are the norm in ML sessions, not the exception. In practice, Quick Close runs too often and important context gets lost.

**Proposed fix:** Invert the logic. Instead of "Quick Close by default, switch to Full if triggers," make it:

**"Evaluate session content. If any of the following occurred, use Full Close: experiment run, architectural decision, workaround introduced, unresolved uncertainty. Otherwise, Quick Close."**

The change is subtle but important: the default is now *evaluation*, not *Quick*. The agent reads the session state and decides, rather than defaulting to the lightweight path.

Also add the metrics snapshot to both close modes:

```markdown
### Session metrics
- Steps completed: <N of M planned>
- Material deviations: <count>
- Evaluation gates triggered: <count and verdicts>
- Unresolved uncertainties: <count>
```

### What needs to be created/modified

| Action | File(s) |
|--------|---------|
| Rewrite Step 0 mode selection logic | `cursor/prompts/session-close.md`, `vscode/prompts/session-close.prompt.md` |
| Add metrics snapshot section | same files |

---

## 7. Negative Result / Failed Experiment Convention

### The user's ask
> "Yes negatives should be emphasised, this is important for future brainstorms and such as well."

### My assessment

The current `JOURNAL.md` template is structured for experiments that produce interpretable results. Failed experiments, blocked runs, and inconclusive outcomes don't fit cleanly — they end up either not recorded or shoehorned into a success-oriented template.

Failed experiments are often *more valuable* than successes for future brainstorms and diagnosis. "We tried X and it failed because Y" directly prevents repeating the same mistake.

**Proposed addition to JOURNAL.md:** A second entry format specifically for negative/failed/inconclusive results:

```markdown
### [YYYY-MM-DD] — NEGATIVE: <what was tried>
**Hypothesis tested:** <the specific claim that was being tested>
**Method:** <what was done>
**Expected result:** <what would have confirmed the hypothesis>
**Actual result:** <what actually happened>
**Why it failed:** <root cause, or best current understanding>
**What this rules out:** <specific directions this eliminates>
**What this does NOT rule out:** <what remains viable despite this failure>
**Severity:** dead-end | needs-rethink | minor-setback
**Lessons for future work:** <what to remember>
```

**Integration with brainstorm:** The rewritten brainstorm prompt should explicitly read NEGATIVE entries from the journal when exploring a problem space. The instruction: "Before suggesting directions, check JOURNAL.md for negative results in this area. Do not propose approaches that have already been tried and failed unless you have a specific reason to believe the failure cause has been addressed."

**Integration with session-close:** When closing a session where something failed, the session-close prompt should explicitly produce a NEGATIVE journal entry, not just a standard entry with bad numbers.

### What needs to be created/modified

| Action | File(s) |
|--------|---------|
| Add NEGATIVE entry format to journal template | `templates/JOURNAL.md` |
| Update session-close to produce NEGATIVE entries | `cursor/prompts/session-close.md`, `vscode/prompts/session-close.prompt.md` |
| Reference negatives in brainstorm rewrite | `cursor/prompts/brainstorm.md`, `vscode/prompts/brainstorm.prompt.md` |

---

## 8. Prompt Schema Lint Script

### The user's ask
> "Doesn't seem like a huge deal, but maybe it is, if it is, fix it."

### My assessment

It matters more than it appears, but for a specific reason: **regression detection**. The prompts in this pipeline require specific output sections (Intent, Evidence, Delta, Decision, Uncertainty from the Execution Kernel; the Phase 8 results report template in implement; the output schemas for each expert). If someone edits a prompt and accidentally removes a required section, there's no automated way to catch it.

The existing `check_prompt_parity.sh` catches Cursor ↔ VS Code drift but not content regressions within a single prompt.

**Proposed: `scripts/check_prompt_schema.sh`**

A lightweight linter that:
1. Checks each expert prompt contains its required output format section
2. Checks `implement` contains the Phase 8 results report template
3. Checks `session-close` contains the required archive format
4. Checks `diagnose` contains all 5 diagnostic hierarchy layers
5. Exits 0 if all pass, 1 with details if any fail

This is ~50 lines of bash checking for required string patterns. Low effort, catches real regressions.

### What needs to be created/modified

| Action | File(s) |
|--------|---------|
| Create schema check script | `scripts/check_prompt_schema.sh` |
| Document in README | `README.md` |

---

## Implementation Order

Based on dependencies and impact:

| Phase | What | Why this order |
|-------|------|---------------|
| **A** | Brainstorm rewrite (#2) | No dependencies. Highest immediate UX impact. |
| **B** | Plan prompt pair (#1) | Depends on brainstorm being settled (brainstorm → plan → implement flow). Highest structural impact. |
| **C** | Session-close fix (#6) + Metrics snapshot (#1 derivative) + Negative results (#7) | These three touch the same files. Batch them. |
| **D** | Experiment comparison (#4) | Depends on journal template changes from Phase C. |
| **E** | Tool dispatch convention (#5) | Independent, low urgency. |
| **F** | Prompt schema lint (#8) | Run last as a safety net over all prior changes. |

After each phase: run `check_prompt_parity.sh` to verify Cursor ↔ VS Code alignment. After Phase F: run the new `check_prompt_schema.sh` as well.

---

## Open Questions for You

1. **Plan file location:** `plans/YYYY-MM-DD_<descriptor>.md` in the project root, or inside `.agentic/plans/`? The former is more visible; the latter groups workflow artifacts together.

2. **Brainstorm specialist transitions:** You said "don't ask about it, just naturally go there." Should the brainstorm partner still *name* the shift ("this is really an architecture question now") or just silently adopt the deeper lens? Naming it provides transparency; silence provides flow.

3. **Journal comparison trigger:** Should comparison entries be generated automatically by session-close whenever 2+ experiments exist on a related topic, or only when explicitly requested?

4. **Negative result emphasis level:** Should `session-close` *force* a NEGATIVE entry when a session ends without achieving its stated goal, or just suggest it?
