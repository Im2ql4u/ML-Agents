---
name: memory-consolidation
description: 'Compress and promote session findings into durable project memory. Use at session boundaries to keep memory layered, compact, and retrievable.'
---

# Memory Consolidation

---

## When to Use

- At session close (Full Close triggers this automatically; Quick Close triggers the lightweight variant)
- When SESSION_LOG.md, JOURNAL.md, or ARCHIVE.md are growing large and retrieval quality is degrading
- When the same pattern has appeared in 3+ sessions without being captured as a constraint
- When starting a new major phase and prior context needs compaction

---

## Procedure

### Step 1 — Inventory current memory state

Read these files and note their size and recency:

- `CONSTRAINTS.md` — if it exists, note how many verified/suspected entries
- `DECISIONS.md` — full file, especially `## Negative Memory`
- `JOURNAL.md` — all entries
- `ARCHIVE.md` — last 5 entries
- `SESSION_LOG.md` — current state

Report: "Memory state: CONSTRAINTS has N verified / M suspected entries. JOURNAL has K entries. ARCHIVE has L entries. Negative Memory has P entries."

### Step 2 — Extract candidate patterns

Scan JOURNAL.md, ARCHIVE.md, and DECISIONS.md for:

1. **Repeated findings** — the same observation, failure mode, or constraint appearing in 2+ sessions
2. **Stable decisions** — choices that have held across 3+ sessions without being revisited
3. **Confirmed negative patterns** — failures in Negative Memory with severity `dead-end` or recurrence count >= 2
4. **Superseded constraints** — entries in CONSTRAINTS.md that conflict with newer evidence

For each candidate, note:
- The pattern/constraint
- How many sessions it appeared in
- The concrete evidence supporting it
- Whether it contradicts anything already in CONSTRAINTS.md

### Step 3 — Promote to CONSTRAINTS.md

**Promotion rules:**

- A pattern observed in 3+ sessions with consistent evidence → add to `## Verified Constraints`
- A pattern observed in 1–2 sessions → add to `## Suspected Constraints` (or update occurrence count if already there)
- A Negative Memory entry with 3+ recurrences → promote to `## Verified Constraints` as a negative constraint (format: "Do not <X> because <evidence>")
- If new evidence contradicts an existing verified constraint → move the old entry to `## Retired Constraints` with reason, add the new one to Suspected

For each promoted constraint, write:
```
- <constraint statement>: <evidence summary>, verified <YYYY-MM-DD>
```

### Step 4 — Compress episodic memory

If JOURNAL.md has more than 8 entries:
- Compress the oldest 4 into an `## Earlier Experiments` summary block
- Preserve: what questions were asked, what was concluded, what failed
- Remove individual entries after compression

If ARCHIVE.md has more than 10 entries:
- Compress the oldest 5 into an `## Older History` block
- Preserve: project trajectory, key decisions, current state at time of compression
- Remove individual entries after compression

### Step 5 — Prune Negative Memory

Review each entry in DECISIONS.md → `## Negative Memory`:

- If the failure cause has been resolved by a later decision or code change → remove the entry and note why in a one-line comment
- If the failure is still relevant → keep it
- If the failure has been promoted to a CONSTRAINTS.md verified constraint → remove from Negative Memory (it now lives in semantic memory)

### Step 6 — Export working state summary

Produce a compact block (max 50 lines) that captures the current cognitive state of the project. This is appended to SESSION_LOG.md as `## Working State Snapshot`:

```
## Working State Snapshot (updated <YYYY-MM-DD>)

### What we know (verified)
- <key verified facts, max 5>

### What we believe (suspected, not yet verified)
- <key suspected facts, max 3>

### What has failed (do not repeat)
- <active negative constraints, max 3>

### Current trajectory
- <one sentence: where the project is heading>

### Biggest open risk
- <one sentence: what could invalidate current direction>
```

---

## Lightweight Variant (for Quick Close)

When invoked during Quick Close, run only:

- Step 2 (scan for candidates — but only in this session's outputs, not full history)
- Step 3 (promote any candidates that cross the threshold)
- Step 6 (export working state summary)

Skip Steps 1, 4, 5 to keep the close fast.

---

## Report Template

```
Memory consolidation complete.

**CONSTRAINTS.md updates:**
- Promoted to verified: <n> (<list>)
- Added to suspected: <n> (<list>)
- Retired: <n> (<list>)

**Episodic compression:**
- JOURNAL.md: <compressed N entries / no compression needed>
- ARCHIVE.md: <compressed N entries / no compression needed>

**Negative Memory pruning:**
- Removed: <n> (resolved or promoted)
- Kept: <n> (still active)

**Working state snapshot:** written to SESSION_LOG.md
```

---

## Acceptance Criteria

- [ ] CONSTRAINTS.md exists and has been updated (or confirmed current)
- [ ] No pattern with 3+ occurrences remains only in episodic memory
- [ ] No Negative Memory entry duplicates a verified constraint
- [ ] JOURNAL.md and ARCHIVE.md are within size limits
- [ ] Working state snapshot is current and under 50 lines
- [ ] All promotions cite concrete evidence, not just "appeared multiple times"
