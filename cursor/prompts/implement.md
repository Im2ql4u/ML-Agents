# Implement

> **How to use:** `@implement.md` after a plan has been confirmed. This prompt drives the full implementation cycle: build, run, examine results honestly, iterate. It does not stop when the code runs — it stops when the results are understood.

---

## Precondition

A plan file exists and has been confirmed. The objective, architecture, training design, and evaluation protocol are specified. If they are not, run `@plan.md` first and confirm the plan before implementation.

Plan artifact convention:
- `plans/YYYY-MM-DD_<short-descriptor>.md`

At implementation start, identify and state the exact plan file path being executed.

Tool interface convention:
- Use `tools/INTERFACES.md` as the dispatch contract for navigation, atomic edits, checks, intent verification, risk evaluation, and prioritization.
- Treat these interfaces as behavior contracts mapped onto editor-native capabilities.

## Execution kernel and orchestration compliance

This prompt must follow `.agentic/EXECUTION_KERNEL.md` and `.agentic/core/orchestrator.md` when present. If absent, use `EXECUTION_KERNEL.md` and `core/orchestrator.md`.

For every implementation cycle:
- Plan: define one atomic change unit and one acceptance check
- Act: apply only that unit
- Observe: run the smallest relevant check and inspect diff quality
- Reflect: continue, retry with a smaller unit, split work, or escalate

After each cycle, update the active plan file `## Current State` so interrupted sessions can resume without reconstructing context.

Escalate by trigger:
- Repeated failure on same symptom: route to diagnose
- Non-trivial claim pending acceptance: route to evaluation expert
- Cross-boundary structural impact: route to codebase expert

---

## Phase 1 — Plan contract and scope lock

Read the confirmed plan in full and extract a short implementation contract before writing code:

- **Scope in** — what this implementation is allowed to change
- **Scope out** — what is explicitly not part of this implementation
- **Acceptance checks** — exact verification criteria from the plan
- **Required artifacts** — files, tests, outputs, and logs that must exist

Initialize the plan's `## Current State` section before first code change:
- **Active step**
- **Last evidence**
- **Current risk**
- **Next action**
- **Blockers**

Use the session-open and plan context as authoritative. Do not re-run broad repo re-grounding unless blocked by missing information.

If any plan step is ambiguous, ask one focused clarification question, then proceed.

### Foundation checks from the plan

Execute the plan's required foundation checks first (data, implementation, baseline) before introducing new modeling code. If a required foundation check fails, fix or report it before continuing.

### Scope discipline

Implement the intent of the approved plan, not just literal wording. Do not "optimize for good-looking results" by bypassing constraints, skipping checks, or narrowing evaluation.

---

## Phase 2 — Implementation standards

### Structure

- Reusable logic in `src/` or `core/`. Scripts in `scripts/` call into those — they do not contain logic.
- One script per well-defined task, named for what it does: `train_residual_correction.py`, not `run_v3.py`
- Config in files (`config/` directory, YAML). No hardcoded parameters anywhere. Every run must be reproducible from a commit hash + config file alone.
- Results written to `results/YYYY-MM-DD_<descriptor>/`. One run, one folder. Never overwrite.

### Code quality

- Functions do one thing. If it needs a comment to explain what it does, rename or split it.
- Type hints on all function signatures.
- Named constants with units where relevant: `GRID_RESOLUTION_M = 1000`, `LR_INIT = 1e-3`, `MAX_EPOCHS = 200`
- No silent failures. If something can go wrong, it should raise an exception with a message that says what happened, where, and what the caller should check.
- Numerical stability: after every loss computation and every gradient step, check for NaN/Inf. Do not continue silently if either is detected.

```python
if torch.isnan(loss):
    raise RuntimeError(
        f"Loss is NaN at epoch {epoch}, step {step}. "
        f"Check: input normalization, loss function implementation, "
        f"learning rate ({optimizer.param_groups[0]['lr']:.2e})"
    )
```

- Workarounds get a `# TODO: [proper fix]` comment and are logged.

### Dependencies

Do not introduce a new library without flagging it, explaining why the existing stack does not suffice, and waiting for acknowledgment.

### Anti-cheating rules

- No label leakage or test-set peeking
- No metric gaming (for example: changing evaluation logic to inflate reported gains)
- No silent architecture simplification to make results easier
- No skipping required verification steps even if intermediate output "looks good"

---

## Phase 3 — Deviation and workaround protocol

### Minor vs. material deviations

If implementation reality diverges from the approved plan:

- **Minor deviation** (naming, local refactor, mechanical wiring): proceed, but log it in the final report.
- **Material deviation** (architecture, evaluation protocol, data split logic, dependency stack, objective semantics): stop and ask for confirmation before proceeding.

### Decision points (material only)

When a material choice exists between two reasonable options:

1. Stop
2. State what the decision is
3. Present both options with their tradeoffs — not just which you prefer
4. State your recommendation and the specific reason
5. Ask what the human thinks

Do not silently choose material direction changes.

### Workarounds

When a proper fix cannot be completed within the current step:

1. Stop
2. Explain what was found and why the proper solution is not being used now
3. State what the proper solution would be
4. State impact on plan validity and result interpretation
5. Ask: proceed with the workaround, or fix the underlying problem first?

Do not log silently and continue.

### Blocker handling

If blocked after reasonable attempts, report clearly:

- What is blocked
- What was tried
- Why it failed
- What evidence was gathered
- The smallest viable next options

Update `## Current State` with blocker status before pausing.

---

## Phase 4 — GPU and remote execution

Check GPU availability explicitly before any training:

