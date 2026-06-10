# Phase 8 Disposition

Repository: llzk-lean
Updated: 2026-06-10

No Phase 8 findings are open.

Phase 8 starts from the completed Phase 7 registered-field modular-reduction
closeout. The first target was the remaining bare/unknown-field
fold-precondition divergence recorded by `unspecified_add_fold.llzk`.

F8-LLZK-01 is resolved by consuming VeIR commit
`d899d95004d4bd988c8456d686c33b11a7a5eb4a`. The target moved to
`differential/corpus/felt/unspecified_add_fold.llzk` as a positive no-fold
case, and the other nonconstant algebraic canonicalization divergences remain
classified as `EXPECTED-DIVERGE`.

F8-LLZK-02 and F8-LLZK-03 are resolved by strengthening the default clean
dependency differential path and Phase 8 evidence checks. The wrapper refreshes
the pinned dependency `veir-opt` executable before running, rejects hidden
`VEIR_OPT` overrides on the clean path, and the evidence records the exact
override-clearing command.
