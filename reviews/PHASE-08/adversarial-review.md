# Phase 8 Adversarial Review

Repository: llzk-lean
Reviewed: 2026-06-10

## Scope

This review closes the first Phase 8 field-precondition target and checks that
the new clean VeIR pin preserves the corpus baseline without claiming broad
Strategy A acceptance. It also checks that the reclassified Phase 8 target is
the field-precondition gap recorded by `unspecified_add_fold.llzk`, not the
remaining nonconstant algebraic rewrite divergences.

## Checks

- Confirm Phase 7 findings are resolved and Phase 7 is marked completed.
- Confirm the Phase 7 clean-pin canonical corpus still records
  `21 pass (incl. expected-diverge), 0 fail`.
- Confirm the consumed VeIR pin is
  `d899d95004d4bd988c8456d686c33b11a7a5eb4a`.
- Confirm expected-divergence polarity remains exact and marker-driven.
- Confirm `docs/harness/CURRENT.md` names Phase 8 as active.
- Confirm Phase 8 reclassifies only
  `differential/corpus/felt/unspecified_add_fold.llzk`.
- Confirm the clean-pin differential path refreshes the pinned dependency
  `veir-opt` executable and rejects hidden `VEIR_OPT` overrides.
- Confirm the differential evidence records the exact override-clearing command
  line and accepted `LLZK_OPT` path.
- Confirm nonconstant algebraic rewrite divergences remain out of scope until a
  reviewed implementation change lands.

## Result

Accepted as Phase 8 implementation evidence for bare/unknown-field
fold-precondition parity. No Phase 7 closeout blocker or Phase 8 blocker
remains.
