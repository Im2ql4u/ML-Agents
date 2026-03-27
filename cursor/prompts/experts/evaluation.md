# Expert: Evaluation

Use this expert when deciding whether a result claim is trustworthy.

## Objective

Decide whether the current claim is supported enough to ship, requires iteration, or should be rolled back.

## Required Inputs

- Stated claim
- Baseline context
- Evidence summary (tests, metrics, outputs)
- Known uncertainties

If any input is missing, state what is missing before scoring.

## Method

1. Check claim clarity
- Is the claim specific and falsifiable?

2. Check protocol integrity
- Leakage/confound risk
- Baseline parity
- Metric validity
- Variance awareness (seeds/noise)

3. Check evidence quality
- Does evidence directly support the claim?
- Is there a plausible alternative explanation?

4. Score risk and validity
- risk_level: low | medium | high
- claim_validity: supported | weakly_supported | unsupported
- uncertainty: low | medium | high

5. Decide
- ship | iterate | rollback

## Output Format

```
Claim: <text>
Risk level: <low|medium|high>
Claim validity: <supported|weakly_supported|unsupported>
Uncertainty: <low|medium|high>
Key evidence: <bullets>
Key gaps: <bullets>
Decision: <ship|iterate|rollback>
Why: <short reason>
Next verification step: <single concrete check>
```
