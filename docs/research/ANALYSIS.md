# ML-Agents: Sources, Alignment, and Open Problems

Date: 2025-03-31

---

## 1. Sources used and how we align with them

### 1.1 Anthropic — "Building Effective Agents" (2025-01)

**What it says:** Use the simplest architecture that works. Prefer augmented LLM calls + tool use over multi-agent orchestration. Agents are just LLMs in a loop with tools. Be explicit about when to act versus suggest. Three critical patterns: (1) workflows with fixed orchestration, (2) agents with model-driven control, (3) tool use as the bridge.

**How we align:**
- Lean core (session-open → plan → implement → review → session-close) is exactly "simplest architecture that works."
- Execution Kernel's plan→act→observe→reflect loop mirrors Anthropic's augmented-LLM-in-a-loop pattern.
- Experts are optional escalation, not mandatory routing — matches "add complexity only when needed."
- After our rewrite, prompts address the agent directly ("You are..."), matching Anthropic's advice to be explicit about action.

**Discrepancy / concern:**
Anthropic's guidance was written assuming Claude 3.5 Sonnet / Opus-class models. Their advice to "give Claude room to reason rather than prescribing steps" assumes strong planning ability. **Weaker models (GPT-4o-mini, Claude Haiku, Gemini Flash, local models) often need the opposite: more rigid step-by-step scaffolding.** Our prompts currently assume a strong model throughout. There is no adaptation layer. A user running this with a weaker model will get worse results than they would with simpler, more prescriptive prompts.

**Age concern:** Published January 2025. Still highly relevant — Anthropic continues to update this as their canonical guidance. ✅ Current.

---

### 1.2 OpenAI — "GPT-4.1 Prompting Guide" (2025-04)

**What it says:** Three short persistence/tool-use/planning sentences at the start of a system prompt raised SWE-bench scores by ~20%. Agentic prompting should: (1) set persistence expectations ("Keep going until fully resolved"), (2) mandate tool use over guessing, (3) require planning before action. Also emphasizes that `#`-delimited markdown sections are more effective than prose for instruction following.

**How we align:**
- Our implement prompt now opens with persistence framing: "Keep going until the plan is executed, tested, and results are examined. Do not stop after writing code."
- The Setup section mandates reading the plan and extracting structure before coding — matches the planning-first guidance.
- We use `##`-delimited sections throughout.

**Discrepancy / concern:**
OpenAI's guide specifically tested with GPT-4.1, which is a strong coding model. The "three sentences" technique is calibrated to that model family. **Claude and Gemini may respond differently to the same persistence framing.** We have not tested cross-model. Additionally, the GPT-4.1 guide emphasizes `<tool_call>` XML formatting for structured tool invocation — we don't do this because we rely on editor-native tool dispatch (Cursor/VS Code), not raw API calls. This is fine but means our "tools" (INTERFACES.md) are aspirational contracts, not actual callable tools.

**Age concern:** April 2025. Very current. ✅

---

### 1.3 Cursor Documentation (2025, ongoing)

**What it says:** `.cursor/rules/` files with `alwaysApply: true` are injected into every context. `.cursor/prompts/` files are invokable via `@prompt-name`. The model sees the prompt content as system-level instructions.

**How we align:**
- `core.mdc` with `alwaysApply: true` sets the always-on rules.
- Prompt files in `.cursor/prompts/` match Cursor's invocation model exactly.

**Discrepancy / concern:**
Cursor's context window management is opaque. When the user invokes `@implement.md`, Cursor injects that file's content, but it is unclear how much of `core.mdc`, `EXECUTION_KERNEL.md`, and `orchestrator.md` are also in context. **If the context is too large, Cursor may silently truncate.** We reference multiple infrastructure files (kernel, orchestrator, interfaces) from within prompts, but we have no guarantee the agent actually reads them. This is likely why experts and tools feel like they are not being called — they may literally not be in the model's context.

