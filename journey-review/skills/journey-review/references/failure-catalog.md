# Journey failure catalog

Read this after execution to broaden analysis, not to turn untested hypotheses into findings. A category needs evidence before it becomes a confirmed defect.

## Severity

- **P0 — Critical:** Data loss, corruption, unauthorized access, irreversible harm, or a core business invariant is violated.
- **P1 — Journey-breaking:** The requested task cannot complete, the final business state is wrong, or a required recovery path makes the task effectively unusable.
- **P2 — Material friction:** The task can complete, but misleading feedback, hidden state, avoidable rework, or an unreasonable workaround materially harms the user.
- **P3 — Improvement:** A useful polish or design suggestion with no demonstrated material effect on task completion.

Severity reflects impact, not how difficult the implementation appears. Do not inflate a P2/P3 suggestion into a failed journey.

## Signals

| Category | Signal to investigate | Typical evidence | Common severity |
| --- | --- | --- | --- |
| Missing transition | The actor completes a step but no route or state transition supports the next required action | Navigation dead end, unchanged status, absent next action | P1 |
| Hidden transition | The transition exists only through an unrelated role, direct URL, stale page, or undocumented action | Comparison of actor views, refresh/relogin evidence | P1 or P2 |
| Object / role boundary | The actor can act on the wrong object, or cannot act on an owned object | Cross-tenant or ownership query, permission response | P0 or P1 |
| Write acknowledged but not applied | Submission succeeds but an independent read shows absent, stale, or incorrect state | Write response paired with later UI/API/query read-back | P1 |
| Partial or inconsistent commit | Parent and child state, counts, balances, or related views disagree | Exact postcondition comparison across reads | P0 or P1 |
| False completion | UI says complete while the business state remains pending, failed, or empty | Immediate and refreshed status plus independent query | P1 or P2 |
| Duplicate / retry behavior | Refresh, back, double-click, timeout retry, or repeated request creates duplicates or loses state | Before/after counts, idempotency evidence, request IDs | P0–P2 |
| Interruption / recovery | Reload, session expiry, rejection, or temporary failure discards safe progress or traps the actor | Interrupted run followed by a recovery run | P1 or P2 |
| Feedback / discoverability | The goal is achievable but requires unexplained knowledge or provides misleading next steps | Screen recording, copy, actor observations | P2 or P3 |
| Scope / trust boundary | A single journey silently assumes another role, tenant, environment, or privileged setup | Task-card comparison and actor/session evidence | P0–P2 |

## Review questions

### Failure Analyst

- Which exact transition or postcondition failed?
- Does an independent read disprove the apparent success?
- Are several screens showing one root failure rather than separate defects?
- Could timing, caching, tenancy, or stale state explain contradictory reads?

### Product Challenger

- Can the actor infer the next action from product-visible information alone?
- Does the flow satisfy the stated goal, or merely exercise the implemented controls?
- Is a workaround reasonable and discoverable, or does it conceal a broken journey?
- Is the observation a confirmed contract violation, material friction, or only a preference?

### Recovery Challenger

- What happens after refresh, back, retry, duplicate submission, rejection, or session interruption?
- Can the actor distinguish safe retry from duplicate effects?
- Does recovery preserve ownership, entered data, and business invariants?
- Was the recovery path actually executed? If not, record it as a residual risk.

## Evidence discipline

- Pair every write with a later independent read.
- Capture exact values and counts when they matter; `object exists` is usually too weak.
- Distinguish product defects from fixture, deployment, account, and network failures.
- Never promote an untested review question into a finding.
- Never demote a reproduced defect because existing tests pass or the implementation looks intentional.
