# Phase 6 Adversarial Review

Repository: llzk-lean
Reviewed: 2026-06-10

## Scope

This review covers the Phase 6 bootstrap and first implementation target. It
verifies that Phase 6 starts from Phase 5's clean-pin corpus and exact
expected-divergence polarity, then reclassifies only DCE-only divergences
without claiming full Strategy A acceptance.

## Bootstrap Checks

- Confirm Phase 5 is marked completed and all Phase 5 findings are closed.
- Confirm `docs/harness/CURRENT.md` names Phase 6 as active.
- Confirm `docs/harness/SOURCES.md` records the Phase 6 phase file and Phase 5
  exact-polarity guard evidence.
- Confirm freshness, source-truth, pin, doctor, skill, build, and clean-pin
  canonical differential baseline gates pass.

## Implementation Checks

- Confirm the consumed VeIR pin is
  `a0bb2fc8e6d38ab068247dfc6506ba63f5feb953`.
- Confirm canonical differential mode runs `felt-combine,dce`.
- Confirm the clean dependency checkout under `.lake/packages/VeIR` is exactly
  `a0bb2fc8e6d38ab068247dfc6506ba63f5feb953` and its diff script invokes
  `-p=felt-combine,dce`.
- Confirm only `registered_add_fold.llzk`, `constant_fold_sub.llzk`, and
  `constant_fold_mul.llzk` moved from expected divergence to `felt/`.
- Confirm those three moved inputs pass independently in canonical mode.
- Confirm remaining expected-divergence files keep exact `EXPECTED-*` polarity.
- Confirm the Phase 6 llzk-lean change did not edit Lean implementation files
  while changing corpus classification, pins, harness scripts, docs, and
  evidence.

## Result

F6-LLZK-01 is resolved. Phase 6 implementation evidence under
`reviews/PHASE-06/evidence/` records the clean-pin corpus at
`21 pass (incl. expected-diverge), 0 fail`. A fresh post-implementation
adversarial pass found no new findings.
