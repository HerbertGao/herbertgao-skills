PROFILE-A-MODE: advisory
PROFILE-A-ROUND1: batched
PROFILE-A-LATER-ROUNDS: fresh-redispatch
PROFILE-A-MODEL-CENSUS: unknown
PROFILE-A-SOFT-CHECK: git-snapshot
PROFILE-A-ASSURANCE-GAPS: prompt-provenance,return-provenance,model-census,tool-write-audit,dispatch-topology,round-one-simultaneity,auditor-re-run-capability
PROFILE-A-TOKEN: ADVISORY (debate-converged; unaudited)
PROFILE-A-AUTHORIZES-IMPLEMENTATION: no
PROFILE-B-MODE: audited
PROFILE-B-CONVERGED-REQUIRES: audit-pass,zero-open-cruxes,human-confirmation
PROFILE-C-TOKEN: STOPPED (cannot run expert seats)
PROFILE-D-TOKEN: STOPPED (advisory is analysis-only)
PROFILE-E-MODE: advisory
PROFILE-E-ROUND1: parallel
PROFILE-E-LATER-ROUNDS: fresh-redispatch
PROFILE-E-TOKEN: ADVISORY (debate-converged; unaudited)
PROFILE-E-AUTHORIZES-IMPLEMENTATION: no
PROFILE-F-TOKEN: UNRESOLVED (dispatch-unverifiable: 0 open)
PROFILE-G-TOKEN: STOPPED (advisory side effect detected)
PROFILE-E-WORKER-PREFERENCE: restricted

## Reasoning

### Profile A
- **Mode**: The host can create fresh-context workers, but cannot provide a canonical return copy, resolved-model record, or per-worker tool log. Because one or more audited capabilities are missing, it routes to `advisory` mode.
- **Round 1**: There are 4 seats in the council, but the capacity is constrained to at most 3 concurrent child workers. Per the Platform Adapter, because the host cannot run all seats concurrently, it must dispatch them in batches. Hence, `batched`.
- **Later Rounds**: Since there's no worker continuation mechanism, it has to re-dispatch a fresh worker (`fresh-redispatch`) for subsequent rounds.
- **Model Census**: Unknown since model records are unavailable.
- **Soft Check**: Supports `git-snapshot` (Git status/diff and file hashing are available).
- **Assurance Gaps**: Lists all missing guarantees because prompt provenance, return provenance, model census, tool/write audit, dispatch topology, round-one simultaneity, and auditor re-run capabilities are all unavailable.
- **Token**: `ADVISORY (debate-converged; unaudited)`.
- **Authorizes Implementation**: `no`.

### Profile B
- **Mode**: The host satisfies all audited eligibility contracts (fresh non-dispatching workers, fresh auditor with shell, canonical prompts/returns/models, and per-worker logs). Thus, it supports `audited` mode.
- **CONVERGED Requires**: The three gates: audit pass, zero open cruxes, and human confirmation (`audit-pass,zero-open-cruxes,human-confirmation`).

### Profile C
- **Token**: The host lacks any mechanism to create fresh-context workers (workers inherit the moderator's prior discussion). According to the Platform Adapter, "No fresh-context worker at all ⇒ `STOPPED (cannot run expert seats)`."

### Profile D
- **Token**: The task requires deploying to production during the council run, which is an external/irreversible action, and the user has not authorized it. Per the Platform Adapter, "A request that requires seats to perform external or irreversible actions during deliberation ⇒ `STOPPED (advisory is analysis-only)`."

### Profile E
- **Mode**: The host can create fresh-context workers that cannot dispatch descendants, but it lacks canonical return copies, resolved-model records, and per-worker logs. Therefore, it does not meet the audited eligibility criteria and defaults to `advisory` mode.
- **Round 1**: All four seats can fit concurrently, so they run in `parallel`.
- **Later Rounds**: As there is no continuation, it uses `fresh-redispatch`.
- **Token**: In advisory mode, a successfully completed run emits `ADVISORY (debate-converged; unaudited)`.
- **Authorizes Implementation**: `no`.
- **Worker Preference**: Preferred restricted worker type.

### Profile F
- **Token**: Late record loss after all cruxes closed is an integrity failure, leading to `UNRESOLVED (dispatch-unverifiable: 0 open)`.

### Profile G
- **Token**: The before/after Git snapshot shows a net change outside `workdir` after a seat batch. This is an unexpected delta, leading to `STOPPED (advisory side effect detected)`.
