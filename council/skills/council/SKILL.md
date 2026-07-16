---
name: council
description: Use for open decisions with NOTHING WRITTEN yet — technology selection, architecture, whether to build something. Pulls real specialists from the agency-agents catalog (one seat per named viewpoint gap, 4 or more), gets independent round-one positions on ONE decision, numbers the disagreements into cruxes, and makes the seats argue them out. The expert debate is the core protocol. Hosts with canonical dispatch, return and tool records add an audited assurance tier and may emit CONVERGED after audit, human confirmation and a confirmation attestation; hosts with fresh-context seats but weaker provenance still run the full debate and emit a non-certifying, non-authorizing ADVISORY with every missing guarantee disclosed. Triggers - convene a council, multi-expert debate, get several perspectives on this decision, have some experts argue this out, 开个评议会, 让几个专家吵一下, 多视角讨论这个方案, 找专家评议, 这个选型该怎么定. Something already written — a proposal, a spec, a diff — that needs tearing apart is review-loop, not council.
---

# council

One decision with nothing written yet → one real specialist per named gap (4+) gives an independent round-one position → extract the disagreement → argue → produce an audited decision or a clearly qualified advisory. **Anything already written (a proposal, a spec, a diff) that needs tearing apart → `review-loop`.**

## Terms

- **crux** — the specific proposition two seats **diverge** on ("will write QPS exceed 2k?", not "A picks Postgres"), numbered `C1..Cn`.
- **named gap** — one sentence naming the constraint this seat will raise that no other seat structurally can. Test by **transposition** — a naming judgment, not a checked gate: move the sentence to another seat's name; if it still fits there, it named no gap.
- **round-one independent** — a seat's first position comes from a fresh context holding only the proposition, truth sources and its persona. An `Agent` dispatch provides that; a fork does not. Capacity batches are allowed when every prompt was frozen before any return. After round one, audited mode uses new `Explore` dispatches carrying the same persona and that seat's prior raw return; `SendMessage` is advisory-only because §6 cannot enumerate it. Without continuation, advisory also re-dispatches a fresh available worker with that persona and raw return.
- **assurance mode** — **audited** when Claude's `Explore` workers and JSONL/sidecar records satisfy §6, otherwise **advisory** when fresh-context seats still exist. Assurance changes what the result certifies, never whether the expert debate itself has value.
- **DA** — the opposing seat's attack round (devil's advocate), §3. **DA-final** — its second stage, §3.
- **run nonce** — the 8 hex characters `openssl rand -hex 4` prints in §0. In audited mode its tool record is a birth event; in advisory mode it is a correlation id, not provenance proof.
- **`k`** — the dispatch counter, one per dispatch, never reused. §2.
- **session log** — audited mode's `~/.claude/projects/<project-path-slug>/<session-id>.jsonl` plus its subagent sidecars. Advisory mode may lack one or more canonical records and must say which.
- **workdir** — a fresh directory holding the run's deliverables (`candidate-<n>.md`). Audited mode keeps no evidence copy there; advisory mode may store its explicitly unaudited transcript bundle there.
- **seat** — one specialist subagent occupying one axis for the whole run, identified by **its catalog path** (the frontmatter `name:` is a display name — `Database Optimizer`, not the slug — and is used only to deduplicate). **axis** — one conflicting-interest dimension (§1). **tie-breaker** — a seat added mid-run on a new axis (§4).
- **truth sources** — the repo paths / docs handed to every seat in round 1, echoed in §0.
- **token** — `CONVERGED` (audited mode only; needs audit PASS, human confirmation and attestation PASS), `ADVISORY (…)` (debate completed without the audited provenance guarantee), or `UNRESOLVED (…)` / `STOPPED (…)`.
- **candidate record** — the §8 record built before emission, `**Status**: <token withheld>`.
- **refutable** — a sentence a reader could name evidence *against*. "Use Postgres" is not; "Postgres over SQLite, because write QPS will exceed 2k" is.
- **cost-of-wrong** — one clause: what breaks, how expensively, if this crux is settled wrong. It orders §5's queue.
- **unlookupable** — a fact crux no traced seat's ① covers, or that nothing available today can check. Open. §3.
- **unasked** — a value crux the human chose not to be asked. Distinct from `delegated` (they saw it and abstained). Open. §5.
- **seat letters** — `A`, `B`, `C`… assigned in the §1 echo; `A.r1` = seat A's reason 1. **`P1..Pn`** — the consensus propositions, §3.
- **`S`** — seats frozen in the round-one manifest. **settle/re-read** — after Claude marks every known non-auditor `Agent` terminal, run one fresh discovery/enumeration; without that event, a missing record stays unverifiable, never an arbitrary sleep.

## Honesty boundary (read first — it is the shape of every rule below)

The seats may be **the same base model wearing different personas**: round-one separation limits context contamination, never model-level correlation. "Three experts independently agreed" and "one model sampled three times" may be structurally indistinguishable — **agreement is weak evidence, not consensus.**

And the moderator (you) is at once the author of the proposition, the appointer of seats, the classifier, the fact adjudicator and the writer of the record, with exactly one incentive: **to be done**. Audited mode therefore sets no gate you grade yourself against. It does one thing:

> **Keep no copy of your own evidence. Every artifact the audit reads is one the platform wrote — so every shortcut leaves a hole in a file you did not author, findable from a different context.**

**What the auditor can catch**: a dispatch that never happened, a dispatch that happened and was hidden, a return misquoted in the record, a persona that was not the expert's, a prompt that leaked another seat's words, a fabricated path, output or citation, a write made before consent, a human's answer recorded as something other than what they chose.

**What it structurally cannot catch — the floor:**

- **The runs you discard.** Every gate binds the run you *declare*. Nothing binds the councils you rehearsed and threw away. A moderator willing to spend the tokens can try seat sets, truth sources and propositions until one converges, and every artifact of the run it finally opens will be genuine. A0 *counts* pre-birth dispatches and prints the number; it cannot know what they were for.
- **How you carve the disagreements.** N disagreements into M cruxes is judgment; no check recomputes the carving.
- **The auditor's own honesty.** It can fabricate a re-run's output as cheaply as you can fabricate a return. Its tool calls are in its own record and nothing reads them. This is one turtle further down than this protocol goes.
- Whether a criterion is *relevant*; whether a synthesized persona is *sound*; **the sincerity of a concession** (citing existing evidence is nearly free); **the quality of a DA attack**; **the fairness of §5's question ordering**; **your recommendation on a `delegated` crux** (the human abstained; nothing attacks what you then decided); **your selection of truth sources**; **tampering with the log** (it runs under your uid).

So `CONVERGED` means **no fabrication was caught** — not "the conclusion is right".

