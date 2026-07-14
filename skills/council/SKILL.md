---
name: council
description: Use for open decisions with NOTHING WRITTEN yet — technology selection, architecture, whether to build something. Pulls real specialists from the agency-agents catalog (one seat per named viewpoint gap, 4 or more), gets independent blind positions on ONE decision, and numbers the disagreements into cruxes. A fact closes only on a criterion QUOTED from a seat's blind "what would change my mind" plus a re-runnable command output; judgment calls go to the human one question at a time with a recommended answer; the rest is argued out in rounds. The moderator keeps no copy of anything the audit checks: before any CONVERGED, a mandatory auditor in a fresh context reads the platform's own records — every dispatch, its prompt, its worker type, its model, its return — and reconciles the run against them. Self-driving. Triggers - convene a council, multi-expert debate, get several perspectives on this decision, have some experts argue this out, 开个评议会, 让几个专家吵一下, 多视角讨论这个方案, 找专家评议, 这个选型该怎么定. Something already written — a proposal, a spec, a diff — that needs tearing apart is review-loop, not council.
---

# council

One decision with nothing written yet → one real specialist per named gap (4+) gives an independent blind position → extract the disagreement → argue → converge. **Anything already written (a proposal, a spec, a diff) that needs tearing apart → `review-loop`.**

## Terms

Each term's rules live in its section. This list is glosses and pointers.

- **crux** — the specific proposition two seats **diverge** on ("will write QPS exceed 2k?", not "A picks Postgres"), numbered `C1..Cn`.
- **named gap** — one sentence naming the constraint this seat will raise that no other seat structurally can. Test by **transposition**: move the sentence to another seat's name; if it still holds, it is not a gap.
- **blind** — a seat runs in a fresh context holding only the proposition, the truth sources and its own persona. Platform Adapter owns the mechanism; A0 checks it.
- **DA** — the opposing seat's attack round (devil's advocate), §3. **DA-final** — its second stage, §3.
- **run nonce** — the 8 hex characters `openssl rand -hex 4` prints in §0. The platform records that call *and its output*, so the run has a birth event the moderator did not author.
- **`k`** — the dispatch counter, one per dispatch, never reused. §2.
- **session log** — the file the platform writes: your prose, your tool calls with their arguments **and outputs**, and every dispatch with its prompt, its worker type, its model and its return. You author the first kind of record; the platform authors the rest.
- **workdir** — a fresh directory holding the run's *deliverables* (`candidate-<n>.md`), and nothing the audit depends on. **You keep no copy of any evidence** — the platform has it all, and a copy you hold is a copy you can rewrite.
- **seat** — one specialist subagent occupying one axis for the whole run, identified by **its catalog path** (the frontmatter `name:` is a display name — `Database Optimizer`, not the slug — and is used only to deduplicate). **axis** — one conflicting-interest dimension (§1). **tie-breaker** — a seat added mid-run on a new axis (§4).
- **truth sources** — the repo paths / docs handed to every seat in round 1, echoed in §0.
- **token** — `CONVERGED` (needs an audit PASS and the human's confirmation) or `UNRESOLVED (…)` / `STOPPED (…)` (reports; they do not need consent to be true).
- **candidate record** — the §8 record built before emission, `**Status**: <token withheld>`.
- **refutable** — a sentence a reader could name evidence *against*. "Use Postgres" is not; "Postgres over SQLite, because write QPS will exceed 2k" is.
- **cost-of-wrong** — one clause: what breaks, how expensively, if this crux is settled wrong. It orders §5's queue.
- **unlookupable** — a fact crux no traced seat's ① covers, or that nothing available today can check. Open. §3.
- **unasked** — a value crux the human chose not to be asked. Distinct from `delegated` (they saw it and abstained). Open. §5.
- **seat letters** — `A`, `B`, `C`… assigned in the §1 echo; `A.r1` = seat A's reason 1. **`P1..Pn`** — the consensus propositions, §3.

## Honesty boundary (read first — it is the shape of every rule below)

The seats are **the same base model wearing different personas**: blindness isolates context contamination, never model-level correlation. "Three experts independently agreed" and "one model sampled three times" are structurally indistinguishable — **agreement is weak evidence, not consensus.**

And the moderator (you) is at once the author of the proposition, the appointer of seats, the classifier, the fact adjudicator and the writer of the record, with exactly one incentive: **to be done**. So this skill sets no gate you grade yourself against. It does one thing:

> **Keep no copy of your own evidence. Every artifact the audit reads is one the platform wrote — so every shortcut leaves a hole in a file you did not author, findable from a different context.**

**What the auditor can catch**: a dispatch that never happened, a dispatch that happened and was hidden, a return misquoted in the record, a persona that was not the expert's, a prompt that leaked another seat's words, a fabricated path, output or citation, a write made before consent, a human's answer recorded as something other than what they chose.

**What it structurally cannot catch — the floor:**

- **The runs you discard.** Every gate binds the run you *declare*. Nothing binds the councils you rehearsed and threw away. A moderator willing to spend the tokens can try seat sets, truth sources and propositions until one converges, and every artifact of the run it finally opens will be genuine. A0 *counts* pre-birth dispatches and prints the number; it cannot know what they were for.
- **How you carve the disagreements.** N disagreements into M cruxes is judgment; no check recomputes the carving.
- **The auditor's own honesty.** It can fabricate a re-run's output as cheaply as you can fabricate a return. Its tool calls are in its own record and nothing reads them. This is one turtle further down than this protocol goes.
- Whether a criterion is *relevant*; whether a synthesized persona is *sound*; **the sincerity of a concession** (citing existing evidence is nearly free); **the quality of a DA attack**; **the fairness of §5's question ordering**; **your recommendation on a `delegated` crux** (the human abstained; nothing attacks what you then decided); **your selection of truth sources**; **tampering with the log** (it runs under your uid).

So `CONVERGED` means **no fabrication was caught** — not "the conclusion is right".

**Correlation is disclosed, never priced away.** When every seat, the DA and the auditor run on one base model, the consensus set is one model agreeing with itself: §7 records it, §8 forbids citing the consensus set as support, and the token says so. `models` counts *distinct base models* and is a **lower bound** on de-correlation.

## Platform Adapter

- **The seat worker** = a fresh worker with no preset persona, **no ability to dispatch**, and **every tool call it makes recorded in a per-worker record you can read** — a seat that can fan out makes the dispatch count, the model census and the write-gate an accounting of the root's edges only. **Not "cannot write": a worker with a shell can write** (`> file`, `sed -i`), and the read-only worker types real platforms ship have shells. Writes are therefore **not prevented — they are caught**, by A9's sweep of each worker's own record. That sweep is load-bearing, not belt-and-braces. **A worker that inherits your context (a "fork") is never a seat**, and neither is any mechanism that *continues* an already-running worker — a continuation leaves no new dispatch record, so A0 reads it as a dispatch that never happened. No fresh, non-dispatching worker whose tool calls are recorded ⇒ `STOPPED (cannot run blind)`.
- **The auditor worker** = fresh context, with a shell (grep / stat / re-run / hash). None ⇒ `auditor cannot re-run` (§5).
- **Session log** — the platform must write, per dispatch, a record you did not author, carrying the prompt, the worker type, the resolved model and **the return**. It must also record *your* tool calls with their outputs, and the seats' (if a seat can act at all). Supply §6 with: **the discovery command**, **the dispatch-record predicate**, **the enumeration command** (one row per dispatch: `k`, dispatch id, worker type, resolved model, prompt digest — parsed from the record, not truncated out of it), and **the return locator** (the platform's *one canonical* copy — **if it stores a return twice, the copies may differ in escaping, and the canonical one is the one the moderator never sees**). No canonical copy ⇒ `STOPPED (returns unverifiable)`: without it, A3/A4/A5 read what you typed, and this protocol's central guarantee is gone.
- Ask the human through whatever single-question affordance exists; with none, print one question and stop.