**Age concern:** Cursor docs update continuously. ✅ Current.

---

### 1.4 VS Code Copilot Chat — Prompt Files (2025, ongoing)

**What it says:** `.github/copilot-instructions.md` is always injected. `.github/prompts/*.prompt.md` files with YAML frontmatter (`agent: agent`) are invokable in chat. `${input:...}` provides user input variables.

**How we align:**
- `vscode/copilot-instructions.md` maps to `.github/copilot-instructions.md`.
- All prompt files have correct frontmatter.
- Parity checker ensures Cursor and VS Code stay aligned.

**Discrepancy / concern:**
**VS Code Copilot does not automatically include files referenced inside a prompt.** When implement.prompt.md says "Read the confirmed plan in full," the agent does not have the plan file in context unless the user explicitly attaches it with `#file:plans/...`. This is your exact experience — **the planner writes a plan, but the implementer doesn't read it unless you add it manually.** This is a platform limitation, not a prompt bug, but our prompts do not acknowledge it or instruct the user to attach the plan.

Similarly, the orchestrator, kernel, and interfaces files referenced from prompts are almost certainly never loaded in VS Code Copilot unless manually attached. **Every `Follow EXECUTION_KERNEL.md` instruction in our prompts is dead text in VS Code.**

**Age concern:** ✅ Current platform.

---

### 1.5 Cline / Roo Code (2025)

**What it says:** Memory bank pattern — structured markdown files that the agent reads at session start to restore context. Emphasizes explicit context restoration rather than relying on conversation history.

**How we align:**
- `SESSION_LOG.md`, `ARCHIVE.md`, `JOURNAL.md`, `DECISIONS.md` serve this purpose.
- Session-open reads these to restore context.

**Discrepancy / concern:**
Same context-loading issue as VS Code above. The session-open prompt tells the agent to read these files, but in VS Code Copilot the agent must use tool calls to read them (which it may or may not do). In Cursor, file reading is more natural but still not guaranteed. **We assume the agent will proactively read files it's told to read — this assumption is fragile.**

**Age concern:** ✅ Current.

---

### 1.6 SWE-agent / SWE-bench (2024-2025)

**What it says:** Give agents good interfaces to files, tests, and commands. The key to performance is execution quality, not agent personality. SWE-bench Verified showed that evaluation quality dramatically changes measured performance.

**How we align:**
- Execution Kernel enforces atomic edit→test→verify cycles.
- Result honesty protocol in review and implement.
- Foundation checks before trusting results.

**Discrepancy / concern:**
SWE-agent's interface is a custom shell with specific commands (`find_file`, `open`, `edit`, `submit`). Our tools/INTERFACES.md defines similar abstractions but **they are not executable.** They are documentation of what the agent *should* do, mapped onto whatever the editor provides. There is no enforcement. The agent may or may not follow the interface contracts.

**Age concern:** SWE-agent v0.7+ from late 2024/early 2025. SWE-bench Verified from late 2024. ✅ Reasonably current.

---

### 1.7 ReAct and Reflexion (2023-2024)

**What it says:** Interleave reasoning with action and observation (ReAct). Use self-correction across attempts based on concrete feedback (Reflexion).

**How we align:**
- Execution Kernel loop (plan→act→observe→reflect) is directly ReAct-inspired.
- Diagnose prompt's hypothesis ledger with "evidence for / evidence against / falsification check" is Reflexion-inspired.

**Discrepancy / concern:**
These papers are from 2023 and tested on GPT-3.5/GPT-4 era models. Modern models (Claude 3.5+, GPT-4o+, Gemini 1.5+) have internalized much of this behavior. **Explicitly prompting for ReAct-style "Thought: / Action: / Observation:" formatting may actually hurt performance on strong models** by forcing them into a rigid output format when they reason better internally. Our execution kernel doesn't force this format (good), but the overhead of the kernel's 4-gate system may be unnecessary for strong models on simple tasks.

