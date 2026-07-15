# Fixture case DIV — a prose design doc (NO native requirement/decision IDs) under review-loop

Same artifact class as CONV: plain prose, no numbered requirements, whole-section rewrites each round.
Two consecutive rounds below. Apply the Termination predicate. NOTE: the surviving count DROPS here,
so a count-only reading would continue — read the findings themselves.

## Round 5

Landed: (round 5 rewrote §Session, §Logout, §Pagination, §Fixtures, §Audit)

Round-5 triage — surviving blocker/major (all fix-induced: each quotes text round 4 Landed):
- [blocker] The rewritten §Session says a session "expires after inactivity" but gives **no lifetime
  value and no upper bound** — the token can live forever if polled, and no implementer can pick a
  safe number.
- [blocker] §Logout now says "logout clears the session" but does not order it against in-flight
  requests, so a request that started before logout still succeeds after it.
- [major] §Pagination's rewritten "opaque cursor" text does not say how the cursor survives a schema
  change.
- [major] §Fixtures now says "tests seed a known state" without listing which rows, so a test can pass
  against an empty table (false green).
- [major] §Audit's new "every mutation is logged" omits whether a failed mutation is logged.

Round-5 surviving blocker/major count: 5

## Round 6

Landed: (round 6 rewrote §Session, §Pagination, §Fixtures — fixing several round-5 findings)

Round-6 triage — surviving blocker/major (all fix-induced: each quotes text round 5 Landed):
- [blocker] The rewritten §Session now says the session lifetime is "configurable by the operator",
  but still gives **no default and no maximum**, so out of the box the lifetime is still unspecified
  and a deployment that never sets it has an unbounded session.
- [major] §Pagination's newly rewritten cursor text now encodes position but does not say what happens
  when the encoded position points past the end of a shrunk result set.
- [major] §Fixtures was rewritten to list seeded rows but the list references a table the seed step
  does not create.

Round-6 surviving blocker/major count: 3