## 0. Self-driving, and what every STOPPED costs

**council never hands control back except at §5's human touchpoints.** An audit FAIL on a quality check means fix and re-audit; an audit FAIL on **A0 / A0b / A5** is evidence of fabrication, not a defect to fix, and takes §5's fabrication row directly.

**Open the run.** Create `workdir` (fresh; not `/`, not `$HOME`, not an ancestor of the project root — A9 rejects those), then:

```bash
openssl rand -hex 4                                  # the nonce: the platform records the call AND its output
git -C ~/.agency-agents rev-parse HEAD               # the catalog rev A2 will re-read at
```

```text
run: <nonce> | workdir: <path> | catalog: <rev>
proposition: <one refutable sentence>
truth sources: <the paths/docs every seat gets in round 1>
```

The proposition goes **verbatim** to every seat; the dispatch prompt carries no evaluative wording, no lean of yours, and no role hint like "you are the opposing seat" — opposition is the persona's job, and A0b greps the log for the leak. A proposition that cannot be compressed into one refutable sentence without hiding a second decision inside it ⇒ `STOPPED (proposition needs splitting)`.

**Every `STOPPED` owes evidence** — otherwise quitting before you start is the only free door. **A `STOPPED` emitted after any dispatch also owes A0** (a full run relabelled as an early exit is the cheapest cheat, and it is the one exit that would otherwise skip the audit): dispatch the auditor with the nonce + the A0 block only. **An A0 FAIL there ⇒ `UNRESOLVED (audit-failed: fabrication)` instead of the STOPPED token.**

