# ML-Agents

A structured agentic coding workflow for ML and scientific computing projects. Works with Cursor and VS Code Copilot.

---

## What this is

A set of prompt files, rules, and log templates that install into any project repo and give your coding agent a coherent, disciplined way of working — with you, not instead of you.

The workflow is built around a few core principles:
- Success is not a metric. It is a codebase where every choice is justified and every result is understood.
- Problems are investigated from the most fundamental layer upward — data before implementation, implementation before architecture, architecture before hyperparameters.
- Results are reported honestly: raw numbers, what they mean, what they don't mean, what is unexplained.
- The agent stops at every real decision and workaround and asks — it does not silently choose.
- Understanding grows alongside the codebase. Every session ends with reflection, not just output.

---

## Install

Clone this repo once, anywhere on your machine:

```bash
git clone https://github.com/Im2ql4u/ML-Agents.git ~/ML-Agents
```

If you previously cloned an older underscore-named repository, replace it:

```bash
rm -rf ~/ML_Agents
git clone https://github.com/Im2ql4u/ML-Agents.git ~/ML-Agents
```

Then, from the root of any project repo you want to add the workflow to:

```bash
bash ~/ML-Agents/install.sh
```

The installer will ask whether you want Cursor, VS Code, or both.

**What it does:**
- Installs prompt and rules files into `.cursor/` and/or `.github/`
- Installs shared orchestration contracts into `.agentic/` (`EXECUTION_KERNEL`, `orchestrator`, `tool interfaces`)
- Installs log templates (`SESSION_LOG.md`, `DECISIONS.md`, `JOURNAL.md`, `ARCHIVE.md`) if they do not already exist
- If any file it would install already exists in your repo, it **moves your existing file** to `.agentic-backup/YYYY-MM-DD_HH-MM/` before installing — nothing is ever deleted
- Adds `.agentic-backup/` to `.gitignore` automatically
- Never overwrites live log files

### One-command apply in any existing repo

From the root of the target repo:

```bash
bash ~/ML-Agents/install.sh
```

Behavior in existing repos:
- Workflow-managed agent files are updated to this repository's versions
- Previous versions of those files are moved to `.agentic-backup/YYYY-MM-DD_HH-MM/` first (not deleted)
- Existing `SESSION_LOG.md`, `DECISIONS.md`, `JOURNAL.md`, `ARCHIVE.md` are never overwritten
- Agent files that are not part of this workflow remain untouched

---

## Update

When this repo is updated, pull and re-run from your project repo:

```bash
bash ~/ML-Agents/update.sh
```

This pulls the latest workflow changes and re-runs the installer. Your existing files that differ from the new versions are backed up before being replaced.

---

## Prompt parity check

Use this to verify Cursor and VS Code prompt files stay semantically aligned:

```bash
./scripts/check_prompt_parity.sh
```

Exit code:
- `0` means all mapped pairs are aligned
- `1` means at least one pair drifted (or a file is missing)

## Prompt schema check

Use this to verify required sections still exist in critical prompts:

```bash
./scripts/check_prompt_schema.sh
```

Exit code:
- `0` means required schema sections were found
- `1` means one or more required sections are missing

---

## File layout after install

**Cursor:**
```
your-project/
├── .agentic/
│   ├── EXECUTION_KERNEL.md
│   ├── core/
│   │   └── orchestrator.md
│   └── tools/
│       └── INTERFACES.md
├── .cursor/
│   ├── rules/
│   │   └── core.mdc                    ← always active
│   └── prompts/
│       ├── session-open.md
│       ├── session-close.md
│       ├── plan.md
│       ├── brainstorm.md
│       ├── implement.md
│       ├── review.md
│       ├── diagnose.md
│       ├── explain.md
│       └── experts/
│           ├── architecture.md
│           ├── framing.md
│           ├── training.md
│           ├── data.md
│           ├── evaluation.md
│           ├── codebase.md
│           ├── prioritization.md
│           └── operations.md
├── SESSION_LOG.md
├── DECISIONS.md
├── JOURNAL.md
└── ARCHIVE.md
```

