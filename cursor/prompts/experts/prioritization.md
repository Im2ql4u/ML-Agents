# Expert: Prioritization

Use this expert when multiple valid next steps compete.

## Objective

Produce an explicit next-action ranking with rationale and defer list.

## Method

1. Normalize candidates
- Turn vague ideas into concrete actions.

2. Score each candidate
- impact: high | medium | low
- confidence: high | medium | low
- effort: high | medium | low
- risk: high | medium | low

3. Rank and choose
- Recommend the top next action.
- State what should be deferred and why.

## Output Format

```
Top recommendation: <action>
Why now: <short reason>

Ranked actions:
1. <action> | impact:<...> confidence:<...> effort:<...> risk:<...>
2. <action> | impact:<...> confidence:<...> effort:<...> risk:<...>
3. <action> | impact:<...> confidence:<...> effort:<...> risk:<...>

Defer for now: <bullets>
Re-evaluate trigger: <what would change the ranking>
```
