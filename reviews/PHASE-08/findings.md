# Phase 8 Findings

Repository: llzk-lean
Reviewed: 2026-06-10

No Phase 8 findings are open.

## F8-LLZK-01: Bare Felt Constant Fold Ignored LLZK Field Preconditions

- Severity: medium
- Status: resolved
- Area: Strategy A canonical differential, VeIR Felt folding

At Phase 8 bootstrap, `unspecified_add_fold.llzk` documented a narrow
field-precondition divergence: LLZK left a bare `!felt.type` add unfired
because no registered field name resolved, while VeIR folded the same constants
under canonicalization.

Resolution: VeIR commit
`d899d95004d4bd988c8456d686c33b11a7a5eb4a` makes constant-fold and associative
constant-fold helpers return no rewrite when the field name cannot resolve
through the accepted registry. The case moved to
`differential/corpus/felt/unspecified_add_fold.llzk` as a positive no-fold
case, and the clean-pin canonical corpus remains
`21 pass (incl. expected-diverge), 0 fail`.

## F8-LLZK-02: Clean-Pin Differential Could Use Stale veir-opt

- Severity: high
- Status: resolved
- Area: Strategy A clean dependency evidence

The default differential path used the clean dependency `scripts/llzk-diff.sh`,
but that script preferred an existing `.lake/build/bin/veir-opt` executable
when present. A pin bump could therefore leave the source checkout at the
accepted commit while the executable still reflected an older build.

Resolution: `differential/run-differential.sh` now rejects hidden `VEIR_OPT`
overrides on the default clean dependency path, runs `lake build veir-opt`
inside `.lake/packages/VeIR` before comparing, verifies the executable exists,
and emits a `CLEAN-VEIR-OPT` evidence marker.

## F8-LLZK-03: Differential Evidence Omitted The Exact Clean-Pin Command

- Severity: medium
- Status: resolved
- Area: Strategy A evidence auditability

The Phase 8 differential evidence recorded pass/fail output but not the exact
command line. That made it possible for freshness checks to accept an output
that could have been produced with a workspace `VEIR_DIFF` or `VEIR_OPT`
override.

Resolution: the Phase 8 evidence now records the exact
`env -u VEIR_DIFF -u VEIR_OPT LLZK_OPT=... ./differential/run-differential.sh --canonicalize differential/corpus`
command, and `scripts/harness/check-doc-freshness.sh` requires that command,
the accepted `LLZK_OPT` path, and the `CLEAN-VEIR-OPT` marker.
