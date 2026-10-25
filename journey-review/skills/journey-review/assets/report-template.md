# Journey review report template

Keep the report compact while preserving the evidence chain. Add one journey section per selected journey and one postcondition row per postcondition. Use `N/A` only with a reason. Do not add another overall token after the final line.

```markdown
# Journey Review: <scope>

## Task card
- Actor: <single role, tenant, permissions>
- Goal: <user task>
- Start state: <known state>
- Environment / build: <target and version>
- Allowed setup: <fixtures and resets>
- Out of scope: <boundaries>
- Assumptions / unresolved requirements: <items or none>
- Role independence: <fresh workers or shared-context limitation>

## Executive result
- Passed journeys: <count and names>
- Failed journeys: <count and names>
- Blocked journeys: <count and names>
- Confirmed findings: <P0 / P1 / P2 / P3 counts>
- Unexecuted risks: <count and brief reason>

## Findings

### JR-1 <title>
- Severity: <P0 | P1 | P2 | P3>
- Journeys: <affected journeys>
- Actor / start state: <context>
- Trigger: <smallest reproduction action>
- Expected: <product requirement>
- Actual: <observed behavior>
- Business impact: <user and final-state consequence>
- Evidence: <E# references>
- Suspected location: <file, component, or endpoint; optional and never a substitute for evidence>
- Scope note: <confirmed defect, friction, or improvement>

## Journey evidence

### <Journey name>
- Actor / goal: <one actor and task>
- Result: <JOURNEY-PASS | JOURNEY-FAIL | JOURNEY-BLOCKED>
- Block reason: <one allowed reason or N/A>

| Step | Action | Expected | Observed | Evidence |
| --- | --- | --- | --- | --- |
| 1 | <operation> | <expectation> | <actual result> | <E1> |

| Postcondition | Expected | Read-back | Result | Evidence |
| --- | --- | --- | --- | --- |
| PC-1 | <exact state> | <method> | <PASS / FAIL / BLOCKED> | <E#> |

## Not executed
- <risk or journey>: <BLOCKED with one allowed reason, or explicitly out of scope>

## Coverage and limitations
- <fresh-context limitations, untested actors, approximate observations, or residual risks>

JOURNEY-<PASS | FAIL | BLOCKED>
```
