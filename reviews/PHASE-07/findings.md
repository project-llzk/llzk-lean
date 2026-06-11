# Phase 7 Findings

Repository: llzk-lean
Reviewed: 2026-06-10

## F7-LLZK-01: Historical phase files still marked active

Severity: low
Status: resolved

After Phase 7 bootstrap, `docs/phases/PHASE-01-pins-and-repro.md`,
`PHASE-02-llzk-source-truth.md`, and
`PHASE-03-felt-op-gap-ledger.md` still said `Status: active`. That left
multiple phase files marked active even though `docs/harness/CURRENT.md`
correctly named Phase 7.

Resolution: mark Phases 1 through 3 completed and superseded, keep Phase 7 as
the only active phase file, and add a freshness gate that fails if any phase
file other than Phase 7 is marked active.

## F7-LLZK-02: Certificate coverage scanner counted a helper as a rewrite pattern

Severity: low
Status: resolved

After the Phase 7 VeIR pin added `foldedConstProperties`, fresh llzk-lean build
evidence reported 16 `Veir.FeltPass` rewrite-pattern defs instead of the
expected 15. The helper was not a rewrite pattern; the scanner was relying only
on namespace/name heuristics.

Resolution: tighten `#assertCatalogCoverage` so a candidate pattern def must
have the rewrite-pattern type shape, i.e. its exported type mentions both
`Veir.PatternRewriter` and `Veir.OperationPtr`, before it contributes to the
coverage count. Fresh build evidence again reports 15 patterns, 2 cataloged,
and 13 uncovered.

## F7-LLZK-03: Certificate smoke failed after the parity reclassification

Severity: high
Status: resolved

Phase 7 changed `constant_fold_add` from `aligned-with-caveats` to `aligned`
after registered-field fold results began reducing through the accepted field
registry. The committed certificate snapshot and Lean catalog were updated, but
`checker/tests/test_loader.cpp` still expected `AlignedWithCaveats` for the
committed snapshot. A direct `scripts/harness/cert-smoke.sh` run failed in
`loader_smoke_tests` on `cert[1] parity`.

Resolution: update the checker snapshot test to expect
`LlzkParityStatus::Aligned` for `constant_fold_add`, record Phase 7
certificate-smoke evidence, and make the freshness gate require that evidence
so future certificate/checker drift is caught by the phase gate.

## F7-LLZK-04: Phase 7 evidence wording lagged the implementation

Severity: low
Status: resolved

The Phase 7 evidence README still described pre-implementation bootstrap state
and said modular-reduction targets had not been reclassified. The live source
ledger also described the consumed VeIR diff path only in Phase 6 DCE terms,
omitting that the accepted Phase 7 pin carries registered-field fold-result
reduction.

Resolution: update the Phase 7 evidence README and source ledger so they
describe the implemented Phase 7 state and the accepted pin's registered-field
reduction behavior.

No Phase 7 findings remain open.