```python
import torch

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"Device: {device}")
if device.type == "cuda":
    props = torch.cuda.get_device_properties(0)
    print(f"  {props.name} | {props.total_memory / 1e9:.1f} GB")
else:
    # If GPU was required by the plan, do not proceed silently
    raise RuntimeError(
        "GPU not available. This training job requires GPU. "
        "Check CUDA installation or run on a GPU machine."
    )
```

For any run exceeding a few minutes on a remote machine, use `tmux`:

```bash
tmux new-session -d -s run_name \
  'python scripts/train_xyz.py --config config/xyz.yaml \
   2>&1 | tee logs/train_xyz_$(date +%Y%m%d_%H%M).log'

# To monitor:
tmux attach -t run_name

# To detach and leave running:
# Ctrl+B then D
```

Log GPU utilization and memory at regular intervals during training. Use `torch.cuda.memory_allocated()` or a periodic `nvidia-smi` call in the training loop.

For long runs, require interruption-safe execution:

- Save checkpoints periodically and on graceful shutdown
- Persist run state (epoch/step/seed/config hash) so reruns can resume cleanly
- Use append-only logs so progress is not lost if interrupted

---

## Phase 5 — Git during implementation

```bash
# Before starting
git status
git log --oneline -5

# For a new hypothesis or approach
git checkout -b hypothesis/<short-description>

# Commit after each logical unit — not at the end of everything
git add -p  # stage selectively
git commit -m "feat(scope): what was added and why

Context: what decision or problem this reflects"
```

Do not commit until the unit runs without error. Use `WIP:` prefix and explanation if committing broken state is necessary.

---

## Phase 6 — Testing

For every new module in `src/` or `core/`:

- At least one test against a known-answer case. Not "does it run" — does it compute the right thing.
- For mathematical functions: test against an analytical result or a known limiting case.
- For data processing functions: test shapes, dtypes, value ranges, and at least one specific known value.
- At least one integration check to confirm wiring with the existing pipeline.
- End-to-end smoke test for the planned path before declaring completion.
- Tests in `tests/`, runnable with `pytest -v`.

Write the test before or immediately after writing the function. Not at the end.

---

## Phase 7 — Run and examine results

This is where most prompts stop. This one does not.

### Run the code

Execute the plan. Monitor actively:

- Loss curves: train and validation together
- Gradient norms per layer (or at minimum the global norm)
- Loss component magnitudes if multi-term loss
- GPU memory and utilization
- Any NaN/Inf warnings

If anything anomalous appears during the run — unexpected loss spikes, NaN, unusually fast convergence — stop, note it, investigate before continuing. Do not run to completion and then examine.

### Examine the outputs

After the run completes, examine actual outputs. Do not skip this. Reading log files and reporting numbers is not examining outputs.

Look at:
- Sample predictions vs. ground truth on a handful of representative cases
- Residuals or errors — are they random, or do they have structure? Structure in the errors means the model has not learned something it should have.
- Performance on the worst cases in the validation set, not just the average
- Whether the output range and distribution are physically plausible
- Whether the improvement over baseline is consistent across the dataset, or concentrated in a subset

---

## Phase 8 — Honest results report

This is mandatory. It is produced in chat, not only in the logs.

```
## Results — [YYYY-MM-DD HH:MM]
**Script:** scripts/<n>.py  |  **Config:** config/<n>.yaml  |  **Commit:** <hash>
**Device:** <GPU + memory>  |  **Duration:** <time>

---

### What was run
<One sentence: what this experiment was testing>

### Raw results
<Metrics with units. No interpretation here — just the numbers.>

Metric         | This model | Baseline | Δ
---------------|------------|----------|----
<metric>       | <value>    | <value>  | <value>

Seeds run: <n>  |  Variance: <std or range across seeds>

### What these results mean
<Interpretation: what does this tell us about the model and the problem.
Not "the model performs well" — what does it actually tell us.>

### What these results do NOT tell us
<What cannot be concluded from this experiment alone.
What alternative explanations exist for this outcome.>

### What is unexplained
<Anything in the results that is surprising, inconsistent, or not understood.
These are the most important things in this section.>

### What a skeptic would say
<Honest critique: what would someone trying to find problems with this result say?
What are the weakest points? What is the most likely methodological concern?>

### Issues encountered during the run
<Everything that went wrong, required a workaround, or was unexpected.>

### Active workarounds
<Any TODOs introduced, with their TODO references.>

### Plan contract status
<Which planned steps are complete, partially complete, or deferred.>

### Deviations from plan
<Minor deviations taken, and any material deviations explicitly approved.>

### Plan state update
<What was written to `## Current State` and why.>

### Output location
results/<dated-folder>/

### Recommended next action
<What this result implies we should investigate or change — not what confirms the plan,
but what the result genuinely points toward.>
```

---

## Phase 9 — Mid-implementation understanding check

After completing a significant component — before moving to the next — ask:

*"Here is what was just written: [two-sentence description]. What would you expect it to produce on [simple specific input]?"*

If the answer is wrong, correct it and explain why before continuing. If the answer is right, build on it. The code and the understanding should grow together.

---

## Phase 10 — Before declaring done

Five gates. All five.

1. Code runs and produces sensible output on a known input
2. NaN/Inf checked in all outputs
3. Committed with a meaningful message
4. Honest results report produced (Phase 8) if a run was performed
5. Chat-facing summary produced:

```
**What was done**
- <file>: <one-line purpose>
[one line per file created or modified]

**Decisions made**
- <decision>: <why — one sentence>

**Workarounds in place**
- <workaround>: <TODO ref and proper fix>

**What I am uncertain about**
<Do not leave this blank. If everything seems fine, say what you would check next
to increase confidence that it actually is.>

**One question for you**
<A specific question about what was just built that you should be able to answer
if you have been following along. Not "any questions?" — something concrete,
answerable, that tests understanding of what was built and why.>
```

6. Plan `Status` and `## Current State` updated for handoff