| STOPPED reason | trigger | evidence owed |
|---|---|---|
| proposition needs splitting | above | the ≥2 decisions it splits into, one refutable sentence each, **plus the axes — at least §1's three — of the one you recommend convening first** (prepay §1's work; cannot list two decisions ⇒ it is not several decisions — convene) |
| not a council question | fewer than 3 or more than 8 non-opposing axes (§1) | the axes you derived, with named gaps, and which interest lacks a representative |
| seats exhausted | fewer than 2 compliant seats in a round (§2) | the failed seats' dispatch ids |
| no real experts: catalog unavailable | zero real experts (§1) | the verbatim `find` output; the message carries `git clone https://github.com/msitarzewski/agency-agents ~/.agency-agents` for the user to run and retry — **do not stop and wait for the clone** |
| no real experts: none on the opposing axis | no catalog match on that axis (§1) | the `find` output + the candidates you read and why each fails the axis |
| no real experts: a second axis has no match | a second seat would have to be synthesized (§1) | the two unmatched axes + the listing lines you searched + why each candidate fails each (the raw `find` output alone *misleads* here — it shows a healthy catalog) |
| cannot run blind | no fresh, non-dispatching worker whose tool calls are recorded (Platform Adapter) | the workers you do have and why each fails |
| returns unverifiable | the platform keeps no canonical copy of a return (Platform Adapter) | which record shapes you found and why none is canonical |
| awaiting human | a §5 question or presentation got no answer | the question or candidate as presented. **A suspension, not an exit** — the platform holds the run, so a resumed session picks up from it, and **no timeout converts silence into consent** |

## 1. Seat the council

**Axes first, people second.** If this decision is wrong, who gets hurt? Cover ① the primary domain, ② the interest naturally in tension with it, ③ the downstream actually touched (security / cost / maintainability / users / compliance). One named gap per axis.

- **Three to eight *non-opposing* axes**, one seat each; the **opposing seat** (§3) is a further seat on its own axis, named here and never re-designated. **Minimum council: 4 seats; maximum 9, tie-breakers included.** Outside that ⇒ `STOPPED (not a council question)` — below it there is no conflict to arbitrate; above it, fan-out quality collapses.
- **One seat per named gap.** A seat with no gap merely restates another and thickens the illusion of independent agreement.
- Below 2 seats mid-run ⇒ `STOPPED (seats exhausted)`.

**Enumerate the catalog before naming any seat** — names invented from an axis (`stability-advocate`, `contrarian`) match nothing:

```bash
find ~/.agency-agents -type f -name '*.md' \
  ! -iname 'README*' ! -iname 'CONTRIBUTING*' ! -iname 'SECURITY.md' ! -path '*/.github/*' | sort
```

The exclusions are anchored to exact filenames, not prefixes — a prefix glob would delete the whole `security-*` division. Paste the output.

Pick candidates per axis; read each frontmatter to confirm it *is* that axis. Echo the seats; **the format is fixed** (the auditor parses it):

```text
axis 1: considered <path-a>, <path-b> -> seated <path-a> (<one clause: why the other lost>)
  A. <absolute path>              # its body, minus frontmatter, IS the persona
  B. <absolute path>
  D. synthesized                  # genuinely absent -> you author the persona, inline in the prompt
opposing: <seat letter>
```

- **A seat is its path.** Deduplicate by frontmatter `name:` (a flat-cache copy and its division copy are one agent) — but never *name* a seat by it: the frontmatter carries a display name, not the slug.
- **Record who you rejected, not only who you seated.** Which experts enter the room is the largest bias lever in the protocol and otherwise leaves the shortest trace.
- **Do not pass a model.** The platform records the resolved model on every dispatch; A8 reads it there. A model you *type* is a claim.
- **At most ONE `synthesized` seat**, tie-breakers included — a self-authored persona is your own words fed back to you and the auditor structurally cannot check it. A second ⇒ `STOPPED (no real experts: a second axis has no match)`. Its text may not contain any option or technology name from the proposition (A0b checks).
- **The opposing seat may not be synthesized** — authoring the agent whose job is to break your own consensus hands the anti-echo mechanism to the echo. None on that axis ⇒ `STOPPED (no real experts: none on the opposing axis)`. Zero real experts ⇒ `STOPPED (no real experts: catalog unavailable)`.

## 2. Dispatch

**Every dispatch prompt begins with the header, and the persona is fenced:**

```text
council: <proposition> | run: <nonce> | seat: <path | —> | round: <n> | kind: <seat|re-dispatch|retry|cross-exam|DA|DA-final|tie-breaker|label|audit> | dispatch: <k>
<persona>
…the catalog file's body, verbatim, minus frontmatter. Nothing else inside these markers.…
</persona>
…the proposition, the truth sources, and the round's return contract…
```

`k` is a per-run counter, never reused; the auditor takes the next `k`. `seat:` reads `—` only for a label recall and the auditor.

