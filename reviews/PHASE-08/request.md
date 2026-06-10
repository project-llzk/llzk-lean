# Phase 8 Review Request

Repository: llzk-lean
Requested: 2026-06-10

Review the Phase 8 Strategy A field-precondition implementation closeout.

Scope:
- Phase 7 is completed and superseded by Phase 8.
- Phase 8 is active in harness docs and gates.
- The implementation target is limited to bare/unknown-field fold-precondition
  parity for `unspecified_add_fold.llzk`.
- The clean-pin canonical baseline remains `21 pass (incl. expected-diverge),
  0 fail` with 10 PASS cases, 10 `EXPECTED-DIVERGE` canonical cases, and
  1 `EXPECTED-LLZK-FAIL`.
- The consumed VeIR pin is
  `d899d95004d4bd988c8456d686c33b11a7a5eb4a`.
- Exact `EXPECTED-*` polarity remains required for all expected-divergence
  inputs.

Out of scope:
- Full Strategy A acceptance.
- Reclassification of nonconstant algebraic rewrite divergences before a
  reviewed implementation change lands.
- New Strategy E certificate proof work or runtime MLIR matching.
