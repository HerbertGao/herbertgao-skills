---
name: review-loop
description: >-
  Tear apart a written artifact and iterate it to a pass. **Use it when something is already written** —
  an OpenSpec change, a proposal, a spec, a diff; a pure-prose proposal belongs here too. **Nothing written yet,
  and the question is "which way should we go" (选型 / 架构 / 要不要做)? → that is `council`, not this.**
  Each round three reviewers run in parallel (Codex + Code Reviewer + Reality Checker), findings merge into one
  triage list, a fixer applies the accepted ones, and the loop re-reviews until a pass token or the round cap.
  Standing counter-pressures keep the loop honest about its own output: a scope fence (a fix that would add
  features/config/subsystems nobody asked for stops and asks), a simplicity lens (the loop only inserts, so
  something must count the bloat its fixes accrue), and a legibility lens (a fresh cold reader, so an iterated
  review cannot turn a readable document into a patch pile only the loop can read).
  Triggers: 「对本次提案/变更做对抗性 review 循环」「review 到通过为止」「避免 review 插入过多无效代码」
  (review this change until it passes / find the ship-blockers / keep fixes minimal).
  Pairs with `/goal` for long runs; runs standalone without it.
---

# review-loop

Tear apart a written artifact and iterate it to a pass. Each round: dispatch reviewers → triage → dispatch fixes → re-review, until a pass token or the cap. Call `/review-loop` directly; for long runs wrap it in `/goal` (last section) — optional; without it the main agent applies the same predicates to itself.

**Scope.** Something is already written — an OpenSpec change (OpenSpec: a spec-driven proposal workflow whose artifacts are markdown change proposals), a proposal, a spec, a diff. A **pure-prose proposal is in scope**: §1b's table comes back naturally empty, §1e applies only its three prose tags, §1f is the lane the round is actually for, and the terminal token is the Pass-tier table's pure-proposal row. A decision with *nothing written yet* is `council` (a sibling skill in this marketplace, built for exactly that), not this. For a trivial diff — a typo, a one-line fix — skip the loop: one direct review is cheaper and enough; the loop pays for itself only when a change can hide a ship-blocker.

## Terms

Defined once, here. Each definition is the term's only home; everywhere else points back.

- **slot** — one of the three verdict-bearing reviewer lanes (Codex / Code Reviewer / Reality Checker). Only a slot carries a verdict. Everything else — §1c augments, §1e, §1f, strong anchors, the bot — is **findings-only**: it feeds triage and holds no verdict.
- **CR / RC / MCE / ASE** — Code Reviewer / Reality Checker / Minimal Change Engineer / Application Security Engineer.
- **anchor** — the independent artifact you set-diff §1b's failure table against, to answer *"did the table miss something?"*. **Strong** = mechanical output from one of §1's three anchor forms, artifact attached. **Weak** = the CR's prose checklist — both sides are prose and can co-miss the same point. (The *cognitive* sense of "anchoring" is called **priming** throughout.)
- **category** — a kind of failure point, from **exactly this closed set**: ① guard / early-return / error branch / exception catch; ② assert / validation / exit-code; ③ state transition (restart, reconnect, renewal, cleanup, dry-run); ④ claimed-pass point (a test assertion, a cassette — a recorded network fixture, a recomputed column, a doctor check — a self-diagnostic command); ⑤ config/entry fan-out (§1b step 0). Two more exist — **narrative drift** (doc says X, code does Y) and **forward fragility** (correct now, silently breaks later) — that **none of §1's stock anchor forms covers**, so the loop must disclose them instead of gating on them; a custom executable invariant that does cover one (e.g. a doc-vs-code consistency script for drift) lifts it like any strong anchor, and evaluator ⑧ is exactly that door. A category is **in scope** when the round's code has a point of that kind — never "when you happen to have an anchor for it".
- **set dimension** — a thing with a *set* of legitimate members some guard must cover: a role set, a config-key set, an enum's arms, the CLI entry points. Check: `declared-coverage set` (what the guard reads) vs `actually-effective set` (the full set in the code). **Not equal = a finding.**
- **distribution** — the kind of defect a reviewer is *structurally* able to see. Two reviewers on one distribution find the same bugs; a fourth on a covered distribution is worth ≈ 0. Codex matters because a different model family is the one distribution another Claude cannot supply.
- **the evaluator** — the small model `/goal` runs at each turn's end, literally checking the predicates in the last section. No `/goal` ⇒ no evaluator; the main agent applies the same predicates to itself and the closing honesty boundary bites harder.
- **bot** — an always-on PR bot (BugBot, Copilot review) if the repo happens to have one. The loop never invokes one; it merges findings that already exist. No bot ⇒ nothing to merge, nothing to disclose.
- **cap / K / patch count** — three numbers, named apart. The **round cap** (default 10; 10–20 is the common range) and **K** (consecutive not-run rounds before an absent Codex is declared structural, default 2) — **their values live here, in this entry**; Termination holds their behavior. The **patch count** (3) lives in §3: a fix landing in a prose **section** (one heading-bounded block) that has already taken 3 of this loop's insertions (one insertion = one accepted finding's fix landing there) must rewrite the section instead of adding a caveat. Counted within this run — across runs that memory is gone, and the artifact-level signal a fresh run can still see is §1f's `restated` counter.

## Verdict normalization

Subagents routinely go off-spec: wrong token, guessed severity, no verdict line. **The main agent normalizes every verdict itself — never get dragged by the token a subagent wrote.**

**Severity** (every finding carries exactly one):

- **blocker** — broken on ship: wrong results / data corruption / crash, security hole, breaks a dependency contract or schema, core path unusable. Must fix to pass.
- **major** — serious defect: design flaw, missed failure mode or edge, clearly inconsistent with existing code, missing a key check. Fix by default.
- **minor** — local issue, doesn't affect correctness. Fix if cheap.
- **nit** — pure style / format. Usually skip.