**The header is the whole ledger, and that is the point**: the platform records it verbatim, **at dispatch time, before the return exists** — so you cannot reclassify a dissenting seat as a `retry` after reading it. There is no ledger file to keep, and nothing for you to author that the audit then trusts.

**Keep no copy of any return.** Read it, work from it, quote it into the record — but the platform's copy is the one every check reads, and a copy you hold is a copy you can rewrite.

Round 1: dispatch every seat in one message.

```text
Position: <one refutable sentence. "It depends" is not a position>
Reasons (1-3, each labeled — three `fact` reasons is legal):
  [fact: <file:line | command | URL>] <…>
  [prediction: indicator=<name> threshold=<comparator+value+unit> observe=<when/where>] <…> -> falsified if: <…>
  [value: <the preference it rests on — a sentence "I don't care about X" would refute, naming which two options it ranks>] <…>
Strongest argument against my own position: <mandatory>
What would change my mind: <mandatory. Either ① something the moderator can verify today — **state the concrete check: a command or file:line, and what condition on its output proves me wrong** — or ② an observable leading indicator (indicator + threshold + when to observe). Neither ⇒ this position is void and I hold no position here — not relabeled `value`>
```

**"What would change my mind ①" is the only legal source of a criterion** (§3): it carries its own check and condition, and it was written blind. **`value` must cost more than `fact`** — a bare preference is the cheapest thing a model can emit, so it buys its way in with a refutable-preference sentence. **A `[value:]` is never quietly dropped: this skill's number-one failure mode** (A4 sweeps the platform's returns for it).

**Normalization, every round, field by field against that round's contract**: an unlabeled reason / an "it depends" position / a missing strongest-counter / **a missing or void "what would change my mind"** / a prediction missing a field / a value missing its preference sentence / a concession quoting no evidence / a rebuttal bringing nothing new ⇒ non-compliant ⇒ **re-dispatch once** (`kind: re-dispatch`). It carries the same prompt body + the contract restated + one structural line naming the missing **field** — never quoting the previous content, so round-1 and tie-breaker re-dispatches stay blind (A0b checks). Still non-compliant or empty ⇒ that seat leaves every "every seat" quantifier for the round; §7's `non-compliant` names seat and field. **The superseded dispatch, not its replacement, is what the audit excludes.**

**A hard failure is not a compliance failure**: an errored, timed-out or empty dispatch is re-sent once as `kind: retry` **without consuming the compliance budget** — a flaky transport must not cost a seat its only retry. A `retry` dispatch has no return; A0 asserts its record shows the failure.

**Seat floors.** Fewer than 3 compliant *non-opposing* seats in round 1 ⇒ the consensus set is empty (the DA falls to its other targets) and §7 reads `seats-degraded`: two samples of one base model agreeing is the weakest form of already-weak evidence and may not be written up as "the council agreed". Fewer than 2 compliant seats in any round ⇒ `STOPPED (seats exhausted)`.

## 3. Aggregate

Every reason lands in **exactly one of three bins**, and the three are exhaustive: contradicted ⇒ crux; asserted by all ⇒ consensus; otherwise ⇒ unopposed.

1. **The consensus set** — propositions **every *non-opposing* round-1 seat explicitly asserted** (quote each; not mentioning ≠ agreeing), numbered `P1..Pn`, **each carrying its provenance** (`P1 <= A.r2, B.r1, C.r3`) so A4 can recompute the quantifier. The exclusion is on the *quantifier*, not on membership: if the opposing seat also asserts `P`, its reason lands here as support — and the DA still attacks `P`. A "consensus" traced to any `[value:]` is not consensus but a value crux.
2. **A crux's provenance** — `C1 <= A.r1, B.r2`. A crux is a *divergence*.
3. **An unopposed position** — asserted by **one or more** non-opposing seats and **contradicted by none**. The named-gap design guarantees these are common: seats raise what the others structurally cannot, so partial agreement is the normal shape of a council, not a defect. **A `[value:]` here is a value crux and gets a number**, however many seats hold it — otherwise every value crux could be parked out of the human's sight. Fact/prediction-class → the record's "Unverified assumptions", **and, if the opposing seat is among the asserters → DA-final's targets**: the opposing seat cannot attack itself, and its unopposed claims are the ones most likely to be sharp, load-bearing and wrong.

