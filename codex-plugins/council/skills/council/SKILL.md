---
name: council
description: Use for open decisions with NOTHING WRITTEN yet — technology selection, architecture, whether to build something. Pulls real specialists from the agency-agents catalog (one seat per named viewpoint gap, 3 or more, no upper limit), gets independent blind positions on ONE decision, and numbers the disagreements into cruxes. A fact closes only on a criterion QUOTED from a seat's blind "what would change my mind" plus a re-runnable command output; judgment calls go to the human one question at a time with a recommended answer; the rest is argued out in rounds. Before any result-claiming verdict, a mandatory auditor in a fresh context reads the platform's own session log, reconciles every claimed dispatch against it, and re-runs the commands. Self-driving. Triggers - convene a council, multi-expert debate, get several perspectives on this decision, have some experts argue this out, 开个评议会, 让几个专家吵一下, 多视角讨论这个方案, 找专家评议, 这个选型该怎么定. Something already written — a proposal, a spec, a diff — that needs tearing apart is review-loop, not council.
---

# council

One decision with nothing written yet → one real specialist per named gap (3+) gives an independent blind position → extract the disagreement → argue → converge. **Anything already written (a proposal, a spec, a diff) that needs tearing apart → `review-loop`.**

## Terms (defined once; never re-explained downstream)

- **crux** — the specific proposition two seats actually diverge on (not "A picks Postgres, B picks SQLite" but "will write QPS exceed 2k?"), numbered `C1..Cn`.
- **named gap** — one sentence naming the constraint this seat will raise that no other seat structurally can. The test is **transposition**: move the sentence to another seat's name; if it still holds, it is not a gap.
- **blind** — a seat runs in a fresh context containing only the proposition + the truth-source paths + its own persona; it cannot see your reasoning or any other seat's return.
- **DA** — the opposing seat's attack round (devil's advocate), §3.
- **working transcript** — the verbatim record you paste into this conversation (seat returns, command outputs, criterion/artifact messages). **Session log** — the file the platform itself writes (Claude Code: `~/.claude/projects/<project-path-slug>/<session-id>.jsonl`, one record per subagent dispatch). Not the same thing: you write the first, the platform writes the second — the auditor trusts the second.
- **seat** — one specialist subagent occupying one axis for the whole run.
- **axis** — one conflicting-interest dimension of the decision (§1); a seat's named gap names its axis.
- **truth sources** — the repo paths / docs the moderator lists as the evidence base, handed to every seat in round 1. Their *selection* is a moderator judgment no audit check covers — disclosed as such in the honesty boundary.
- **token** — one of the three terminal outcomes (`CONVERGED` / `UNRESOLVED (…)` / `STOPPED (…)`), §5.
- **candidate record** — the §8 decision record built before emission, with its status field reading `<token withheld>`.
- **slug** — two senses: in §1, an agent's **filename** (`security-appsec-engineer`); in the session-log path, the **project path** transliterated.
- **`A.r1`** — seat A's reason 1.

## Honesty boundary (read first — it is the shape of every rule below)

The seats are **the same base model wearing different personas**: blindness isolates context contamination, never model-level correlation. "Three experts independently agreed" and "one model sampled three times" are structurally indistinguishable — **agreement is weak evidence, not consensus.**

And the moderator (you) is at once the author of the proposition, the appointer of seats, the classifier, the fact adjudicator and the writer of the record, with exactly one incentive: **to be done**. So this skill sets no gate you grade yourself against. It does one thing:

> **Make every shortcut leave a hole in the artifact, and make that hole mechanically findable from a different context.**

Five things can leave such a hole: **per-dispatch records in the session log** (every claimed dispatch must have its own record in a file the platform wrote), **a real expert's file path** (stat it, diff it against the enumeration), **a command + its verbatim output** (re-run it), **a verbatim citation** (diff it against the source), and **a criterion a seat wrote while blind** (it carries its own condition; diff its source).

**What the auditor can catch**: a fabricated path, a fabricated output, a fabricated citation, a fabricated label, a dispatch that never happened. **What it structurally cannot catch**: whether a criterion is *relevant*, whether a crux is *faithful*, whether a synthesized persona is *sound*, **the sincerity of a concession** (citing an existing piece of evidence is nearly free), **the quality of a DA attack**, **the fairness of §5's question ordering**, and **the moderator's selection of truth sources**. So "converged" means **no fabrication was caught** — not "the conclusion is right".

## Platform Adapter

