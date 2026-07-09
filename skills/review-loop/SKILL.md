---
name: review-loop
description: Run an adversarial review-and-fix loop for the current proposal and code change. Use when the user asks to review until pass, find ship-blockers, run a strict adversarial review loop, or keep fixes minimal while iterating to approval.
---

# review-loop

Review the current proposal and code change, triage findings, fix the accepted issues, and repeat until the normalized verdict passes or the round cap is reached.

## Platform Adapter

This skill is platform-neutral. It uses **logical role names** (`Code Reviewer`, `Reality Checker`, `Minimal Change Engineer`, `Independent Reviewer`, plus optional augment `Application Security Engineer`) and resolves each to a concrete subagent at runtime via the four-tier fallback below.

### Role registry

| Logical Role | agency-agents source | Source path |
|---|---|---|
| Code Reviewer | `engineering/engineering-code-reviewer.md` | `name: Code Reviewer` |
| Reality Checker | `testing/testing-reality-checker.md` | `name: Reality Checker` |
| Minimal Change Engineer | `engineering/engineering-minimal-change-engineer.md` | `name: Minimal Change Engineer` |
| Application Security Engineer (optional augment) | `security/security-appsec-engineer.md` | `name: Application Security Engineer` |
| Independent Reviewer | — (always generic) | no agency-agents mapping |

`Independent Reviewer` is always a generic subagent with a fresh adversarial prompt — it has no agency-agents mapping by design.

### Four-tier fallback (per lane, resolved at dispatch time)

For each specialist lane, resolve the role prompt in this order:

1. **Registered agent** (`registered`) — If the runtime has the agency-agents agent installed (by `name` or `@<slug>` where slug = `slugify(name)`, e.g. `Code Reviewer` → `@code-reviewer`), dispatch it directly. This is the strongest tier.
2. **Local cache** (`local`) — If not registered, check whether `~/.agency-agents/<slug>.md` exists. If it does, read it, validate it (YAML frontmatter `---` + `name:` field), and embed the markdown body (skip frontmatter) as the role prompt for a generic subagent. No network access needed.
3. **Remote fetch** (`fetched`) — If the local cache file is missing or invalid, fetch from jsDelivr into `~/.agency-agents/`, then embed it as in tier 2.
4. **Embedded prompt** (`embedded`) — If the network is unavailable or the fetch fails validation, use the embedded fallback prompt below.

Tiers 2 and 3 deliver the same content as a registered agent (the full agency-agents source), just via a generic subagent. Tier 4 is a condensed prompt and is weaker.

**How to fetch** (tier 3): ensure the cache directory exists, then fetch:

```bash
mkdir -p "$HOME/.agency-agents"
# Check local cache first (tier 2)
[ -f "$HOME/.agency-agents/<slug>.md" ] && cat "$HOME/.agency-agents/<slug>.md" && exit 0
# Remote fetch (tier 3)
curl -fsSL --max-time 10 "https://cdn.jsdelivr.net/gh/msitarzewski/agency-agents@main/<path>" -o "$HOME/.agency-agents/<slug>.md"
# e.g. https://cdn.jsdelivr.net/gh/msitarzewski/agency-agents@main/engineering/engineering-code-reviewer.md
```

Or use any available web-fetch tool on the same URL, writing the result to `~/.agency-agents/<slug>.md`. Validate the fetched content before use (it must contain a YAML frontmatter block starting with `---` and include a `name:` field). If validation fails, delete the cached file and fall through to the embedded prompt. Extract the markdown body (skip the YAML frontmatter) and use it as the role prompt for a generic subagent.

**Embedded prompts** (tier 4, used when fetch fails):

- **Code Reviewer**: "You are an adversarial code reviewer. Check correctness, contracts, security, consistency with existing code, and edge cases. Produce a guard/check checklist with `file:line` entries. End with exactly one verdict line: `APPROVE` or `CHANGES-REQUESTED` + a findings list (severity / location / explanation / fix)."
- **Reality Checker**: "You are a failure-enumeration reviewer. List every guard, early-return, err branch, exception catch, assert, validation, exit-code, state transition, and claimed-pass point in a table with `file:line`. For each row, instantiate failing inputs (empty / null / malformed / timeout / partial-write / concurrent / token-expired). Record observed behavior vs contract claim and a terminal state. End with exactly one verdict line."
- **Minimal Change Engineer**: "You are a minimal-change engineer. Fix only the specified finding with the smallest possible diff. Do not add abstractions, config, dependencies, or features unless the finding's correctness requires it. Do not touch unrelated code."
- **Application Security Engineer** (optional augment): "You are a security reviewer. Check for injection, auth bypass, data exposure, and OWASP top-10 issues in the changed code. Report findings with severity and `file:line`."
- **Independent Reviewer**: "You are an independent adversarial reviewer with no prior commitment to the design. Find issues the author may have missed: self-contradiction, cross-file drift, forward fragility, ambiguity, scope creep, and security. Report findings with severity and `file:line`. End with exactly one verdict line: `APPROVE` or `CHANGES-REQUESTED`."

### Tier echo and pass-gate impact

Echo the resolved tier for each lane in the round status (see step 4 for the format). Tier affects the terminal pass:

