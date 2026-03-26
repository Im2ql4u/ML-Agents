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
- Installs log templates (`SESSION_LOG.md`, `DECISIONS.md`, `JOURNAL.md`, `ARCHIVE.md`) if they do not already exist
- If any file it would install already exists in your repo, it **moves your existing file** to `.agentic-backup/YYYY-MM-DD_HH-MM/` before installing — nothing is ever deleted
- Adds `.agentic-backup/` to `.gitignore` automatically
- Never overwrites live log files

---

## Update

When this repo is updated, pull and re-run from your project repo:

```bash
bash ~/ML-Agents/update.sh
```

This pulls the latest workflow changes and re-runs the installer. Your existing files that differ from the new versions are backed up before being replaced.

---

## File layout after install

**Cursor:**
```
your-project/
├── .cursor/
│   ├── rules/
│   │   └── core.mdc                    ← always active
│   └── prompts/
│       ├── session-open.md
│       ├── session-close.md
│       ├── brainstorm.md
│       ├── plan.md
│       ├── implement.md
│       ├── review.md
│       ├── diagnose.md
│       ├── explain.md
│       └── experts/
│           ├── architecture.md
│           ├── framing.md
│           ├── training.md
│           └── data.md
├── SESSION_LOG.md
├── DECISIONS.md
├── JOURNAL.md
└── ARCHIVE.md
```

**VS Code:**
```
your-project/
├── .github/
│   ├── copilot-instructions.md         ← always active
│   └── prompts/
│       ├── session-open.prompt.md
│       ├── session-close.prompt.md
│       ├── brainstorm.prompt.md
│       ├── plan.prompt.md
│       ├── implement.prompt.md
│       ├── review.prompt.md
│       ├── diagnose.prompt.md
│       ├── explain.prompt.md
│       └── experts/
│           ├── architecture.prompt.md
│           ├── framing.prompt.md
│           ├── training.prompt.md
│           └── data.prompt.md
├── SESSION_LOG.md
├── DECISIONS.md
├── JOURNAL.md
└── ARCHIVE.md
```

---

## Prompt reference

| Prompt | When to use |
|--------|-------------|
| `session-open` | Start of every session. Reads logs, reports state, asks what we're doing. |
| `session-close` | End of every session. Reflection questions, digest, archive, log reset. |
| `brainstorm` | Thinking through a problem, direction, or idea. Adaptive — works with formed views or blank slates. |
| `plan` | After direction is established. Produces a full engineering specification. Use in Plan Mode. |
| `implement` | Implementation with stopping points, honest result examination, and chat summary. |
| `review` | Three modes: `debug` (diagnose errors), `validate` (adversarial result review), `full` (complete review). |
| `diagnose` | When something is not working. Goes bottom-up through the stack. Never suggests surface fixes first. |
| `explain` | On-demand explanation of code, results, or decisions. Ends with a calibrating question. |
| `experts/architecture` | Architecture selection — full landscape, failure-mode-first, searches literature. |
| `experts/framing` | Problem reframing — is this the right task, is there a better decomposition? |
| `experts/training` | Training design — baselines, loss functions, dynamics monitoring, convergence diagnosis. |
| `experts/data` | Data pipelines — splits for correlated data, missing data, normalization, multi-source combination. |

---

## Conflict handling

If the installer finds a file in your repo that conflicts with one it wants to install:

1. Your file is moved to `.agentic-backup/YYYY-MM-DD_HH-MM/<original_path>`
2. The workflow file is installed in its place
3. Nothing is deleted

To review what changed:
```bash
diff .agentic-backup/YYYY-MM-DD_HH-MM/.cursor/prompts/plan.md .cursor/prompts/plan.md
```

To restore your original:
```bash
cp .agentic-backup/YYYY-MM-DD_HH-MM/.cursor/prompts/plan.md .cursor/prompts/plan.md
```

---

## Keeping project-specific prompts

The installer only touches files that exist in this repo. Any prompts or rules you have in `.cursor/prompts/` or `.github/prompts/` that are not in this repo are left completely untouched. You can keep project-specific prompts alongside the workflow prompts freely.

---

## Log files

The four log files (`SESSION_LOG.md`, `DECISIONS.md`, `JOURNAL.md`, `ARCHIVE.md`) are installed once as blank templates and then maintained by the agent during sessions. The installer will never overwrite them once they contain real data — they belong to your project, not to this repo.
