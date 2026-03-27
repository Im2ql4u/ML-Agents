# Two Integration Plans: Execution Kernel + ReAct/Experts + Tools

**Context:** You want the Execution Kernel (small edits, fast tests, clear diffs, instant retry) to work:
- Embedded in core files (implementer, review, diagnose)
- Available when you ask directly (not just in agent mode)
- Integrated with ReAct/Reflexion behavior, experts, and tools
- Filling gaps: evaluation, codebase, prioritization, operations

---

## PLAN A: "Embedded Kernel + Tool Registry Architecture"

**Philosophy:** Execution Kernel is DNA of all decision-making. Tools are reusable validators. Experts decide when to use specialized tools.

### 1. Core Files (Embedded Kernel)

**Updated files (all modes):**
- `implementer.prompt.md`: Kernel rules in preamble (edit atomicity, test after each, diff clarity)
- `review.prompt.md`: Kernel inspection (small change → fast pass; large → request split)
- `diagnose.prompt.md`: Kernel-informed failure analysis (is change too large? test incomplete? diff unclear?)

**Kernel Policy (embedded as executable rules):**
```
ATOMICITY: One semantic concern per change (~5-20 lines)
TEST: Run after every change, inline
CLARITY: Diffs must show intent, not noise (ignore whitespace, group related)
RETRY: On failure, apply smallest possible fix (not revert entire batch)
```

**Result:** Works whether called as agent OR pasted into chat directly. Kernel is prompting DNA, not a separate mode.

---

### 2. Tool Registry (New: `tools/REGISTRY.md`)

**Not new agents.** Reusable capabilities for experts to invoke.

