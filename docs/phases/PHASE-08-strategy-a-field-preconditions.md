# Phase 8: Strategy A Field Preconditions

Status: active
Last reviewed: 2026-06-10
Repository: llzk-lean
Companion phase file: ../../../veir/docs/phases/PHASE-08-strategy-a-field-preconditions.md

## Objective

Continue the Strategy A burn-down after Phase 7's registered-field
modular-reduction closeout: consume the VeIR field-precondition parity fix
through the clean dependency pin while preserving the clean-pin differential
baseline and exact `EXPECTED-*` polarity rules.

Phase 8 starts from the Phase 7 clean dependency pin and the 21-input canonical
corpus. The first target was the remaining field-registry precondition
divergence where LLZK skips a bare `!felt.type` constant fold but VeIR still
folded it under canonicalization.

## Starting State

- llzk-lean HEAD at Phase 8 bootstrap:
  `17ad33a335683ae5831288741542abf5f9a6c68a`.
- Workspace VeIR HEAD at Phase 8 bootstrap:
  `8e9c08925fce1caf8d6eb1d69239aae263629802`.
- Consumed VeIR dependency pin at Phase 8 bootstrap:
  `8e9c08925fce1caf8d6eb1d69239aae263629802`.
- Accepted LLZK source commit remains:
  `db922857bc5a88a9107627ef6b36a8b5e57bc5c2`.
- Phase 7 closed the registered-field modular-reduction target with 9 PASS
  cases, 11 `EXPECTED-DIVERGE` canonical cases, and 1 `EXPECTED-LLZK-FAIL`
  parser/verifier gap over 21 inputs.
- Phase 7 adversarial review reports no open findings after certificate smoke,
  source-ledger wording, and clean-pin canonical evidence were refreshed.

## Implementation Update

- Phase 8 consumes VeIR commit
  `d899d95004d4bd988c8456d686c33b11a7a5eb4a`.
- The accepted dependency pin now preserves Phase 7 registered-field modular
  reduction and adds a fold guard for bare or unknown field names. VeIR now
  skips constant folds when the `!felt.type` field name cannot resolve through
  the accepted registry, matching LLZK's fold precondition.
- `differential/corpus/felt/unspecified_add_fold.llzk` is now a positive
  no-fold case. It moved from expected divergence after the clean pin closed
  the field-precondition gap.
- The clean-pin canonical corpus remains 21 inputs and now records 10 PASS
  cases, 10 `EXPECTED-DIVERGE` canonical cases, and 1
  `EXPECTED-LLZK-FAIL` parser/verifier gap.

## Target Cases

- `differential/corpus/felt/unspecified_add_fold.llzk`
  records LLZK's registered-field precondition: bare `!felt.type` constants do
  not fold because no field name resolves through the accepted registry. VeIR
  now leaves the same input unfired.

This was the first Phase 8 implementation target. The remaining nonconstant
algebraic canonicalization divergences stay classified as `EXPECTED-DIVERGE`
until there is a reviewed LLZK/VeIR behavior change and exact clean-pin
evidence.

## Non-Goals

- Do not claim full Strategy A acceptance from the current 21-input corpus.
- Do not change the accepted LLZK source commit or field-registry facts.
- Do not treat the workspace VeIR checkout as clean-pin evidence.
- Do not reclassify nonconstant algebraic rewrite divergences as positives
  without a reviewed implementation change and exact clean-pin evidence.
- Do not add Strategy E certificates or runtime MLIR matching in this phase.

## Artifacts To Create Or Update

- `docs/phases/PHASE-08-strategy-a-field-preconditions.md`: Phase 8
  implementation state.
- `docs/phases/PHASE-07-strategy-a-modular-reduction.md`: mark Phase 7
  completed.
- `docs/harness/CURRENT.md`: move the active phase to Phase 8 and record the
  field-precondition target.
- `docs/harness/SOURCES.md`: record the Phase 8 phase file and review
  workspace while preserving Phase 7 closeout evidence.
- `docs/harness/GATES.md`: document the Phase 8 implementation and
  field-precondition target gates.
- `scripts/harness/check-doc-freshness.sh`: require Phase 8 to be active while
  preserving Phase 2 through Phase 7 evidence checks.
- `scripts/harness/doctor.sh`: require Phase 8 docs and review workspace.
- `reviews/PHASE-08/{request.md,findings.md,disposition.md,adversarial-review.md,evidence/}`:
  Phase 8 review workspace and closeout evidence.

## Gates To Implement

- Freshness:
  `scripts/harness/check-doc-freshness.sh` passes only when Phase 8 is active,
  the Phase 8 review workspace exists, Phase 7 is marked complete, and Phase 7
  clean-pin closeout evidence remains present.
- Source truth:
  `scripts/harness/verify-llzk-source.sh --llzk-lib ../llzk-lib` continues to
  pass with only the known stale-worktree warning.
- Pin verification:
  `scripts/harness/verify-pins.sh --workspace-veir ../veir` continues to pass
  against the clean accepted VeIR dependency pin.
- Strict doctor:
  `scripts/harness/doctor.sh --workspace-veir ../veir` continues to pass.
- Build:
  `lake build` succeeds.
- Strategy A baseline:
  `env -u VEIR_DIFF -u VEIR_OPT LLZK_OPT=/nix/store/awcw2wiypa02sl5vx4xm06qwji68xz3h-llzk-debug-2.0.0/bin/llzk-opt ./differential/run-differential.sh --canonicalize differential/corpus`
  continues to report `21 pass (incl. expected-diverge), 0 fail` with 10 PASS
  cases, 10 `EXPECTED-DIVERGE` canonical cases, and 1 `EXPECTED-LLZK-FAIL`.
- Target guard:
  the Phase 8 docs and adversarial evidence identify `unspecified_add_fold.llzk`
  as the reclassified field-precondition target and preserve all other
  remaining canonical divergences.

## Review Requirements

- The reviewer must verify that Phase 7 findings are closed before Phase 8
  implementation work starts.
- The reviewer must verify that the Phase 8 target is limited to
  field-precondition parity, not broad Strategy A acceptance.
- The reviewer must verify that expected-divergence polarity remains exact and
  marker-driven.
- Every Phase 8 finding must be dispositioned before the phase closes.

## Done Criteria

- Phase 8 docs and review workspace exist in both llzk-lean and VeIR.
- `docs/harness/CURRENT.md` names Phase 8 as active.
- `docs/harness/SOURCES.md` records Phase 8 and the Phase 7 closeout evidence.
- Freshness, source truth, pin verification, strict doctor, skill validation,
  `lake build`, and the clean-pin canonical differential baseline pass.
- The first Phase 8 implementation target is complete: the bare/unknown-field
  fold-precondition divergence is burned down without weakening the clean-pin
  baseline or broadening unproved Strategy A claims.
