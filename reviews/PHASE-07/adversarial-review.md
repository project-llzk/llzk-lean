# Phase 7 Adversarial Review

Repository: llzk-lean
Reviewed: 2026-06-10

## Scope

This review closes Phase 6 and covers the Phase 7 registered-field
modular-reduction execution. It verifies that Phase 6's DCE-only burn-down
remains supported by clean-pin evidence, then checks that the two Phase 7 target
cases are reclassified only after the VeIR implementation and clean-pin
differential evidence agree with LLZK.

## Closeout Checks

- Confirm Phase 6 findings are resolved and Phase 6 is marked completed.
- Confirm the Phase 6 clean-pin canonical corpus still records
  `21 pass (incl. expected-diverge), 0 fail`.
- Confirm the consumed VeIR pin is
  `8e9c08925fce1caf8d6eb1d69239aae263629802`.
- Confirm expected-divergence polarity remains exact and marker-driven.

## Implementation Checks

- Confirm `docs/harness/CURRENT.md` names Phase 7 as active.
- Confirm `docs/harness/SOURCES.md` records the Phase 7 phase file and review
  workspace.
- Confirm `docs/harness/GATES.md` documents the Phase 7 burn-down target.
- Confirm Phase 7 targets only the registered-field modular-reduction cases:
  `registered_add_wrap.llzk` and `constant_fold_neg.llzk`.
- Confirm those target cases moved from expected-divergence to the positive
  corpus after VeIR commit `8e9c08925fce1caf8d6eb1d69239aae263629802`.
- Confirm the remaining expected-divergence set keeps exact marker polarity.
- Confirm Phase 7 helper defs do not inflate the Strategy E certificate
  coverage count.
- Confirm certificate smoke passes after `constant_fold_add` moved to
  `aligned`.
- Confirm Phase 7 is the only phase file still marked active.

## Result

The fresh review found one high-severity gate failure and one low-severity
documentation drift in addition to the earlier resolved issues. The high issue
was that `scripts/harness/cert-smoke.sh` failed because the checker snapshot
test still expected `constant_fold_add` to be `AlignedWithCaveats` after the
Phase 7 catalog moved it to `aligned`. The test and Phase 7 freshness evidence
are now updated, and the freshness gate requires certificate-smoke evidence.
The low issue was stale Phase 7 evidence/source-ledger wording; both are now
refreshed.

The Phase 7 registered-field modular-reduction target is implemented and
verified by the clean-pin canonical corpus, certificate smoke, and the refreshed
phase gates. No Phase 6 closeout blocker or Phase 7 implementation blocker
remains.
