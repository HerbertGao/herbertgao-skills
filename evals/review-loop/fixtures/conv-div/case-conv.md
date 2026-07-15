# Fixture case CONV — a prose design doc (NO native requirement/decision IDs) under review-loop

The artifact under review is a plain-prose design document (no numbered requirements). §3 forces
whole-section rewrites, so each round's fix re-writes whole sections and the next round's cold read
quotes text the previous round Landed. Below are the triage lists (blocker/major only) and the Landed
sections for two consecutive rounds. Apply the Termination predicate.

## Round 5

Landed: (round 5 rewrote §Rate-Limiting, §Token-Refresh, §Manifest, §Error-Envelope, §Pagination, §Retry)

Round-5 triage — surviving blocker/major (all fix-induced: each quotes text round 4 Landed):
- [blocker] The rewritten §Rate-Limiting says "burst is allowed within the window" but never says the
  window length or the burst ceiling — two implementers will pick different numbers.
- [blocker] §Token-Refresh now says "refresh races are resolved last-writer-wins" but doesn't say how a
  client learns its refresh lost, so it will use a revoked token.
- [major] §Manifest's new line "the manifest declares a schema version" gives no version format and no
  behavior when the version is unknown.
- [major] §Error-Envelope was rewritten to "every error carries a code and a message" but the code set
  is not enumerated, so clients cannot switch on it.
- [major] §Pagination now mandates "an opaque cursor" without saying how the cursor encodes position,
  so a server restart invalidates every outstanding cursor silently.
- [major] §Retry's new "exponential backoff" text omits the base delay and the max attempts.

Round-5 surviving blocker/major count: 6

## Round 6

Landed: (round 6 rewrote §Auth, §Manifest-Validity, §Publish — fixing the round-5 findings above)

Round-6 triage — surviving blocker/major (all fix-induced: each quotes text round 5 Landed):
- [blocker] The rewritten §Auth says "reject on invalid signature" but never gives the HTTP status for
  an auth failure, so a client cannot tell auth-fail from a 500.
- [major] §Manifest-Validity's new rule "the manifest lists every capability" does not say whether an
  empty manifest is valid or an error.
- [major] §Publish now says "publish is idempotent" without defining the idempotency key, so a retried
  publish with a changed body has undefined behavior.

Round-6 surviving blocker/major count: 3
