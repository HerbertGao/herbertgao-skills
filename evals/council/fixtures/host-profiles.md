# Council host profiles

Apply the council Platform Adapter and terminal rules to each independent profile. Assume the catalog resolves four compliant real seats, including a real opposing seat, and the debate ends with zero open cruxes unless the profile says otherwise.

## Profile A: fresh but unaudited, capacity constrained

- The host can create fresh-context workers.
- Workers can dispatch descendants and can write to the shared workspace.
- Canonical dispatch and full prompt records are available, but the moderator receives each return with no canonical return copy, resolved-model record, complete descendant topology, per-worker tool log, or platform-authored confirmation record available to an auditor.
- A separate fresh auditor has a shell and can re-run read-only checks against those records.
- At most three child workers can run concurrently, while the council has four seats.
- The host has no worker-continuation mechanism, but it can create a fresh replacement worker.
- Git status/diff and repository file hashing are available as scoped soft checks; assume they detect no delta.
- The decision is analysis-only; no seat needs an external or irreversible action.

## Profile B: fully audited

- The host has fresh non-dispatching seat workers and a fresh auditor with a shell.
- Canonical prompt, return, resolved-model, dispatch and per-worker tool records satisfy every Platform Adapter output contract.
- All four seats fit concurrently.
- The audit's canonical return includes the finalized candidate digest then `PASS`; the human confirms that digest, the post-confirmation attestation returns `PASS`, at least two seat-facing base models are recorded, and no value crux is delegated.

## Profile C: no fresh seats

- The only worker mechanism inherits the moderator's existing discussion.
- There is no way to create a fresh context for a round-one seat.

## Profile D: action required during deliberation

- Fresh-context workers exist, but the proposition can only be tested by having a seat deploy to production during the council run.
- The user has not authorized that deployment.

## Profile E: restricted seats, no provenance, parallel capacity

- Fresh-context seat workers exist and cannot dispatch descendants, but they have shell access and can write.
- Canonical dispatch/full-prompt records and a fresh shell auditor are available, but there is no canonical return copy, resolved-model record, per-worker tool log, or platform-authored confirmation record.
- All four seats fit concurrently.
- The host has no worker-continuation mechanism, but it can create a fresh replacement worker.
- The decision is analysis-only; no seat needs an external or irreversible action.
- No repository soft-check primitive is available.

## Profile F: audited record disappears after dispatch

- Audited preflight succeeded and the run began in audited mode.
- After all cruxes close, a required canonical seat return is missing even after the one settle/re-read.
- No fabrication cause can be distinguished from record loss; zero cruxes are open.

## Profile G: advisory soft check detects a write

- Fresh-context advisory seats exist.
- The before/after Git snapshot shows a net change outside `workdir` after a seat batch.
- The changed path belongs to the user and must not be auto-reverted.

## Profile H: candidate changed after audit

- Audited preflight and the candidate audit pass, whose canonical return records digest A.
- Before presentation, the candidate is changed to digest B; the human confirms B and zero cruxes are open.

## Profile I: post-audit interval contains another dispatch

- Audited preflight and candidate audit pass; its digest still matches the presented/current candidate and the human confirms it.
- Between the candidate audit and attestation, the moderator launches another worker; zero cruxes are open.

## Profile J: required read-only presentation projection

- Profile B's audited premises all hold.
- After the candidate audit, the moderator runs only the required read-only command that prints its canonical verdict/digest, presents that digest, receives confirmation, and the attestation passes.

## Profile K: post-audit actual write

- Profile B's audited premises all hold and the candidate digest remains unchanged.
- After the candidate audit but before attestation, a tool call writes outside `workdir`; the human still confirms and zero cruxes are open.

## Profile L: audit pins changed after seating

- Audited preflight records procedure/adapter paths and full digests A before the first seat dispatch.
- The candidate-audit payload substitutes paths or digests B; zero cruxes are open.
