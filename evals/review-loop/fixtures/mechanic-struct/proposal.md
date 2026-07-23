# Change: add-retry-with-circuit-breaker

*Drafted by the assistant.*

## Why

A transient backend blip currently fails the request outright. We want to retry transient
failures, but not hammer a backend that is genuinely down — so a circuit breaker trips after
sustained failure.

## What changes

- `client/retry.py` — new. On a failed call, retry with exponential backoff **1s, 2s, 4s**, up to
  **`max_retries = 3`**.
- `client/breaker.py` — new. Count *consecutive* failures; when the count reaches
  **`failure_threshold = 3`**, trip the breaker and stop calling the backend until it half-opens.

## The guarantee

The two limits are chosen to agree: a request to a backend suffering a *transient* blip is
**retried its full 3 times before the breaker trips**, so a short outage is ridden out by the
retries and never cut short by an over-eager breaker. The breaker is there only for *sustained*
failure — i.e. it should trip only once the retries are exhausted and the backend is still down.

## Non-goals

- **No change to the backoff schedule.** The 1/2/4s delays are fixed.
- **No new configuration surface.** `max_retries` and `failure_threshold` are the two constants
  above; no env var, no flag.

## Tasks

1. Implement the backoff retry loop in `client/retry.py` (`max_retries = 3`).
2. Implement the consecutive-failure counter and trip in `client/breaker.py`
   (`failure_threshold = 3`).
3. Wire the breaker to observe every call's outcome: a success resets the counter, a failure
   increments it.
4. Add a test asserting the breaker trips after 3 consecutive failed calls.
