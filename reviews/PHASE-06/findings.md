# Phase 6 Findings

Repository: llzk-lean
Reviewed: 2026-06-10

## F6-LLZK-01: DCE-only constant-fold divergences remained classified negative

Severity: medium
Status: resolved

At Phase 6 bootstrap, `registered_add_fold.llzk`, `constant_fold_sub.llzk`,
and `constant_fold_mul.llzk` were still classified as `EXPECTED-DIVERGE`
although the difference was pipeline alignment rather than arithmetic: LLZK's
canonicalizer erased now-dead input constants, while VeIR canonical
differential mode ran only `felt-combine`.

Resolution: VeIR commit `a0bb2fc8e6d38ab068247dfc6506ba63f5feb953` updates
canonical differential mode to run `felt-combine,dce`. llzk-lean consumes that
clean pin and reclassifies the three files under `differential/corpus/felt/`.
The clean-pin canonical corpus remains `21 pass (incl. expected-diverge),
0 fail`.

No Phase 6 findings remain open.