**Advisory honesty boundary.** Advisory mode cannot make that claim: the moderator may be the only actor that sees prompts and returns, model identity may be unavailable, and dispatches, tool calls or writes may be unobservable. It preserves catalog personas, fresh round-one positions, cruxes, DA/cross-exam, human value rulings and the minority report while denying certification. An advisory must never cite agreement as support, say `blind: yes`, contain audit `PASS`, authorize implementation, or satisfy a consumer that requires `CONVERGED`.

**Correlation is disclosed, never priced away.** When every seat, the DA and the auditor run on one base model, the consensus set is one model agreeing with itself: §7 records it, §8 forbids citing the consensus set as support, and the token says so. `models` counts *distinct base models* and is a **lower bound** on de-correlation.

## Assurance modes on Claude Code

Choose the mode before seating. Select audited only when the required worker types, JSONL joins, sidecars and auditor re-run capability are already known to work; uncertainty selects advisory. A record that disappears after audited dispatch begins is an integrity failure, not a retroactive downgrade.

- **Audited eligibility**: seats use fresh `Explore` dispatches and readable sidecars; the auditor uses fresh `general-purpose`; JSONL provides a platform-authored confirmation record binding presentation and human response; the payload pins this skill and its enumerator by absolute path and SHA-256. Only this mode reaches `CONVERGED`.
- **Advisory eligibility**: fresh workers exist but a required worker type, canonical sidecar, resolved model or audit primitive does not. Record every missing guarantee separately. Prompt seats not to mutate files, dispatch descendants or contact external systems. For Git-only checks, put `workdir` outside the repo and, with Bash `set -euo pipefail`, snapshot before round one and after every dispatch batch (including later rounds): `git status --porcelain=v1 -z -uall`; `git diff --binary --no-ext-diff --no-textconv`; `git diff --cached --binary --no-ext-diff --no-textconv`; and `git ls-files --others --exclude-standard -z | while IFS= read -r -d '' p; do printf '%s\0' "$p"; git hash-object --no-filters -- "$p" | tr '\n' '\0'; done`. Save outputs separately and byte-compare all four to the baseline. This sees dirty-baseline and non-ignored untracked-content net changes, not reverted, ignored-path or outside-Git writes. A post-dispatch command failure or delta ⇒ `STOPPED (advisory side effect detected)`: paste evidence and never auto-revert. A baseline failure degrades to `Soft checks: none`.
- No fresh-context worker at all ⇒ `STOPPED (cannot run expert seats)`. A deliberation that itself requires external or irreversible action ⇒ `STOPPED (advisory is analysis-only)`.
- `ADVISORY` recommends only. It never authorizes edits, messages, installs or other side effects; those require a later explicit user instruction.
- Gap ids are normative: `prompt-provenance` prompts not canonical; `return-provenance` returns not canonical; `model-census` models unavailable; `tool-write-audit` worker tools incomplete; `dispatch-topology` descendants not excluded; `round-one-simultaneity` batching required; `auditor-re-run-capability` no fresh auditor or pinned procedure; `confirmation-provenance` presentation/response not auditable.

## 0. Self-driving, and what every STOPPED costs

**council never hands control back except at §5's human touchpoints.** An audit FAIL on a quality check means fix and re-audit; an audit FAIL on **A0 / A0b / A5** is evidence of fabrication, not a defect to fix, and takes §5's fabrication row directly.

**Open the run.** Create `workdir` (fresh; not `/`, not `$HOME`, not an ancestor of the project root — A9 rejects those), then:

```bash
openssl rand -hex 4                                  # the nonce: the platform records the call AND its output
git -C ~/.agency-agents rev-parse HEAD               # the catalog rev A2 will re-read at
```

```text
run: <nonce> | workdir: <path> | catalog: <rev> | mode: <audited|advisory>
proposition: <one refutable sentence>
truth sources: <the paths/docs every seat gets in round 1>
assurance gaps: <none | comma-separated canonical ids — see Assurance modes on Claude Code>
audited only: audit-procedure: <absolute installed-skill path> · version/commit:<id> · sha256:<digest> | enumerator: <absolute reference path> · version/commit:<id> · sha256:<digest>
```

Emit this opening block exactly once, before the first dispatch. In audited mode the pin line also appears exactly once in that block; a duplicate or later pin declaration is fabrication, not an update.

The proposition goes **verbatim** to every seat; the dispatch prompt carries no other seat's position, no other seat's catalog path, and no role hint like "you are the opposing seat" — its own path appears only in the required header/persona. Opposition is the persona's job, and **A0b checks those exclusions**. (A "lean" below that — bias in your own phrasing — has no mechanical test; it sits on the disclosed floor, not a gate.) A proposition you cannot compress into one refutable sentence is hiding a second decision — the operational test is the STOPPED table below: if you can list it as ≥2 decisions each with its own axes, it is several ⇒ `STOPPED (proposition needs splitting)`.

**Every `STOPPED` owes evidence** — otherwise quitting before you start is the only free door. In audited mode, a `STOPPED` after any dispatch also owes A0; an A0 FAIL becomes `UNRESOLVED (audit-failed: fabrication)`. Advisory mode cannot run A0, so its STOPPED report pastes the dispatch ids and returns it received and labels them `moderator-visible, unaudited`.

| STOPPED reason | trigger | evidence owed |
|---|---|---|
| proposition needs splitting | above | the ≥2 decisions it splits into, one refutable sentence each, **plus the axes — at least §1's three — of the one you recommend convening first** (prepay §1's work; cannot list two decisions ⇒ it is not several decisions — convene) |
| not a council question | fewer than 3 or more than 8 non-opposing axes (§1) | the axes you derived, with named gaps, and which interest lacks a representative |
| seats exhausted | fewer than 2 compliant seats in a round (§2) | the failed seats' dispatch ids |
| no real experts: catalog unavailable | zero real experts (§1) | the verbatim `find` output; the message states the prerequisite is missing — `~/.agency-agents`, installed by the user per the README — and hands no command: the user's environment is theirs to change |
| no real experts: none on the opposing axis | no catalog match on that axis (§1) | the `find` output + the candidates you read and why each fails the axis |
| no real experts: a second axis has no match | a second seat would have to be synthesized (§1) | the two unmatched axes + the listing lines you searched + why each candidate fails each (the raw `find` output alone *misleads* here — it shows a healthy catalog) |
| cannot run expert seats | no fresh-context worker | the workers you do have and why none can produce an independent round-one position |
| advisory is analysis-only | the debate itself requires an external or irreversible action | the action, why a read-only check cannot replace it, and the authorization required |
| advisory side effect detected | an advisory soft check changed outside `workdir` | the before/after artifacts and exact scope; preserve user state and do not auto-revert |
| awaiting human | a §5 question or presentation got no answer | the question or candidate as presented. **A suspension, not an exit** — the platform holds the run, so a resumed session picks up from it, and **no timeout converts silence into consent** |

## 1. Seat the council

**Axes first, people second.** If this decision is wrong, who gets hurt? Cover ① the primary domain, ② the interest naturally in tension with it, ③ the downstream actually touched (security / cost / maintainability / users / compliance). One named gap per axis.

