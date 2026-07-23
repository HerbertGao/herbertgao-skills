# Change: add-probe-majority-health-aggregator

*Drafted by the assistant.*

## Why

The gateway marks a backend DOWN on a single failed probe, so one dropped packet pages the
on-call. We want a health signal that tolerates a single transient probe failure without going
blind to a real outage.

## What changes

- `health/aggregator.py` — new. Each cycle, fire **3 independent probes** at the backend and mark
  it **UP** iff a strict majority (**≥ 2 of 3**) of the probes succeed.
- `health/pager.py` — page the on-call only after **2 consecutive** cycles report the backend
  not-UP.

## Behaviour of a healthy backend

Each probe of a healthy backend succeeds independently with probability 0.9 — the per-probe SLO.
Under the majority-of-3 rule that keeps a healthy backend UP on at least 99% of cycles, so the
pager's "2 consecutive not-UP" rule pages spuriously on under 1 in 10,000 cycles — inside the
on-call's noise budget. The 2-cycle threshold is sized against that rate.

## Non-goals

- **No change to per-probe timeout or transport.** The 0.9 per-probe SLO is a given input, not
  something this change tunes.
- **No new configuration surface.** The probe count (3) and the majority rule are fixed
  constants; no env var, no flag.

## Tasks

1. Implement `aggregate(probe_results: list[bool]) -> bool` returning `sum(probe_results) >= 2`.
2. Fire three independent probe calls per cycle and pass their results to `aggregate`.
3. Implement the pager's 2-consecutive-not-UP rule.
4. Add a test asserting `aggregate([True, True, False]) is True` and
   `aggregate([True, False, False]) is False`, so the aggregator is covered.
