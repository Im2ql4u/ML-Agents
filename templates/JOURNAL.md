# Journal

Research journal. Each entry documents an experiment, a significant result, or a meaningful shift in understanding. Written as if read by a technically capable person who has not been following the project.

Entries older than 8 are compressed into ## Earlier Experiments by session-close. Preserve conclusions, discard step-by-step detail.

---

## Format

```
### [YYYY-MM-DD] — <experiment title>
**Motivation:** <what question were we trying to answer>
**Method:** <what was done — concisely but precisely>
**Results:** <numbers, with units always>
**What the numbers actually mean:** <interpretation separate from the numbers>
**What we cannot explain:** <anomalies or uncertainties>
**Caveats:** <what might be wrong with this interpretation>
**What a skeptic would say:** <honest critique>
**Output reference:** results/YYYY-MM-DD_<n>/
**Next question:** <what this makes us want to investigate>
```

## Negative / Failed / Inconclusive format

```
### [YYYY-MM-DD] — NEGATIVE: <what was tried>
**Hypothesis tested:** <specific claim under test>
**Method:** <what was done>
**Expected result:** <what would have confirmed the hypothesis>
**Actual result:** <what actually happened>
**Why it failed:** <root cause, or best current understanding>
**What this rules out:** <directions this failure eliminates>
**What this does NOT rule out:** <what remains plausible>
**Severity:** dead-end | needs-rethink | minor-setback
**Lessons for future work:** <what to remember next time>
**Output reference:** results/YYYY-MM-DD_<n>/ or n/a
```

## Comparison format

Use this when 2+ experiments address the same question and a cross-run verdict is needed.

```
## Comparison: <question being answered>
Date: YYYY-MM-DD
Experiments compared: <entry refs>

| Dimension       | Experiment A | Experiment B | Experiment C |
|-----------------|--------------|--------------|--------------|
| Method          | <short>      | <short>      | <short>      |
| Key metric      | <value>      | <value>      | <value>      |
| Secondary metric| <value>      | <value>      | <value>      |
| Training cost   | <value>      | <value>      | <value>      |
| Failure modes   | <short>      | <short>      | <short>      |

**Winner and why:** <evidence-based verdict>
**What this does NOT settle:** <remaining uncertainty>
**What a skeptic would say:** <critique of the comparison itself>
**Recommended next experiment:** <next most informative step>
```

---

*(No entries yet.)*