**Age concern:** ⚠️ 2023. Still conceptually valid but the specific prompting strategies need updating for 2025-era models.

---

### 1.8 Aider (2024-2025)

**What it says:** Disciplined coding loop around git: edit, run tests, inspect diff, repeat. Tight integration with existing repos. Small, reviewable changes.

**How we align:**
- Git section in implement.md enforces this pattern.
- Atomic cycles with commit-after-pass.

**Discrepancy / concern:**
Aider works because it has actual tool integration — it can run `git diff`, execute tests, and parse results programmatically. **Our prompts describe the Aider philosophy but rely on the agent voluntarily doing these things.** Whether it actually runs `git status` before starting depends on the model and the editor.

**Age concern:** ✅ Current, actively maintained.

---

### 1.9 LangGraph / AutoGen (2024-2025)

**What it says:** Separate orchestration from agent behavior. Emphasize long-running reliability, resumability, and human interrupts.

**How we align:**
- Orchestrator contract separates routing from execution.
- Plan's `## Current State` enables resume.

**Discrepancy / concern:**
These are runtime frameworks with actual state machines. Our orchestrator is a markdown document that describes a state model. **There is no runtime enforcement.** The orchestrator contract is only as good as the model's willingness to follow it, which in practice (especially in VS Code) is low because it's likely not even in context.

**Age concern:** ✅ Current.

---

### 1.10 MetaGPT (2023-2024)

**What it says:** SOP-style structured handoffs between role-based agents.

**How we align:**
- Plan → implement → review handoff with structured artifacts.
- Fixed output schemas in results reports.

**Discrepancy / concern:**
MetaGPT's value comes from actual multi-agent execution with message passing. **We simulate this pattern within single-agent conversations.** The "handoff" between planner and implementer is the user switching prompts, not an automated pipeline. This means state is lost between prompts unless the user manually carries it.

**Age concern:** ⚠️ Original paper from 2023. Updated versions exist but the core SOP pattern is well-established.

---

## 2. Open problems and honest assessment

### 2.1 The plan→implement handoff is broken in VS Code

**Problem:** The planner writes a plan to `plans/YYYY-MM-DD_*.md`. The implementer says "Read the confirmed plan in full." But VS Code Copilot does not load that file into context automatically. The user must manually attach it with `#file:`.

**This is your most reported friction point** and it's a platform limitation. Cursor handles this better because `@` file references work more naturally, but even there, the agent may not proactively read the plan file without being told the exact path.

**What we should do:** The implement prompt should explicitly say: "If the plan file is not attached to this conversation, ask the user to attach it before proceeding." This is a one-line fix that would eliminate the confusion.

---

### 2.2 The review agent doesn't orient toward the goal

**Problem:** When reviewing results, you find yourself having to ask "how far are we from the goal, what's missing, think about this..." The reviewer should do this automatically.

**Why it happens:** The review prompt's three modes (debug, validate, full) are all backward-looking — they analyze what exists. None of them start with "compare current state to the plan's success criteria." The validate mode checks whether a claim holds, but doesn't proactively assess progress toward the overall objective.

**What we should do:** Add a mandatory first step to all review modes: "Before reviewing, read the active plan and its success criteria. Frame your review against what remains to be achieved, not just what has been done." This turns review from a passive audit into an active progress check.

---

### 2.3 The "Before declaring done" section is confusing for models

**Problem:** The What was done / Decisions made / Workarounds / What I am uncertain about / One question for you section produces vague, loquacious output from agents. The model doesn't know what to put there.

**Why it happens:** These prompts are structured as open-ended fill-in-the-blank. "What I am uncertain about" is an invitation to either say nothing meaningful or enumerate every possible concern. "One question for you" often produces generic questions like "Does this look right?" because the model has no concrete rubric for what makes a good question.