- **"Generic subagent"** = a worker with no preset persona into which you inject a role prompt; resolve the mechanism per platform. **A worker that inherits the moderator's context (a "fork") is never a seat** — if the platform offers nothing else, `STOPPED (cannot run blind)`.
- **Blindness**: if seats can only run sequentially in one shared context — later seats able to see earlier returns — the run is **not blind**: Quality line `blind: no`, and **the converged verdict is unavailable** (best terminal: `UNRESOLVED (not-blind: N open)`). Blindness is this protocol's core mechanism, not a preference.
- **A0 needs a platform-side dispatch record** — a log the moderator did not write. No such log obtainable ⇒ Quality line `auditor: dispatch-unverifiable`, and the converged verdict is unavailable (§5 table). This skill will not pretend "the seats were consulted" is provable without one.
- The auditor needs tool access (stat / grep / re-run). None ⇒ `auditor: cannot re-run`.
- Ask the human through whatever single-question affordance exists; with none, print one question and stop.

## 0. Self-driving, and what every STOPPED costs

**council runs its whole loop within one turn.** Apart from §5's human touchpoints, never hand control back at the end of a round — an audit FAIL means fix and continue, not stop and report progress.

**Every `STOPPED` exit owes evidence** (otherwise quitting before you start is the only free door):