**VS Code:**
```
your-project/
├── .agentic/
│   ├── EXECUTION_KERNEL.md
│   ├── core/
│   │   └── orchestrator.md
│   └── tools/
│       └── INTERFACES.md
├── .github/
│   ├── copilot-instructions.md         ← always active
│   └── prompts/
│       ├── session-open.prompt.md
│       ├── session-close.prompt.md
│       ├── plan.prompt.md
│       ├── brainstorm.prompt.md
│       ├── implement.prompt.md
│       ├── review.prompt.md
│       ├── diagnose.prompt.md
│       ├── explain.prompt.md
│       └── experts/
│           ├── architecture.prompt.md
│           ├── framing.prompt.md
│           ├── training.prompt.md
│           ├── data.prompt.md
│           ├── evaluation.prompt.md
│           ├── codebase.prompt.md
│           ├── prioritization.prompt.md
│           └── operations.prompt.md
├── SESSION_LOG.md
├── DECISIONS.md
├── JOURNAL.md
├── ARCHIVE.md
└── plans/
```

---

## Prompt reference

| Prompt | When to use |
|--------|-------------|
| `session-open` | Start of every session. Reads logs, reports state, asks what we're doing. |
| `session-close` | End of every session. Reflection questions, digest, archive, log reset. |
| `plan` | Build a detailed markdown execution plan with atomic steps and acceptance checks. |
| `brainstorm` | Thinking through a problem, direction, or idea. Adaptive — works with formed views or blank slates. |
| `implement` | Implementation with stopping points, honest result examination, and chat summary. |
| `review` | Three modes: `debug` (diagnose errors), `validate` (adversarial result review), `full` (complete review). |
| `diagnose` | When something is not working. Goes bottom-up through the stack. Never suggests surface fixes first. |
| `explain` | On-demand explanation of code, results, or decisions. Ends with a calibrating question. |
| `experts/architecture` | Architecture selection — full landscape, failure-mode-first, searches literature. |
| `experts/framing` | Problem reframing — is this the right task, is there a better decomposition? |
| `experts/training` | Training design — baselines, loss functions, dynamics monitoring, convergence diagnosis. |
| `experts/data` | Data pipelines — splits for correlated data, missing data, normalization, multi-source combination. |
| `experts/evaluation` | Evaluation integrity gate — validates claim trustworthiness and returns ship/iterate/rollback. |
| `experts/codebase` | Codebase quality gate — boundary/debt checks and safe sequencing before commit. |
| `experts/prioritization` | Prioritization gate — ranks next actions by impact, confidence, effort, and risk. |
| `experts/operations` | Operations gate — run reproducibility, resume safety, and environment health checks. |

---

## End-to-end behavior walkthrough

The orchestration layer is always-on. You do not need to remember extra commands for it.

### Example 1 — direct build request

User request:
```text
"Implement feature X in module Y and keep tests green."
```

Expected behavior:
1. Router classifies this as a build/change task.
2. Execution flows through implement behavior.
3. Agent runs atomic plan -> act -> observe -> reflect cycles.
4. Each cycle produces evidence (small relevant check output).
5. If changes cross boundaries, codebase expert gate runs before final commit recommendation.

### Example 2 — direct failure/debug request

User request:
```text
"Training loss goes to NaN after epoch 3."
```

Expected behavior:
1. Router classifies this as debug/failure.
2. Execution starts in diagnose behavior first.
3. Diagnosis follows bottom-up hierarchy before suggesting tuning.
4. If root cause fix introduces structural risk, codebase gate is invoked.
5. If fix claim is non-trivial, evaluation gate checks trustworthiness before acceptance.

### Example 3 — direct validation/trust request

User request:
```text
"Can we trust this +3.2% improvement over baseline?"
```

Expected behavior:
1. Router classifies this as validate/claim.
2. Execution starts in review validate behavior.
3. Evaluation expert scores risk, claim validity, and uncertainty.
4. Output returns explicit decision: ship, iterate, or rollback.

### What "seamless" means operationally

- Direct asks and prompt-invoked flows use the same kernel and orchestrator contracts.
- Experts are invoked by trigger conditions, not by role theater.
- Every meaningful claim carries evidence and explicit uncertainty.
- Escalation is automatic when retries fail or integrity risk is detected.

---

