# Phase 5 Disposition

Repository: llzk-lean
Created: 2026-06-09
Updated: 2026-06-10

## Dispositioned Findings

- F5-LLZK-01 resolved by making `differential/run-differential.sh` exit
  non-zero whenever `llzk-diff.sh` reports SKIP for any selected input.
- F5-LLZK-02 resolved by pinning VeIR
  `220cd215579b435c3c22ce86b34a3f4ce2ca276e`, whose differential driver uses
  the built `veir-opt` binary when available and preserves `lake exec` as a
  fallback.
- F5-LLZK-03 resolved by updating stale Phase 5 status docs and adding
  freshness checks that reject seed-only/future-expansion language.
- F5-LLZK-04 resolved by documenting `EXPECTED-LLZK-FAIL` and
  `EXPECTED-VEIR-FAIL` corpus polarity and gating those labels in doc
  freshness.
- F5-LLZK-05 resolved by refreshing `verify-llzk-source.txt` with stderr
  captured so the known stale `../llzk-lib` warning is present in the evidence.
- F5-LLZK-06 resolved by making expected-divergence files declare the exact
  accepted `EXPECTED-*` outcome and by adding polarity-guard evidence that a
  wrong failure mode exits nonzero.

No Phase 5 findings remain open.
