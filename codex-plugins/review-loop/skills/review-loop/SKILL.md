---
name: review-loop
description: Run an adversarial review-and-fix loop in Codex for the current proposal and code change. Use when the user asks to review until pass, run a strict adversarial review loop, find ship-blockers, or keep fixes minimal while iterating to approval.
---

# review-loop for Codex

Review the current proposal and code change, triage findings, fix the accepted issues, and repeat until the normalized verdict passes or the round cap is reached.

## Platform Adapter

This is the Codex port.

- Use Codex subagent workflows only.
- Do not use Claude Code `Agent tool`, `Task tool`, or `subagent_type`.
- Do not use `codex:codex-rescue`; that is a Claude-hosted bridge, not a Codex agent.
- If agency-agents custom agents are installed, spawn agents by their `name` field:
  - `Code Reviewer`
  - `Reality Checker`
  - `Minimal Change Engineer`
- If the runtime tool schema does not enumerate custom agents, spawn a normal Codex subagent and embed the target role prompt in the task. Record the slot as `fallback`.
- Keep any third review lane platform-neutral. Call it `Independent Reviewer`, never `Codex`.

## Severity and Verdicts

Re-grade every finding yourself before triage.

- `blocker`: wrong results, data loss, crash, security hole, dependency contract break, or core path unusable.
- `major`: serious design flaw, missed key edge, inconsistent behavior, or missing important check.
- `minor`: local issue that does not affect correctness.
- `nit`: style or wording only.

Normalize verdicts as follows:

- Any unresolved `blocker` or `major` means `CHANGES-REQUESTED`.
- Only `minor` or `nit` findings left means `APPROVE`.
- `APPROVE-DEGRADED` and `CAPPED` are main-agent terminal tokens only.

## Loop

1. Establish truth sources:
   - User requirement and accepted scope.
   - Proposal, design notes, specs, or issue text when present.
   - Current diff from Git and directly impacted unchanged call sites.
   - Existing tests or verification commands.

2. Run deterministic anchors before review when cheap:
   - Linters, type checks, static analysis, existing test commands, or targeted `rg` fan-out for new config keys, enum arms, role names, API paths, and exit-code mappings.
   - Keep the command and short output in the round notes.
   - A strong anchor proves only the scanned set, not total correctness.

3. Dispatch review lanes in parallel:
   - `Code Reviewer`: correctness, contracts, security, consistency, and tests. Require a guard/check checklist with `file:line` entries and, for any set-like dimension, `declared-coverage set | actually-effective set | equal?`.
   - `Reality Checker`: failure enumeration. Require guard/branch/assert/state-transition/claimed-pass rows with `file:line`, failing inputs, observed behavior, contract claim, and terminal state.
   - `Independent Reviewer`: fresh adversarial review over the same truth sources. Use a generic Codex subagent unless a better custom reviewer is clearly available.

4. Echo this status block every round:

```text
This round: Code Reviewer=<APPROVE|CHANGES-REQUESTED|not-run(reason)> | Reality Checker=<APPROVE|CHANGES-REQUESTED|not-run(reason)> | Independent Reviewer=<APPROVE|CHANGES-REQUESTED|not-run(reason)>
Augment: <none|agent list and fallback notes>
Scope fence: <agreed scope anchored|no full requirement context, skip> | out-of-scope findings: <N>
Simplicity: <lean|net -N flagged | over-eng: K open|no code this round, skip>
```

5. Triage:
   - Merge, deduplicate, and re-grade findings.
   - Out-of-scope `blocker` or `major` findings pause for user authorization before fixes.
   - Fix in-scope `blocker` and `major` findings by default.
   - Fix `minor` only when cheap and low risk; usually skip `nit`.
   - Treat over-engineering findings as advisory unless they create a correctness or contract problem.

6. Dispatch fixes:
   - Prefer `Minimal Change Engineer` for local fixes.
   - If unavailable, spawn a Codex worker/default subagent with explicit minimal-change instructions.
   - Give the fixer exact files, the issue, expected behavior, verification, scope boundary, and the rule: add no abstraction, config, dependency, or feature unless required by the accepted finding.
   - For large cross-module fixes, split into disjoint write scopes or keep the fix in the main thread when delegation would add coordination risk.

7. Re-review:
   - Return to step 1 on the latest diff.
   - Do not terminate just because a subagent wrote a pass token. Terminate only after main-agent normalization and the pass gate.

## Pass Gate

A pass-class terminal verdict requires:

- Every Reality Checker row has a terminal state.
- The Code Reviewer checklist and Reality Checker table reconcile by `file:line`; omissions remain unresolved.
- No unresolved `blocker` or `major` findings remain after main-agent normalization.
- Clean `APPROVE` requires all three review lanes to complete with parseable verdicts.
- If any lane is `not-run` after fallback attempts, terminal pass can only be `APPROVE-DEGRADED (<missing lane and reason>)` after at least two lanes completed, all completed lanes reconcile, and no unresolved `blocker` or `major` remains.
- If fewer than two lanes completed, or a missing lane leaves blocker/major coverage unresolved, use `CAPPED` or `CHANGES-REQUESTED`.
- If a lane used fallback, disclose it.

Clean pass:

```text
APPROVE
```

Degraded pass:

```text
APPROVE-DEGRADED (<reason list>)
```

Use degraded when review relied on weak reconciliation, accepted-degraded rows, missing custom agents with generic fallback, a missing lane after fallback attempts, or unanchored narrative/forward-fragility coverage.

Cap:

```text
CAPPED (cap-reached, <N> items left)
```

Default cap is 10 rounds unless the user sets another cap or wraps the task in Codex `/goal`.

## Pairing with Codex `/goal`

For long runs, suggest:

```text
/goal Run $review-loop on this change until the latest round has the status block, at least two completed review lanes, the pass gate is satisfied, no unresolved blocker/major findings remain, and the final token is APPROVE or APPROVE-DEGRADED; stop for OUT-OF-SCOPE-PENDING or CAPPED.
```
