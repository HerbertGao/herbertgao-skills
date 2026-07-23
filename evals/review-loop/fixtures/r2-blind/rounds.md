# Fixture R2-BLIND — a prose proposal under review-loop, rounds 1 and 2

The artifact under review is a prose OpenSpec change proposal (no native requirement IDs).
Round 1 is the loop's **first** round. Below are both rounds' triage lists and `Landed:` records.

## Round 1 (the loop's first round)

Regression: n/a (no prior fix)

Round-1 triage — surviving blocker/major:
- [major] §Loading never says what happens when two overlay files declare the same key.
- [major] §Loading's "the loader reads the overlay" does not say at what point in start-up it reads,
  so a consumer that reads config at import time may see the un-overlaid value.

Landed: §Loading -"the loader reads the overlay"
        +"`load_overlay(path, *, base)` returns a merged mapping; on a duplicate key the
        later file wins. The assembly site calls it exactly once, before the router is
        constructed, and no consumer may read config at import time."

## Round 2

Round-2 triage — surviving blocker/major (3 total, no minors survived):

- [blocker] The new `load_overlay(path, *, base)` signature takes a single `path`, but §Sources
  (unchanged, written before round 1) requires **an ordered list** of overlay files. With one path
  per call and "later file wins" resolved *inside* the function, two calls cannot express precedence
  — the very duplicate-key rule round 1 added is unimplementable through the signature round 1 added.

- [blocker] "The assembly site calls it exactly once, before the router is constructed" contradicts
  §Reload (unchanged), which requires the overlay to be re-read on SIGHUP — a once-only call at
  assembly cannot re-read.

- [major] "no consumer may read config at import time" is unenforceable as written — nothing in the
  proposal says how an implementer detects an import-time read, and two of the proposal's own tasks
  create modules that do exactly that.

Landed: (round 2's fixes have not been dispatched yet — you are deciding what round 2 does)