## Practical session flow (what you do, what the system does)

This is the shortest reliable way to run a full session with the new architecture.

### 1) Start with session-open

You run:
```bash
@session-open
```

System behavior:
- Reads logs and relevant repo context
- Loads orchestration contracts from `.agentic/` if installed
- Locks scope for this session before coding starts

### 2) If something is unclear, brainstorm first

You run:
```bash
@brainstorm
```

System behavior:
- Surfaces candidate causes/options
- Keeps focus on falsifiable checks
- Helps choose the next atomic move

### 3) Plan the strategy with built-in tools

You ask naturally in chat, for example:
```text
"Plan a minimal-risk strategy to fix this and verify it."
```

System behavior:
- Router classifies this as planning/strategy
- Produces atomic steps with explicit acceptance checks
- Selects tool-like actions (navigate, edit_atomic, test_quick, verify_intent)

### 4) Implement the plan

You run:
```bash
@implement
```

System behavior:
- Executes plan -> act -> observe -> reflect per atomic unit
- Runs the smallest relevant check after each unit
- Escalates automatically when needed:
	- repeated failure -> diagnose
	- claim trust uncertainty -> evaluation expert
	- cross-boundary risk -> codebase expert

### 5) Review and decide

You run:
```bash
@review -- validate: <claim>
```

System behavior:
- Verifies evidence quality and intent match
- Applies evaluation gate for non-trivial claims
- Returns explicit decision: ship, iterate, or rollback

### 6) Close the session

You run:
```bash
@session-close
```

System behavior:
- Records decisions, uncertainty, and next step
- Archives session context cleanly for the next run

---

## Updating repos where you already installed ML-Agents

If you installed this workflow in other repos before these changes, use one of these paths.

### Option A — update one target repo (recommended)

From the root of the target repo:
```bash
bash ~/ML-Agents/update.sh
```

What this does:
1. Pulls latest changes in your local `~/ML-Agents` clone
2. Re-runs installer into the current target repo
3. Backs up replaced workflow files into `.agentic-backup/<timestamp>/`
4. Installs new `.agentic/` contracts and new expert prompts
5. Keeps existing log files (`SESSION_LOG.md`, `DECISIONS.md`, `JOURNAL.md`, `ARCHIVE.md`) untouched

### Option B — update many previously installed repos

Run this from anywhere, after editing `REPOS=(...)` to your paths:
```bash
REPOS=(
	"$HOME/path/to/repo-one"
	"$HOME/path/to/repo-two"
	"$HOME/path/to/repo-three"
)

for repo in "${REPOS[@]}"; do
	echo "Updating $repo"
	(cd "$repo" && bash "$HOME/ML-Agents/update.sh")
done
```

### After update: quick verification in each repo

From each target repo root:
```bash
ls -R .agentic
```

You should see:
- `.agentic/EXECUTION_KERNEL.md`
- `.agentic/core/orchestrator.md`
- `.agentic/tools/INTERFACES.md`

And under prompts, you should now have experts for:
- evaluation
- codebase
- prioritization
- operations

---

## Conflict handling

If the installer finds a file in your repo that conflicts with one it wants to install:

1. Your file is moved to `.agentic-backup/YYYY-MM-DD_HH-MM/<original_path>`
2. The workflow file is installed in its place
3. Nothing is deleted

To review what changed:
```bash
diff .agentic-backup/YYYY-MM-DD_HH-MM/.cursor/prompts/implement.md .cursor/prompts/implement.md
```

To restore your original:
```bash
cp .agentic-backup/YYYY-MM-DD_HH-MM/.cursor/prompts/implement.md .cursor/prompts/implement.md
```

---

## Keeping project-specific prompts

The installer only touches files that exist in this repo. Any prompts or rules you have in `.cursor/prompts/` or `.github/prompts/` that are not in this repo are left completely untouched. You can keep project-specific prompts alongside the workflow prompts freely.

---

## Log files

The four log files (`SESSION_LOG.md`, `DECISIONS.md`, `JOURNAL.md`, `ARCHIVE.md`) are installed once as blank templates and then maintained by the agent during sessions. The installer will never overwrite them once they contain real data — they belong to your project, not to this repo.