- **Three to eight *non-opposing* axes**, one seat each; the **opposing seat** (§3) is a further seat on its own axis, named here and never re-designated. **Minimum council: 4 seats; maximum 9, tie-breakers included.** Outside that ⇒ `STOPPED (not a council question)` — below it there is no conflict to arbitrate; above it, fan-out quality collapses.
- **One seat per named gap.** A seat with no gap merely restates another and thickens the illusion of independent agreement.

**The catalog is a prerequisite the user installs (per the README); the council reads it and never writes to it** — a seat that argues a decision comes from a checkout the user chose to trust, at a revision they control (A9 checks the no-write side).

**Enumerate the catalog before naming any seat** — names invented from an axis (`stability-advocate`, `contrarian`) match nothing:

```bash
find ~/.agency-agents -mindepth 2 -type f -name '*.md' \
  ! -iname 'README*' ! -iname 'CONTRIBUTING*' ! -iname 'SECURITY.md' ! -path '*/.github/*' 2>/dev/null | sort
```

The exclusions are anchored to exact filenames, not prefixes — a prefix glob would delete the whole `security-*` division. `-mindepth 2` is where the catalog keeps its agents — a bare root-level `.md` is not part of the checkout the user installed; the `2>/dev/null` turns a missing directory into the empty listing the STOPPED table reads. Paste the output.

Pick candidates per axis; read each frontmatter and judge whether it fits that axis — a selection judgment, not a mechanical gate. In audited mode every seat, DA and cross-exam dispatch uses `subagent_type: Explore`; `general-purpose` is for the auditor. Advisory mode also prefers `Explore` and uses a more capable fresh worker only when no restricted fresh worker exists; record an assurance gap when the selected type can dispatch or lacks a sidecar. Echo the seats in the fixed format:

```text
axis 1: considered <path-a>, <path-b> -> seated <path-a> (<one clause: why the other lost>)
  A. <absolute path>              # its body, minus frontmatter, IS the persona
  B. <absolute path>
  D. synthesized                  # no catalog file fits this axis (paste the candidates read + why each fails) -> you author the persona inline
opposing: <seat letter>
```

- **A seat is its path.** Deduplicate by frontmatter `name:` (two divisions can carry one `name:` — `engineering/engineering-backend-architect.md` and `integrations/mcp-memory/backend-architect-with-memory.md` are both *Backend Architect*; the seat takes the copy under the division matching its axis) — but never *name* a seat by it: the frontmatter carries a display name, not the slug.
- **Record who you rejected, not only who you seated.** Which experts enter the room is the largest bias lever in the protocol and otherwise leaves the shortest trace.
- **Do not pass a model.** In audited mode the platform records the resolved model and A8 reads it there. Advisory mode does not run A8: report a host-recorded model with that source when available; otherwise use `unknown`. A model you type is an unverified claim, never a substitute.
- **At most ONE `synthesized` seat**, tie-breakers included — a self-authored persona is your own words fed back to you and the auditor structurally cannot check it. A second ⇒ `STOPPED (no real experts: a second axis has no match)`. Its text may not contain any option or technology name from the proposition (A0b checks).
- **The opposing seat may not be synthesized** — authoring the agent whose job is to break your own consensus hands the anti-echo mechanism to the echo. None on that axis ⇒ `STOPPED (no real experts: none on the opposing axis)`. Zero real experts ⇒ `STOPPED (no real experts: catalog unavailable)`.

**Freeze round one before its first dispatch.** Emit one `Round-1 manifest:` transcript record containing the proposition, truth sources, complete seat echo, dispatch order, and every full prompt or the full SHA-256 digest §6 enumerates. When capacity is lower than the seat count, dispatch the frozen prompts in batches. In audited mode A0b verifies that the JSONL record of this manifest precedes every round-one dispatch and return, and that order and digests match exactly. Advisory mode labels it moderator-authored disclosure. Echo `round1: parallel` or `round1: batched`.

## 2. Dispatch

**Every dispatch prompt begins with the header, and the persona is fenced:**

```text
council: <proposition> | run: <nonce> | seat: <path | —> | round: <n> | kind: <seat|re-dispatch|retry|cross-exam|DA|DA-final|tie-breaker|label|audit> | dispatch: <k>
<persona>
…the catalog file's body, verbatim, minus frontmatter. Nothing else inside these markers.…
</persona>
…the proposition, the truth sources, and the round's return contract…
```

`k` is a per-run counter, never reused; the auditor takes the next `k`. `seat:` reads `—` only for the auditor (including its retry); every seat-facing dispatch, including `label`, names the seat path.

In audited mode the header is the whole ledger: the platform records it at dispatch time, before the return exists. In advisory mode it keeps the debate legible but proves no provenance claim.

**Work from the return.** In audited mode the sidecar copy is authoritative. In advisory mode paste the raw return you received unedited and label it `moderator-visible, unaudited`; it is useful evidence of a perspective, not proof against omission or rewriting.

Round 1: dispatch every seat in one message when capacity allows; otherwise dispatch the frozen manifest in batches. Every seat still receives a fresh context and no other seat's return.

```text
Position: <one refutable sentence. "It depends" is not a position>
Reasons (1-3, each labeled — three `fact` reasons is legal):
  [fact: <file:line | command | URL>] <…>
  [prediction: indicator=<name> threshold=<comparator+value+unit> observe=<when/where>] <…> -> falsified if: <…>
  [value: <the preference it rests on — a sentence "I don't care about X" would refute, naming which two options it ranks>] <…>
Strongest argument against my own position: <mandatory>
What would change my mind: <mandatory. Either ① something the moderator can verify today — **state the concrete check: a command or file:line, and what condition on its output proves me wrong** — or ② an observable leading indicator (indicator + threshold + when to observe). Neither ⇒ this position is void and I hold no position here — not relabeled `value`>
```

**"What would change my mind ①" is the only legal source of a criterion** (§3): it carries its own check and condition, and it was written round-one independently. **`value` must cost more than `fact`** — a bare preference is the cheapest thing a model can emit, so it buys its way in with a refutable-preference sentence. **A `[value:]` is never quietly dropped: this skill's number-one failure mode** (A4 sweeps the platform's returns for it).

**Normalization, every round, field by field against that round's contract**: an unlabeled reason / an "it depends" position / a missing strongest-counter / **a missing or void "what would change my mind"** / a prediction missing a field / a value missing its preference sentence / a concession quoting no evidence / a rebuttal bringing nothing new ⇒ non-compliant ⇒ **re-dispatch once** (`kind: re-dispatch`). Immediately after its header write `re-dispatch-for: <superseded k>` then `missing-field: <field>`; the remaining body is byte-identical to the superseded prompt after its own header/linkage lines. Still non-compliant or empty ⇒ that seat leaves every "every seat" quantifier for the round; §7's `non-compliant` names seat and field. **The superseded dispatch, not its replacement, is what the audit excludes.**

