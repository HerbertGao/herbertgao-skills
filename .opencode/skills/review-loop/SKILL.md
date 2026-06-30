---
name: review-loop
description: Run an adversarial review-and-fix loop in OpenCode for the current proposal and code change. Use when asked to review until pass, find ship-blockers, run strict review, or iterate minimal fixes to approval using OpenCode subagents.
---

# review-loop for OpenCode

Review the current proposal and code change, triage findings, fix accepted issues, and repeat until the normalized verdict passes or the round cap is reached.

## Platform Adapter

This is the OpenCode port.

- Use OpenCode subagents only.
- Do not use Codex subagents, Codex custom agents, or `codex:codex-rescue`.
- Do not use Claude Code `Agent tool`, `Task tool`, or `subagent_type`.
- Invoke installed agency-agents through OpenCode `@` slugs:
  - `@engineering-code-reviewer` for the `Code Reviewer` lane.
  - `@testing-reality-checker` for the `Reality Checker` lane.
  - `@engineering-minimal-change-engineer` for fixes.
  - `@security-appsec-engineer` for optional security augmentation.
- If an OpenCode subagent is unavailable, embed the role prompt in a generic OpenCode subagent or continue in the primary agent and mark the lane as `fallback`.
- Keep any third review lane platform-neutral. Call it `Independent Reviewer`, never `Codex`.

## Severity and Verdicts

Re-grade every finding yourself.

- `blocker`: wrong results, data loss, crash, security hole, dependency contract break, or core path unusable.
- `major`: serious design flaw, missed key edge, inconsistent behavior, or missing important check.
- `minor`: local issue that does not affect correctness.
- `nit`: style or wording only.

Normalize verdicts:

- Any unresolved `blocker` or `major` means `CHANGES-REQUESTED`.
- Only `minor` or `nit` findings left means `APPROVE`.
- `APPROVE-DEGRADED` and `CAPPED` are main-agent terminal tokens only.

## Loop

1. Establish truth sources: user requirement, accepted scope, proposal/specs, current Git diff, impacted unchanged call sites, and test commands.

2. Run cheap deterministic anchors before review: linters, type checks, existing tests, static analysis, or targeted `rg` fan-out for new dimensions. Keep command and short output in the round notes.

3. Dispatch review lanes, preferably in parallel:
   - `@engineering-code-reviewer`: correctness, contracts, security, consistency, and tests. Require a guard/check checklist with `file:line` entries and, for set-like dimensions, `declared-coverage set | actually-effective set | equal?`.
   - `@testing-reality-checker`: failure enumeration. Require rows for guard/branch/assert/state-transition/claimed-pass points, failing inputs, observed behavior, contract claim, and terminal state.
   - `Independent Reviewer`: use a generic OpenCode review subagent or the primary OpenCode agent with a fresh adversarial prompt. Do not call this lane Codex.

4. Echo this status block every round:

```text
This round: Code Reviewer=<APPROVE|CHANGES-REQUESTED|not-run(reason)> | Reality Checker=<APPROVE|CHANGES-REQUESTED|not-run(reason)> | Independent Reviewer=<APPROVE|CHANGES-REQUESTED|not-run(reason)>
Augment: <none|agent list and fallback notes>
Scope fence: <agreed scope anchored|no full requirement context, skip> | out-of-scope findings: <N>
Simplicity: <lean|net -N flagged | over-eng: K open|no code this round, skip>
```

5. Triage:
   - Merge, deduplicate, and re-grade findings.
   - Pause for user authorization on out-of-scope `blocker` or `major` findings.
   - Fix in-scope `blocker` and `major` findings by default.
   - Fix `minor` only when cheap and low risk; usually skip `nit`.
   - Treat over-engineering findings as advisory unless they create a correctness or contract problem.

6. Dispatch fixes to `@engineering-minimal-change-engineer` when possible. If unavailable, use a generic OpenCode subagent with explicit minimal-change instructions. Provide exact files, issue, expected behavior, verification, and scope boundary.

7. Re-review the latest diff. Do not terminate just because a subagent wrote a pass token; terminate only after main-agent normalization and the pass gate.

## Pass Gate

A pass-class terminal verdict requires:

- Every Reality Checker row has a terminal state.
- The Code Reviewer checklist and Reality Checker table reconcile by `file:line`; omissions remain unresolved.
- No unresolved `blocker` or `major` findings remain after main-agent normalization.
- Clean `APPROVE` requires all three review lanes to complete with parseable verdicts.
- If any lane is `not-run` after fallback attempts, terminal pass can only be `APPROVE-DEGRADED (<missing lane and reason>)` after at least two lanes completed, all completed lanes reconcile, and no unresolved `blocker` or `major` remains.
- If fewer than two lanes completed, or a missing lane leaves blocker/major coverage unresolved, use `CAPPED` or `CHANGES-REQUESTED`.
- If a lane used fallback, disclose it.

Use:

```text
APPROVE
APPROVE-DEGRADED (<reason list>)
CAPPED (cap-reached, <N> items left)
```

Default cap is 10 rounds unless the user sets another cap.
