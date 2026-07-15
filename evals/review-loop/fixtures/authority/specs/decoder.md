# Capability spec — Decoder

The Decoder consumes a byte stream and emits a WorkRecord (see design.md) per frame.

- Input framing and the response envelope are defined by the Hangar response contract
  (design.md, pinned by version + sha256). Conform to it exactly.
- On a malformed frame, the Decoder rejects and continues.
  <!-- "rejects" is not defined: drop the frame? abort the stream? emit an error WorkRecord?
       the artifact's own rule is incomplete — an implementer cannot pick — genuine local gap -->

This spec is one file of a co-authored bundle (design.md + this file). The read-set is exactly
those two files; the OpenAPI contracts are external and referenced by digest only.