- **All lanes `registered` or `local` or `fetched`** → clean `APPROVE` reachable (if the pass gate is otherwise satisfied). Tiers 1-3 all deliver the full agency-agents source content.
- **Any lane `embedded`** (network unavailable, fetch failed) → terminal pass capped at `APPROVE-DEGRADED (<lane>: embedded fallback)`, because an embedded condensed prompt is a weaker reviewer than the full agency-agents source.
- **Optional augment (`Application Security Engineer`)**: if resolved to `embedded` tier, flag it in the round status but do not cap the terminal verdict — the augment is findings-only and holds no verdict slot. An embedded augment's findings should be treated as advisory.

### Platform rules

- Do not use Claude Code `Agent tool`, `Task tool`, or `subagent_type`.
- Do not use `codex:codex-rescue` (it is a Claude-hosted bridge, not a standalone agent).
- Keep the third review lane platform-neutral. Call it `Independent Reviewer`, never a platform name.

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

3. Dispatch review lanes in parallel (resolve each specialist via the four-tier fallback in Platform Adapter):
   - **Code Reviewer**: correctness, contracts, security, consistency, and tests. Require a guard/check checklist with `file:line` entries and, for any set-like dimension, `declared-coverage set | actually-effective set | equal?`.
   - **Reality Checker**: failure enumeration. Require guard/branch/assert/state-transition/claimed-pass rows with `file:line`, failing inputs, observed behavior, contract claim, and terminal state.
   - **Independent Reviewer**: fresh adversarial review over the same truth sources. Always a generic subagent with a fresh adversarial prompt — no agency-agents mapping. Do not call this lane by a platform name.

4. Echo this status block every round:

```text
This round: Code Reviewer=<APPROVE|CHANGES-REQUESTED|not-run(reason)> [registered|local|fetched|embedded] | Reality Checker=<APPROVE|CHANGES-REQUESTED|not-run(reason)> [registered|local|fetched|embedded] | Independent Reviewer=<APPROVE|CHANGES-REQUESTED|not-run(reason)> [generic]
Augment: <none|agent list and tier notes>
Scope fence: <agreed scope anchored|no full requirement context, skip> | out-of-scope findings: <N>
Simplicity: <lean|net -N flagged | over-eng: K open|no code this round, skip>
```

5. Triage:
   - Merge, deduplicate, and re-grade findings.
   - Out-of-scope `blocker` or `major` findings pause for user authorization before fixes.
   - Fix in-scope `blocker` and `major` findings by default.
   - Fix `minor` only when cheap and low risk; usually skip `nit`.
   - Treat over-engineering findings as advisory unless they create a correctness or contract problem.
   - Optional security augmentation: dispatch `Application Security Engineer` as a findings-only lane (takes no slot, holds no verdict), resolved via the same four-tier fallback.

6. Dispatch fixes (resolve `Minimal Change Engineer` via the four-tier fallback):
   - **Registered** → dispatch the installed `Minimal Change Engineer` directly.
   - **Local** → read cached prompt from `~/.agency-agents/minimal-change-engineer.md`, embed in a generic subagent.
   - **Fetched** → fetch its prompt from jsDelivr into `~/.agency-agents/`, embed in a generic subagent.
   - **Embedded** → use the embedded minimal-change prompt in a generic subagent.
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
- Clean `APPROVE` requires all three review lanes to complete with parseable verdicts, and no lane is `embedded` (see Tier echo and pass-gate impact in Platform Adapter).
- If any lane is `not-run` after fallback attempts, terminal pass can only be `APPROVE-DEGRADED (<missing lane and reason>)` after at least two lanes completed, all completed lanes reconcile, and no unresolved `blocker` or `major` remains.
- If any lane resolved to `embedded` tier, terminal pass is capped at `APPROVE-DEGRADED (<lane>: embedded fallback)` — an embedded condensed prompt is a weaker reviewer than the full agency-agents source.
- If fewer than two lanes completed, or a missing lane leaves blocker/major coverage unresolved, use `CAPPED` or `CHANGES-REQUESTED`.
- Disclose the resolved tier of each lane in the final round's status block (step 4) that accompanies the terminal verdict.

Clean pass:

```text
APPROVE
# Accompanied by final status block with all lanes [registered|local|fetched] and Independent Reviewer [generic]
```

Degraded pass:

```text
APPROVE-DEGRADED (<reason list>)
# e.g. APPROVE-DEGRADED (Code Reviewer: embedded fallback, Reality Checker: embedded fallback)
```

Use degraded when review relied on weak reconciliation, accepted-degraded rows, any lane at `embedded` tier, a missing lane after fallback attempts, or unanchored narrative/forward-fragility coverage. An embedded augment does not cap the verdict (advisory only).

Cap:

```text
CAPPED (cap-reached, <N> items left)
```

Default cap is 10 rounds unless the user sets another cap or wraps the task in `/goal`.

## Pairing with /goal

For long runs, wrap the loop in `/goal`:

```text
/goal Run review-loop on this change until the latest round has the status block, at least two completed review lanes, the pass gate is satisfied, no unresolved blocker/major findings remain, and the final token is APPROVE or APPROVE-DEGRADED; stop for OUT-OF-SCOPE-PENDING or CAPPED.
```