| STOPPED reason | evidence owed |
|---|---|
| proposition needs splitting | the ≥2 decisions it splits into, one refutable sentence each, **plus its axes — at least the three §1 requires — for the one you recommend convening first** (prepay §1's work; cannot list two decisions ⇒ it is not several decisions — convene) |
| not a council question | the <3 axes you did derive, with named gaps, and which interest lacks a representative |
| seats exhausted | the failed seats' returns, verbatim, in the working transcript |
| no real experts (catalog unavailable / none on the opposing axis) | the verbatim `find` output in the transcript; the message carries `git clone https://github.com/msitarzewski/agency-agents ~/.agency-agents` for the user to run and retry — **do not stop and wait for the clone** |
| awaiting human | the exact question/candidate you presented + the fact of no response |
| cannot run blind | which dispatch mechanisms the platform offers and why each fails the blindness test |

`STOPPED` is a pre-candidate exit: **no audit, no confirmation — pay the evidence above and emit directly** (the audit governs result-claiming records only, §5).

The proposition: compress it into **one refutable sentence** and echo it. That sentence is dispatched **verbatim** to every seat; the dispatch prompt carries no evaluative wording, no lean of yours, and no role hints like "you are the opposing seat" (opposition is the persona's job). A0b checks the greppable subset: proposition verbatim present; no other seat's position or name; no "opposing seat" string.

## 1. Seat the council

**Axes first, people second.** Extract the conflicting interests: if this decision is wrong, who gets hurt? Cover ① the primary domain, ② the interest naturally in tension with it, ③ the downstream actually touched (security / cost / maintainability / users / compliance — whichever applies). One named gap per axis.

- **One seat per named gap; no upper limit.** The transposition test is the only bound — a seat with no gap merely restates another and thickens the illusion of independent agreement.
- **Fewer than 3 axes ⇒ `STOPPED (not a council question)`.**
- The **opposing seat** (whose job is to argue against the forming consensus) is named here, echoed, and never re-designated.
- Below 2 seats mid-run ⇒ `STOPPED (seats exhausted)`.

**Enumerate the catalog before naming any seat** — names invented from an axis (`stability-advocate`, `contrarian`) match nothing; real names carry a division prefix (`engineering-database-optimizer.md`):

```bash
find ~/.agency-agents -type f -name '*.md' ! -iname 'README*' ! -iname 'CONTRIBUTING*' ! -iname 'SECURITY*'
```

**Paste that command's verbatim output into the working transcript** — the auditor re-runs it and diffs (A2). Pick candidates per axis from the listing; read each frontmatter to confirm it *is* that axis. Two keys: **the filename slug is the lookup key**; **the frontmatter `name:` is the dispatch key**.

Resolve each seat; **the echo format is fixed** (the auditor parses it):

```text
<seat> — registered: <registered name>   # the frontmatter name: is an installed agent -> dispatch it
<seat> — catalog: <absolute path>        # not registered -> the file's body (minus frontmatter) becomes a generic subagent's persona
<seat> — synthesized                     # genuinely absent -> you author the persona (below)
```

- **Deduplicate by frontmatter `name:`, never by filename** — the root flat-cache copy and its division copy are one agent. Two seats resolving to one `name:` ⇒ one axis: drop a seat, re-derive.
- **At most ONE `synthesized` seat** — a self-authored persona is your own words fed back to you; the auditor structurally cannot check it. A second ⇒ `STOPPED (no real experts)`. Content: its domain, the knowledge it holds that the others lack, the *class* of thing it habitually argues against; **the persona text may not contain any option or technology name from the proposition** (A0b checks); paste it into the transcript.
- **The opposing seat must be `registered` or `catalog`** — authoring the agent whose job is to break your own consensus hands the anti-echo mechanism to the echo. None found ⇒ `STOPPED (no real experts: none on the opposing axis)`.
- Zero real experts ⇒ `STOPPED (no real experts: catalog unavailable)`.

## 2. Blind positions and normalization

**Every subagent return — round 1, cross-examination, DA, tie-breakers, the auditor — is pasted into the working transcript verbatim** (no paraphrase, no summary). This is the ground A1/A5/A6 stand on.

**Every dispatch prompt — round 1, re-dispatch, cross-examination, DA, tie-breaker, label recall — begins with the standard header line** `council: <the proposition sentence> | seat: <seat name> | round: <n>`. The header is what A0 matches in the session log and what A0b greps — without it, neither check has a guaranteed key.

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

**"What would change my mind ①" is the only legal source of a criterion** (§3): it carries its own check and condition, and it was written blind. **`value` must cost more than `fact`**: a `value` with no refutable-preference sentence is non-compliant (re-dispatch — **never discarded**: quietly dropping a `[value:]` is this skill's number-one failure mode).

**Normalization (every round, field by field against that round's contract)**: an unlabeled reason / an "it depends" position / a missing strongest-counter / a prediction missing a field / a value missing its preference sentence / **a concession quoting no evidence** / **a rebuttal bringing nothing new to that crux** ⇒ non-compliant ⇒ **re-dispatch once**. A re-dispatch = **that round's original prompt verbatim** + the contract restated + one structural line naming the missing **field** (never quoting its previous content) — round-1 and tie-breaker re-dispatches thereby stay blind (A0b checks their prompts). Still non-compliant / empty ⇒ that seat leaves every "every seat" quantifier for the round; the Quality line's `non-compliant` field names seat and field. **Fewer than 2 compliant seats in a round ⇒ the round is void ⇒ `STOPPED (seats exhausted)`** — one seat's assertion never becomes "consensus".

## 3. Aggregate

Every reason must land in **exactly one of three places** (a reason landing nowhere is the one you quietly dropped — A4 catches it):

1. **The consensus set** — propositions **every round-1 seat explicitly asserted** (quote each; not mentioning ≠ agreeing). A "consensus" traced to any `[value:]` is not consensus but a value crux — unanimity of preference is one model's taste sampled N times.
2. **A crux's provenance** — `C1 <= A.r1, B.r2`.
3. **A single-seat position (unopposed)** — the named-gap design *guarantees* these are common (each seat's gap is precisely what the others cannot raise). Value-class → the §5① queue (the question lists **the existing sides**; a one-sided crux carries the moderator's recommendation, labeled as such); fact/prediction-class → the record's "Unverified assumptions".

**Classification = priority aggregation over provenance labels, `value > prediction > fact`, locked both ways**: any traced `[value:]` ⇒ value crux (add-only); and **a crux classified value must have a seat-labeled `[value:]` in its provenance** — otherwise you promoted a fact to a value and handed the human your homework (`value` is the exit, not the expensive bucket: a value crux leaves your plate, so the ratchet locks both directions). The auditor **recomputes** every crux's class by this same rule (A4).

**A crux born mid-debate** (a DA break, a partial concession's residual): its provenance = the `label: <fact|prediction|value> — <why>` line written by the seat that produced it, in that same return (`label: value` counts as seat-labeled); **no label ⇒ inherit the parent crux's class** — never default to value.

**Fact ruling: the criterion is quoted from a seat, full stop.**

1. **Criterion** — its own message, `criterion-C<k>`, **quoted verbatim from the "what would change my mind ①" of a seat in that crux's provenance**, sent before any command runs. **A seat's `[fact: locator]` is an artifact locator, never a criterion** — a bare locator carries no condition, so the condition would be yours, smuggled back in through the ruling sentence. No traced seat's ① covers the crux ⇒ mark it `unlookupable`; do not rule.
2. **Artifact** — its own message, `artifact-C<k>`: `command + verbatim output`, or `file:line + the quoted line`.
3. **Ruling** — derived mechanically ⇒ the crux closes as `ruled`.

Output cannot decide the criterion ⇒ not a fact: about the future → return it to the traced seats for a one-line `label:` (a dispatch like any other: standard header, enters A0; payload = the crux + that seat's own prior return) and follow the new label; **simply not lookup-able today** ⇒ `unlookupable` (stays open, skips cross-examination — arguing the declared-unverifiable burns rounds), rides to the terminal and lands in "Unverified assumptions".

**DA (once per aggregation, mandatory; a three-branch target function guarantees a target always exists)**:

1. Consensus set non-empty → targets = its propositions;
2. else any fact rulings → targets = the rulings (is the criterion relevant? does the artifact support the conclusion?);
3. else → target = **the aggregation itself**: is each crux's class faithful to its provenance, plus the dominant position on the sharpest open crux — or, with no cruxes at all, the single-seat positions.

```text
For each target T:
T: <attack> — consulted: <file:line | command + verbatim output> — verdict <broken | unbroken: and what evidence WOULD break it (must be verifiable-today or an observable indicator)>
```

The DA dispatch carries the standard header + the targets verbatim (consensus quotes / rulings with their criterion-and-artifact lines / the aggregation table) + the return format above — nothing else. `consulted:` must genuinely resolve (A6 re-runs it). All "unbroken" with nothing resolvable ⇒ a no-op: re-dispatch once; still so ⇒ Quality line `DA: no-op`, the consensus set may not be marked "attacked", and **A6 switches to verifying the no-op itself** (both dispatches in the log, returns pasted, citations genuinely unresolvable). "Unbroken" = the opposing seat found no counter-source — not that T is true; the record says it that way. A broken consensus proposition becomes a new crux; a broken ruling reopens.

## 4. Cross-examination (default: at most 3 rounds)

Only for **prediction cruxes + fact disagreements not yet dissolved** (`unlookupable` stays out). Give each seat: **every opposing position on that crux, verbatim** + the crux number + each ruling's criterion-and-artifact line + **its own previous return verbatim** (without its own words back, a fresh subagent is a memoryless re-roll).

```text
On C<k>: <rebut | concede | partially concede>
- Rebut: **must bring one artifact or verbatim citation new to this crux in the working transcript** — otherwise it is restatement and the seat holds no position here this round. (Rebuttal costs what concession costs; if only concessions pay, everyone rebuts for free and round one hits deadlock.)
- Concede: write "I concede C<k>" and **quote verbatim** the one piece of evidence that moved you — ① a ruled fact's artifact, or ② a `[fact: …]` that actually appears in an opposing seat's return (copy it with its locator). The opponent's argument / position / reasoning is not evidence (an LLM handed the opposing argument concedes out of agreeableness).
- New crux (a partial concession's residual): `label: <fact|prediction|value> — <why>`
```

**A known dead corner, disclosed**: on a prediction crux where neither side holds `[fact:]` evidence, concession is structurally impossible — the only ways out are new artifacts, deadlock, or riding to the terminal. That is the design (no evidence, no concession), not an oversight.

**Partial concession**: the conceded part closes the crux as `conceded` (it never joins the consensus set — that set is produced by round 1 only); the residual becomes a new crux.

**Re-seating**: a crux on a domain nobody owns ⇒ seat a tie-breaker on a **new axis**, **blind first** (crux + truth sources + its named gap + the §2 contract), then it joins. It never enters the consensus quantifier. **At most 1 per round, 3 per run** — unbounded seats blow the auditor's context.

**Termination (in order)**: ① no open cruxes → §5. ② only `value` and `unlookupable` remain open → §5. ③ **deadlock**: a round in which no crux closed and no new artifact or citation entered the working transcript → stop. ④ round cap → stop. Cruxes left open by ③/④ **still go through §5①** (a value crux that should be asked is still asked), then the terminal.

## 5. The human, and the terminal (one state machine — every row has exactly one exit)

**① Value-crux questions** (`/grilling` mode, adapted from mattpocock/skills):

- **One question at a time, then wait**; each question call carries exactly one question (A9 checks the arity).
- Each question: **the existing sides' positions verbatim (quoted — paraphrase puts your thumb on the scale)** + your recommendation and why (the recommended option listed first) + the cost of getting it wrong; **one option must be "You decide (I abstain)"**.
- **At most 3 questions**, in descending cost-of-wrong; the 4th and beyond auto-close as `delegated`. **Every value crux, with its cost, goes in the record** — burying must be visible.
- Never ask the human a fact. A choice ⇒ `human-settled`; "you decide" ⇒ `delegated`; no answer ⇒ the run ends here: record `STOPPED (awaiting human)` as its standing state in the working transcript (a resumed session picks up from §5).

**② The terminal (audit first, then present; only the converged verdict needs confirmation)**:

1. Build the **candidate record**: its status field reads `<token withheld>`, and no line-initial terminal verdict line appears anywhere in it (A9 checks by anchored pattern).
2. Run §6's audit. **One audit + at most one re-audit per candidate.** A candidate = one §5② presentation attempt: an audit-FAIL fix revises the *same* candidate (that is the one re-audit); a candidate rebuilt after a human rejection is a *new* candidate with a fresh budget. "Out of rounds" below = no §4 rounds left to implement the fix.
3. Take **exactly one** row — the table is evaluated top to bottom, and the first matching row is the run's only exit:

| state | action and emission point |
|---|---|
| audit PASS ∧ no open cruxes ∧ dispatches verified ∧ blind | present the candidate → **after the human confirms**, emit `CONVERGED` (the one token needing confirmation — it is the strong claim; a failure report does not need consent to be true) |
| the human rejects the presented candidate | candidate void; convert the rejection into a constraint or a value ruling, reopen the affected cruxes, back to §4 (rounds keep drawing the same cap). **A third rejection ⇒ emit `UNRESOLVED (rejected: N open)` directly** |
| no response to a presentation | `STOPPED (awaiting human)` |
| audit FAIL, unfixable or out of rounds | emit `UNRESOLVED (audit-failed: N open)` directly (N may be 0); Quality line lists the failing checks |
| audit not run / cannot re-run / a shard truncated | emit `UNRESOLVED (unaudited: N open)` directly |
| no session log obtainable (open cruxes or not) | emit `UNRESOLVED (dispatch-unverifiable: N open)` directly (N may be 0) |
| audit PASS ∧ open cruxes remain (deadlock / cap / unlookupable / reopened-after-rejection) | present and **emit directly**: `UNRESOLVED (<deadlock \| round-cap \| unlookupable \| rejected>: N open)` |
| the run was not blind (Platform Adapter) | emit `UNRESOLVED (not-blind: N open)` directly |

**Implement nothing before the human has called it** (A9: no tool call writing to the target artifacts/repo before confirmation; the protocol's own working files — the candidate record, the audit payload — are exempt).

## 6. The auditor (mandatory for result-claiming records; STOPPED is gated by §0's evidence instead)

Dispatch a **fresh-context** generic subagent. **Payload = the session-log file path + the working transcript in time order** (every dispatch's prompt text, every return, every `criterion-/artifact-` message, every tool call this run made, with arguments and output) + the candidate record. **A0/A0b/A1/A5/A6 read the session log first** (the platform wrote it); the working transcript is an index — the moderator's re-pasted copies are never the sole basis.

```text
A0  Per-dispatch reconciliation: for EVERY dispatch the working transcript claims (each seat each round,
    re-dispatches, DA, tie-breakers), find ITS OWN record in the session log by its standard header line
    (`council: <proposition> | seat: <name> | round: <n>`). Any one missing ⇒ FAIL (that return was typed,
    not dispatched). Exclude the auditor's own record; the log must contain this run's proposition echo (binds
    the file to this run). Totals are a sanity floor only.
    No session log obtainable ⇒ Quality line `dispatch-unverifiable` (not a FAIL; token per the §5 table)   <- grep the log
A0b Blindness did not leak: every round-1 / tie-breaker dispatch prompt carries the standard header (which
    contains the proposition verbatim) and
    contains no other seat's position, no other seat's name, no "opposing seat" string; a synthesized persona
    contains no option/technology name from the proposition                                                  <- grep
A1  Every return is in the working transcript (A0 owns log reconciliation); every label and quote in the echo
    and record matches the returns line by line; every return satisfies its round's contract (or was recorded
    non-compliant)                                                                                           <- diff
A2  Mechanical (gating): re-run §1's find and diff against the pasted output; every catalog path exists, its
    frontmatter name: IS the seat name, and it appears in the re-run listing; no two seats share a name.
    Disclosed judgment (non-gating, no PASS evidence): whether each synthesized seat's axis truly has no match
    in the listing — semantic; written for the human reader only                                       <- stat + re-run
A3  Every fact: the criterion is quoted verbatim from a traced seat's "what would change my mind ①"
    (moderator-authored, or lifted from a bare [fact:] locator ⇒ FAIL); the criterion-C<k> message precedes the
    artifact-C<k> tool call; re-run the command — same ruling under the same criterion (decision-equal: the re-run output gives the criterion's condition the same truth value —
    bytes may differ for time-varying commands); the ruling follows mechanically                                                             <- re-run
A4  Recompute every crux's class (value > prediction > fact over provenance labels); mismatch with the record ⇒
    FAIL. Every reason lands in {crux provenance, consensus support, single-seat position}; every [value:]
    lands on a value crux; every value crux has a seat-labeled [value:] (a `label: value` line counts)
A5  Every concession quotes a ruled artifact, or a [fact:] that actually exists in an opposing seat's return    <- diff
A6  If the Quality line says DA: no-op ⇒ verify the no-op itself (both dispatches in the log, returns pasted,
    citations genuinely unresolvable); otherwise: the DA covered every target of its branch, and every
    consulted: resolves / re-runs                                                                            <- re-run
A7  Every crux is closed (ruled / conceded / human-settled / delegated) or listed open in the candidate
A8  Every Quality-line field matches the transcript (the `auditor` field reads `pending` now — out of scope here)
A9  The candidate has no line-initial terminal verdict line and its status field reads `<token withheld>`;
    no tool call writes to the target artifacts before the human's confirmation (protocol working files exempt);
    every human-question call carries exactly one question                                                    <- grep
Answer each check. **A PASS must carry its evidence** — the stat output, the re-run command and output, both
sides of a diff. **A PASS with no pasted evidence is a FAIL of that check.**
Last line: `PASS` or `FAIL: <ids + evidence>`
```

**The auditor's return goes into the working transcript verbatim and is quoted verbatim in the record's `## Audit` section.**

**Payload too large ⇒ split into two shards, grouped by the data each check needs**: shard α = {A0, A0b, A2, A9} with the log path + every dispatch prompt + tool-call records + the pasted `find` output + the candidate; shard β = {A1, A3, A4, A5, A6, A7, A8} with every return + the criterion/artifact messages + the candidate + the Quality line. Each shard's payload ends with `PAYLOAD-END <random-string>`, which the return must echo verbatim — no echo = that shard did not run (truncation becomes greppable). **Combined verdict: PASS only if every shard returns an evidenced PASS; any FAIL ⇒ FAIL; any shard missing or not-run ⇒ unaudited.**

## 7. Quality line (mandatory; A8 reconciles it)

```text
Quality: seats <registered:a, catalog:b, synthesized:c> (tie-breakers d, outside the consensus quantifier) | non-compliant <seat=field,… | none>
  | opposing <name>(registered|catalog) | blind <yes|no> | rounds R | concessions C
  | DA target=<consensus|rulings|aggregation> <attacked P, broke B | no-op> | value cruxes V (asked A, delegated D)
  | auditor <pending | PASS | FAIL(ids) | not run | cannot re-run | dispatch-unverifiable>
```

It lays the truth out instead of encoding it: a "converged in four steps" run honestly renders `rounds 0 | concessions 0` — the numbers speak.

## 8. Decision record

```markdown
## Decision
<one line + the reasoning>
**Every seat is the same base model wearing a different persona; agreement is weak evidence. "Converged" = no
fabrication was caught, NOT = the conclusion is right.**
**Traceability** (one of four; no fifth): ① a seat's position verbatim (name it); ② the human's choice;
③ your recommendation after explicit delegation (name the crux); ④ a synthesis whose every component traces
verbatim to ①②③ — ruled cruxes may only exclude options, never invent one.

## Quality
<the Quality line>

## Audit
<the auditor's return, verbatim. Never summarized.>

## How it converged
- Consensus (asserted by every round-1 seat; DA outcome noted): P1 <unbroken = the opposing seat found no counter-source> | P2 broken -> C4
- C1 [fact <=A.r1] -> criterion (quoted from A's ①) -> artifact -> ruling
- C2 [prediction <=A.r2,C.r1] -> who conceded / which evidence they quoted
- C3 [value <=C.r2] -> the human's choice | delegated (recommendation + cost)
- Every value crux with its cost-of-wrong (asked, unasked, delegated): …
- C5 [open] -> why unresolved + what would resolve it

## Minority report (transcribe only; never author)
① the positions of seats that never conceded; ② each concession's "remaining objection"; ③ if both empty → each seat's "strongest argument against my own position".

## Unverified assumptions
<what the decision rests on but nobody checked — including single-seat unopposed fact/prediction reasons — + how to check (indicator + threshold + when)>
```