**What we should do:** Make each field more constrained:
- "What was done" → require file:purpose format, max 8 lines
- "Decisions made" → only material decisions, each with "because [one reason]"
- "Workarounds" → only items with a `# TODO` in the codebase, with the file reference
- "What I am uncertain about" → "Name one specific test I would run to increase confidence in this result"
- "One question for you" → "Ask a question whose answer would change what you do next"

More structure = less spaghetti.

---

### 2.4 The experts and tools are probably not being used

**Problem:** You're not sure if the experts or tools (INTERFACES.md) are being invoked. They probably are not.

**Why:**
1. **No forcing function.** The orchestrator says "route to codebase expert when boundaries are crossed" — but nothing enforces this. The model would need to autonomously decide to load and follow another markdown file mid-conversation.
2. **Not in context.** In VS Code, these files are not loaded unless attached. In Cursor, `@experts/evaluation.md` must be explicitly invoked by the user or referenced in the prompt.
3. **Tools are documentation, not executable.** INTERFACES.md describes what `navigate`, `edit_atomic`, `test_quick` should do, but these are not actual tool definitions. The agent uses the editor's built-in tools (file search, edit, terminal) and there's no bridge from our interface spec to those.

**Reality check:** The experts work as documented prompt files that the user invokes manually (`@experts/architecture.md`). They do **not** work as automatically-routed specialists. The orchestrator's routing policy is aspirational — it describes what should happen, but in practice the agent stays in whatever mode it was invoked in.

The tools (INTERFACES.md) are essentially dead. No model in Cursor or VS Code parses them and maps them to editor actions. They serve as philosophical documentation of what good tool use looks like, but they don't affect agent behavior.

---

### 2.5 Small vs. large model calibration

**Problem:** The prompts are written for a strong model (Claude Sonnet/Opus, GPT-4o/4.1). Weaker models need different treatment.

**Specific differences:**

| Aspect | Strong model (Sonnet, 4o, 4.1) | Weak model (Haiku, mini, Flash) |
|--------|-------------------------------|-------------------------------|
| Persistence | Needs a nudge ("keep going") | Needs explicit checkpoints ("after step 3, continue to step 4") |
| Planning | Can plan internally | Needs the plan in context, step by step |
| Tool use | Uses tools proactively | Needs "run this command now" directives |
| Open prompts | Handles "What I am uncertain about" | Produces filler; needs constrained choices |
| Long context | Can hold 100K+ tokens | Degrades after 8-16K; our full implement + kernel + orchestrator may exceed this |
| Self-correction | Adjusts based on feedback | Repeats same mistake; needs explicit "if X happens, do Y" rules |

**What we should do:** At minimum, acknowledge this in README. Ideally, offer a "compact mode" for weaker models — shorter prompts with more explicit step-by-step instructions and fewer open-ended fields. The current prompts assume the agent can hold the full plan + prompt + code + results in context while reasoning about all of them. A 16K-context model cannot do this.

---

### 2.6 tmux / GPU use is conditional, not automatic

**Problem:** Does the agent naturally use tmux and GPUs when available?

**Current state:** The implement prompt says:
- "ETA > 30 min: use tmux" — this is an instruction to the agent, but whether it actually runs `tmux new-session` depends on the model and editor. Cursor agents can run terminal commands. VS Code Copilot agents can too (in agent mode). But the model must decide to do it.
- "Check GPU availability explicitly before training" — same situation. The prompt tells the agent to do it, but doesn't force it.

**Reality:** Strong models in Cursor agent mode will likely follow these instructions because they can execute terminal commands. VS Code Copilot in agent mode can too, but may be less reliable about proactive checks. **Neither platform makes tmux or GPU detection automatic — it's always model-decided.**

The bigger issue: if the model is running inside VS Code terminal and starts a long training run, the terminal may time out or the user may close the window. The tmux instruction is good but relies on the model actually executing it. A more robust approach would be to have the training script itself handle this (daemonize, nohup, etc.) rather than relying on the agent to remember to wrap things in tmux.