**Classification = priority aggregation over provenance labels, `value > prediction > fact`, locked both ways**: any traced `[value:]` ⇒ value crux (add-only); and a crux classified value must have a seat-labeled `[value:]` in its provenance — otherwise you promoted a fact to a value and handed the human your homework. A4 recomputes every class. **A crux born mid-debate** (a DA break, a partial concession's residual, a broken `P`) carries the `label: <fact|prediction|value> — <why>` line the seat wrote in that same return; no label ⇒ inherit the parent's class, or — for a broken `P` — the class of the reason that supported it. Never default to value.

**Fact ruling: the criterion is quoted from a seat, full stop.**

1. **Criterion** — its own message and its own turn, `criterion-C<n>`, **quoted verbatim from the "what would change my mind ①" of a seat in that crux's provenance**, before any command runs. **A seat's `[fact: locator]` is an artifact locator, never a criterion** — a bare locator carries no condition, so the condition would be yours, smuggled in through the ruling sentence. No traced seat's ① covers the crux ⇒ `unlookupable`; do not rule.
2. **Artifact** — its own message, `artifact-C<n>`: `command + verbatim output`, or `file:line + the quoted line`.
3. **Ruling** — derived mechanically ⇒ the crux closes as `ruled`.

Output cannot decide the criterion ⇒ not a fact: about the future → return it to the traced seats for a one-line `label:` (`kind: label`) and follow it. **Not lookup-able today ⇒ `unlookupable`**: open, skips cross-examination, rides to the terminal. **It owes its evidence** — the traced seats' ①s and why none covers this crux — because a moderator-declared label with no evidence is a free exit.

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

**Re-seating**: a crux on a domain nobody owns ⇒ seat a tie-breaker on a **new axis**, **blind first** (the crux + truth sources + its named gap + §2's contract — the crux is the seat's *question*; A0b's leak check still bars other seats' positions and names). Echoed in §1's format, its gap passing the transposition test, counted against the seat maximum and the one-synthesized cap, and never in the consensus quantifier. **At most 1 per round, 3 per run.**

**Termination, in order**: ① no open cruxes → DA-final → §5. ② only `value` and `unlookupable` open → DA-final → §5. ③ **deadlock**: a round in which no crux closed and no new artifact or citation entered. **It owes its evidence** — the searches you ran that returned nothing new; a deadlock reached by not looking is a free exit. ④ round cap. Cruxes left open by ③/④ still go through DA-final and §5's value queue; the rest ride to the terminal.

## 5. The human, and the terminal

**① Value cruxes** (`/grilling` mode, adapted from mattpocock/skills). Value cruxes only.

- **One question at a time, then wait**; each question call carries exactly one question, and a call carrying none is a FAIL (A9 checks the arity — batching is offloading the decision).
- Each question: **the existing sides' positions verbatim, quoted in the question body** (the body has room; the option labels do not — never truncate a position to fit a label) + your recommendation and why (recommended option first) + the cost of getting it wrong; **one option must be "You decide (I abstain)"**.
- **Ask at least `min(3, V)` questions**, in descending cost-of-wrong (`V` = the number of distinct numbered value cruxes; A4 recounts it, and A9 FAILs a record whose `V` disagrees). A ceiling with no floor is not a budget: `asked 0, delegated 5` would satisfy "at most 3" and still reach the strong token.
- **`V > 3` ⇒ after the third question, ask one meta-question**: *"`N` value cruxes remain: `<list, each with its cost-of-wrong>`. ① Ask them, one at a time. ② I abstain on the rest. ③ Stop here."* ① continues to `asked == V`; ② closes them `delegated`; ③ closes them `unasked`. **A7 counts `unasked` as open**, so a run that stops there ends `UNRESOLVED (unasked: N open)`. The cap of 3 binds *you*, not the human — capping what the human may spend on their own decision would make `CONVERGED` unreachable for the very councils this protocol convenes.
- Never ask the human a fact. A choice ⇒ `human-settled`; "I abstain" ⇒ `delegated`; no answer ⇒ `STOPPED (awaiting human)`.

**② The terminal.** Build the **candidate record** (§8) at `workdir/candidate-<n>.md` — a new file per candidate, because a rejected candidate is the strongest signal the council is off and overwriting it erases the finding. `**Status**: <token withheld>`; no line-initial terminal verdict anywhere in it (A9 greps `^(CONVERGED|UNRESOLVED|STOPPED)`). Run §6's audit. **One audit + at most one re-audit per candidate**; a candidate rebuilt after a human rejection is a new candidate with a fresh budget.

**Read the verdict from the auditor's own record in the log** — the platform's copy, which you cannot rewrite — not from what you transcribed.

Take the **first matching row**:

| state | action |
|---|---|
| A0 reports `blind: no` — a seat ran on a worker type that inherits context or can dispatch | emit `UNRESOLVED (not-blind: N open)` directly |
| no session log obtainable, or the log does not contain the dispatch that produced the auditor | emit `UNRESOLVED (dispatch-unverifiable: N open)` directly (N may be 0) |
| verdict FAIL on **A0 / A0b / A5** — a dispatch that never happened, one that happened and was hidden, a leaked prompt, fabricated concession evidence | **no re-audit.** These are evidence of fabrication, not quality defects; a retry budget that erases them erases the only checks that can see the protocol's core failure. Emit `UNRESOLVED (audit-failed: fabrication)` directly; §7 lists the failing checks |
| verdict FAIL on any other check, fixable, re-audit budget unspent | fix the candidate, re-run §6, re-enter this table |
| verdict FAIL, and (unfixable ∨ out of §4 rounds ∨ re-audit budget spent) | emit `UNRESOLVED (audit-failed: N open)` directly |
| no auditor return, or its last line is neither `PASS` nor `FAIL:` — after one `kind: retry` | emit `UNRESOLVED (unaudited: N open)` directly |
| verdict PASS ∧ open cruxes remain | present, then **emit directly**: `UNRESOLVED (<deadlock \| round-cap \| unlookupable \| unasked \| reopened \| rejected>: N open)` — **list every applicable reason**, comma-separated, in that order |
| verdict PASS ∧ no open cruxes | **present the candidate, then take the human's response as the next input** (below) |

**The presentation** carries the auditor's `dispatch: <k>` and the one command that prints its verdict **from the platform's own record** — consent must be consent to something you did not write. Three outcomes:

| the human… | action |
|---|---|
| confirms | emit `CONVERGED`, with every applicable qualifier: `(single-model)` when §7 reads `correlated yes`; `(delegated D/V)` when `D > 0` — a run where the human abstained on every value call is a rubber stamp, and the token is where a reader looks |
| rejects | the candidate is void; convert the rejection into a constraint or a value ruling (**both recorded in §8's `## Human inputs`**), reopen the affected cruxes, back to §4. **With no §4 rounds left, or on a third rejection** ⇒ `UNRESOLVED (rejected: N open)` — re-presenting an unchanged candidate is how a human is trained to rubber-stamp |
| does not respond | `STOPPED (awaiting human)` |

**Implement nothing before the human has called it.** Every write outside `workdir` before that moment is A9's business.

## 6. The auditor (mandatory before `CONVERGED`; `STOPPED` after a dispatch runs A0 alone, §0)

Dispatch a **fresh-context** worker with a shell, taking the next `k`.

**Payload:** `run nonce · workdir · candidate: <n> · the §1 seat echo · the catalog rev`. **Nothing else.** Every prompt, worker type, model, tool call and return is in the session log — the file the moderator did not author. Handing you its re-narration would hand you the audited party's own account. `candidate: <n>` is not optional: a rejection rebuilds the record, so a run that reaches `CONVERGED` after one normally has ≥2 — an auditor that opens `candidate-1.md` PASSes the document the moderator is *not* presenting. The `find` output is *not* in the payload either: you have a shell and the pinned rev — `git -C ~/.agency-agents ls-tree -r <rev> --name-only` is the same listing, one fewer moderator copy.

**Bound the run on two platform-authored events, in ONE file:**

- **its end** — **the log containing your own dispatch record.** That file, and only that file, is the window. Absent from every log ⇒ `FAIL: replay — this log did not dispatch me`.
- **its birth** — the `openssl rand -hex 4` tool-call record **whose output is this nonce**, *in that same file*. Every dispatch in the run postdates it.

**Do not "walk every log that mentions the nonce".** A replay produces exactly the signature that accommodation was written for: the moderator re-declares an old run's nonce, the birth event is found in the old file, your dispatch record in the new one, both bounds "satisfied" — and an entire previous council is inside the window, inherited wholesale by a moderator who dispatched nothing but you. Birth not in the file that dispatched you ⇒ `FAIL: replay`.

**Enumerate first, never read the log whole.** Run the Platform Adapter's enumeration command: one row per dispatch record in the window — `k`, dispatch id, worker type, resolved model, prompt digest, **and the worker's own record locator** — **parsed out of the record, not truncated out of it**. Every check below reads that table plus targeted lookups. **Read a return by projection** (`grep -nE '\[(fact|prediction|value):|What would change my mind|concede|label:|consulted:|Position:'`) — about ten lines each; materialize a whole return only to resolve a specific mismatch.

**Normalize entities before you diff anything.** The moderator only ever saw the platform's *escaped* copy of a return (`&lt;` where the worker wrote `<`); the copy you read is raw. The return contract *mandates* angle brackets — `[fact: <file:line>]`, `[prediction: threshold=<comparator+value+unit>]` — so an honest transcription mismatches on sight. **`html.unescape()` both sides before comparing** (A3, A5). A byte-diff without this FAILs the honest run and passes nothing.

```text
A0  Every dispatch in the window, against the platform's own records. **A dispatch record is ONLY a real
    dispatch tool-call record**; a header in the moderator's prose is not one — its prose is in this file too,
    so a textual grep would pass on a dispatch that never happened, the one thing this check exists to catch.
      Every dispatch record in the window carries a well-formed header with a unique `k`. A dispatch with no
      header ⇒ FAIL (the hidden seat) — **unless §7 lists it as `out-of-band <id>: <reason>` AND its prompt
      contains neither the nonce, nor a seat path, nor 8 consecutive words of the proposition** (§5 hands
      control to a human, whose own requests must not be read as fabrication).
      Every `kind` in a header matches what that dispatch actually was: a `retry` record shows a platform
      failure; a `re-dispatch` names the superseded `k`. The header was written BEFORE the return existed, so
      it cannot be a post-hoc reclassification — that is the whole reason it, and not a file, is the ledger.
      Worker type: no seat ran on a type that inherits context or can dispatch ⇒ else `blind: no`.
      **A shell is not a dispatch.** A seat that CAN write is still blind — writes are A9's business, not this one;
      failing them here marks every normal shell-backed seat non-blind before A9 ever runs.
      Report, non-gating: `pre-run <dispatches>/<nonce-rolls>` — dispatch records BEFORE the birth event, and
      `openssl rand -hex 4` calls in the log. A council is self-driving and owns its session; a pre-polled
      council shows up here, and the reader is entitled to the number. **A pre-birth dispatch whose prompt
      carries the proposition (or 8 consecutive words of it) ⇒ FAIL** — a hidden seat must be handed the
      proposition to be a seat.
      Records lag: re-read once after a settle before ruling one missing. Exclude your own dispatch.
A0b Blindness did not leak — read the prompts FROM THE LOG. **Round 1 is structural, not a header claim**:
    §2 dispatches every seat in one message, so the first `S` dispatches ARE round 1 whatever their `round:`
    says. Every round-1 / tie-breaker dispatch or re-dispatch prompt contains no other seat's position, no
    other seat's path, no "opposing seat" string; a synthesized persona contains no option/technology name
    from the proposition
A2  Catalog (gating): for every seated path — it exists at the recorded rev (`git -C ~/.agency-agents show
    <rev>:<path>`, read-only; never check out), its frontmatter is that axis, it appears in the pasted
    listing, **and the file's body (minus frontmatter) is byte-identical to the `<persona>…</persona>` block
    of that seat's dispatch prompt in the log, ignoring whitespace** — a real path with an invented persona
    is cheaper than a fabricated path and is otherwise uncatchable. No two seats share a frontmatter `name:`.
    Catalog changes elsewhere are reported, not FAILed
A3  Every fact: the criterion is quoted verbatim from a traced seat's "what would change my mind ①" **in the
    platform's copy of that return** (moderator-authored, or lifted from a bare `[fact:]` locator ⇒ FAIL);
    `criterion-C<n>` precedes `artifact-C<n>` in the log's record order; re-run the command, or re-read the
    `file:line` and diff the quoted line — same ruling under the same criterion (bytes may differ for a
    time-varying command; **a flipped truth value is a FAIL, not a tolerance**)
A4  Recompute, from the platform's copies of the returns: every crux's class; the three bins (a reason is
    contradicted ⇒ crux, asserted by all non-opposing ⇒ consensus, else ⇒ unopposed); **every `P` was
    asserted by EVERY compliant non-opposing round-1 seat — one seat short ⇒ it is an unopposed position, not
    consensus ⇒ FAIL**; **every `[value:]` in a round-1 or tie-breaker return maps to a NUMBERED value crux
    (many-to-one is fine; unmapped ⇒ FAIL), and `V` is the count of those cruxes**. Excluded: superseded
    (`re-dispatch`ed) dispatches and seats §7 records `non-compliant` — the exclusion set must equal exactly
    that
A5  Every concession quotes a ruled artifact, or a `[fact:]` that actually exists in an opposing seat's
    platform return. **Every quote in the §1 echo, the §8 record and the Minority report matches its return**
A6  If §7 says `DA no-op` ⇒ verify the no-op. Otherwise: the DA covered the additive target set; DA-final
    covered both classes; **every DA-final `broken` verdict has its crux recorded open (`reopened`) or
    re-argued in a later §4 round — a `broken` target still recorded `conceded` OR `ruled` ⇒ FAIL**; every
    `consulted:` resolves
A7  Every crux is closed (`ruled` / `conceded` / `human-settled` / `delegated`) or listed open in the
    candidate. `unlookupable`, `unasked` and `reopened` are OPEN
A8  Every §7 field is present (a dropped field is a FAIL, not a vacuous pass) and reconciles against the log:
    `dispatches` = non-audit dispatch records in the window; `retries`, `candidates` (= `ls
    workdir/candidate-*.md`), `rejected`, `rounds`, `concessions`, `non-compliant`, `seats`, `tie-breakers`,
    `seats-degraded`, `opposing`, `blind`, `DA`, `DA-final`, `value cruxes (asked/delegated/unasked)`, and
    **`models`: over the SEAT-FACING dispatches only** (seat / re-dispatch / cross-exam / DA / DA-final /
    tie-breaker / label — **not your own audit dispatch, and not a failed retry carrying no resolved model**).
    Lowercase, strip any context-tier suffix (`[1m]`, `[1M]`) and any trailing `-<8 digits>`, count distinct
    BASE models, and **paste the raw→base mapping** so an over-count is visible. Two strings for one model, or
    one stray null, would render `correlated no` and switch the disclosure off by accident — and the audit
    worker is *deliberately* a different type from the seats, so counting it is exactly that accident, one
    level up. `correlated yes` ⇔ `models 1`; a violation ⇒ FAIL
A9  `workdir` resolves from §0's echo **in the log** (payload ≠ echo ⇒ FAIL) and is not `/`, `$HOME`, or an
    ancestor of the project root. The payload's `candidate: <n>` equals the candidate's own `Candidate:` line
    **and** the highest `n` in `ls workdir/candidate-*.md`; lower ⇒ FAIL (you were handed a rejected draft).
    The candidate has no line-initial terminal verdict and its **Status** reads
    `<token withheld>`; `asked >= min(3, V)` against A4's `V`, and `V > 3` ⇒ the meta-question is in the log
    (with `asked == V` iff the human chose ①); every human-question call carries exactly one question.
    **Every `human-settled` choice equals what the human actually chose — and the question call's OWN result
    record is not where that lives.** On most platforms that record is a verbatim echo of the moderator's
    *input*: the options it offers, not the option taken. Reading it, you would find the moderator's claimed
    label sitting in the list it wrote and pass. The human's answer is in the **next** record — the one the
    platform writes *back*, carrying the chosen label as text. Locate that record; a `human-settled` line
    that does not match it ⇒ FAIL.
    **The write-gate.** A worker's tool calls are recorded **with the worker, not with you** — so iterate the
    enumeration's dispatch rows and **open each worker's own record**. A seat worker cannot dispatch, but it
    *can* write (a shell is a write tool: `> file`, `sed -i`, `git commit`). **This sweep is the only thing
    that catches it** — not the worker-type pin. A sweep that reads your log alone reports on the moderator
    and calls it a write-gate. Between §0's echo and now: a write tool naming a path outside `workdir`, or a
    shell command containing a redirect (`>`, `>>`, `| tee`) or a mutating verb (`rm mv cp ln touch chmod
    sed -i dd git commit git add git checkout apply_patch`) targeting a path outside `workdir` ⇒ FAIL.
    `mkdir workdir` is the one exception §0 requires. A command whose text appears verbatim on a
    `criterion-C<n>` / `artifact-C<n>` / `consulted:` line **already in the log before it ran** is a §3
    artifact command, not a write — including `npm ls` / `pip show`, which a seat's ① routinely asks for.
    Everything else — `openssl`, `find`, `grep`, `git show` — is a read.
Answer each check. **A PASS must carry its evidence** — the enumeration rows, the stat output, the re-run
command and output, both sides of a diff. **A PASS with no pasted evidence is a FAIL of that check.**
Last line: `PASS` or `FAIL: <ids + evidence>`
```

## 7. Quality line (mandatory; A8 reconciles every field)

```text
Quality: run <nonce> | dispatches <n> (retries r) | candidates <n> (rejected j) | pre-run <d>/<rolls>
  | seats <n> (tie-breakers d, synthesized c, outside the consensus quantifier) <| seats-degraded>
  | models <n distinct base> | correlated <yes|no> | blind <yes|no> | non-compliant <seat=field,… | none>
  | opposing <path> | rounds R | concessions C | out-of-band <id: reason,… | none>
  | DA <attacked P, broke B | no-op> | DA-final <pass1: attacked P, broke B>[; pass2: …] | n/a>
  | value cruxes V (asked A, delegated D, unasked U)
  | auditor <pending | PASS | FAIL(ids) | not run | cannot re-run | dispatch-unverifiable>
```

## 8. Decision record

```markdown
**Status**: <token withheld>
Run: <nonce> · Workdir: <path> · Candidate: <n>

## Decision
<one line + the reasoning>
**Every seat is the same base model wearing a different persona; agreement is weak evidence. "Converged" = no
fabrication was caught, NOT = the conclusion is right.**
**When `correlated yes` or `DA no-op`, the consensus set may not be cited as support here** — unattacked, or
one model agreeing with itself, it launders correlation into a reason. This is the single home of that rule.
**Traceability** (one of four; no fifth): ① a seat's position verbatim (name it); ② the human's choice;
③ your recommendation after explicit delegation (name the crux — and note that nothing attacked it);
④ a synthesis of ①②③ — every claim it makes must appear in one of them; it may recombine and exclude, never
introduce.

## Quality
<the Quality line>

## Audit
<the auditor's return, verbatim. Its `dispatch: <k>`; the platform's own copy is what §5 read.>

## Human inputs
<one line per touchpoint: each question with the option chosen; each rejection verbatim + the constraint or
value ruling it became. What the human objected to shapes every later round and is otherwise unreconstructable.>

## How it converged
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