| Tool | Purpose | Input | Output | Owner |
|------|---------|-------|--------|-------|
| `navigate` | Find files, functions, tests by pattern | search term, scope | [file:line](file.ts#L10), context | implementer |
| `edit_atomic` | Apply small, testable change | file, change, reasoning | diff, test command | implementer |
| `test_quick` | Run unit/integration test, capture output | test path, timeout | pass/fail, output, duration | implementer |
| `verify_intent` | Check if change matches stated goal | goal, code, diff | alignment score, gaps | review |
| `evaluate_risk` | Score change against SWE-bench criteria | code, context, goal | risk level, claim validation | evaluation expert |
| `codebase_impact` | Map affected boundaries, debt, refactor sequence | file, change | impact map, safe sequence | codebase expert |
| `prioritize_next` | Decide which gap to address next | current state, goal | next task, rationale | prioritization expert |
| `reproduce` | Rebuild state after change, verify reproducibility | commit hash, environment | state, reproducible? | operations expert |

**How it works:**
- Expert decides "we need to evaluate risk" → calls `evaluate_risk`
- Tool returns structured output
- Expert uses output to decide next action
- No new personas; tools are decision support

---

### 3. Experts as Decision Gates (Tier 1: Evaluation + Codebase)

**Evaluation Expert** (new: `experts/evaluation.prompt.md`)
- **When:** Before review gate, and at review time
- **Inputs:** Change, test output, code context
- **Decisions:**
  - Does change validate claimed behavior?
  - Are we leaking assumptions (e.g., framework version, workspace state)?
  - Is baseline parity maintained?
  - Ship now? Iterate? Rollback?
- **Tools used:** `verify_intent`, `evaluate_risk`
- **Outputs:** Claim validation (pass/flag), uncertainty level, decision (ship/iterate/rollback)

**Codebase Expert** (new: `experts/codebase.prompt.md`)
- **When:** After change applied, before commit
- **Inputs:** Files changed, diff, context
- **Decisions:**
  - What boundaries does this cross?
  - What debt am I creating?
  - Is there a safer refactor sequence?
  - Should this be split into smaller changes?
- **Tools used:** `codebase_impact`, `edit_atomic`
- **Outputs:** Boundary map, debt score, safe sequence recommendation

---

### 4. Filling the Gaps (Where do they live?)

| Gap | Where | How |
|-----|-------|-----|
| **Evaluation Integrity** | Evaluation Expert gate | Before review; review gate checks SWE-bench criteria (claim, test, baseline, uncertainty) |
| **Codebase Quality** | Codebase Expert gate | Before commit; surfaces debt, boundaries, refactor sequence |
| **Prioritization** | Prioritization Expert (Tier 2) | Post-review; decides which gap/gap-filler to address next |
| **Operations/Reproducibility** | Operations Expert (Tier 2) | Post-deploy; validates state reconstruction, environment stability |

---

### 5. Flow (How ReAct/Reflexion integrates)

```
DIRECT CALL (you paste into chat)
  ↓
Implementer sees request
  ├─ Apply kernel: small edits, inline tests, clear diffs
  ├─ Call `navigate`, `edit_atomic`, `test_quick` as needed
  └─ Pass result to review

REVIEW (automated or manual)
  ├─ Apply kernel: verify small size, test passing, diffs clear
  ├─ Call `verify_intent` tool
  ├─ **Evaluation Expert gate:**
  │   ├─ `evaluate_risk`
  │   ├─ Checks claim/test/baseline/uncertainty
  │   └─ Decision: ship? iterate? rollback?
  └─ If "iterate": loop back to implementer with feedback

BEFORE COMMIT
  ├─ **Codebase Expert gate:**
  │   ├─ `codebase_impact`
  │   ├─ Checks boundaries, debt, sequence
  │   └─ Decision: commit now? split? refactor first?
  └─ Commit or request sequence change

AFTER SUCCESS (Tier 2)
  ├─ **Prioritization Expert:**
  │   └─ Evaluates what gap to close next
  └─ **Operations Expert:**
      └─ Validates reproducibility, environment stability
```

**ReAct/Reflexion:** Baked into each step. Tool output → decision → feedback. Not a separate mode.

---

### 6. Implementation Order (Plan A)

1. **Week 1:** Embed Kernel rules into `implementer.prompt.md`, `review.prompt.md`, `diagnose.prompt.md`
2. **Week 2:** Create `tools/REGISTRY.md` and first 3 tools (`navigate`, `edit_atomic`, `test_quick`)
3. **Week 3:** Implement Evaluation Expert with tool-call infrastructure
4. **Week 4:** Implement Codebase Expert
5. **Week 5+:** Tier 2 (Prioritization, Operations), then tool expansion

**Pros:**
- Direct use without agents works immediately (kernel in core prompts)
- Tools are lightweight, testable, composable
- Experts are decision-makers, not executors
- Gaps filled naturally as experts add
- Low coupling; each expert is independent

**Cons:**
- More files (tools registry, expert prompts)
- Coordination between tools + experts needs clear interfaces
- Requires tool-call infrastructure (LLM functions or prompting pattern)

---

---

## PLAN B: "Orchestrated Execution Kernel + Orchestration Layer Architecture"

**Philosophy:** Execution Kernel is a policy document. Orchestration layer is a decision engine. Tools are first-class primitives with formal interfaces. Experts are specialized decision sub-routines.

### 1. Execution Kernel as Standalone Policy (`EXECUTION_KERNEL.md`)

Instead of embedding in prompts, create a formal document referenced by all modes:

```
# Execution Kernel Policy

## Principles
- Atomicity: One concern per change
- Observability: Test after each change
- Reversibility: Can undo without full rollback
- Clarity: Diff must show intent

## Constraints
- Change size: ≤20 lines per atomic unit
- Test: Run within 2 minutes after change
- Diff: No whitespace noise, grouped by concern
- Retry: Smallest-possible fix, not revert

## Decision Gates
- Size check: Is this atomic?
- Test check: Did all tests pass?
- Clarity check: Is diff clear?
- If any fail: Decompose or request review
```

**How it's used:** Any prompt, any flow references this ONE document. Version control, auditable.

---

### 2. Orchestration Layer (New: `core/orchestrator.md`)

This layer sits BETWEEN requests and execution. It coordinates:
- Tool selection (which tools answer this question?)
- Expert invocation (which experts decide?)
- Feedback loops (what do we learn from this attempt?)

**Orchestrator pattern:**
```
INPUT:  Task (e.g., "fix failing test")
  ↓
PLAN:   Orchestrator selects tools + experts
        - "Fix failing test" → navigate (find test) + diagnose (understand failure) + implement (apply fix)
  ↓
EXECUTE: Tools run, return structured output
  ↓
REFLECT: Did output match intent? Did we learn something?
         - Yes: Move to next step
         - No: Adjust plan, retry
  ↓
OUTPUT: Final state + what we learned
```

**Lives in:** `core/orchestrator.md` (1 page reference guide)

---

### 3. Tools as First-Class API (New: `tools/INTERFACES.md`)

Formal signatures, not fuzzy descriptions:

```yaml
Tool: navigate
Input:
  query: string (file path pattern, function name, or keyword)
  scope: string (entire_codebase | current_file | tests_only)
Output:
  results: array
    - file: string
      line: number
      context: string
      relevance: 0-1

Tool: edit_atomic
Input:
  file: string
  change: {before: string, after: string}
  reasoning: string
  kernel_check: {atomic: bool, reversible: bool}
Output:
  success: bool
  diff: string
  test_command: string
  reversible: bool
  
Tool: test_quick
Input:
  path: string
  timeout_seconds: number
Output:
  passed: bool
  output: string
  duration_seconds: number
  failures: array
```

**Result:** Tools are language-agnostic, composable, testable independently.

---

### 4. Experts as Specialized Orchestrators (Tier 1)

**Evaluation Expert:**
`experts/evaluation.md` (orchestrator for evaluation tasks)

```
WHEN: Before review threshold

TOOLS AVAILABLE:
  - navigate (find related tests, claims, baseline)
  - verify_intent (is change validating claimed behavior?)
  - evaluate_risk (SWE-bench criteria check)

DECISION POINTS:
  1. Is the claim clear and testable?
  2. Do tests validate the claim?
  3. Is baseline parity maintained?
  4. What's our uncertainty?

OUTPUT SCHEMA:
  {
    claim_valid: bool,
    test_quality: 0-1,
    baseline_parity: bool,
    uncertainty: "low" | "medium" | "high",
    decision: "ship" | "iterate" | "rollback",
    reasoning: string
  }
```

**Codebase Expert:**
`experts/codebase.md` (orchestrator for codebase tasks)

```
WHEN: Before commit

TOOLS AVAILABLE:
  - navigate (find affected boundaries)
  - codebase_impact (map debt, coupling, refactor sequence)

DECISION POINTS:
  1. What boundaries does this cross?
  2. What technical debt am I creating?
  3. Is there a safer refactor sequence?
  4. Should I split this change?

OUTPUT SCHEMA:
  {
    boundaries_crossed: array,
    debt_introduced: number (0-10),
    safe_sequence: array,
    recommendation: "commit_now" | "split" | "refactor_first",
    reasoning: string
  }
```

---

### 5. Filling the Gaps (Orchestrator Routes)

| Gap | Route | Orchestrator Pattern |
|-----|-------|----------------------|
| **Evaluation Integrity** | Evaluation Expert orchestrator | Task "validate change" → calls navigate + verify_intent + evaluate_risk → outputs decision |
| **Codebase Quality** | Codebase Expert orchestrator | Task "check impact" → calls navigate + codebase_impact → outputs sequence |
| **Prioritization** | Prioritization orchestrator (async) | Task "what's next?" → calls all experts for status → outputs priority queue |
| **Operations** | Operations orchestrator (post-deploy) | Task "verify reproducibility" → calls reproduce + state validation tools → outputs health report |

---

### 6. Flow (How ReAct/Reflexion integrates)

```
DIRECT CALL
  ↓
Orchestrator evaluates: "What tools/experts does this need?"
  ├─ Implements Kernel atomicity check
  ├─ Selects tools (navigate, edit_atomic, test_quick)
  ├─ Implements ReAct loop:
  │   ├─ Reason: "First, understand the current state"
  │   ├─ Action: Call navigate
  │   ├─ Observe: Return files + context
  │   ├─ Reason: "Now apply the smallest change"
  │   ├─ Action: Call edit_atomic
  │   ├─ Observe: Diff + test command
  │   └─ Reflect: "Did this work? What did we learn?"
  └─ Route to Evaluation Expert (outputs: claim validation, risk, decision)

IF ITERATE:
  ├─ Orchestrator sees "iterate" decision
  ├─ Reroutes to implementer with feedback
  ├─ Adjusts plan based on what failed
  └─ All tools maintain state (no full resets)

BEFORE COMMIT:
  ├─ Orchestrator routes to Codebase Expert
  ├─ Expert evaluates impact + safety
  └─ Outputs: commit/split/refactor recommendation

POST-SUCCESS (Tier 2):
  ├─ Prioritization Orchestrator
  ├─ Operations Orchestrator
  └─ Both use same tool infrastructure + ReAct loop
```

---

### 7. Implementation Order (Plan B)

1. **Week 1:** Create formal `EXECUTION_KERNEL.md` policy document
2. **Week 2:** Create `core/orchestrator.md` (1 pager) + `tools/INTERFACES.md` (signatures)
3. **Week 3:** Implement first tools with formal interfaces (navigate, edit_atomic, test_quick)
4. **Week 4:** Implement Evaluation Expert orchestrator + tool-call infrastructure
5. **Week 5:** Implement Codebase Expert orchestrator
6. **Week 6+:** Tier 2 orchestrators (Prioritization, Operations), async flows

**Pros:**
- Execution Kernel is explicit, auditable, versioned
- Tools have formal interfaces; can be tested independently
- Orchestrator is reusable across modes (agents, direct, CLI)
- ReAct/Reflexion is baked into orchestrator; natural feedback loops
- Tier 2 gap-fillers slot in cleanly (same tool + orchestrator infrastructure)
- Highly extensible; new experts add without changing core

**Cons:**
- More upfront structure (might feel over-engineered for your use case)
- Requires tool infrastructure investment
- More files, more formal interfaces to maintain

---

---

## COMPARISON MATRIX

| Aspect | Plan A | Plan B |
|--------|--------|--------|
| **Kernel Location** | Embedded in prompts | Formal policy document |
| **Tool Infrastructure** | Lightweight registry | Formal interfaces + orchestrator |
| **Works Direct-Call?** | Yes (kernel in prompts) | Yes (orchestrator is universal) |
| **ReAct/Reflexion** | Implicit in prompt design | Explicit in orchestrator loop |
| **Gap-Filling** | Each expert adds independently | Experts use orchestrator pattern |
| **Extensibility** | Medium (add expert, update registry) | High (add expert, reuse orchestrator) |
| **Upfront Cost** | Low (update 3 files) | Medium (5-6 files, signatures) |
| **Complexity** | Simpler, fewer layers | More formal, more structure |
| **Best For** | "Keep it lean, add as needed" | "Build once, extend for years" |

---

## My Recommendation

**Start with Plan A,** migrate to Plan B if:
- You add 3+ experts and orchestration needs are clear
- Tools become complex enough to need formal interfaces
- You want reproducible, auditable decision flows

**Plan A gets you moving.** Plan B gives you foundation for scale.

---

**Your Questions Answered:**

1. ✅ **Kernel in core files?** Plan A: embedded rules. Plan B: referenced policy. Both are in implementer + review + diagnose.
2. ✅ **Works without agents?** Yes, both plans. Kernel is in prompts (A) or orchestrator (B).
3. ✅ **Fuse all pieces?** Plan A uses tools as decision support; Plan B uses orchestrator. Both output structured decisions to experts.
4. ✅ **Fill gaps?** Plan A: each expert + tools. Plan B: experts are orchestrators using same tools.

**Next step?** Which plan resonates? Or hybrid (Plan A core, Plan B orchestrator structure)?
