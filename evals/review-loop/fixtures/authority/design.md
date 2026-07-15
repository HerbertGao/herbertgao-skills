# Design — Hangar Decoder integration

**This change is NOT standalone.** It implements against these named external authorities
(the cold read is not given their bodies — they are pinned by path + version + digest):

| authority | path | version | sha256 |
|---|---|---|---|
| Hangar response contract | contracts/hangar.openapi.yaml | v2.3.0 | 9f2c1e77a41b0c33de55aa7719b2f0c8d4e6a1b299f4c0113ae5db77c2016f84 |
| Control-plane contract | contracts/control.openapi.yaml | v1.0.4 | 3be8d0aa77d61c92f4470b1e5c8a99d21f6e0b7734ac115de92887ab04c3ee19 |

The Decoder MUST produce output that conforms to the Hangar response contract above, and MUST
call the Control-plane per its contract above. The service runs under **ASGI**; releases go out
as a **canary** to a single **principal** before fleet rollout.

## Cancellation
A cancelled job stops. The operator issues cancel and the job ends.
<!-- (no statement of whether in-flight partial writes are rolled back, whether stop is immediate
     or after the current step, or who owns the terminal state — an implementer cannot build this) -->

## Records
Every decode emits a **WorkRecord** to the audit sink. Downstream consumers read WorkRecords to
reconcile state.
<!-- WorkRecord is used as a load-bearing project term but is defined nowhere in the read-set -->
