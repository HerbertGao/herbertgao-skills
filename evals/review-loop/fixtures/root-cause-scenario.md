# Repeated-blocker cases

Apply each case independently.

## Case A — same cause, moved locus

Round 1 blocker: the `POST /admin/export` authorization contract is violated because the same middleware-ordering defect executes export before the admin guard. It returns `200` to a non-admin at `routes/admin.ts:41`.

After a local patch, round 2 finds the same middleware-ordering defect on the same operation and contract. The visible failure is now `500`, and the relevant line moved to `middleware/admin.ts:18`. No root-cause expert has run yet.

## Case B — escalation failed

For Case A, a new expert who participated in neither round identifies the middleware composition as the root cause. The main agent applies one materially different in-scope pipeline-order fix, runs focused checks, and CR+RC re-review it. The same authorization blocker remains. That escalation has already been used.

## Case C — same symptom, independent cause

`POST /billing/export` also returns `200` to a non-admin, but evidence shows a stale authorization cache in a different operation and causal chain. It violates the same broad authorization invariant as Case A. It has appeared in only one round and has never used root-cause escalation.

## Case D — escalation produced no applicable approach

For Case A, the one new root-cause expert returns only another middleware-order symptom patch and no materially different applicable approach. The main agent has nothing new it can apply and check. That escalation has already been used.

## Case E — only new approach needs authorization

For Case A, the one new root-cause expert identifies a materially different approach, but it requires replacing the public authorization subsystem outside the adopted scope. The user has not accepted or rejected that expansion yet.
