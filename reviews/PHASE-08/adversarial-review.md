# Phase 8 Adversarial Review

Repository: llzk-lean
Reviewed: 2026-06-10

## Scope

This bootstrap review closes Phase 7 and checks that Phase 8 starts from the
clean-pin corpus baseline without claiming broad Strategy A acceptance. It also
checks that the first Phase 8 target is the field-precondition gap recorded by
`unspecified_add_fold.llzk`, not the remaining nonconstant algebraic rewrite
divergences.

## Checks

- Confirm Phase 7 findings are resolved and Phase 7 is marked completed.
- Confirm the Phase 7 clean-pin canonical corpus still records
  `21 pass (incl. expected-diverge), 0 fail`.
- Confirm the consumed VeIR pin remains
  `8e9c08925fce1caf8d6eb1d69239aae263629802`.
- Confirm expected-divergence polarity remains exact and marker-driven.
- Confirm `docs/harness/CURRENT.md` names Phase 8 as active.
- Confirm Phase 8 targets only
  `expected-divergence/canonical/unspecified_add_fold.llzk`.
- Confirm nonconstant algebraic rewrite divergences remain out of scope until a
  reviewed implementation change lands.

## Result

Accepted as a Phase 8 bootstrap. No Phase 7 closeout blocker or Phase 8
bootstrap blocker remains.
