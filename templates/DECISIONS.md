# Decisions

Permanent, append-only record of architectural and methodological decisions. Never delete or rewrite. If a decision was reversed, add a new entry explaining why.

Only write entries for genuine decisions. Not every small implementation choice. Quality over completeness.

---

## Format

```
### [YYYY-MM-DD] — <short title>
**Decision:** <what was chosen>
**Alternatives considered:** <what else was on the table>
**Reasoning:** <why this, not the alternatives>
**Constraints introduced:** <what this makes harder going forward>
**Confidence:** high / medium / low
```

---

*(No entries yet.)*

---

## Negative Memory — Failed Approaches and Anti-Patterns

Append-only record of approaches that were tried and failed, or patterns that should not be repeated. Consulted by session-open before proposing direction. Prevents the most expensive failure mode in multi-session work: rediscovering dead ends.

### Format

```
### [YYYY-MM-DD] — FAILED: <what was tried>
**What:** <the approach or pattern that was attempted>
**Why it failed:** <root cause or best understanding>
**Evidence:** <concrete output, error, or metric that proves failure>
**What to do instead:** <known better alternative, or "unknown — needs investigation">
**Severity:** dead-end | needs-rethink | minor-setback
```

### Compaction rule

If the same failure pattern recurs 3+ times (same root cause across different sessions), promote it to a permanent constraint entry in the Decisions section above with a note referencing the negative memory entries.

### Retrieval rule

Before any plan or brainstorm, session-open must check this section for prior failures related to the current problem. If a match is found, it must be surfaced in the synthesis and the new approach must explicitly avoid the documented failure.

---

*(No entries yet.)*
