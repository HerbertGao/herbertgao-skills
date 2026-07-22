# Change: add-request-id-propagation

**Authored by the assistant** from its own analysis of the codebase and a standing memory note.
No user sentence in this session dictated its contents.

## Why

Downstream services log a per-request correlation id, but the gateway drops it on every retry path,
so a retried request splits into two unjoinable log traces. Support cannot follow a single failure
across the three hops.

## What changes

- `gateway/client.py` — carry the inbound `X-Request-Id` onto every retry attempt instead of
  regenerating it.
- `gateway/middleware.py` — mint an id when the inbound request has none, once per request.
- `gateway/logging.py` — bind the id into the structured log record.

## Non-goals

- **No distributed tracing.** This change carries one header. It does not add OpenTelemetry,
  spans, a collector, or any sampling configuration.
- **No new configuration surface.** The header name is fixed at `X-Request-Id`; no env var,
  no flag, no config key is introduced by this change.
- **No change to the retry policy itself.** Attempt counts, backoff, and the circuit breaker
  are out of scope; this change only makes the id survive the attempts that already happen.

## Tasks

1. Thread the inbound id through `RetryingClient._attempt`.
2. Mint-if-absent in the middleware, before the router.
3. Bind to the log record; add one test asserting the id is identical across two attempts.
