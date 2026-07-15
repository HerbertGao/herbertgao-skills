---
name: review-loop
description: >-
  Tear apart a written artifact and iterate it to a pass. **Use it when something is already written** —
  an OpenSpec change, a proposal, a spec, a diff; a pure-prose proposal belongs here too. **Nothing written yet,
  and the question is "which way should we go" (technology selection / architecture / whether to build)?
  → that is `council`, not this.**
  Each round three reviewers run in parallel (Code Reviewer + Reality Checker + Codex — a cross-family
  reviewer, which is the one distribution the other two cannot supply), their returns are pasted verbatim, findings merge into one triage list, a
  fixer applies the accepted ones, and the loop re-reviews until a terminal token. Every check reads an artifact
  the checked party did not author — that is the whole design. Standing counter-pressures: a scope fence (a fix
  that would add features nobody asked for stops and asks), a simplicity lens (the loop only inserts, so
  something must count the bloat), a legibility lens (a cold reader, so an iterated review cannot turn a
  readable document into a patch pile), and a convergence check (if two rounds running find blockers that the
  loop's own last fix produced, it stops and says so instead of iterating forever).
  Triggers: review this change until it passes / find the ship-blockers / keep fixes minimal /
  对本次提案/变更做对抗性 review 循环 / review 到通过为止 / 避免 review 插入过多无效代码.
  Pairs with a /goal-style completion harness for long runs; runs standalone without one.
---

# review-loop

Tear apart a written artifact and iterate it to a pass. Each round: dispatch reviewers → triage → dispatch fixes → re-review, until a terminal token. For long runs wrap it in a completion harness (`/goal` on Claude Code — last section); optional, and without one the main agent applies the evaluator's predicates to itself.

**Scope.** Something is already written — an OpenSpec change (a spec-driven proposal workflow whose artifacts are markdown change proposals), a proposal, a spec, a diff. A **pure-prose proposal is in scope**: §1b's table comes back naturally empty, §1e applies only its three prose tags, §1f is the lane the round is actually for. A decision with *nothing written yet* is `council`, not this. For a trivial diff — a typo, a one-line fix — skip the loop: one direct review is cheaper and enough.

## The evidence rule (read first — it is the shape of every rule below)

The main agent dispatches the reviewers, grades their findings, writes the fixes, and writes the status block the evaluator then reads. It has exactly one incentive: **to be done**. So a check whose input the main agent typed is not a check — it is a disclosure wearing a check's clothes, and it will be written `clean` on the round it matters.

> **A check is only as strong as the artifact it reads. Three tiers, and every gate names its own.**

| the artifact | who makes it | what it proves |
|---|---|---|
| **the slot returns** — each reviewer's verdict line + findings list, **pasted verbatim** | the reviewers | the round was dispatched, and these are the findings |
| **the triage list** — every finding after re-grading and dedup, with severity, location, disposition, **pasted** | the main agent, but *derived* from the returns above and diffable against them | what the round decided, and whether the grading holds |
| **`Landed:`** — the diff the round's fixes actually produced, **not the ranges the spec aimed at**. On code: `git diff --stat` or the edit's own reported ranges. **On prose: the changed text itself** — `git diff -U0`'s added/changed lines, pasted | the fixer's edit | what the loop actually changed, in the same coordinates as next round's findings |

**On prose `Landed:` carries text, not coordinates**, because ⑫'s operand there is text (a prose fix-induced blocker must *quote* what the fix added, below) and the evaluator reads only the transcript. Hand it `--stat` and the intersection it recomputes has nothing to intersect: the backstop this loop calls its only unfabricatable check silently degrades to the number the graded party typed.

**Tier 1 — mechanical output: a proof.** A command's output, a diff, a re-run. The main agent cannot produce it without running the command, and anyone can re-run it. `Landed:` and the anchors' `command + output` are here.

**Tier 2 — a pasted subagent return: a cost barrier, not a proof.** The main agent *could* fabricate one — but fabricating a five-thousand-word adversarial review *is doing the review*. That is the whole value: paraphrase is cheap and is laundering; verbatim is not. **Verbatim means the raw return, in its original language, unedited** — a translation, a tidy-up or a splice of two non-adjacent fragments is a NEW artifact, and pasting one under a "verbatim" label is fabrication, not formatting. Translate beside it if the reader needs it (`原文: … ／ 译: …`), never instead of it: the moment a quote is something you typed, the cost barrier is gone and the tier collapses to 3. **A lane whose return was not pasted is `not-run`.**

**Tier 3 — a status line: a disclosure.** A number the graded party typed. It is not a check. Predicates ②–⑤, ⑦, ⑧, ⑩, ⑬ and ⑭ read only this, and are marked `[disclosure]` where they appear — they exist so an omission is visible, not so a lie is impossible.

**Honesty**: this loop's floor is that a determined main agent can fabricate a tier-2 artifact and every tier-3 line. What it cannot fabricate cheaply is tier 1, and what it cannot fabricate *at all* is the intersection ⑫ recomputes from two artifacts it did not write. That is the real backstop, and it is one predicate wide.

The floor this cannot reach is named in the closing honesty boundary. It is real, and disclosing it is cheaper than a mechanism that pretends to close it.

## Terms

Each term's rules live in its section. This list is glosses and pointers.

- **slot** — one of the three verdict-bearing reviewer lanes (Code Reviewer / Reality Checker / Codex). Only a slot carries a verdict. Everything else — §1c augments, §1e, §1f, anchors, the bot — is **findings-only**: it feeds triage and holds no verdict.
- **CR / RC / MCE / ASE** — Code Reviewer / Reality Checker / Minimal Change Engineer / Security Engineer (§1's ladder).
- **anchor** — the independent artifact you set-diff §1b's failure table against, to answer *"did the table miss something?"*. **Strong** = mechanical output from one of §1's three anchor forms, artifact attached, passing §1's acceptance test. **Weak** = the CR's prose checklist — both sides are prose and can co-miss the same point. (The *cognitive* sense of "anchoring" is called **priming** throughout.)
- **category** — a kind of failure point, from **exactly this closed set**: ① guard / early-return / error branch / exception catch; ② assert / validation / exit-code; ③ state transition (restart, reconnect, renewal, cleanup, dry-run); ④ claimed-pass point (a test assertion, a cassette — a recorded network fixture — a recomputed column, a doctor check); ⑤ config/entry fan-out (§1b step 0). Two more — **narrative drift** (doc says X, code does Y) and **forward fragility** (correct now, silently breaks later) — that no stock anchor form covers, so the loop **discloses** them instead of gating on them; a custom executable invariant that does cover one lifts it like any strong anchor. A category is **in scope** when the round's code has a point of that kind — never "when you happen to have an anchor for it".
- **set dimension** — a thing with a *set* of legitimate members some guard must cover: a role set, a config-key set, an enum's arms, the CLI entries. Check: `declared-coverage set` (what the guard reads) vs `actually-effective set` (the full set in the code). **Not equal = a finding.**
- **distribution** — the kind of defect a reviewer is *structurally* able to see. Two reviewers on one distribution find the same bugs; a fourth on a covered distribution is worth ≈ 0. A different model family is the one distribution same-family lanes cannot supply.
- **the evaluator** — the small model a completion harness runs at each turn's end, literally checking the predicates in the last section, reading only the transcript. No harness ⇒ no evaluator; the main agent applies the same predicates to itself and the closing honesty boundary bites harder.
- **bot** — an always-on PR bot (BugBot, Copilot review) if the repo has one. The loop never invokes one; it merges findings that already exist. No bot ⇒ nothing to merge.
- **fix-induced blocker** — a blocker or major **in the triage list** (post-grading, post-dedup) whose location falls inside the **previous** round's `Landed:`. On prose, location overlap is not enough — the finding must **quote text `Landed:` added or changed AND name a requirement that did not exist before that rewrite**. A whole-section rewrite (§3) makes *all* of a section's text "changed", so text-overlap alone would count every re-expressed pre-existing rule as a regression; the requirement test is what separates a genuine fix-induced defect from a rule the rewrite merely restated. **When the artifact carries native requirement/decision IDs** (an OpenSpec change, a numbered spec), the intersection is by those IDs — a verbatim string-match present in both pastes, so the evaluator still recomputes it and the graded agent cannot author it. **Otherwise** the finding must **quote the *pre-rewrite* artifact** to show the requirement is absent there; a finding that cannot is a re-expression, not a regression. `Regression:` is the count of surviving fix-induced blockers/majors, recomputed from the two artifacts rather than read as a number.
- **tool record** — the platform-written record of a tool call in this run (Claude Code: the session log; generically, whatever the platform itself logs). A path "has a tool record" when it appears in the arguments or output of a call this run actually made — the check is a lookup in that log, never a recollection.
- **cap / patch count** — two numbers. The **round cap** (default 10) lives here; Termination holds its behaviour. The **patch count** (3) lives in §3: a fix landing in a prose section (one heading-bounded block) that has already taken 3 of this loop's insertions must rewrite the section instead of adding a caveat.

## Verdict normalization

Subagents routinely go off-spec: wrong token, guessed severity, no verdict line. **The main agent normalizes every verdict itself — never get dragged by the token a subagent wrote.** (And this is exactly why the raw returns are pasted: normalization overwrites them, so the evaluator needs both the raw and the normalized side.)

**Severity** — every finding carries exactly one:

- **blocker** — broken on ship: wrong results / data corruption / crash, security hole, breaks a dependency contract or schema, core path unusable. Must fix to pass.
- **major** — serious defect: design flaw, missed failure mode or edge, clearly inconsistent with existing code, missing a key check. Fix by default.
- **minor** — local issue, doesn't affect correctness. Fix if cheap.
- **nit** — pure style / format. Usually skip.

**Verdict tokens**: pass = `APPROVE` (the RC tends to write `CLEAR`; same token); reject = `CHANGES-REQUESTED` (`NEEDS WORK` is a synonym).

**Re-grade first.** Promote the under-marked (especially a subagent that rejects while labelling its reason minor); demote the over-marked. **A demotion holds only if you name which severity definition the original grade got wrong**; otherwise the finding stays unresolved. A blocker/major is **resolved** only when *fixed* or *explicitly demoted / ruled not-applicable* by that rule — a verbal "noted, skipping" with the severity unchanged is unresolved.

**Normalization rule**: any unresolved blocker/major ⇒ the round is a **reject**, even if every subagent wrote APPROVE; only minor/nit left ⇒ a **pass**. Throughout, "pass / reject" means this normalized verdict.

`APPROVE-DEGRADED`, `CAPPED` and `NOT-CONVERGED` are **main-agent terminal tokens** — never in a slot.

## The loop

### 1. Dispatch reviewers

Dispatch all three slots **in parallel, in one message**. Each prompt is self-contained and carries: the artifact + the change; the truth source (spec / contract / existing code — for the RC a **to-be-proven baseline**, never settled fact); what prior rounds fixed, so reviewers hunt **new** ship-blockers (**except the RC**, which gets §1b's de-polluted form); the agreed scope (§1d) with the `[out-of-scope]` tagging demand; the severity definitions; and the output contract — **end with the findings list (severity / location / explanation / fix) and, as the final line, exactly one verdict token**. **On a prose artifact, `location` names the heading-bounded section as well as the line** — line numbers move when a section is rewritten; sections don't, and the section is what `Landed:` intersects on.

**Not-yet-implemented artifact — the proposal's own deliverables are not missing prerequisites.** When the artifact is a change not yet built (an OpenSpec change / proposal / spec), **every** reviewer prompt carries this rule, the RC's de-polluted form included: the files, functions, fields, endpoints and components the proposal's own tasks will create or modify **are the deliverables — their absence from the current codebase is the expected state, never a finding.** "Referenced symbol doesn't exist yet", "baseline unproven because the code isn't there", and an internal build-order forward-reference among the proposal's own tasks are **the work, not defects in it** — a to-be-proven baseline means *don't assume the existing system already works*, never *the proposal's own future work is a gap*. A prerequisite gap is real **only** for something (a) no task in the proposal creates, (b) it never declares as an existing assumption, and (c) not self-evidently present — an **unstated external or pre-existing dependency** (a third-party API; an existing column the change reads but no migration adds; a service it assumes is deployed). Internal contradictions (proposal↔spec mismatch, a spec no task satisfies, a data-flow that never connects) and genuine design flaws stay in scope, graded normally. **Tell: a finding whose fix is "prove the baseline" or "add a task to build X" where building X is already the proposal's job is the reviewer reporting the work as its own blocker — drop it.**

**Paste each slot's return — verdict line and findings list — verbatim into the transcript. A slot with no pasted return is `not-run`.** You are the actor with an interest in a flattering read; paraphrase is laundering.

**The three slots:**

- **Code Reviewer** — correctness, contracts, edges, security, consistency with existing code. **Mandatory deliverable — the guard checklist**: every guard/check point with `file:line`, over the same categories and scope as §1b's enumeration. This is the loop's **weak anchor**. For every checkpoint consuming a **set dimension**, add three columns — `declared-coverage set` │ `actually-effective set` │ `equal?` — because writing the two sets side by side turns "the guard covers less than exists" into a comparison the reviewer cannot skip past.
  **The prior-fix context primes the CR's *findings*, never its *enumeration*.** The checklist demand is the same fixed wording every round, and it sits *before* any prior-fix context in the CR prompt — the enumeration instruction itself never mentions rounds or regions. A checklist is an enumeration, not a judgment — and a CR told "round N−1 fixed region R, hunt *new* blockers" under-enumerates R, so the anchor thins over exactly the region the loop's own fix just touched, `anchor ∖ table` comes back empty there, and the loop stops without ever re-anchoring it. **That is the mechanism by which a loop certifies the defect it just introduced.**
  **A CR APPROVE without its deliverable is not a pass** → the slot is `not-run(missing guard checklist)`. One exception: an artifact with no guard points at all (a pure-prose proposal) — an empty checklist **that states the scope it enumerated over** counts as produced.
- **Reality Checker** — dispatched per §1b.
- **Codex** — `subagent_type: codex:codex-rescue`, **dispatched read-only**: it is the review lane and can never be the fixer. A different model family is the one distribution the other two lanes cannot supply — a same-family Independent Reviewer would be a fresh view, not a new distribution. It returns prose by default; the prompt must explicitly demand the final verdict line. (`/codex:adversarial-review` is manual and emits no verdict line — this is the only Codex path the loop may auto-dispatch.) Absent ⇒ the loop degrades honestly per Termination; there is no same-family substitute. **Security-artifact failure mode (recoverable).** When the artifact is security-sensitive — a parser, input validator, sanitiser, or regex/ReDoS surface — an *attack-framed* prompt (`attack`, `exploit`, `construct a ReDoS input`, `adversarial`) can trip Codex's **own** cybersecurity content filter, which aborts the turn (`Codex error: This content was flagged for possible cybersecurity risk … Turn failed`) and yields no verdict. Frame the request as **correctness, not exploitation** — describe the function and its correctness floor and ask for *an input that produces wrong or incorrect output*: equivalent finding power, no abort. This `not-run` is **recoverable** — re-dispatch once with the reframed prompt before recording it, and name it `not-run(content-filter)` so a reader tells a recoverable filter-trip from a genuinely silent slot or a terminal API error.

**Resolution ladder** — how a named lane or fixer (CR / RC / MCE / ASE) becomes a running subagent. Three tiers, resolved per lane at dispatch; **echo the tier**. The Independent Reviewer never enters the ladder: a fresh adversarial prompt *is* its persona.

**The catalog is a prerequisite the user installs (per the README); the loop reads it and never writes to it — and neither does anything it dispatches**: a reviewer that stamps `APPROVE` on code comes from a checkout the user chose to trust, at a revision they control. Missing ⇒ the lane degrades and says so; the loop never installs it.

**Two identifiers, named apart, because conflating them silently drops a lane through every tier:** the **type-name** is the string a platform would register a lane under (`Code Reviewer`); the **catalog path** is where the file lives (`engineering/engineering-code-reviewer.md`). The catalog's frontmatter `name:` is the *type-name*, not the filename slug. **The table below is a lookup key, not a registry** — it says which string to search the host's subagent list for; it never says the host has it.

| lane | type-name (the string to look up) | catalog path (local tier) |
|---|---|---|
| CR | `Code Reviewer` | `engineering/engineering-code-reviewer.md` |
| RC | `Reality Checker` | `testing/testing-reality-checker.md` |
| MCE | `Minimal Change Engineer` | `engineering/engineering-minimal-change-engineer.md` |
| ASE | **`Security Engineer`** | `security/security-appsec-engineer.md` |

*(ASE is the trap: the catalog file's frontmatter reads `Application Security Engineer`, which is registered nowhere and matches no filename. A lane that looks itself up under that string finds no catalog file and halts — the one lane whose job is security, stopped by a name.)*

**Read the catalog before you resolve any lane.** The read is the only step of this ladder with a falsifiable artifact: a file either is at that path or it is not, and a tool record says which. "The host has this type registered" is a sentence, and a sentence costs nothing to write — put it first and the halt below is one an agent can talk its way past without ever touching the filesystem.

| step | act | outcome |
|---|---|---|
| **1 — resolve** | read the lane's **catalog path** under `~/.agency-agents/` (a git clone of the catalog; nests two levels). Confirm the file's frontmatter `name:` equals the lane's type-name | no file ⇒ the lane is **unresolved** ⇒ halt, below |
| **2 — dispatch** | the file is there, so the lane is real. Its type-name is an installed subagent type on this host ⇒ dispatch that subagent natively, marker `[registered]` — **strongest: the host owns the persona and its tool scope**. Otherwise embed the file's body, minus frontmatter, as a `general-purpose` agent's persona, marker `[local: <catalog path>]` | **each marker carries what falsifies it** — the path a reader can stat, or (⑮) the dispatch record that must name the type |


**An unresolved lane halts the run** — `PREREQUISITE-MISSING (<lane> — see README)`, a hand-back like `OUT-OF-SCOPE-PENDING`, not a verdict: the catalog is a prerequisite the user installs, and a run without a real reviewer has nothing to certify with.

**Deterministic strong anchors** — optional to run the loop, **required for a clean `APPROVE`**; findings-only. The main agent runs these **before** dispatching; hits become §2 findings, artifacts become §1b's anchors. Three forms:

1. **Executable invariant check** — a change-impact rule for a bug category §1b has already written up (§1b's invariant library). **Not available on round one of a fresh artifact** — the library is empty until a recurring bug has been written into it. Say so rather than inventing one.
2. **Off-the-shelf static analysis** — shellcheck / clippy / ruff / an existing CI contract check / AST or grep extraction of guard points.
3. **New-dimension fan-out grep** — a real, reproducible grep of the diff's new dimensions across every repo consumer, hunting `declared ⊊ effective` and "same error, different exit codes per entry point".

**Acceptance test — all three forms.** An anchor counts as **strong for category X** only if it left its **command + output** *and* its output covers **every `file:line` the CR checklist listed under X**. Without this, a zero-warning `ruff` run "strong-anchors" categories ① and ② having certified nothing, and the clean tier is buyable with a linter. The scan proves what it *scanned*; only an independent enumeration says whether it scanned *enough*, and the CR checklist is the round's only independent enumeration. Compared during §1b's reconciliation, after the CR returns. CR columns missing or empty → nothing to compare → **weak**. **A strong anchor proves "the scanned set is clean", never "the scan was complete"** — pattern completeness is not mechanically provable, which is why the clean tier is rare and honestly so.

**Echo this status block every round.** A failed subagent returns empty, indistinguishable from "no problems" — so an empty slot never defaults to pass. Slots carry the **normalized** verdict plus the resolved tier.

```text
Slots: Code Reviewer=APPROVE [registered] │ Reality Checker(§1b)=CHANGES-REQUESTED [local: testing/testing-reality-checker.md] │ Codex=not-run(empty)
Augment: none
Scope fence: agreed scope anchored | out-of-scope findings: 0
Anchors: ①strong(invariant cmd#1) ⑤strong(grep cmd#2) ④weak
Simplicity: net +18 this round (measured, from Landed:) | would-remove: -140 cumulative | over-eng: 1 open
Legibility: unfollowable 0
Spot-audit: row 14 | re-ran empty-input | observed exit 1 vs claim exit 0
Landed: src/auth.py:91-152, src/cli.py:12-19
Regression: 2 of 7 (triage blocker/major ∩ last round's Landed) | hits: src/auth.py:96, src/auth.py:131
```

On a prose round the last two read instead — the added text, verbatim, because that is what next round's findings must be quoted against:

```text
Landed: §3 "A fix landing in a section that has already taken 3 of this loop's insertions must
        rewrite the section instead of adding a caveat." | §1e "net: counts what §1e's own
        findings would remove."
Regression: 1 of 6 (a triage blocker/major quoting text Landed: added) | hits: §1e's "would remove"
```

**Canonical skip strings** — a lane that did not run says so in the string the evaluator matches, and **never the bare word `none`** where a gate reads "no anchor at all":

| line | skip string | when |
|---|---|---|
| `Anchors:` | `n/a (0 in-scope categories; weak anchor = the produced-empty CR checklist)` | pure prose |
| `Scope fence:` | `no full requirement context, skip` | §1d |
| `Simplicity:` | `no code or prose this round, skip` | §1e |
| `Legibility:` | `no prose this round, skip` | §1f |
| `Spot-audit:` | `no verified-safe rows` | §1b |
| `Landed:` | `n/a (no fix dispatched)` | **the terminating round, by construction** |
| `Regression:` | `n/a (no prior fix)` | round 1, or after a fix-less round |

The last two matter more than they look: **the round that passes is the round that finds nothing and therefore fixes nothing.** Without its skip strings, the convergence predicate would deadlock the one round allowed to terminate.

**Paste the triage list** (§2) into the transcript every round. It is the second of the evaluator's three artifacts, and an input it cannot see is an input it cannot check.

### 1b. Failure enumeration (Reality Checker slot)

Semantic reviewers verify the happy path plus already-written assertions and systematically miss **failure paths × edges × false-green** (a false green: a signal that reports success while the thing it certifies is broken or unexercised) — nothing forces them to enumerate, and reading beside green tests primes "it was tested" into "it is settled". The RC slot removes both causes: a forced enumeration structure, fed de-polluted input.

**De-polluted input.** The diff + truth source marked **to-be-proven**; all evaluative framing stripped (no "already APPROVE'd N rounds", "tests pass", "fixed last round"). The one prior-round artifact it gets is a neutral **row ledger** — `row ID + boolean "did this round's fix touch this row or its dependencies"`, terminal-state values and praise excluded (`verified-safe` is itself a verdict; re-feeding it primes re-confirmation). The ledger answers *"which rows need re-verification"*, never *"which rows may be skipped"*.

**Step 0 — new-dimension lateral fan-out** (before the enumeration; decides which *unchanged* consumers the table must include). Steps 1–2 are vertical and miss the lateral class: *the diff introduced a new dimension and some unchanged consumer was never updated*. Mechanically extract the diff's new dimensions (new config keys, new enum arms, new role/capability constants, changed `exception → exit-code` mappings); grep **every consumer of each dimension across the repo** (preflight, validation, attribution, probes, each CLI entry, `except` blocks); pull every consumer the diff didn't touch into the table.

Two honesty rules. **The executor sets the anchor strength** — the RC hand-listing consumers is weak; the main agent's real pre-dispatch grep with command + output is strong (subject to §1's acceptance test). And **running step 0 never makes category ⑤ "covered"** — scope comes from the code having that kind of guard; a guard with no main-agent artifact stays in scope under a weak anchor and caps the tier, else a category and its anchor would be self-produced by one prose step.

**Step 1 — mechanical enumeration (list, don't judge).** Every point of categories ①–④ plus step 0's pulled-in consumers, in a table with `file:line`. **Scope = changed diff lines + directly-impacted unchanged code**: unchanged callers of a changed contract/signature/return semantics, called helpers, unchanged cleanup/finally paths, unchanged tests and CI whose assertions depend on changed behaviour — regressions hide in code the diff made newly reachable or newly dead. An empty table states the scope it enumerated over.

**Step 2 — per-row adversarial.** For each row, instantiate **the failing inputs applicable to that row's kind** from the menu `{empty / null / malformed / timeout / partial-write / restart-mid-op / concurrent dual-driver / returns-error-not-value / token-expired / zero-row query / transient error that clears on retry}` — a **menu, not a per-row quota**: demanding all eleven of every row forces fabricated evidence, the very false-green this pass hunts. Record "observed behaviour vs contract claim". Any *reports-success-while-the-underlying-thing-broke-or-lied* = **blocker** (fault-tolerant degradation is not lying — the contract baseline tells them apart).

**Contract silent on a failing input ⇒ record "behaviour undefined" — never pass by default.** It is a finding, graded like any other: undefined behaviour that would produce a wrong result is blocker/major (fix the contract, or the code); genuinely don't-care is `accepted-degraded` with `minor` named. **It is never `verified-safe`, and never left as a bare `unresolved` row** — every real diff has an input its contract is silent on, so leaving them unresolved would make every real diff unpassable.

**Step 3 — out-of-table tail.** Untestable acceptance, pseudo-acceptance, whole-design unprovables — appended at the end.

**Harness false-green sub-template.** When the diff touches any green-signal-producing file (by content intent, not directory: `tests/`, `*.sh`, `conftest.py`, test config, `*.bats`, `Dockerfile`, CI yaml, a doctor script, a soak run), additionally walk: vacuous assert (always-true, or asserting on the mock itself) / exception swallowed then marked success / cassette recorded from a broken run / flush-writing an empty or garbage file / write fails yet marked flushed / a check returning 0 on query failure or zero rows. **This is where the evidence itself lies** — orthogonal to production failure injection, hence its own list.

**Completeness reconciliation.** The table cannot attest itself (prose reviewers satisfice), so set-diff it against an **anchor**. Bidirectional, on `file:line`, mandatory:

| direction | meaning | terminal state |
|---|---|---|
| anchor ∖ table | omission — an anchor point absent from the table | `unresolved` |
| table ∖ anchor | unverified row — a `file:line` in neither the diff nor the anchor | `unresolved`; two possible causes (a fabricated row, or a legitimately-impacted line the anchor missed) — **don't presume which**; settle only after adding or confirming the anchor |

**1:1 pin (hard rule)**: each anchor point maps to exactly one table row — a merged mega-row doesn't count as enumerating its members, else `anchor ∖ table` is always empty and the diff is theatre. The pin binds only under a fine-grained anchor; under a weak one, a merged row *is* the declared incompleteness.

**In-scope categories** = every category the round's code actually has a guard point for — the union of the §1b enumeration, the CR checklist and all strong anchors, **decoupled from which categories have anchors**. The gate reads categories ①–⑤ only; **drift and fragility never enter it** — they can neither block nor unlock a tier, only force the disclosure suffix: **without strong-anchor coverage of drift/fragility, every terminal token carries `[narrative-drift/forward-fragility: not-covered]`.** *Honesty boundary*: under weak reconciliation, scope-truth itself comes from prose enumeration — if both prose passes miss a whole category it silently drops out; only a strong anchor decouples scope from prose.

**Anti-vacuum (pure proposal).** An empty in-scope set is never read as "every in-scope category has a strong anchor, vacuously". On a pure-prose artifact the §1b table is empty by design, so gate clauses 1–2 (Termination) would evaluate to `true` **without executing** — the whole mechanical apparatus vacuously satisfied, leaving only "three reviewers found nothing", which is precisely the false-green this loop exists to hunt. Therefore, **on an empty §1b table, gate clauses 1–2 are satisfied instead by §1f**: the cold read ran with its return pasted, `unfollowable = 0`, and every Q4/Q5 item carries a disposition. §1f is the lane that does the real work on prose; on that artifact class it is the gate, not an advisory. The tier is `APPROVE [in-scope: empty/pure-proposal]` — a clean pass whose suffix discloses the empty in-scope set; it is a coverage gap, not a degradation.

**Executable invariant library.** For each **recurring** bug category, one lightweight executable change-impact rule: pattern hit = flag + demand evidence. Example (capability-lifecycle): a diff adding `requires_capabilities: [X]` must show ① X's provider, ② its acquisition path (eager or lazy, and when), ③ where preflight checks X *relative to* that acquisition — any missing ⇒ that row `unresolved`. One rule per real recurring bug lifts that category from weak prose to strong deterministic; a new category's first occurrence still slips (weak reconciliation and the bot backstop it — then write its invariant).

**Bot findings are pure increments**: they enter triage but never enter the coverage proof, never raise a tier, never remove a disclosure suffix. Running §1b — or the bot — is not coverage; only anchors are.

**Every row ends in exactly one of four terminal states** (the gate checks terminal states, not "has a disposition"); rows that became findings merge into §2:

- **`verified-safe`** — verified against its applicable failing inputs, behaviour matches contract, **evidence attached** (which inputs + observed vs claim). A bare label counts as `unresolved`. **The main agent spot-audits at least one claimed row per round** — among `verified-safe` rows, the one whose failing input is cheapest to actually re-run (a command over a code walk, a walk over a judgment); state the pick in the `Spot-audit:` line: re-check its evidence against the truth source, re-running the cheapest applicable failing input, and **echo it**. A round with any `verified-safe` row and no `Spot-audit:` line audited nothing — and the spot-audit is the only thing standing between a fabricated evidence field and a pass.
- **`fixed`** — became a finding, fixed (pointer attached).
- **`accepted-degraded`** — explicitly demoted or ruled not-applicable, **with an auditable reason keyed to a severity definition**; no named definition ⇒ still `unresolved`.
- **`unresolved`** — not verified, not fixed, reason doesn't hold, or a terminal state claimed without evidence.

**Expectation setting.** Without a strong anchor per in-scope category — most small repos — the steady state is `APPROVE [weak-reconciliation: not-covered]`: the change is clean, its completeness merely unproven. That is a **disclosure suffix, not a degradation** — `APPROVE-DEGRADED` is reserved for a real accepted degradation. To retire the suffix and reach a bare clean `APPROVE`, add the anchors.

### 1c. Adaptive augmentation (optional, findings-only, no slot)

The main agent may **add** specialists per change domain — along exactly two axes, both meaning "a new distribution":

- **Knowledge axis** — named domain knowledge the slots lack: reentrancy, WCAG contrast, query-plan pathology, RTOS timing, tax law…
- **Method axis** — a clearly different review method: structural design, threat modelling, forward fragility. Not another generic semantic reviewer.

**Trigger pre-pass** (before dispatch; leave the matrix in the transcript): scan `changed-file globs × content greps × subject` → matched domain → named gap or lens → resolvable specialist? → dispatch, or skip with the reason recorded. Mapping examples, non-authoritative — **the registry wins** (installed types + the local catalog outrank this list): `*.sol`·`delegatecall` → Blockchain Security Auditor; DB migration → Database Optimizer; ARIA → Accessibility Auditor; CI/IaC → DevOps Automator; proposal/design text → Software Architect; security-sensitive change → ASE.

**Three add gates — all must hold, or don't add.** The burden of proof is on the adder; a reviewer whose new distribution you can't name is itself a defect — over-augmentation is the vacuous-assert of review lanes.

1. **You can name the new distribution** ("frontend-related" is not one).
2. **The domain is actually touched** — a matrix hit, not a "maybe".
3. **It resolves to exactly one real specialist.** Primary: the ladder's `local` path match. Fallback for a sub-concept with no filename (`reentrancy` → *Blockchain Security Auditor*): `grep -ril "<term>" ~/.agency-agents/*/ --include="*.md" 2>/dev/null` — the `*/` keeps it inside the division directories the ladder resolves from, and an empty or errored listing is `0 confirmed` — a **candidate generator only**. Both paths end in the same confirm: read each candidate's frontmatter `name:`, confirm the role *is* the domain, drop anything without frontmatter (that check is what rejects READMEs and decoys). Then: **`>1` → prefer the candidate whose frontmatter `name:` *is* the domain** (`accessibility` → `Accessibility Auditor`); still `>1` → **dispatch the top two and merge their findings** — they are findings-only, one extra augment costs a round and a wrong SKIP costs the finding. **`0` confirmed → SKIP.**

**Two ways to skip a matrix hit, graded apart:**

| skipped because… | grade |
|---|---|
| the expert genuinely doesn't exist (not registered, not in the catalog) | not a finding — **disclose it**: the `Augment:` line carries `expert unavailable` **with the grep command and its candidate count pasted**, and the terminal token carries `(<domain>: expert unavailable, generic coverage only)` |
| the expert was resolvable and you skipped anyway | a **`major` you did not fix** — justify it like any other |

Augment findings feed §2 only — no slot, no verdict, and they never erase the CR checklist anchor (even the correctness-class ASE stays findings-only). **Echo** each with its tier: `Augment: +Blockchain Security Auditor(knowledge:reentrancy)[local: security/security-blockchain-security-auditor.md]`; else `Augment: none`.

**Method-axis backfill when Codex is absent**: a different model family has no same-family substitute. A method-axis specialist (Software Architect for the structural view) may backfill to reduce the miss rate, but **never lifts** the `[third-slot: not-run]` disclosure — increment-only, no slot.

### 1d. Scope fence (mandatory when full requirement context exists)

Prevents scope creep laundered as bug-fixing: reviewers propose "robustness", triage fixes by default, and the loop ends having built features nobody asked for.

**Raise the fence, once at start.** If the context contains a complete requirement description the AI and user settled on (explicit goal / acceptance / boundaries — not one vague instruction), extract and restate an **agreed scope** list: what's in, what's out, which contracts the user already approved. **The test for "complete": every item on the list quotes a sentence the user actually wrote in this session** — a boundary you cannot quote is a boundary you invented. If writing it forces a guess, **skip the fence** (echo the skip string) rather than fence on a guess. Never block, never invent scope. **A skipped fence attaches `[scope-fence: not raised]` to the terminal token** — the opt-out costs its disclosure, and a fence raised on unquotable boundaries is visible to anyone who asks for the quotes.

**The scope binary** (triage runs it once per blocker/major):

- **In-scope**: fixes a failure path that would cause wrong results / crash / corruption / contract mismatch under the agreed behaviour — without adding user-visible behaviour, interfaces, config or dependencies, and without changing an approved contract → **fixed by default**.
- **Out-of-scope (big change)**: needs to add features / config / a CLI entry / a dependency not in the requirement, change an approved contract, or materially expand implementation scope (a new cross-module subsystem, an abstraction layer, retry / persistence / concurrency / cache machinery nobody asked for). **Tiebreak for "materially"**: if the fix introduces something the user would now have to know about or operate — a new flag, file, daemon, dependency or changed contract — it is out; an internal guard confined to existing files and knobs is not.

**Handling: don't auto-fix, ask immediately, never launder.** On a hit, pause and report: the finding, why it crosses, the minimal in-scope fix vs the crossing fix, and a request for authorization. Before authorization: **no fix dispatch, and no silent demotion to `accepted-degraded` to keep the round clean** — that is one more false-green. Authorized → scope updates, finding becomes in-scope. Declined → `accepted-degraded`, reason "out of scope, user declined".

**Prompt landing, every round**: reviewer prompts carry the agreed scope + the `[out-of-scope]` tag demand; the §3 fix spec pins "only touch X, add no new Y". The hard pause is Termination's `OUT-OF-SCOPE-PENDING` row.

### 1e. Simplicity counter-pressure (findings-only, no slot)

The three slots are all **additive** and the fixer is only locally minimal — nothing else in the loop perceives bloat, so each round trends the artifact up: severity drains while lines climb, and Termination fires on a diff far larger than necessary. This is the subtractive counter-pressure.

**Run** on every round whose diff contains **code or prose** — the ratchet argument holds verbatim with "clauses" for "lines". **On the loop's first round, run it over the whole artifact, not just the diff**, and **carry `net:` forward cumulatively**: a per-round diff lens sees one individually-justified insertion at a time, and the accrued total is invisible to it by construction — which is exactly how a loop adds 60% to a document while every round's addition looks necessary. Neither code nor prose → the skip string. Dispatch as a `general-purpose` subagent carrying the rubric, in parallel with §1.

**Rubric** (self-contained). One line per finding: `file:line: <tag> <what>. <replacement>.` — tags `delete:` · `stdlib:` (hand-rolled what the stdlib ships) · `native:` (the platform already does it) · `yagni:` · `shrink:`. On prose only three apply: `delete:` (a rule nobody will follow; a section restating another) · `yagni:` (a branch that can never fire) · `shrink:` (same rule, fewer words). End with `would-remove: -N this round, -M cumulative` or `Lean already. Ship.` The ladder: stdlib > native > installed-dep > one line > minimum code.

**Never flag the never-simplify set**: validation at trust boundaries · error handling that prevents data loss · security · accessibility · **anything the *user* explicitly requested** — *not* "anything a prior round's triage requested", which would exempt the loop's own output from the lens built to counter it · a hardware calibration knob · the one runnable check.

**Report-only.** Findings ride §2 as `minor` advisory, never auto-dispatched to the fixer — a prose pass can't prove a line dead ("no caller" by grep ≠ unreachable), and auto-acting on the label is the mislabel → delete → re-add hazard. Promotable to `major` only when the bloat itself breaks correctness or a contract; never `blocker`. `would-remove:` counts what §1e's own findings *would* remove — a proposal, and tier 3.

**`net:` is a different number, and the gate reads that one: the round's MEASURED delta, recomputed from `Landed:`.** They are easy to conflate and the conflation is fatal: §1e can honestly report `would-remove: -500` in a round that actually *added* 400 words, so a gate reading §1e's number would never fire on the growth it exists to catch.

### 1f. Legibility counter-pressure (cold-read lens — findings-only, no slot; **the gate on prose**)

**The second ratchet.** §1e counters the code ratchet; this one fires when the artifact is **prose a human has to read** — a spec, a proposal, an ADR, an OpenSpec change, a `SKILL.md`, a README, a design doc. Three things happen every round, and no other lane can see them, **because every other lane is a reviewer and none is a reader**:

- a fix lands **where the finding was found**, not where a reader needs it;
- a term the loop coined mid-run is **never defined**;
- a rule gets restated somewhere else in **slightly different words** — now no copy is authoritative, so nobody dares change any of them.

The end state is a **patch pile**: a document only the loop that produced it can read. The loop's exit is "no reviewer can find a hole"; the reader's is "I can act on this correctly". Those diverge, and every round widens the gap. **On an artifact with no code (§1b's table empty), this lane is the pass gate** (§1b's anti-vacuum rule) — because it is the only one doing work there.

**Run on every round whose *artifact* is prose — including the fix-less terminating round, where the cold read *is* the gate.** Not "whose diff touches prose": the terminating round is by construction the round that fixes nothing, so a diff-scoped trigger would skip §1f on the one round that must satisfy the gate, and the pure-prose class could never pass. The skip string applies only when the artifact contains no prose at all.

**The cold read.** Dispatch a `general-purpose` subagent and **constrain what it may read, not just what you tell it** — a subagent has tools and will otherwise read git history and the neighbours, becoming a warm reader with a fresh transcript. Pin verbatim:

> *Read exactly these files and no others: `<artifact read-set>` — the artifact, plus (only when it is one file of a co-authored bundle: an OpenSpec change, a multi-file spec) the sibling files it was written against, each named explicitly by the main agent. Do not read git history, do not read files outside this set, do not search the web. Answer only from that text. Behaviour this text explicitly delegates to a named, locatable authority — a spec path, a source file, a contract fixture it points at — is a **dependency, not a missing local definition**; flag it only when the reference is missing, ambiguous, contradictory, or the artifact introduces a new local boundary the authority cannot determine.*

A return that cites any file, commit, or conversation outside the declared read-set is a warm read — discard it and re-dispatch once (the citations are in the return; the check is a read, not trust).

Ask these five, and **let it pick its own targets in 2 and 3** — if you pick them, you are the exam-setter, the graded party, and the most primed actor in the loop:

1. What is this for, and when should I use it — and when should I *not*?
2. **Pick the most consequential scenario this document describes**, and walk me through what happens. Say exactly where you would stall.
3. **Pick the rule you would most likely need to change**; where do you edit, and what else would that break?
4. **Every load-bearing term this artifact introduces or redefines** that a reader must understand to implement, operate, test, or change it — quote where each first appears. A standard technical noun the artifact did not coin (a widely-known tool, protocol, or concept) is not this — only the project's own coinages count.
5. **Every rule you could not follow** — quote it; say exactly what is ambiguous or impossible.

**Its return goes into the transcript verbatim** (the evidence rule; a `Legibility:` line with no pasted return is `not run`).

**Two finding kinds from the read** (the finding is always the reader's quote — never a count of your own):

- **unfollowable** — a rule the reader quoted in Q5. **A rule no reader can satisfy is decoration — worse than an absent rule, because it manufactures the appearance of a check that isn't there.** Separate two kinds before counting. **`unfollowable-local`**: the artifact's own rule is self-contradictory, or leaves an execution rule the read-set cannot supply — `major`, fixed by default, and **only these count toward the gate.** **`external-reference-required`**: the rule points at an external artifact the cold read was forbidden to open, and the reference is **pinned** — path + version/commit + digest, all three present — so an implementer who fetches exactly that artifact *can* follow it; the cold reader's inability to open it is an isolation artifact, not an unfollowable rule. It is **not counted**; it rides the terminal token as `[external-refs: N pinned, not inlined]`. A reference missing its digest is not pinned — it can drift, so it stays `unfollowable-local`. The `Legibility:` line carries the `unfollowable-local` count, because ⑪ bites on it.
- **undefined** — a term the reader quoted in Q4 (which now counts only the artifact's own coinages, never standard technical nouns). Findings-only, riding triage: a term only the loop understands must be reverse-engineered by the next reader.

**On the loop's first prose round, run the read over the whole artifact, not just the diff** — a diff-scoped pass can only slow the next pile, never clean the one you came for.

The counts are not scores (two honest runs won't agree); **the finding is the reader's quote** — the number only makes it visible in the echo.

**Severity**: `minor` advisory, riding §2, never blocking — **except an unfollowable rule, which is a `major`, fixed by default.** A review-demotion of an `unfollowable` must **quote the reader's Q5 text and name why the *reader*, not the author, was wrong**; anything less is the author grading their own prose.

**Honesty boundary.** §1f is weak-reconciliation class: a fresh reader and you are both prose passes and can co-miss. `Legibility: clean` proves one reader could follow this text once. **§1f is subject to itself** — a legibility rule that exempts itself is the first rule a reader stops believing.

### 2. Triage

Merge findings from all sources — three slots, anchors, augments, §1e, §1f, bot — into **one deduped list** (never two fixes for one spot); re-grade per Verdict normalization. **Paste the result**: it is the evaluator's second artifact, and the only place the *normalized* severities exist.

1. **Scope binary first** (fence up): out-of-scope blocker/major → pause for authorization; never auto-fix, never launder.
2. In-scope blocker/major → fixed by default. A major you won't fix → **review-demoted** with its named definition, never skipped verbally.
3. Minor by cost-benefit; nit usually skipped.
4. §1e / §1f findings ride as `minor` advisory, report-only — **except an unfollowable rule (§1f): `major`, fixed by default**.
5. Tell the user what was fixed and what was skipped.

### 3. Dispatch fixes

**The dispatch table splits by artifact, because "minimal" means opposite things in code and prose.** For code, minimal = the smallest *textual diff* — that discipline prevents scope creep. For prose, the smallest textual diff is an inline caveat at the finding site — **exactly the §1f patch-pile generator**. A prose fix minimizes the *semantic delta* instead.

| fix target | dispatch | minimality metric |
|---|---|---|
| code — local bug, single module, mechanical per spec | **MCE** (ladder) | smallest textual diff |
| code — cross-module / architecture or data-flow rethink / schema or API migration / needs a test strategy | a `general-purpose` subagent with the full context — **never `codex:codex-rescue`**: §1 dispatches it read-only, so it cannot apply a fix; and if it did, next round the Codex slot would review its own family's output, destroying the one distribution it exists to supply | smallest coherent change |
| prose — mechanical (wording, format, filling in an already-decided design) | main agent edits directly | — |
| **prose — semantic** (a rule wrong / ambiguous / unfollowable / restated) | **never MCE** — its persona ("smallest possible diff, touch nothing unrelated") is the patch generator and will fight the spec. Main agent, or a `general-purpose` subagent carrying the rewrite contract | **smallest semantic delta, textual diff unbounded** |

**The rewrite contract** (pinned into every prose-semantic fix spec): rewrite the containing **section from its purpose** — never add a caveat to a section that has already taken 3 of this loop's insertions (Terms: patch count). Every rule keeps exactly what it required before, except the rule the finding names — and making an *unfollowable* rule followable is in-scope by construction: a requirement nobody could satisfy was never a requirement. One authoritative statement per rule; the others point at it. Each rule carries, **in one clause**, the failure it prevents — a rule with no why is the one the next reader deletes as noise, and then the loop rediscovers the hole. **That clause is a clause, not a paragraph**: a rule escorted by an argument against the draft it replaced is written for the reviewer approving the document, not the agent executing it, and it is how a thousand words of rule becomes three thousand words of document. Land each rule **where a reader needs it**, not where the finding was found. **A re-expression that preserves what the rules require is in-scope by construction** — it does not trip §1d; changing what a rule requires is a scope change and does.

**Echo `Landed:` after the round's fixes land** — the diff they actually produced (`git diff --stat`, or the edit's own reported ranges), **never the ranges the spec aimed at**. Aim is a prediction the fixing party authors: declare two lines, ship a two-hundred-line rewrite, and next round's findings truthfully fall outside it — no lie required. A diff is a fact anyone can re-derive, and it is in **post-fix coordinates**, the same ones next round's findings use, so an insertion cannot push the code it broke out of its own footprint.

**Every fix spec** (any lane): file, fix, acceptance per problem; the §1d scope pin at the top. **The ponytail ladder is pinned** for each triage-approved fix: the laziest fix that holds (stdlib > native > installed-dep > one line > minimum code); no new abstraction / config / dependency unless the finding's correctness requires it; a deliberate simplification carries a `ponytail:` comment naming its ceiling and upgrade path — **non-contractual**: §1b still judges that line against the truth source next round. Never simplify the never-simplify set (§1e). For large cross-module fixes, split into disjoint write scopes, or keep the fix in the main thread when delegation would add coordination risk.

**Fixer boundaries**: uncontested items first; pause and report only when a discovery would make the spec wrong, introduce a regression, or require expanding scope; record adjacent small issues without self-expanding. A finding **unfixable without crossing scope** → report back only (§1d).

### 4. Re-review

Back to §1, three slots in parallel — Codex may recover mid-run: a slot that returned nothing is `not-run(empty)`, re-dispatched next round.

## Termination

**A Codex non-verdict** (anything unparseable = `not-run`): re-dispatch it next round with a stricter prompt; a round that ends with the slot still silent discloses it — the terminal carries `[third-slot: not-run]`, and a clean `APPROVE` is out of reach (the tier table). No retry ceiling, no escalation machinery: the disclosure is the whole mechanism.

**Pass gate** — every pass-class termination requires all three:

1. every §1b row has a terminal state **in {verified-safe, fixed, accepted-degraded}** — `unresolved` is a terminal state and does **not** satisfy this;
2. the bidirectional reconciliation passed; **no anchor at all = no pass**; a prose-only anchor passes here but caps the tier;
3. no unresolved blocker/major after normalization;
4. **this round dispatched no fix** — `Landed:` reads `n/a (no fix dispatched)`. Without this, a round that finds nine blockers, fixes all nine and normalizes them to `fixed` satisfies clauses 1–3 and passes — **and those nine fixes are never reviewed by anything.** A fix is only ever validated by the round that follows it.

**On an artifact with an empty §1b table** (pure prose), clauses 1–2 are vacuous — they are satisfied instead by §1f: the cold read ran with its return pasted, `unfollowable = 0` (the `unfollowable-local` count — §1f; a pinned `external-reference-required` is a disposition, not a residual), and every Q4/Q5 item carries a disposition (§1b's anti-vacuum rule).

**"All three slots wrote APPROVE" is not a pass** — that would make the exit condition the very false-green the loop hunts.

**The terminal-token table — the single authority. Take the first matching row.**

| condition | token |
|---|---|
| a lane has no catalog file at its path (**unresolved**, §1) | **`PREREQUISITE-MISSING (<lane> — see README)`** — a hand-back, not a verdict; the user installs the prerequisite (or declines) and the run resumes or ends there |
| an unadjudicated out-of-scope blocker/major (§1d) | **`OUT-OF-SCOPE-PENDING (N left)`** — no token, no suffix; **outranks everything, including the cap**. Halt for the user; the harness stops auto-continuing. If the user never replies, the loop stays halted — **no timeout converts silence into consent.** No fence up ⇒ never triggers |
| `Regression:` ≥1 for **two consecutive rounds**, and **not** converging-with-regressions (defined below the table) | **`NOT-CONVERGED (fix-induced blockers in 2 consecutive rounds; N items left, listed)`** — a terminal hand-back, **not a pass**. The loop is not iterating toward a pass; its fixes are producing the next round's findings. **It fires with or without a cap**, which is what closes the "delete the cap line to loop until pass" hole. *Two, not three*: a replay of a real six-round run showed a threshold of 3 fires exactly where the loop stopped by exhaustion anyway. And the asymmetry is not close — a false positive costs a hand-back the user overrides in one sentence; a false negative costs another N rounds of the loop certifying the defects it is inserting |
| a tool record in this run wrote into `~/.agency-agents` | **`CAPPED (catalog self-installed)`** — terminal, not a pass: the personas came from a checkout the loop installed, not one the user chose. A catalog the *user* installs mid-run is theirs, and resolves as `local` from the next round |
| the pass gate fails, or a slot rejected, **and** rounds remain | no token — **continue** |
| `net:` > 0 for **two consecutive rounds** | **`APPROVE-DEGRADED (bloat: +N over 2 rounds, no lane removed anything)`** — recompute `net:` from `Landed:` yourself; do not read the number. Three lanes hold a verdict and all three are additive; §1e is the one that subtracts and it holds none. Without a gate that reads this **value**, ⑭ checks only that the line is *present*, and `net: +400` passes every check — the loop's sole anti-bloat instrument reporting the bloat it does not stop |
| the pass gate holds ∧ all rows ∈ {verified-safe, fixed} ∧ every in-scope category strong-anchored ∧ the in-scope set is non-empty ∧ Codex gave a verdict | clean **`APPROVE`** / `CLEAR` |
| the pass gate holds ∧ all rows ∈ {verified-safe, fixed} (**no real degradation**), with any **coverage gap**: a weak-only category · Codex absent · an empty in-scope set (pure proposal) · a skipped scope fence | **`APPROVE`** / `CLEAR` **carrying the matching coverage-gap suffix(es)** — `[weak-reconciliation: not-covered]` · `[third-slot: not-run]` · `[in-scope: empty/pure-proposal]` · `[scope-fence: not raised]` — **plus any unconditional suffix from "Suffixes on every terminal token" below** (e.g. `[narrative-drift/forward-fragility: not-covered]`); this row lists only the coverage-gap suffixes, not the full suffix set. The change is clean; the suffix discloses **unproven completeness**, never a degradation — so the subject stays `APPROVE` and keeps carrying the one bit "was anything actually degraded?". **Stop immediately** once the only open suffix reason is one no further round can change — a pure proposal (the artifact class), Codex silent through its one re-dispatch, or a weak-only category whose every runnable anchor form was already attempted this run. |
| the pass gate holds, with a **real degradation**: an `accepted-degraded` row (a real finding explicitly demoted or ruled not-applicable) — `bloat` (above) and `[residual-floor]` (below) are the other two degradation sources | **`APPROVE-DEGRADED (<all reasons, one parenthesis>)`** — the subject means *a degradation was accepted*, no longer diluted by coverage gaps. |
| the cap is reached with anything unresolved | **`CAPPED (cap-reached, N items left)`**, listing them — terminal, not a pass. Under a harness with no cap set, `CAPPED` does not exist |

**Converging-with-regressions — the one exception to the two-round rule.** `Regression:` ≥1 for two consecutive rounds is **not** `NOT-CONVERGED` when, across those rounds, **both** hold: the surviving blocker/major **count strictly decreases** (recomputed from the pasted triage lists, never read as a number), **and no requirement recurs** — no round's fix-induced finding names a requirement a prior round's fix-induced finding already named (by native ID where the artifact has one, else by the requirement the finding quotes). That is a loop closing its own holes, not one manufacturing them, so it **continues** on the no-token "rounds remain" row — but **at most twice**: a third consecutive regression round, or any round where the count fails to drop or a requirement recurs, is `NOT-CONVERGED` regardless of cap. The two-round rule's asymmetry still holds — this exception fires only on evidence the defect set is *shrinking*, and its bound is what keeps it from becoming the "loop until pass" hole.

**Suffixes on every terminal token** (disclosures — not on their own a degrade reason — the lone exception is `[residual-floor: N registered]` below, which sets the `APPROVE-DEGRADED` subject): `[narrative-drift/forward-fragility: not-covered]` unless both have strong-anchor coverage · `[weak-reconciliation: not-covered]` when any in-scope category is weak-only — the scanned set is clean, its completeness merely unproven · `[third-slot: not-run]` if Codex stayed silent · `[in-scope: empty/pure-proposal]` on an empty in-scope set (prose-only artifact) · `[scope-fence: not raised]` if §1d was skipped · `(<domain>: expert unavailable, generic coverage only)` if any round's `Augment:` line said so · `[external-refs: N pinned, not inlined]` if §1f disposed any Q5 rule as `external-reference-required` · `[residual-floor: N registered]` when every surviving finding is a **document-registered residual class** needing a production-unreachable precondition (a provably-not-fully-immune parser — a regex/`indexOf` scanner — where each remaining wrong-output input requires malformed input the production source never emits): the pass is `APPROVE-DEGRADED`, and the suffix lists the residual class rather than chasing production-unreachable inputs forever.

## Pairing with a completion harness

A harness (`/goal` on Claude Code) re-reads the transcript at each turn's end with the evaluator and restarts the turn while the completion condition is unmet. The status block is echoed **every round**; the terminal token appears only on the terminating round.

```text
Run an adversarial review loop on this change per review-loop.

COMPLETE when the latest round ends in a terminal token: APPROVE, CLEAR, APPROVE-DEGRADED,
CAPPED, or NOT-CONVERGED. The last two are terminals, not passes — they END the run; they do
not restart the turn. A round ending OUT-OF-SCOPE-PENDING halts for the user instead.

A PASS-CLASS token (APPROVE / CLEAR / APPROVE-DEGRADED) additionally requires:
  1. Both experts (Code Reviewer, Reality Checker) returned a verdict, and their returns are
     pasted verbatim in the transcript.
  2. Codex returned a parseable verdict, or its absence is disclosed on the
     terminal as [third-slot: not-run].
  3. The pass gate holds (see Termination). On a pure-prose artifact the §1b clauses are
     satisfied by §1f instead: the cold read ran, its return is pasted, unfollowable = 0.
  4. A clean APPROVE additionally needs: every §1b row verified-safe or fixed, a strong anchor
     for every in-scope category, and a Codex verdict. A weak-only category, absent Codex, empty
     in-scope set, or skipped scope fence keeps the subject APPROVE with the matching [disclosure]
     suffix — a coverage gap, not a degradation. Only a real degradation — an accepted-degraded row
     (or the bloat / residual-floor cases) — is APPROVE-DEGRADED. A lane
     resolving at neither tier is PREREQUISITE-MISSING — halt for the user, no token.

ECHO every round: the Slots line with resolved tiers; Augment; Scope fence; Anchors; Simplicity;
Legibility (on prose rounds); Spot-audit; Landed; Regression. PASTE every slot's return verbatim,
and the triage list. The evaluator reads those artifacts, not the numbers.

RECOMPUTE Regression yourself from the pasted triage list and the previous round's Landed —
do not take the number on faith. TWO consecutive rounds with a fix-induced blocker ⇒ NOT-CONVERGED.

ROUND CAP 10 (raise it freely; to loop until pass, delete this line — NOT-CONVERGED still applies).
```

**The evaluator judges literally** — each predicate independently checkable; **any hit ⇒ continue**.

**Two short-circuits, first**: a round ending `OUT-OF-SCOPE-PENDING` is halt-for-user — no predicate applies. A round ending **`NOT-CONVERGED` is a terminal hand-back: ②–⑪ are inapplicable and the run ENDS** — it is written *because* items are left, so leaving ③ (a slot rejected) and ⑥ (an unresolved row) armed would restart the turn on the one honest report the loop cannot afford to punish, and with the cap deleted it would never end. Only ⑫ still applies: it checks the token was owed.

**Suffix kinds, once for all predicates**: match tokens by **subject as a whole token, ignoring parenthesized suffixes** (`APPROVE` does not match `APPROVE-DEGRADED`).

Continue if any holds:

- **①** the latest round is missing the status block, **or any slot's return is not pasted verbatim** (a slot with no pasted return is `not-run`) **or the triage list is not pasted** — these are the artifacts every predicate below reads;
- **②** the CR or RC slot is empty / `not-run`;
- **③** any slot is `CHANGES-REQUESTED`;
- **④** the Codex slot is `not-run(...)` and the terminal token lacks the `[third-slot: not-run]` disclosure;
- **⑤** the final token's subject isn't one of `APPROVE` / `CLEAR` / `APPROVE-DEGRADED` / `CAPPED` / `NOT-CONVERGED` — **omitting either terminal from this list makes an honest failure report restart the turn instead of ending it**;
- **⑥** the §1b table is missing, has an `unresolved` row or a row with no terminal state, or failed the reconciliation — including **no anchor at all**. *(On a pure-prose artifact the table is empty by design: ⑥ is then satisfied by §1f's return being pasted with `unfollowable = 0`, per the anti-vacuum rule.)*
- **⑦** the token is `APPROVE`/`CLEAR` while the `Anchors:` line shows an in-scope category weak-only **and the token lacks the `[weak-reconciliation: not-covered]` disclosure**, or a row is `accepted-degraded` (that subject must be `APPROVE-DEGRADED`, not clean-APPROVE), or the §1b table is empty on a code diff;
- **⑧** drift/fragility has no strong-anchor coverage and the terminal token lacks `[narrative-drift/forward-fragility: not-covered]`;
- **⑨** the `Augment:` line is missing; or a round declared `expert unavailable` **without pasting the grep command and its candidate count**; or the terminal token lacks the corresponding suffix;
- **⑩** the `Scope fence:` line is missing (the skip string satisfies it, and adds its suffix); or the round has an unadjudicated out-of-scope blocker/major yet a token was written;
- **⑪** the `Legibility:` line is missing on a prose round (skip string and `clean` both satisfy it); or the reader quoted a rule in Q5 that the terminating round neither fixed, nor demoted with a quote of that Q5 text, nor disposed as `external-reference-required` with the pinned reference (path + version + digest) named;
- **⑫** the `Landed:` or `Regression:` line is missing (the `n/a` strings satisfy them on a fix-less round); **or the `Regression:` count disagrees with the intersection you recompute yourself** — `{the pasted triage list's blockers/majors}` ∩ `{the previous round's Landed:}`; **read the two artifacts, do not read the number** — or two consecutive rounds carry ≥1 fix-induced blocker and the terminating round is neither `NOT-CONVERGED` nor a bounded converging-with-regressions continue (Termination);
- **⑬** any §1b row is `verified-safe` and the round carries no `Spot-audit:` line naming a row, an input re-run, and an observed-vs-claim;
- **⑭** the `Simplicity:` line is missing on a code-or-prose round (the skip string and `lean` satisfy it) — without this it is the one echoed field no predicate reads, so an agent that never runs §1e passes every check; **or its `net:` disagrees with the delta you recompute from `Landed:`** — read the artifact, not the number — **or `net:` > 0 for two consecutive rounds and the terminating round carries no `bloat:` degrade reason.**
- **⑮** a `strong(cmd#N)` on the `Anchors:` line has no matching tool record in this round (that category is **weak** — an anchor nobody can trace is an anchor nobody ran, and it is the sole gate on a clean `APPROVE`); or an expert slot claims a tier without falsifiable evidence — a pathless local marker, a `[local: <path>]` no tool record read, a `[registered]` no dispatch record names — the slot is `not-run(tier unverified)`;

**Cap precedence** (only when a cap is set; `OUT-OF-SCOPE-PENDING` and `NOT-CONVERGED` both outrank it): predicates keep the loop running only below the cap. At the cap, stop unconditionally — but **"stop" ≠ "pass"**: record a pass token only if the gate is still verifiably satisfied; a missing table, a row with no terminal state, or an unverifiable reconciliation always records `CAPPED`. The disclosure suffixes are not waived at the cap.

## Honesty boundary

Three floors this loop cannot get under. Each is disclosed rather than papered over, because a mechanism that pretends to close one is worse than the hole: it manufactures the appearance of a check that isn't there.

- **The evaluator is prose with no runtime enforcement.** It lowers, never eliminates, a false green taken as a pass. What makes it more than a wish is that every predicate reads a *pasted artifact* rather than a typed number — but nothing forces the pasting except this rule.
- **`Regression:` sees only *noisy* divergence.** A loop whose fixes break things **no reviewer then finds** emits `Regression: 0` truthfully, every round. §1's un-primed-checklist rule narrows that — the CR re-enumerates the fixed region at full scope every round, so the loop cannot instruct itself to stop looking — but does not close it. **`Regression: 0` means *no reviewer found a regression*, never *there is none*.**
- **Completeness is not mechanically provable.** A strong anchor proves the scanned set is clean, never that the scan was complete; drift and fragility carry no coverage guarantee at all. That is why a bare clean `APPROVE` is rare, and why the disclosure suffixes are unconditional: the honest steady state of a real repo is `APPROVE` **carrying its completeness-disclosure suffixes**, with `APPROVE-DEGRADED` reserved for a real accepted degradation.