---

### 2.7 Results feel "out of context"

**Problem:** When models report results, they focus on the numbers without connecting back to the larger objective.

**Why it happens:** The Results report template has "What was run," "Raw results," "What these results mean" — but it doesn't start with "The plan's objective was X. Here is how these results relate to that objective." The template encourages reporting in isolation.

**What we should do:** Add to the top of the report template:
```
### Plan objective
<One sentence from the plan's ## Objective>

### Where these results fit
<Which plan step(s) these results address. What remains.>
```

This forces contextualization before any numbers are presented.

---

### 2.8 Output is spaghetti — too much cross-linking

**Problem:** The agent links a lot of code everywhere, making the output hard to follow.

**Why it happens:** The prompts reward thoroughness (list every file, reference every change, link to diffs). But they don't enforce hierarchy or brevity. The "What was done" section can become a dump of every file touched, with inline code blocks and cross-references that obscure the narrative.

**What we should do:**
- Cap "What was done" to max 8 lines, one per significant file
- Require a 2-sentence narrative summary before any file lists
- Replace the freeform sections with more structured templates that limit verbosity
- Consider a rule: "If your summary is longer than 15 lines, compress it"

---

## 3. Which sources are too old?

| Source | Date | Verdict |
|--------|------|---------|
| Anthropic "Building Effective Agents" | Jan 2025 | ✅ Current |
| OpenAI GPT-4.1 Prompting Guide | Apr 2025 | ✅ Current |
| Cursor docs | 2025 ongoing | ✅ Current |
| VS Code Copilot prompt files | 2025 ongoing | ✅ Current |
| Cline / Roo Code | 2025 | ✅ Current |
| SWE-agent / SWE-bench | Late 2024 | ✅ Reasonably current |
| Aider | 2024-2025 | ✅ Current |
| LangGraph / AutoGen | 2024-2025 | ✅ Current |
| ReAct (Yao et al.) | Oct 2023 | ⚠️ Conceptually valid, prompting details outdated |
| Reflexion (Shinn et al.) | Jun 2023 | ⚠️ Same — concept good, implementation patterns pre-date current models |
| MetaGPT | Aug 2023 | ⚠️ Core SOP idea valid, multi-agent patterns outdated |

The 2023 papers (ReAct, Reflexion, MetaGPT) informed our design philosophy but their specific prompting techniques were tested on GPT-3.5/early GPT-4. Modern models need less explicit reasoning scaffolding and more action-oriented directives. This shift is reflected in the Anthropic and OpenAI 2025 guides, which both emphasize simplicity over elaborate chain-of-thought structures.

---

## 4. Summary of what should change (not implemented, just noted)

1. **Plan→implement handoff:** Implement prompt should tell the agent to ask for the plan file if not in context. One-line fix.

2. **Review prompt needs goal-orientation:** Add "read the plan's success criteria first" as step 0 in all review modes. The reviewer should track progress, not just audit artifacts.

3. **Tighten the "Before declaring done" section:** Make each field constrained and specific so models produce dense, useful output instead of filler.

4. **Acknowledge the expert routing gap:** Experts work as manual invocations. Automatic routing is aspirational. Document this honestly in README.

5. **Consider removing or simplifying INTERFACES.md and orchestrator.md:** If they're not being loaded into context, they're dead weight that confuses the architecture. Either find a way to enforce them or simplify them into the prompts that actually get loaded.

6. **Add plan context to the results template:** Force the agent to state the objective and where results fit before reporting numbers.

7. **Add model-tier guidance:** Document which models this is tested with and what adjustments smaller models need. Possibly offer compact prompt variants.

8. **Address tmux as defense-in-depth:** The training script itself should handle persistence (nohup, logging to file), not just rely on the agent remembering to use tmux.

9. **Reduce output verbosity:** Cap file lists, require narrative summaries before details, add a "compress if longer than N lines" rule.