**A hard failure is not a compliance failure.** Record `FAILED` only from a platform-authored failure status. A proven pre-launch failure may omit model/return/sidecar; a started or ambiguous failure must expose its sidecar for A9 or the run is unverifiable. Re-send once as `kind: retry` with `retry-for: <failed k>` immediately after the header. Preserve seat, round, `subagent_type` and prompt body byte-for-byte after removing the original header and retry's two header lines. The replacement assumes the failed functional kind; no second transport retry.

**Seat floors.** Fewer than 3 compliant *non-opposing* seats in round 1 ⇒ the consensus set is empty (the DA falls to its other targets) and §7 reads `seats-degraded`: two samples of one base model agreeing is the weakest form of already-weak evidence and may not be written up as "the council agreed". Fewer than 2 compliant seats in any round ⇒ `STOPPED (seats exhausted)`.

## 3. Aggregate

Every reason lands in **exactly one of three bins**, and the three are exhaustive: contradicted ⇒ crux; asserted by all ⇒ consensus; otherwise ⇒ unopposed.

1. **The consensus set** — propositions **every *non-opposing* round-1 seat explicitly asserted** (quote each; not mentioning ≠ agreeing), numbered `P1..Pn`, **each carrying its provenance** (`P1 <= A.r2, B.r1, C.r3`) so A4 can recompute the quantifier. The exclusion is on the *quantifier*, not on membership: if the opposing seat also asserts `P`, its reason lands here as support — and the DA still attacks `P`. A "consensus" traced to any `[value:]` is not consensus but a value crux.
2. **A crux's provenance** — `C1 <= A.r1, B.r2`. A crux is a *divergence*.
3. **An unopposed position** — asserted by **one or more seats** and **contradicted by none**; only the consensus quantifier excludes the opposing seat. The named-gap design guarantees these are common: seats raise what the others structurally cannot, so partial agreement is the normal shape of a council, not a defect. **A `[value:]` here is a value crux and gets a number**, however many seats hold it — otherwise every value crux could be parked out of the human's sight. Fact/prediction-class → the record's "Unverified assumptions", **and, if the opposing seat is among the asserters → DA-final's targets**: the opposing seat cannot attack itself, and its unopposed claims are the ones most likely to be sharp, load-bearing and wrong.