**Verdict tokens**: pass = `APPROVE` (the RC tends to write `CLEAR`; same token); reject = `CHANGES-REQUESTED` (`NEEDS WORK` is a synonym).

**Re-grade first.** Subagent severities are guesses: promote the under-marked (especially a subagent that rejects while labeling its reason minor), demote the over-marked. **A demotion holds only if you name which severity definition the original grade got wrong; otherwise the finding stays unresolved.**

**"Unresolved"**: a blocker/major is resolved only when **fixed** or **explicitly demoted / ruled not-applicable** per the sentence above. A verbal "noted, skipping" with the severity unchanged is unresolved.

**Normalization rule**: any unresolved blocker/major ⇒ the round is a **reject**, even if every subagent wrote APPROVE; only minor/nit left ⇒ a **pass**. Throughout this document "pass / reject" means this normalized verdict.

`APPROVE-DEGRADED` and `CAPPED` are **main-agent terminal tokens** — never in a slot (Termination).

## The loop

### 1. Dispatch reviewers

Dispatch all three slots **in parallel, in one message**. Each prompt is self-contained and carries: this proposal + change; the truth source (spec / contract / existing code — for the RC, a **to-be-proven baseline**, never settled fact); what prior rounds fixed, so reviewers hunt **new** ship-blockers (**except the RC**, which gets §1b's de-polluted form); the agreed scope (§1d, when it exists) with the `[out-of-scope]` tagging demand; the severity definitions; and the output contract — **end with the findings list (severity / location / explanation / fix) and, as the final line, exactly one verdict token**.

**The three slots:**

- **Codex** — `subagent_type: codex:codex-rescue`, read-only; the only Codex path the loop may auto-dispatch (`/codex:adversarial-review` is manual and emits no verdict line). Codex returns prose by default — the prompt must explicitly demand the final verdict line.
- **Code Reviewer** — correctness, contracts, edges, security, consistency with existing code. **Mandatory extra deliverable — the guard checklist**: every guard/check point with `file:line`, over the same categories and scope as §1b's enumeration. This checklist is the loop's **weak anchor**. For every checkpoint consuming a **set dimension**, add three columns — `declared-coverage set` │ `actually-effective set` │ `equal?` — because writing the two sets side by side turns "the guard covers less than exists" into a comparison the reviewer cannot skip past (not-equal = a finding, feeding §1b step 0).
- **Reality Checker** — dispatched per **§1b**.

**A CR APPROVE without its deliverable is not a pass**: checklist missing, or missing its three columns → the slot is `not-run(missing guard checklist)`. **One exception — the artifact has no guard points at all** (a pure-prose proposal): an empty checklist that states the scope it enumerated over **counts as produced** — the `not-run` rule catches a CR that skipped its deliverable, not one with nothing to enumerate. (§1b's empty table states its enumerated scope the same way.)

**Resolution ladder — how any named lane or fixer (CR / RC / MCE / ASE) becomes a running subagent.** Four tiers, resolved per lane at dispatch time; **echo the resolved tier** in the status block:

| tier | resolve | notes |
|---|---|---|
| **registered** | the agent's frontmatter `name:` is an installed `subagent_type` → dispatch directly | strongest tier |
| **local** | `~/.agency-agents/<slug>.md` (flat cache) or `find ~/.agency-agents -type f -name '*<slug>*.md'` (nests up to two levels, e.g. `game-development/unity/unity-architect.md`); confirm the frontmatter `name:` matches (flat-cache copy ≡ its division copy — dispatch either); embed the markdown body, minus frontmatter, as a `general-purpose` agent's persona | full source content, no network |
| **fetched** | cache miss → fetch the role's known source path from jsDelivr into `~/.agency-agents/`, validate (frontmatter `---` + `name:`), then as `local`. `curl -fsSL --max-time 10 https://cdn.jsdelivr.net/gh/msitarzewski/agency-agents@main/<path>` — paths: CR `engineering/engineering-code-reviewer.md` · RC `testing/testing-reality-checker.md` · MCE `engineering/engineering-minimal-change-engineer.md` · ASE `security/security-appsec-engineer.md`. **Fixed registry roles only** — an open-ended §1c augment has no derivable path → SKIP | same content as local |
| **embedded** | network down or validation fails → the condensed embedded prompt below | **weaker reviewer: either reviewer slot (CR / RC) at this tier caps the terminal at `APPROVE-DEGRADED (<lane>: embedded fallback)`** (Pass-tier table). A fixer or augment (MCE / ASE) at this tier is echoed but does not cap — its output is re-reviewed next round |

Embedded prompts (tier 4): **CR** — "You are an adversarial code reviewer. Check correctness, contracts, security, consistency with existing code, and edge cases. Produce a guard/check checklist with `file:line` entries and the three set-dimension columns. End with the findings list and, as the final line, exactly one verdict token." **RC** — "You are a failure-enumeration reviewer. List every guard, early-return, error branch, exception catch, assert, validation, exit-code, state transition, and claimed-pass point in a table with `file:line`. For each row, instantiate the applicable failing inputs; record observed behavior vs contract claim and a terminal state. End with the findings list and one final verdict token." **MCE** — "You are a minimal-change engineer. Fix only the specified finding with the smallest possible diff. Add no abstractions, config, dependencies, or features unless the finding's correctness requires it. Touch nothing unrelated." **ASE** — "You are a security reviewer. Check injection, auth bypass, data exposure, and OWASP top-10 issues in the changed code. Report findings with severity and `file:line`."

**Deterministic strong anchors** — optional to run the loop, required for a clean `APPROVE` (Pass-tier table); findings-only. The main agent runs these **before** dispatching; hits become §2 findings, artifacts become §1b's strong anchors. Three forms:

1. **Executable invariant check** — a change-impact rule for a bug category §1b has already written up (§1b's invariant library).
2. **Off-the-shelf static analysis** — shellcheck / clippy / ruff / an existing CI contract check / AST or grep extraction of guard points.
3. **New-dimension fan-out grep** — a real, reproducible grep of the diff's new dimensions across every repo consumer, hunting `declared ⊊ effective` and "same error, different exit codes per entry point".

**Acceptance test for form ③: the grep counts as strong only if it left its command + output AND its output contains every consumer the CR's `actually-effective set` lists.** The grep proves what it *scanned*; only an independent enumeration says whether it scanned *enough*, and the CR checklist is the round's only independent enumeration. Compared during §1b reconciliation, after the CR returns. CR columns missing or empty → nothing to compare → **weak**. The grep missed a consumer the CR listed → **weak**. A strong anchor proves "the scanned set is clean," never "the scan was complete" — pattern completeness is not mechanically provable.

**Echo this status block every round** — a failed subagent returns empty, indistinguishable from "no problems," so an empty slot must never default to pass. Slots carry the **normalized** verdict plus the resolved tier; the Codex slot carries only `APPROVE` / `CHANGES-REQUESTED` / `not-run(reason)`. Alternate canonical strings: `Scope fence: no full requirement context, skip`; `Anchors: none` (on a pure-prose round this is consistent with the gate — the produced-empty CR checklist is the weak anchor, per §1's exception); `Simplicity: lean` / `Simplicity: no code or prose this round, skip`; `Legibility: clean` / `Legibility: no prose this round, skip`.

```
This round: Code Reviewer=APPROVE [registered] │ Reality Checker(§1b)=CHANGES-REQUESTED [local] │ Codex=not-run(empty)
Augment: none
Scope fence: agreed scope anchored │ out-of-scope findings: 0
Anchors: ①strong(invariant cmd#1) ⑤strong(grep cmd#2) ④weak
Simplicity: net -12 flagged │ over-eng: 1 open
Legibility: unfollowable 0 │ undefined 2 │ restated 1
```

The `Anchors:` line names, per in-scope category, the anchor and its strength — it is what evaluator ⑦ reads; without it "every category strong-anchored" is an unverifiable claim. `over-eng: K open` counts §1e findings not yet actioned or review-closed in triage.

### 1b. Failure-enumeration pass (Reality Checker slot)

Semantic reviewers (CR / Codex) verify the happy path plus already-written assertions and systematically miss **failure paths × edges × false-green** — nothing forces them to enumerate, and reading beside green tests primes "it was tested" into "it is settled". The RC slot removes both causes: a forced enumeration structure, fed de-polluted input.

**De-polluted input.** The diff + truth source marked **to-be-proven**; all evaluative framing stripped (no "already APPROVE'd N rounds", "tests pass", "fixed last round"). The one prior-round artifact it gets is a neutral **row ledger** — `row ID + boolean "did this round's fix touch this row or its dependencies"` — with terminal-state values and praise excluded (`verified-safe` is itself a verdict; re-feeding it primes re-confirmation). The ledger answers "which rows need re-verification", never "which rows may be skipped".

**Step 0 — new-dimension lateral fan-out** (before the enumeration; decides which *unchanged* consumers the table must include). Steps 1–2 are vertical and miss the lateral class: *the diff introduced a new dimension and some unchanged consumer was never updated*. Mechanically extract the diff's new dimensions (new config keys like `os.environ.get(...)`, new enum arms / Python typing `Literal` members, new role/capability constants, changed `exception → exit-code` mappings); grep **every consumer of each dimension across the repo** (preflight, validation, attribution, probes, each CLI entry, `except` blocks); pull every consumer the diff didn't touch into the table. The criterion is the set-dimension check (Terms). No whole-repo symbol index needed — grep the dimension strings, list their consumers.

Two honesty rules: **the executor sets the anchor strength** — the RC hand-listing consumers is weak; the main agent's real pre-dispatch grep with command + output is strong (subject to §1's form-③ acceptance test). And **running step 0 never makes category ⑤ "covered"** — scope comes from the code having that kind of guard; a guard with no main-agent grep artifact stays in scope under a weak anchor and caps the tier, else a category and its anchor would be self-produced by one prose step.

**Step 1 — mechanical enumeration (list, don't judge).** Every point of categories ①–④ plus step 0's pulled-in consumers, in a table with `file:line`. **Scope = changed diff lines + directly-impacted unchanged code**: unchanged callers of a changed contract/signature/return semantics, called helpers, unchanged cleanup/finally paths, unchanged tests and CI whose assertions depend on changed behavior — regressions hide in code the diff made newly reachable or newly dead. An empty table states the scope it enumerated over.

**Step 2 — per-row adversarial.** For each row, instantiate **the failing inputs applicable to that row's kind** from the menu `{empty / null / malformed / timeout / partial-write / restart-mid-op / concurrent dual-driver (two writers on one resource) / returns-error-not-value / token-expired / zero-row query / transient error that clears on retry}` — a **menu, not a per-row quota**: demanding all eleven of every row forces fabricated evidence, the very false-green this pass hunts. Record "observed behavior vs contract claim". Any *reports-success-while-the-underlying-thing-broke-or-lied* = **blocker** (fault-tolerant degradation is not lying — the contract baseline tells them apart). Contract **silent** on a failing input ⇒ record "behavior undefined" — never pass by default.

**Step 3 — out-of-table tail.** Untestable acceptance, pseudo-acceptance, whole-design unprovables — appended at the end.

**Harness false-green sub-template.** When the diff touches any green-signal-producing file (by content intent, not directory: `tests/`, `*.sh`, `conftest.py`, test config, `*.bats`, `Dockerfile`, CI yaml, a doctor script, a soak — long-running stability — run), additionally walk: vacuous assert (always-true, or asserting on the mock itself) / exception swallowed then marked success / cassette recorded from a broken run / flush-writing an empty or garbage file / write fails yet marked flushed / a check returning 0 on query failure or zero rows. This is where **the evidence itself lies** — orthogonal to production failure injection, hence its own list.

**Completeness reconciliation** — the table cannot attest itself (prose reviewers satisfice), so set-diff it against an **anchor** (Terms). Bidirectional, on `file:line`, mandatory:

| direction | meaning | terminal state |
|---|---|---|
| anchor ∖ table | omission — an anchor point absent from the table | `unresolved` |
| table ∖ anchor | unverified row — a `file:line` in neither the diff nor the anchor | `unresolved`; two possible causes (a fabricated row, or a legitimately-impacted line the anchor missed) — **don't presume which**; settle only after adding or confirming the anchor |

**1:1 pin (hard rule)**: each anchor point maps to exactly one table row — a merged mega-row doesn't count as enumerating its members, else anchor ∖ table is always empty and the diff is theater. The pin binds only under a fine-grained anchor; under a weak one, a merged row *is* the declared incompleteness. Anchor-absence consequences: the Pass gate (Termination) is the authority; in short — none at all ⇒ no pass, prose-only ⇒ tier capped.

**In-scope categories** = every category the round's code actually has a guard point for — the union of the §1b enumeration, the CR checklist, and all strong anchors, decoupled from which categories have anchors (Terms: category). **The gate reads categories ①–⑤ only; drift and fragility never enter it** (Terms) — they can neither block nor unlock a tier, only force the `not-covered` suffix (evaluator ⑧ owns it; that suffix rule's home is here: **without strong-anchor coverage of drift/fragility, every pass-class or `CAPPED` token carries `narrative-drift/forward-fragility: not-covered`**). **Honesty boundary**: under weak reconciliation, scope-truth itself comes from prose enumeration — if both prose passes miss a whole category it silently drops out; only a strong anchor decouples scope from prose.

**Anti-vacuum (pure proposal).** An empty in-scope set is never read as "every in-scope category has a strong anchor, vacuously". A pure proposal's correctness rests on prose alone — what this loop distrusts — so its terminal is the Pass-tier table's pure-proposal row. §1b still runs (an empty table is naturally empty, not switched off), and a design / spec-vs-existing-system mismatch found and left unresolved still rejects — the loop cannot *anchor* drift, but a drift a reviewer finds is still a finding.

**Executable invariant library.** For each **recurring** bug category, one lightweight executable change-impact rule: pattern hit = flag + demand evidence. Example (capability-lifecycle): a diff adding `requires_capabilities: [X]` is flagged and must show ① X's provider, ② its acquisition path (eager or lazy, and when), ③ where preflight checks X *relative to* that acquisition — any missing ⇒ that row `unresolved`. One rule per real recurring bug lifts that category from weak prose to strong deterministic; a new category's first occurrence still slips (weak reconciliation and the bot backstop it — then write its invariant).

**Bot findings are pure increments**: they enter triage but never enter the coverage proof, never raise a tier, never remove a disclosure suffix. Running §1b — or the bot — is not coverage; only anchors are.

**Every row ends in exactly one of four terminal states** (the gate checks terminal states, not "has a disposition"); rows that became findings merge into §2:

- `verified-safe` — verified against its applicable failing inputs, behavior matches contract, **evidence attached** (which inputs + observed vs claim). A bare label counts as `unresolved`; the main agent spot-audits at least one claimed row per round (pick the highest-consequence one): re-check its attached evidence against the truth source, re-running the cheapest applicable failing input where one exists. Evidence *sufficiency* is provable only under a strong anchor — so even a full table of `verified-safe` caps at degraded under a weak one.
- `fixed` — became a finding, fixed (pointer attached).
- `accepted-degraded` — explicitly demoted or ruled not-applicable, **with an auditable reason keyed to a severity definition** (the row-level form of the demotion rule); no named definition ⇒ still `unresolved`.
- `unresolved` — not verified, not fixed, reason doesn't hold, or a terminal state claimed without evidence.

**Expectation setting.** Without a strong anchor per in-scope category — most small repos — the steady state is `APPROVE-DEGRADED (weak-reconciliation: incomplete)`, by design. To reach clean, add the anchors.

### 1c. Adaptive augmentation (optional, findings-only, no slot)

The main agent may **add** specialists per change domain — along exactly two axes, both meaning "a new distribution" (Terms):

- **Knowledge axis** — named domain knowledge the slots lack: reentrancy, WCAG contrast, query-plan pathology, RTOS timing, tax law…
- **Method axis** — a clearly different review method: structural design, threat modeling, forward fragility. Not another generic semantic reviewer.

**Trigger pre-pass** (before dispatch; leave the matrix in the transcript): scan `changed-file globs × content greps × proposal subject` → matched domain → named gap or lens → resolvable specialist? → dispatch, or skip with the reason recorded. Mapping examples — non-authoritative; **the registry wins**, i.e. what actually resolves at dispatch time (installed subagent types + the local catalog) outranks this list: `*.sol`·`delegatecall` → Blockchain Security Auditor; DB migration → Database Optimizer; ARIA → Accessibility Auditor; CI/IaC (infrastructure-as-code) → DevOps Automator; proposal/design text → Software Architect; security-sensitive change → ASE.

**Three add gates — all must hold, or don't add** (the burden of proof is on the adder; a reviewer whose new distribution you can't name is itself a defect — over-augmentation is the vacuous-assert of review lanes):

1. **You can name the new distribution** ("frontend-related" is not one — Terms: distribution).
2. **The domain is actually touched by this change** — a matrix hit, not a "maybe".
3. **It resolves to exactly one real specialist.** Primary: the Resolution ladder's `local` filename match. Fallback for a sub-concept with no filename (e.g. `reentrancy` → *Blockchain Security Auditor*): `grep -ril "<term>" ~/.agency-agents --include="*.md"` — a **candidate generator only**. Both paths end in the same mandatory confirm: read each candidate's frontmatter `name:`, confirm the role *is* the domain, drop anything without frontmatter (that check is what rejects READMEs and decoys), resolve to **exactly one** (>1 → disambiguate by division directory; 0 confirmed → SKIP). Open-ended augments have no `fetched` tier and no embedded fallback — no registration and no single confirmed catalog agent ⇒ **SKIP**.

**Two ways to skip a matrix hit, graded apart:**

| skipped because… | grade |
|---|---|
| the expert genuinely doesn't exist (not registered, not in the catalog) | not a finding — disclose it: the `Augment:` line carries `expert unavailable` and the terminal token carries `(<domain>: expert unavailable, generic coverage only)` (evaluator ⑨ keys off the `Augment:` literal) |
| the expert was resolvable and you skipped anyway | a **`major` you did not fix** — justify it like any other |

Augment findings feed §2 only — no slot, no verdict, and they never erase the CR checklist anchor (even the correctness-class ASE stays findings-only). **Echo** each specialist with its tier: `Augment: +Blockchain Security Auditor(knowledge:reentrancy)[local]`; else `Augment: none`.

**Method-axis backfill when Codex is structurally absent**: a different model family has no same-family substitute. A method-axis Claude (e.g. Software Architect for the structural view) may backfill to reduce the miss rate, but **never lifts** `APPROVE-DEGRADED (Codex structural: …)` — increment-only, no slot.

### 1d. Scope fence (mandatory when full requirement context exists)

Prevents scope creep laundered as bug-fixing: reviewers propose "robustness", triage fixes by default, and the loop ends having built features nobody asked for.

**Raise the fence, once at start.** If the context contains a complete requirement description the AI and user settled on (explicit goal / acceptance / boundaries — not one vague instruction), extract and restate an **agreed scope** list: what's in, what's out, which contracts the user already approved — a truth source beside code and spec. **The test for "complete": you can write that list without inventing a single boundary**; if writing it forces a guess, skip the fence (echo the skip string) rather than fence on a guess. Never block, never invent scope.

**The scope binary** (triage runs it once per blocker/major):

- **In-scope**: fixes a failure path that would cause wrong results / crash / corruption / contract mismatch under the agreed behavior — without adding user-visible behavior, interfaces, config, or dependencies, and without changing an approved contract → fixed by default.
- **Out-of-scope (big change)**: needs to add features / config / a CLI entry / a dependency not in the requirement, change an approved contract, or materially expand implementation scope (a new cross-module subsystem, an abstraction layer, retry / persistence / concurrency / cache machinery nobody asked for). **Tiebreak for "materially"**: if the fix introduces something the user would now have to know about or operate — a new flag, file, daemon, dependency, or changed contract — it is out; an internal guard confined to existing files and knobs is not.

**Handling: don't auto-fix, ask immediately, never launder.** On a hit, pause and report: the finding, why it crosses, the minimal in-scope fix vs the crossing fix, and a request for authorization. Before authorization: no fix dispatch, and no silent demotion to `accepted-degraded` to keep the round clean — that is one more false-green. Authorized → scope updates, finding becomes in-scope. Declined → `accepted-degraded`, reason "out of scope, user declined".

**Prompt landing, every round**: reviewer prompts carry the agreed scope + the `[out-of-scope]` tag demand; the §3 fix spec pins "only touch X, add no new Y". Hard-pause semantics — `OUT-OF-SCOPE-PENDING (N left)`, no token, overrides the cap, halts for the user — live in Termination (sole authority).

### 1e. Simplicity counter-pressure (ponytail lens — standing, findings-only, no slot)

The three slots are all **additive** and the fixer is only locally minimal — nothing in the loop perceives bloat, so each round trends the artifact up: severity drains while lines climb, and Termination fires on a diff far larger than necessary. This lens is the subtractive counter-pressure; advisory, because a prose pass can't *prove* a line dead.

**Run** on every round whose diff contains **code or prose** — the ratchet argument holds verbatim with "clauses" for "lines". On prose, only three tags apply: `delete:` (a rule nobody will follow; a section restating another) · `yagni:` (a branch that can never fire, a knob nobody sets) · `shrink:` (same rule, fewer words). Neither code nor prose → the skip string. Dispatch in parallel with §1 (a `general-purpose` subagent carrying the rubric, or invoke `/ponytail-review`).

**Rubric** (embedded; self-contained — the ladder below is the whole of it): one line per finding — `file:line: <tag> <what>. <replacement>.` — tags `delete:` · `stdlib:` (hand-rolled what the stdlib ships) · `native:` (the platform already does it) · `yagni:` · `shrink:`; end with `net: -N lines possible` or `Lean already. Ship.` The ladder: stdlib > native > installed-dep > one line > minimum code. Never flag the never-simplify set: validation at trust boundaries · error handling that prevents data loss · security · accessibility · anything explicitly requested · a hardware calibration knob · the one runnable check.

**Report-only.** Findings ride §2 as `minor` advisory, never auto-dispatched to the fixer — a prose pass can't prove a line dead ("no caller" by grep ≠ unreachable), and auto-acting on the label is the mislabel → delete → re-add hazard; with no mid-loop mutation from §1e, the add↔delete oscillation can't start. Promotable to `major` only when the bloat itself breaks correctness or a contract; never `blocker`. `net: -N` counts what §1e's own findings would remove — not the diff's net delta. `Simplicity: lean` is advisory — the lens has no completeness anchor.

### 1f. Legibility counter-pressure (cold-read lens — standing, findings-only, no slot)

**The second ratchet.** §1e counters the code ratchet; this one fires when the artifact is **prose a human has to read** — a spec, a proposal, an ADR (architecture decision record), an OpenSpec change, a `SKILL.md`, a README, a design doc. Three things happen every round, and no other lane can see them, **because every other lane is a reviewer and none is a reader**:

- a fix lands **where the finding was found**, not where a reader needs it;
- a term the loop coined mid-run is **never defined**;
- a rule gets restated somewhere else in **slightly different words** — now no copy is authoritative, so nobody dares change any of them.

The end state is a **patch pile**: a document only the loop that produced it can read. The loop's exit is "no reviewer can find a hole"; the reader's is "I can act on this correctly". Those diverge, and every round widens the gap.

**Run** on any round whose diff touches a prose artifact (the list above — named, because a lane with a judgment-call trigger is a lane that gets skipped). Otherwise the skip string.

**The cold read.** Dispatch a `general-purpose` subagent and **constrain what it may read, not just what you tell it** — a subagent has tools and will otherwise read git history and the neighbours, becoming a warm reader with a fresh transcript. Pin verbatim:

> *Read exactly one file: `<artifact>`. Do not read git history, do not read other files, do not search the web. Answer only from that text.*

Ask these five, and **let it pick its own targets in 2 and 3** — if you pick them, you are the exam-setter, the graded party, and the most primed actor in the loop:

1. What is this for, and when should I use it — and when should I *not*?
2. **Pick the most consequential scenario this document describes**, and walk me through what happens.
3. **Pick the rule you would most likely need to change**; where do you edit, and what else would that break?
4. **Every term used without definition** — quote where each first appears.
5. **Every rule you could not follow** — quote it; say exactly what is ambiguous.

**Its return goes into the transcript verbatim** — you are the actor with an interest in a flattering read, and paraphrase is the laundering §1b's de-pollution exists to prevent. A `Legibility:` line with no pasted return is `not run`.

**Three counters over the artifact** (you, no dispatch):

| counter | counts | why it exists |
|---|---|---|
| **undefined** | terms the reader listed in Q4 | a term only the loop understands must be reverse-engineered by the next reader |
| **unfollowable** | rules the reader listed in Q5 | **a rule no reader can satisfy is decoration — worse than an absent rule, because it manufactures the appearance of a check that isn't there** (this cell is the why's only home; ⑪ and triage point here) |
| **restated** | rules stated in more than one place in words that don't match (grep the artifact for its own load-bearing nouns) | the patch pile's signature: N near-copies means no copy is authoritative, and a stale copy an evaluator reads silently reverses a decision. **Fix: name one statement authoritative, point the others at it** |

**On the loop's first prose round, run all three over the whole artifact, not just the diff** — a diff-scoped pass can only slow the next pile, never clean the one you came for.

The counts are not scores (two honest runs won't agree); the finding is the reader's **quote** — the number only makes it visible in the echo.

**Severity**: `minor` advisory, riding §2, never blocking — **except an unfollowable rule, which is a `major`, fixed by default** (the counter table's why). Evaluator ⑪ is where it bites.

**Honesty boundary.** §1f is weak-reconciliation class: a fresh reader and you are both prose passes and can co-miss. `Legibility: clean` proves one reader could follow this text once. **§1f is subject to itself** — a legibility rule that exempts itself is the first rule a reader stops believing.

### 2. Triage

Merge findings from all sources — three slots, anchors, augments, §1e, §1f, bot — into **one deduped list** (never two fixes for one spot); re-grade per Verdict normalization. Then:

1. **Scope binary first** (fence up): out-of-scope blocker/major → pause for authorization; never auto-fix, never launder.
2. In-scope blocker/major → fixed by default. A major you won't fix → **review-demoted** with its named definition, never skipped verbally.
3. Minor by cost-benefit; nit usually skipped.
4. §1e / §1f findings ride as `minor` advisory, report-only — **except an unfollowable rule (§1f): `major`, fixed by default**.
5. Tell the user what was fixed and what was skipped.

### 3. Dispatch fixes

**The dispatch table splits by artifact, because "minimal" means opposite things in code and prose.** For code, minimal = the smallest *textual diff* — that discipline prevents scope creep. For prose, the smallest textual diff is an inline caveat at the finding site — **which is exactly the §1f patch-pile generator**. A prose fix minimizes the *semantic delta* instead: hold what every rule requires fixed (unless the finding is about the requirement itself) and let the textual diff be as large as the rewrite needs.

| fix target | dispatch | minimality metric |
|---|---|---|
| code — local bug, single module, mechanical per spec | **MCE** (Resolution ladder) | smallest textual diff |
| code — cross-module / architecture or data-flow rethink / schema or API migration / needs a test strategy | `subagent_type: codex:codex-rescue` | smallest coherent change |
| prose — mechanical (wording, format, filling in an already-decided design) | main agent edits directly | — |
| **prose — semantic** (a rule wrong / ambiguous / unfollowable / restated) | **never MCE** — its persona ("smallest possible diff, touch nothing unrelated") is the patch generator and will fight the spec. Main agent, or a `general-purpose` subagent carrying the rewrite contract below | **smallest semantic delta, textual diff unbounded** |

The rewrite contract (pinned into every prose-semantic fix spec): rewrite the containing **section from its purpose** — never add a caveat to a section that has taken 3 of this loop's insertions (Terms: patch count); every rule keeps exactly what it required before, except the rule the finding names; one authoritative statement per rule, others point at it; each rule carries, in one clause, **the failure it prevents** (a rule with no why is the one the next reader deletes as noise — and then the loop rediscovers the hole); land each rule **where a reader needs it**, not where the finding was found. **A re-expression that preserves what the rules require is in-scope by construction — it does not trip §1d; changing what a rule requires is a scope change and does.**

**Every fix spec** (any lane): file, fix, acceptance per problem; the §1d scope pin at the top. **The ponytail ladder is pinned** for each triage-approved fix: the laziest fix that holds (stdlib > native > installed-dep > one line > minimum code), no new abstraction / config / dependency unless the finding's correctness requires it; a deliberate simplification carries a `ponytail:` comment naming its ceiling and upgrade path — **non-contractual**: §1b still judges that line against the truth source next round and still instantiates the failing inputs. Never simplify the never-simplify set (§1e).

**Fixer boundaries**: uncontested items first; pause and report only when a discovery would make the spec wrong, introduce a regression, or require expanding scope; record adjacent small issues without self-expanding. A finding **unfixable without crossing scope** → report back only (§1d).

### 4. Re-review

Back to §1, three slots in parallel — Codex may recover mid-run. Codex retry, stated once: a **transient** not-run is re-dispatched every round, including when both Claude experts already pass (Termination's transient rule then continues the loop rather than degrading early — a missing verdict is not a pass). Only a **structural** absence, or an already-returned verdict, never buys an extra round.

## Termination

**Classifying a Codex non-verdict** (anything unparseable = "not-run"):

- **Transient** — empty return, or ran without a verdict line → retry next round with a stricter prompt; never stop early on it, never degrade because of it.
- **Structural** — not installed, not logged in, quota; won't self-heal this session → retrying is pointless.
- **Can't tell** → treat as transient (a misjudgment costs rounds, never a false pass) — bounded by K.

**Mechanical escalation**: `not-run` for **K consecutive rounds** (Terms; an explicit not-installed / not-logged-in / quota signal is structural on round one) → **force structural**. Escalation converts an infinite retry into an honest degraded termination, never a false pass. Every structural reason is written **`Codex structural: <reason>`** — the literal `structural` is what evaluator ④ matches.

**The out-of-scope hard pause outranks every termination judgment and the cap** (sole authority here). A round holding an unadjudicated out-of-scope blocker/major ends `OUT-OF-SCOPE-PENDING (N left)` and **emits no pass or `CAPPED` token** — even with other unresolved findings, even at the cap (they suspend and re-judge after authorization). The ending line is non-terminal, so no disclosure suffix (it re-attaches to the eventual terminal). **Halt-for-user**: `/goal` stops auto-continuing and hands the request over. **If the user never replies, the loop stays halted — by design**: no timeout converts silence into consent. No fence up ⇒ never triggers.

**Pass gate** — every pass-class termination (`APPROVE` / `CLEAR` / `APPROVE-DEGRADED`) requires all three (this list is the authority on anchor-absence):

1. every §1b row has a terminal state;
2. the bidirectional reconciliation passed; **no anchor at all = no pass**; a prose-only anchor passes here but caps the tier (table below);
3. no unresolved blocker/major after normalization.

"All three slots wrote APPROVE" is **not** a pass — that would make the exit condition the very false-green the loop hunts. A legitimately demoted finding (`accepted-degraded`, reason named) doesn't block a pass; it lowers the tier.

**Pass tier — this table is the single authority on tiers and terminal tokens.** §1, §1b, the `/goal` TIER block and evaluator ⑦ carry named mirrors; where wording drifts, this table wins (the `/goal` block must stay a self-contained mirror — editing this table means re-syncing it). Take the strictest row:

| condition | tier |
|---|---|
| all rows ∈ {verified-safe, fixed} ∧ every in-scope category strong-anchored ∧ in-scope set non-empty ∧ both reviewer slots' tiers ∈ {registered, local, fetched} ∧ Codex gave a verdict | clean `APPROVE` |
| any `accepted-degraded` row ∨ any in-scope category weak-only ∨ either reviewer slot at `embedded` tier (`<lane>: embedded fallback`) ∨ Codex structural ∨ in-scope set empty (a pure proposal — or a diff with no guard points; same treatment), written `APPROVE-DEGRADED (pure-proposal: prose-only)` | at most `APPROVE-DEGRADED`, all degrade reasons in one parenthesis, the disclosure suffix appended in brackets — full form: `APPROVE-DEGRADED (weak-reconciliation: incomplete; Codex structural: not-logged-in) [narrative-drift/forward-fragility: not-covered]` |
| any `unresolved` row ∨ reconciliation failed | reject / `CAPPED` (out-of-scope-pending excepted — held per the hard pause, never `CAPPED`) |

**Judgment, per round:**

- **Clean termination**: all three slots ran (Codex verdict included), everything passes after normalization, the gate holds, the clean row applies → `APPROVE` / `CLEAR`. At least two Claude experts returned verdicts; a missing non-Codex expert is incomplete — retry or fall down the Resolution ladder, never terminate on one expert.
- **Codex transient**: both experts pass, gate holds, Codex transient → don't terminate, don't degrade; retry until verdict, structural, or cap.
- **Degraded termination**: both experts pass, the gate holds, and an unremovable degrade reason from the table's second row applies — (a) Codex structural, (b) a weak-only category, (c) an `accepted-degraded` row, (d) an empty in-scope set (pure proposal), (e) a lane at embedded tier → **stop immediately** (another round adds no information), `APPROVE-DEGRADED` with all reasons parenthesized.
- **Round cap** — a backstop against pathological non-convergence, not a quality bar (Terms: cap). At the cap, with no out-of-scope pending (which outranks it): both experts pass + gate holds + Codex merely transient → `APPROVE-DEGRADED (Codex transient, cap-reached)`; anything unresolved or a slot rejected/empty → `CAPPED (cap-reached, N items left)`, listing the open items — terminal, not a pass. Under `/goal` with no cap set, `CAPPED` doesn't exist: the loop ends only on a pass token or user interrupt.

## Pairing with /goal

`/goal` re-reads the transcript at each turn's end with the evaluator and restarts the turn while the completion condition is unmet. The status block must be echoed **every round**; the terminal token appears only on the terminating round.

```
/goal Run an adversarial review loop on this change per review-loop.

COMPLETE only when all of these hold in the latest round:
  1. Both Claude experts (Code Reviewer, Reality Checker) returned a verdict.
  2. Codex either returned a parseable verdict, or was determined structural not-run
     (including via the K-consecutive-round escalation). A transient not-run does NOT
     satisfy this — keep retrying.
  3. The pass gate holds: every §1b row has a terminal state; the bidirectional
     reconciliation passed (no anchor point missing from the table, no table row
     without an anchor); no blocker/major after normalization. With no anchor at all,
     there is no pass.
  4. The final token is APPROVE, CLEAR, or APPROVE-DEGRADED.

TIER (mirror of the authoritative Pass-tier table): a clean APPROVE additionally needs
every §1b row verified-safe or fixed, a strong anchor for every in-scope category, no
lane at the embedded tier, AND a Codex verdict. Any weak-only category, accepted-degraded
row, embedded lane, or pure proposal (empty §1b table) caps the token at APPROVE-DEGRADED.

ECHO every round: the three-slot status line with resolved tiers; the Augment line; the
scope-fence line (when full requirement context exists); the Anchors line; the Simplicity
line; the Legibility line on prose-touching rounds. Simplicity and Legibility carry no
verdict. An `unfollowable` rule from the cold read is a major and must be fixed or demoted.

SUFFIXES on the terminating token: without strong-anchor coverage of narrative drift /
forward fragility, the token carries `narrative-drift/forward-fragility: not-covered`;
if any round's Augment line said `expert unavailable`, the token carries
`(<domain>: expert unavailable, generic coverage only)`.

HALT FOR THE USER — do not auto-continue — when a round ends with
OUT-OF-SCOPE-PENDING (N left): a fix adding features/config/subsystems nobody asked for
needs authorization first. That round is neither complete nor CAPPED and emits no token,
even if other items remain or the cap is reached.

ROUND CAP 10 (raise it freely; to loop until pass, delete this line). At the cap with no
pass: terminate and record CAPPED (cap-reached, M items left).
```

**The evaluator judges literally** — each predicate independently checkable; any hit ⇒ continue. **Short-circuit first**: a round ending `OUT-OF-SCOPE-PENDING (N left)` is halt-for-user — neither complete nor `CAPPED`, predicates and cap inapplicable (⑩ only catches a token wrongly written anyway). **Suffix kinds, once for all predicates**: match tokens by **subject, ignoring parenthesized suffixes**; degrade suffixes (`weak-reconciliation: incomplete` / `accepted-degraded` / `Codex structural: …` / `<lane>: embedded fallback`) belong to ④ and ⑦; the disclosure suffix (`narrative-drift/forward-fragility: not-covered`) belongs to ⑧ and is never a degrade reason. Continue if any holds:

- **①** the latest round is missing the three-slot status line;
- **②** any Claude expert slot is empty / not-run;
- **③** any slot is `CHANGES-REQUESTED`;
- **④** the Codex slot is `not-run(...)` and the final token is not `APPROVE-DEGRADED` with a reason containing the literal `structural` or `transient, cap-reached`;
- **⑤** the final token's subject isn't in `APPROVE` / `CLEAR` / `APPROVE-DEGRADED`;
- **⑥** the §1b table is missing, has an `unresolved` row or a row with no terminal state, or failed the reconciliation — including **no anchor at all** (a weak CR-checklist anchor is an anchor; it caps the tier via ⑦, not here);
- **⑦** the final token's subject is `APPROVE` / `CLEAR` while the `Anchors:` line shows any in-scope category weak-only, or a row is `accepted-degraded`, or any slot's tier marker is `[embedded]`, or the §1b table is empty (pure proposal — only the table's `APPROVE-DEGRADED (pure-proposal: prose-only)` is legal there);
- **⑧** drift/fragility has no strong-anchor coverage and a pass-class or terminal token lacks the `narrative-drift/forward-fragility: not-covered` suffix;
- **⑨** the `Augment:` line is missing; or the terminating token lacks the `(<domain>: expert unavailable, generic coverage only)` suffix while a round's Augment line listed a domain as `expert unavailable`;
- **⑩** the `Scope fence:` line is missing (the skip string satisfies it); or the round has an unadjudicated out-of-scope blocker/major yet a pass / `CAPPED` token was written;
- **⑪** the `Legibility:` line is missing on a prose-touching round (skip string and `clean` both satisfy it); or it reports `unfollowable ≥ 1` and the terminating round contains no corresponding fix or review-demotion (`undefined` and `restated` never block — only `unfollowable` bites, per §1f's counter table).

**Cap takes precedence** (only when set; out-of-scope-pending outranks it and never becomes `CAPPED`): predicates keep the loop running only below the cap. At the cap, stop unconditionally — but "stop" ≠ "pass": record a pass token only if the gate is still verifiably satisfied; a missing table, a row with no terminal state, or an unverifiable reconciliation always records `CAPPED`. The disclosure suffix is not waived at the cap.

> **Honesty boundary**: prose with no runtime enforcement — it lowers, never eliminates, a false green taken as a pass. Drift and fragility carry no coverage guarantee (§1b's coverage rule and suffix). The real backstop is the evaluator's literal checks plus §1b's reconciliation — and none of that waives a step: the status block, normalization, the gate, and the judgment still run item by item.