**Classification = priority aggregation over provenance labels, `value > prediction > fact`, locked both ways**: any traced `[value:]` ⇒ value crux (add-only); and a crux classified value must have a seat-labeled `[value:]` in its provenance — otherwise you promoted a fact to a value and handed the human your homework. A4 recomputes every class. **A crux born mid-debate** (a DA break, a partial concession's residual, a broken `P`) carries the `label: <fact|prediction|value> — <why>` line the seat wrote in that same return; no label ⇒ inherit the parent's class, or — for a broken `P` — the class of the reason that supported it. Never default to value.

**Fact ruling: the criterion is quoted from a seat, full stop.**

1. **Criterion** — its own message and its own turn, `criterion-C<n>`, **quoted verbatim from the "what would change my mind ①" of a seat in that crux's provenance**, before any command runs. **A seat's `[fact: locator]` is an artifact locator, never a criterion** — a bare locator carries no condition, so the condition would be yours, smuggled in through the ruling sentence. No traced seat's ① covers the crux ⇒ `unlookupable`; do not rule.
2. **Artifact** — its own message, `artifact-C<n>`: `command + verbatim output`, or `file:line + the quoted line`.
3. **Ruling** — derived mechanically ⇒ the crux closes as `ruled`.

Output cannot decide the criterion ⇒ not a fact: about the future → dispatch one `kind: label` request per traced seat, each naming that seat path and carrying its persona, prior raw return and this crux. Aggregate their one-line `label:` returns with the same `value > prediction > fact` priority and follow it; the moderator never supplies the label. **Not lookup-able today ⇒ `unlookupable`**: open, skips cross-examination, rides to the terminal. **It owes its evidence** — the traced seats' ①s and why none covers this crux — because a moderator-declared label with no evidence is a free exit.

**DA — mandatory, once, after aggregation.** Targets are **additive**: the consensus set **∪ every fact ruling** — a converging run is precisely the run that has a consensus set, so anything but a union leaves its rulings unattacked in exactly the runs that reach the strong token. Both empty ⇒ the target is the aggregation itself.

The DA dispatch carries the header + the fenced persona + the targets verbatim + **its own round-1 return** (a fresh subagent without its own words back is a memoryless re-roll) + the return format.

```text
For each target T:
T: <attack> — consulted: <file:line | command + verbatim output> — verdict <broken | unbroken: and what evidence WOULD break it (verifiable-today or an observable indicator)>
```

`consulted:` must genuinely resolve — A6 re-runs a command and re-reads a `file:line`. A broken `P` becomes a new crux; a broken ruling reopens. **`DA: no-op`** — every target "unbroken" with nothing resolvable, or the opposing seat unavailable / non-compliant twice: re-dispatch once; still so ⇒ §7 reads `DA no-op`, A6 verifies the no-op itself, and **the consensus set may not be marked "attacked"** (§8 then forbids citing it).

**DA-final — mandatory, after §4, *before* §5**, so the human is never asked to settle a state a later attack invalidates. Two target classes, **each its own dispatch**: (a) every crux closed in §4 by a concession or a mid-§4 ruling → to the opposing seat; (b) the opposing seat's unopposed fact/prediction positions → to a **non-opposing** seat. Concession is the cheapest close there is and its sincerity is unauditable, so §4's closes are exactly what needs a second look. No targets in a class ⇒ that dispatch is skipped; both empty ⇒ `DA-final n/a`.

**A DA-final `broken` verdict:** on a crux ⇒ it **reopens**; on an unopposed position ⇒ it becomes a new crux, class = the position's own label. A §4 round remaining ⇒ back to §4, then DA-final runs once more against **that round's closures only** — at most two passes; a break in the second is recorded open, never a third cycle. No round remaining ⇒ open, reason `reopened`. **A6 checks the outcome, not just the coverage**: a `broken` target still recorded closed (`conceded` *or* `ruled`) ⇒ FAIL — otherwise a moderator facing an attack whose success has no consequence simply never finds a break.

## 4. Cross-examination (default: at most 3 rounds — `R`)

Only for **prediction cruxes + fact disagreements not yet dissolved** (`unlookupable` stays out). **One dispatch per seat per round** (`kind: cross-exam`), carrying every open crux that seat is traced to: **every opposing position on that crux verbatim** + the crux number + each ruling's criterion-and-artifact line + **its own previous return**.

```text
On C<n>: <rebut | concede | partially concede>
- Rebut: **must bring one artifact or verbatim citation new to this crux** — otherwise it is restatement and the seat holds no position here this round. (Rebuttal costs what concession costs; if only concessions pay, everyone rebuts for free and round one hits deadlock.)
- Concede: write "I concede C<n>" and **quote verbatim** the one piece of evidence that moved you — ① a ruled fact's artifact, or ② a `[fact: …]` that actually appears in an opposing seat's return (copy it with its locator). The opponent's argument / position / reasoning is not evidence: an LLM handed the opposing argument concedes out of agreeableness.
- New crux (a partial concession's residual): `label: <fact|prediction|value> — <why>`
```

**A known dead corner, disclosed**: on a prediction crux where neither side holds `[fact:]` evidence, concession is structurally impossible — the only ways out are new artifacts, deadlock, or riding to the terminal.

**Partial concession**: the conceded part closes as `conceded`; the residual becomes a new crux.

**Re-seating**: a crux on a domain nobody owns ⇒ seat a tie-breaker on a **new axis**, **round-one independent first** (the crux + truth sources + its named gap + §2's contract — the crux is the seat's question; A0b's audited check still bars other seats' positions and names). Echoed in §1's format, its gap passing the transposition test, counted against the seat maximum and the one-synthesized cap, and never in the consensus quantifier. **At most 1 per round, 3 per run.**

**Termination, in order**: ① no open cruxes → DA-final → §5. ② only `value` and `unlookupable` open → DA-final → §5. ③ **deadlock**: a round in which no crux closed and no new artifact or citation entered. **It owes its evidence** — paste the searches you ran that returned nothing new. This is a disclosure, not a checked gate: nothing distinguishes "looked and found nothing" from "did not look", so the pasted searches are the only thing standing against a lazy deadlock. ④ round cap. Cruxes left open by ③/④ still go through DA-final and §5's value queue; the rest ride to the terminal.

## 5. The human, and the terminal

**① Value cruxes** (`/grilling` mode, adapted from mattpocock/skills). Value cruxes only.

- **One question at a time, then wait**; each question call carries exactly one question, and a call carrying none is a FAIL (A9 checks the arity — batching is offloading the decision).
- Each question: **the existing sides' positions verbatim, quoted in the question body** (the body has room; the option labels do not — never truncate a position to fit a label) + your recommendation and why (recommended option first) + the cost of getting it wrong; **one option must be "You decide (I abstain)"**.
- **Ask at least `min(3, V)` questions**, in descending cost-of-wrong (`V` = the number of distinct numbered value cruxes; A4 recounts it, and A9 FAILs a record whose `V` disagrees). A ceiling with no floor is not a budget: `asked 0, delegated 5` would satisfy "at most 3" and still reach the strong token.
- **`V > 3` ⇒ after the third question, ask one meta-question**: *"`N` value cruxes remain: `<list, each with its cost-of-wrong>`. ① Ask them, one at a time. ② I abstain on the rest. ③ Stop here."* ① continues to `asked == V`; ② closes them `delegated`; ③ closes them `unasked`. **A7 counts `unasked` as open**, so a run that stops there ends `UNRESOLVED (unasked: N open)`. The cap of 3 binds *you*, not the human — capping what the human may spend on their own decision would make `CONVERGED` unreachable for the very councils this protocol convenes.
- Never ask the human a fact. A choice ⇒ `human-settled`; "I abstain" ⇒ `delegated`; no answer ⇒ `STOPPED (awaiting human)`.

**② The terminal.** Build and freeze the **candidate record** (§8) at `workdir/candidate-<n>.md` — a new file per candidate, because overwriting a rejected or audit-failed candidate erases the finding. `**Status**: <token withheld>`; no line-initial terminal verdict anywhere in it. It declares assurance mode before either path and is never changed after its audit dispatch. Reserve the line prefixes `candidate-digest:`, `audit-dispatch:`, `canonical-audit-return:`, `presentation-record:`, `confirmation-record:`, `attestation-return:`, `PASS` and `FAIL:` for the post-candidate evidence envelope; any such line in candidate bytes is A9 failure.

**Advisory path.** Do not run §6 or fabricate an audit substitute. Paste the `Round-1 manifest:`, every moderator-visible raw return, crux ledger, DA outcome, human inputs, minority report and complete `Assurance gaps:` list.

| advisory state | token |
|---|---|
| no open cruxes | **`ADVISORY (debate-converged; unaudited)`** |
| open cruxes remain | **`ADVISORY (N open; unaudited)`**, listing them and what would resolve each |

`ADVISORY` is terminal and non-authorizing; confirmation cannot upgrade it.

**Audited path.** Run §6 over the frozen bytes. One audit + at most one re-audit per candidate. Read the verdict from the auditor's own sidecar; never append that return to the candidate it hashes. (Changing your transcript changes nothing the audit reads; log tampering remains in the honesty floor.)

Take the **first matching row**:

| state | action |
|---|---|
| A0 reports `blind: no` — a seat ran on a worker type that inherits context or can dispatch | emit `UNRESOLVED (not-blind: N open)` directly |
| no session log obtainable, the log lacks the dispatch that produced the auditor, or a canonical dispatch/prompt/return/resolved-model/per-worker-tool-log record that should exist disappears after one settle/re-read | emit `UNRESOLVED (dispatch-unverifiable: N open)` directly (N may be 0); this is an integrity failure, never a retroactive advisory downgrade |
| verdict FAIL on **A0 / A0b / A5** — a dispatch that never happened, one that happened and was hidden, a leaked prompt, fabricated concession evidence | **no re-audit.** These are evidence of fabrication, not quality defects; a retry budget that erases them erases the only checks that can see the protocol's core failure. Emit `UNRESOLVED (audit-failed: fabrication)` directly; §7 lists the failing checks |
| verdict FAIL on any other check, fixable, re-audit budget unspent | fix external run state without changing candidate bytes and re-audit; if candidate bytes must change, build and freeze `candidate-<n+1>.md` with a fresh audit budget; then re-enter this table |
| verdict FAIL, and (unfixable ∨ out of §4 rounds ∨ re-audit budget spent) | emit `UNRESOLVED (audit-failed: N open)` directly |
| no auditor return, or its last line is neither `PASS` nor `FAIL:` — after one `kind: retry` | emit `UNRESOLVED (unaudited: N open)` directly |
| verdict PASS ∧ open cruxes remain | present, then **emit directly**: `UNRESOLVED (<deadlock \| round-cap \| unlookupable \| unasked \| reopened \| rejected>: N open)` — **list every applicable reason**, comma-separated, in that order |
| verdict PASS ∧ no open cruxes | **present the candidate, then take the human's response as the next input** (below) |

**The post-candidate evidence envelope** is outside the hashed candidate and uses the reserved labels `audit-dispatch:`, `canonical-audit-return:`, `presentation-record:`, `confirmation-record:` and `attestation-return:` for the auditor dispatch, canonical return/digest projection, exact presentation, human response and attestation return. Present the frozen candidate plus the command that prints this evidence **from the platform's own record**. Three outcomes:

| the human… | action |
|---|---|
| confirms | run the post-confirmation attestation below; only its `PASS` may emit `CONVERGED`, with every applicable qualifier: `(single-model)` when §7 reads `correlated yes`; `(delegated D/V)` when `D > 0` — a run where the human abstained on every value call is a rubber stamp, and the token is where a reader looks |
| rejects | the candidate is void; convert the rejection into a constraint or a value ruling (**both recorded in §8's `## Human inputs`**), reopen the affected cruxes, back to §4. **With no §4 rounds left, or on a third rejection** ⇒ `UNRESOLVED (rejected: N open)` — re-presenting an unchanged candidate is how a human is trained to rubber-stamp |
| does not respond | `STOPPED (awaiting human)` |

**Implement nothing during a council run; wait for a later explicit user instruction.**

**Post-confirmation attestation.** The candidate auditor hashes the frozen candidate and puts `candidate-digest: sha256:<digest>` immediately before sidecar `PASS`; neither return nor digest enters the candidate. After presentation and confirmation, dispatch fresh `general-purpose` with `kind: audit` and only nonce, workdir/candidate, prior audit dispatch, original §0 pins and `post-confirmation-attestation`. It proves prior digest = presented digest = current SHA-256 and the platform-authored confirmation record. The interval permits only the read-only projection, presentation, one human response and this dispatch; any other dispatch or actual write under A9 ⇒ `FAIL: confirmation-unverifiable`. Put its return in the evidence envelope; failure emits `UNRESOLVED (confirmation-unverifiable: 0 open)`.

## 6. The auditor (audited mode only; mandatory before `CONVERGED`)

Advisory skips this section and records auditor `not run (advisory)`.

Dispatch a **fresh-context** `general-purpose` worker (it needs Bash), taking the next `k`.

**Payload has three forms.** Candidate audit: `run nonce · auditor k · workdir · candidate: <n> · seat echo · catalog rev · audit-procedure path+version/commit+SHA-256 · enumerator path+version/commit+SHA-256`; `candidate: <n>` is mandatory because a rejection rebuilds it. A0-only early-stop uses `early-stop reason`; A9 does not run. Attestation uses §5's smaller payload with the exact same pins. First hash-verify each pinned file against the payload's own `sha256:` — a digest match needs no log — then reconcile those pins against §0 before trusting either file; mismatch is A0 fabrication and emits `UNRESOLVED (audit-failed: fabrication)`, never retroactively advisory.

For `post-confirmation-attestation`, run the enumerator and only §5's identity, confirmation, dispatch and actual-write interval gates; do not re-run the earlier A0-A9 window. End with `PASS` or `FAIL: confirmation-unverifiable`.

**Bound the run on two platform-authored events, in ONE file:**

- **its end** — **the log containing your own dispatch record.** That file, and only that file, is the window. Absent from every log ⇒ `FAIL: replay — this log did not dispatch me`.
- **its birth** — the `openssl rand -hex 4` tool-call record **whose output is this nonce**, *in that same file*. Every dispatch in the run postdates it. Birth not in the file that dispatched you ⇒ `FAIL: replay`.

**Do not "walk every log that mentions the nonce".** A replay produces exactly the signature such an accommodation is written for: the moderator re-declares an old run's nonce ⇒ birth event in the old file, your dispatch in the new one, both bounds "satisfied" — and a whole previous council sits inside the window, inherited by a moderator who dispatched nothing but you. (Measured: across 164 logs, every log has exactly one `sessionId`, equal to its filename. The accommodation buys nothing and opens the door.)

**Enumerate first, never read the log whole.** After verifying the two payload digests, read the pinned SKILL.md for A0-A9 and the pinned references/auditor-enumerator.md; run its fenced script with the payload nonce and auditor dispatch `k`. It prints `LOG` plus canonical sidecar locators; use those emitted paths for every projection. A missing reference, digest mismatch, nonzero exit, or anything other than one discovered audit log is `FAIL: replay`; do not improvise another log search.

**An `UNVERIFIABLE` row is not a clean row.** The enumerator marks this in-flight audit/audit-retry `IN-FLIGHT`; pre-birth rows are count-only `PRE-RUN`. Only a platform-proven pre-launch `FAILED` may omit model/sidecar. Every started dispatch after birth needs exactly one sidecar, even when failed, because zero or duplicates hide its tools/return. Any `UNVERIFIABLE` ⇒ §5 emits `UNRESOLVED (dispatch-unverifiable: N open)`; never downgrade or pass.

`agentId` and `resolvedModel` live on the *result* record, joined by `tool_use_id` — a sweep that reads only the `tool_use` blocks recovers neither, and `toolUseResult` is sometimes a bare string (an error), so guard the index or the sweep aborts mid-file and silently truncates.

**Tool completeness.** Emit every non-`Agent` tool call from every opened record, including unknown names; omission is indistinguishable from no write, so A9 must classify rather than filter the tool inventory.

**The sidecar loop is not an optimization — it is A9.** A seat goes to `Explore`, which has `Bash`, so a seat *can* write; and **a seat's tool calls are never in this log**, they are in its own `subagents/agent-<agentId>.jsonl`. Sweep the main log alone and every `TOOL` row you print is the moderator's — you would PASS the write-gate having never opened a single seat's tool calls. Every check below reads that table plus targeted lookups. **Read a return by projection** — its canonical copy is the sidecar at the absolute locator printed on its `DISPATCH` row:

```bash
jq -rs 'map(select(.message.role=="assistant"))|last|.message.content[]|select(.type=="text")|.text' \
  "<locator from its DISPATCH row>" \
  | grep -nE '\[(fact|prediction|value):|What would change my mind|concede|label:|consulted:|Position:'
```

about ten lines each; materialize a whole return only to resolve a specific mismatch. Use the absolute locator printed on its `DISPATCH` row; on a resumed session the unique sidecar may sit under an earlier session directory.

```text
A0  Every dispatch in the window, against the platform's own records. **A dispatch record is ONLY a
    `{"type":"tool_use","name":"Agent"}` block**; a header in the moderator's prose is not one — its prose is in this file too,
    so a textual grep would pass on a dispatch that never happened, the one thing this check exists to catch.
      Exactly one §0 opening block exists. Its single procedure/enumerator pin line and full digests predate the first seat dispatch;
      every audit and attestation payload reproduces it byte-for-byte. A duplicate, late or changed
      post-hoc pin ⇒ FAIL.
      Every dispatch record in the window carries a well-formed header with a unique `k`. A dispatch with no
      header ⇒ FAIL (the hidden seat) — **unless §7 lists it as `out-of-band <id>: <reason>` AND its prompt
      contains neither the nonce, nor a seat path, nor 8 consecutive words of the proposition** (§5 hands
      control to a human, whose own requests must not be read as fabrication).
      Every `kind` in a header matches what that dispatch actually was: each `FAILED` row names the failed
      original; a `retry` carries `retry-for: <k>` naming exactly one earlier `FAILED` non-retry row, preserves
      its seat/round/type/body, and otherwise behaves like its functional kind. A `re-dispatch` carries canonical `re-dispatch-for`/`missing-field` lines, names one earlier successful non-re-dispatch, preserves seat/round/type/body and is unique for that target. The header was written BEFORE the return existed, so
      it cannot be a post-hoc reclassification — that is the whole reason it, and not a file, is the ledger.
      `subagent_type`, read from the log, **both branches spelled out**: every seat ran on `Explore` ⇒
      `blind: yes`. Any seat on `fork` (inherits your context) or `general-purpose` (it has `Agent`, so a seat
      could fan out and the dispatch count would stop being the run) ⇒ `blind: no`.
      **`Explore` has `Bash` and this check does not care**: a seat that writes is still `blind: yes`, and its
      writes are A9's business. Fail them here and every shell-backed seat — i.e. every seat this platform can
      give you — is `blind: no` before A9 ever opens its sidecar.
      Report, non-gating: `pre-run <dispatches>/<nonce-rolls>` — dispatch records BEFORE the birth event, and
      `openssl rand -hex 4` calls in the log. A council is self-driving and owns its session; a pre-polled
      council shows up here, and the reader is entitled to the number. **A pre-birth dispatch whose prompt
      carries the proposition (or 8 consecutive words of it) ⇒ FAIL** — a hidden seat must be handed the
      proposition to be a seat.
      Records lag: re-read once after a settle before ruling one missing. Exclude your own dispatch.
A0b Round-one independence did not leak — the JSONL `Round-1 manifest:` predates every round-one dispatch/return;
    reconcile its order/digests against the original frozen Agent attempts. The
    first functional dispatch for each `S` seat is round one, including a successful retry of its failed original.
    Every round-one / tie-breaker dispatch, re-dispatch or resolved retry prompt contains no other seat's position, no
    other seat's path, no "opposing seat" string; a synthesized persona contains no option/technology name
    from the proposition
A2  Catalog (gating): for every seated path — it exists at the recorded rev (`git -C ~/.agency-agents show
    <rev>:<path>`, read-only; never check out), it appears in the pasted
    listing, **and the file's body (minus frontmatter) is byte-identical to the `<persona>…</persona>` block
    of that seat's dispatch prompt in the log, ignoring whitespace** — a real path with an invented persona
    is cheaper than a fabricated path and is otherwise uncatchable. No two seats share a frontmatter `name:`.
    Catalog changes elsewhere are reported, not FAILed
A3  Every fact: the criterion is quoted verbatim from a traced seat's "what would change my mind ①" **in the
    platform's copy of that return** (moderator-authored, or lifted from a bare `[fact:]` locator ⇒ FAIL);
    `criterion-C<n>` precedes `artifact-C<n>` in the log's record order; re-run the command, or re-read the
    `file:line` and diff the quoted line — same ruling under the same criterion (bytes may differ for a
    time-varying command; **a flipped truth value is a FAIL on a stable fact** — where the value can legitimately change between the seat's run and the re-run, the divergence is disclosed as `time-varying`, not FAILed).
    **`html.unescape()` BOTH SIDES before any diff here or in A5.** The moderator only ever saw the
    `<task-notification>` copy, which is entity-escaped; the sidecar you read is raw. And the return contract
    *mandates* angle brackets — `[fact: <file:line>]`, `threshold=<comparator+value+unit>` — so a criterion
    quoted **faithfully** comes to you as `&gt;`, byte-mismatches the raw `>`, and you FAIL an honest run.
    A byte-diff without this normalization fails the honest and catches no one.
A4  Recompute, from the platform's copies of the returns: every crux's class; the three bins (a reason is
    contradicted ⇒ crux, asserted by all non-opposing ⇒ consensus, else ⇒ unopposed); **every `P` was
    asserted by EVERY compliant non-opposing round-1 seat — one seat short ⇒ it is an unopposed position, not
    consensus ⇒ FAIL**; **every `[value:]` in a round-1 or tie-breaker return maps to a NUMBERED value crux
    (many-to-one is fine; unmapped ⇒ FAIL), and `V` is the count of those cruxes**. Excluded: superseded
    (`re-dispatch`ed) dispatches, `FAILED` dispatches, and seats §7 records `non-compliant` — the exclusion set
    must equal exactly that. Every `label` request/return reconciles to its traced seat path, persona and prior return
A5  Every concession quotes a ruled artifact, or a `[fact:]` that actually exists in an opposing seat's
    platform return. **Every quote in the §1 echo, the §8 record and the Minority report matches its return**
A6  For every §4 round, reconstruct the eligible open cruxes and their traced compliant seats at round start
    from canonical returns, resolving retries to their failed functional kind. Require exactly one cross-exam dispatch per traced seat; its prompt contains every
    eligible crux traced to that seat and every opposing position on each. Any missing/duplicate seat or crux
    ⇒ FAIL. If §7 says `DA no-op` ⇒ verify the no-op. Otherwise: the DA covered the additive target set; DA-final covered both classes; **every DA-final `broken` verdict has its crux recorded open (`reopened`) or
    re-argued in a later §4 round — a `broken` target still recorded `conceded` OR `ruled` ⇒ FAIL**; every
    `consulted:` resolves
A7  Every crux is closed (`ruled` / `conceded` / `human-settled` / `delegated`) or listed open in the
    candidate. `unlookupable`, `unasked` and `reopened` are OPEN
A8  Every audited-mode §7 field is present (a dropped field is a FAIL, not a vacuous pass), `mode audited`,
    and reconciles against the log:
    `dispatches` = all records except audit/attestation and a retry whose `retry-for` names an audit; `retries`
    = every `kind: retry`; `candidates` (= `ls
    workdir/candidate-*.md`), `rejected`, `rounds`, `concessions`, `non-compliant`, `seats`, `tie-breakers`,
    `seats-degraded`, `opposing`, `round1`, `blind`, `provenance`, `DA`, `DA-final`, `value cruxes (asked/delegated/unasked)`, and
    **`models`: over successful SEAT-FACING dispatches only** — seat / re-dispatch / cross-exam / DA / DA-final /
    tie-breaker / label, plus a successful retry whose `retry-for` resolves to one of those. **Exclude every
    `FAILED` row and your own audit/attestation or auditor retry** (it goes to `general-purpose` while the seats go
    to `Explore`, and two worker types routinely resolve to two models — counting yourself is exactly the
    accident this check exists to prevent, one level up). Lowercase, strip
    a context-tier suffix (`[1m]`, `[1M]`) and a trailing `-<8 digits>`, count distinct BASE models, and
    **paste the raw→base mapping** so an over-count is visible. `correlated yes` ⇔ `models 1`; a violation ⇒ FAIL
A9  `workdir` and both audit pins resolve from §0's echo **in the log** (any payload ≠ echo ⇒ FAIL) and workdir is not `/`, `$HOME`, or an
    ancestor of the project root. No tool call in the log writes into `~/.agency-agents` — the seats come
    from the user's checkout, so a run that populated it seated agents the user never installed. The payload's `candidate: <n>` equals the candidate's `Candidate:` line
    **and** the highest `n` in `ls workdir/candidate-*.md`; lower ⇒ FAIL (you were handed a rejected draft).
    The candidate has no line beginning with a reserved evidence-envelope prefix, no line-initial terminal
    verdict, and its **Status** reads `<token withheld>`; on candidate-audit PASS hash those exact bytes after their last write and emit
    `candidate-digest: sha256:<digest>` immediately before `PASS`; `asked >= min(3, V)` against A4's `V`, and `V > 3` ⇒ the meta-question is in the log
    (with `asked == V` iff the human chose ①); every `AskUserQuestion` call carries a `questions` array of
    length exactly 1.
    **The human's choice is NOT in the `AskUserQuestion` call's `toolUseResult`.** That object is a verbatim
    echo of the moderator's own *input* — `{question, header, multiSelect, options}` — the options it offered,
    never the one taken. Read it and you find the moderator's claimed label sitting in the list the moderator
    wrote, and you pass: **the graded party would be producing the gate's evidence.** The human's answer is in
    the *following* `user` record's `tool_result` content string:
    `Your questions have been answered: "<question>"="<the chosen label>"`. **That string is the only evidence.**
    A `human-settled` line that does not match it ⇒ FAIL.
    **The write-gate.** A worker's tool calls are recorded **with the worker** — `subagents/agent-<agentId>.jsonl`
    — **not in this log**. The enumeration above already opens each one; if you did not run its sidecar loop,
    every `TOOL` row you have is the moderator's and **you have not checked the seats at all**. Seats go to
    `Explore`, which **has `Bash`** — a seat *can* write (`> file`, `sed -i`), and this sweep is the only thing
    that catches it. Between §0's echo and now: a write tool naming a path outside `workdir`, or a shell command
    containing a redirect (`>`, `>>`, `| tee`) or a mutating verb (`rm mv cp ln touch chmod sed -i dd git commit git add git checkout apply_patch`, and any sibling that writes: `truncate`, `perl -i`, `tee`, `chown` …) targeting a path outside `workdir` ⇒ FAIL. The verb list is illustrative, **not a closed set** — the test is whether it writes outside `workdir`, and when in doubt, treat it as a write. `mkdir workdir` is the one
    exception §0 requires. Predeclaration on a `criterion-C<n>` / `artifact-C<n>` / `consulted:` line may
    identify an artifact command, but never exempts one that actually writes: write semantics always win.
    Only demonstrably read-only artifact commands are allowed (`npm ls`, `pip show`, `openssl`, `find`, `grep`,
    `git show`); ambiguity is a write and FAILs outside `workdir`.
Answer each check. **A PASS must carry its evidence** — the enumeration rows, every command and output cited by a check, and both sides of every comparison. **A PASS with no pasted evidence is a FAIL of that check.**
Last line: `PASS` or `FAIL: <ids + evidence>`
```

## 7. Quality line (mandatory; A8 reconciles audited fields)

```text
Quality: run <nonce> | mode <audited|advisory> | dispatches <n> (retries r) | candidates <n> (rejected j) | pre-run <d>/<rolls|unknown>
  | seats <n> (tie-breakers d, synthesized c, outside the consensus quantifier) <| seats-degraded>
  | round1 <parallel|batched> | provenance <canonical|moderator-visible> | models <n distinct base (host-recorded)|unknown>
  | correlated <yes|no|unknown> | blind <yes|no|not-certified> | non-compliant <seat=field,… | none>
  | opposing <path> | rounds R | concessions C | out-of-band <id: reason,… | none>
  | DA <attacked P, broke B | no-op> | DA-final <pass1: attacked P, broke B[; pass2: …] | n/a>
  | value cruxes V (asked A, delegated D, unasked U)
  | auditor <pending | PASS | FAIL(ids) | not run (advisory) | cannot re-run | dispatch-unverifiable>
```

## 8. Decision record

```markdown
**Status**: <token withheld>
Run: <nonce> · Workdir: <path> · Candidate: <n>

## Decision
<one line + the reasoning>
**Seats may be the same base model wearing different personas; agreement is weak evidence. An unknown model
census is treated as correlated for decision-writing. "Converged" = no fabrication was caught, NOT = the
conclusion is right; "Advisory" makes no fabrication claim at all.**
**In advisory mode, or when `correlated yes` / `DA no-op`, the consensus set may not be cited as support here** —
unverified provenance, an unattacked claim, or one model agreeing with itself launders repetition into a reason.
**Traceability** (one of five; no sixth): ① a seat's position verbatim (name it); ② the human's choice;
③ your recommendation after explicit delegation (name the crux — and note that nothing attacked it);
④ **a fact ruling's criterion + artifact** (§3) — the command output or `file:line` that closed the crux;
⑤ a synthesis of ①–④ — every claim it makes must appear in one of them; it may recombine and exclude, never
introduce.

## Quality
<the Quality line>

## Assurance
Mode: <audited|advisory>
Round-1 manifest: <parallel|batched> · <prompt digests or full frozen prompts>
Preserved: <catalog personas; fresh round-one contexts; crux ledger; DA/cross-exam; human value rulings; minority report>
Assurance gaps: <none | comma-separated canonical ids — see Assurance modes on Claude Code>
Soft checks: <commands and exact scope | none>

## Audit binding
<audited: `post-candidate evidence envelope` outside these frozen bytes | advisory: `not run (advisory)`>

## Human inputs
<one line per touchpoint: each question with the option chosen; each rejection verbatim + the constraint or
value ruling it became. What the human objected to shapes every later round and is otherwise unreconstructable.>

## How the debate resolved
- Consensus (asserted by every non-opposing round-1 seat; DA outcome noted): P1 <= A.r2, B.r1, C.r3 -> unbroken | P2 broken -> C4
- C1 [fact <=A.r1] -> criterion (quoted from A's ①) -> artifact -> ruling
- C2 [prediction <=A.r2,C.r1] -> who conceded / which evidence they quoted -> DA-final <unbroken | reopened>
- C3 [value <=C.r2] -> the human's choice | delegated (recommendation + cost)
- Every value crux with its cost-of-wrong (asked, delegated, unasked): …
- C5 [open] -> why unresolved + what would resolve it (for an `unlookupable`: the traced ①s, and why none covers it)

## Minority report (transcribe only; never author)
① the positions of seats that never conceded; ② each concession's "remaining objection"; ③ if both empty → each seat's "strongest argument against my own position".

## Unverified assumptions
<what the decision rests on but nobody checked — including unopposed fact/prediction reasons — + how to check (indicator + threshold + when)>
```
