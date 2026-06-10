# Phase 7: Strategy A Modular Reduction

Status: completed; superseded by Phase 8
Last reviewed: 2026-06-10
Repository: llzk-lean
Companion phase file: ../../../veir/docs/phases/PHASE-07-strategy-a-modular-reduction.md

## Objective

Bootstrap the next Strategy A burn-down after Phase 6's DCE-only closeout:
make registered-field modular reduction the explicit implementation target
while preserving the clean-pin differential baseline and exact
`EXPECTED-*` polarity rules.

Phase 7 starts from the Phase 6 clean dependency pin and the 21-input canonical
corpus. The first target is the pair of registered-field modular-reduction
divergences where LLZK canonicalization reduces through the accepted field
modulus but VeIR emitted the raw folded integer at bootstrap.

## Starting State

- llzk-lean HEAD at Phase 7 bootstrap:
  `17ad33a335683ae5831288741542abf5f9a6c68a`.
- Workspace VeIR HEAD at Phase 7 bootstrap:
  `8036fadd1a36ee202416aa9d6f0e0e388c686b25`.
- Consumed VeIR dependency pin at Phase 7 bootstrap:
  `a0bb2fc8e6d38ab068247dfc6506ba63f5feb953`.
- Accepted LLZK source commit remains:
  `db922857bc5a88a9107627ef6b36a8b5e57bc5c2`.
- Phase 6 closed the DCE-only burn-down with 7 PASS cases, 13
  `EXPECTED-DIVERGE` canonical cases, and 1 `EXPECTED-LLZK-FAIL`
  parser/verifier gap over 21 inputs.
- Phase 6 adversarial review found no remaining implementation findings after
  the clean-pin `felt-combine,dce` baseline was refreshed.

## Phase 7 Implementation Update

- Registered-field reduction VeIR commit:
  `8e9c08925fce1caf8d6eb1d69239aae263629802`.
- llzk-lean now consumes that clean VeIR pin through Lake metadata and a clean
  `.lake/packages/VeIR` checkout.
- VeIR registered-field constant folds now reduce through the accepted field
  registry, aligning the Phase 7 target cases with LLZK's `Field::reduce`
  behavior.
- The clean-pin corpus still has 21 inputs and `0 fail`, but the classification
  is now 9 PASS cases, 11 `EXPECTED-DIVERGE` canonical cases, and
  1 `EXPECTED-LLZK-FAIL` named-field parser/verifier gap.
- Reclassified positives:
  `felt/registered_add_wrap.llzk` and `felt/constant_fold_neg.llzk`.

## Target Cases

- `differential/corpus/felt/registered_add_wrap.llzk`
  records a registered-field add fold where LLZK reduces modulo babybear and
  VeIR now emits the reduced integer.
- `differential/corpus/felt/constant_fold_neg.llzk`
  records a registered-field neg fold where LLZK reduces modulo babybear and
  VeIR now emits the reduced integer.

These were the first Phase 7 implementation targets. They are reclassified to
the positive Felt corpus after VeIR-side registered-field reduction evidence.
The remaining algebraic canonicalization divergences stay outside this Phase 7
target until their implementation behavior is reviewed independently.

## Non-Goals

- Do not claim full Strategy A acceptance from the current 21-input corpus.
- Do not change the accepted LLZK source commit or field-registry facts.
- Do not treat the workspace VeIR HEAD as clean-pin evidence.
- Do not reclassify nonconstant algebraic rewrite divergences as positives
  without a reviewed implementation change and exact clean-pin evidence.
- Do not implement Strategy E certificates or runtime MLIR matching in this
  phase bootstrap.

## Artifacts To Create Or Update

- `docs/phases/PHASE-07-strategy-a-modular-reduction.md`: Phase 7 bootstrap.
- `docs/phases/PHASE-06-strategy-a-divergence-burndown.md`: mark Phase 6
  completed.
- `docs/harness/CURRENT.md`: move the active phase to Phase 7 and record the
  modular-reduction target.
- `docs/harness/SOURCES.md`: record the Phase 7 phase file and review
  workspace while preserving Phase 6 closeout evidence.
- `docs/harness/GATES.md`: document the Phase 7 bootstrap and modular-reduction
  target gates.
- `scripts/harness/check-doc-freshness.sh`: require Phase 7 to be active while
  preserving Phase 2 through Phase 6 evidence checks.
- `scripts/harness/doctor.sh`: require Phase 7 docs and review workspace.
- `reviews/PHASE-07/{request.md,findings.md,disposition.md,adversarial-review.md,evidence/}`:
  Phase 7 review workspace.

## Gates To Implement

- Bootstrap freshness:
  `scripts/harness/check-doc-freshness.sh` passes only when Phase 7 is active,
  the Phase 7 review workspace exists, Phase 6 is marked complete, and Phase 6
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
- Certificate smoke:
  `scripts/harness/cert-smoke.sh` passes against
  `certs/felt-combine.cert.json`, including the Phase 7 `constant_fold_add`
  parity change to `aligned`.
- Strategy A baseline:
  `LLZK_OPT=/nix/store/awcw2wiypa02sl5vx4xm06qwji68xz3h-llzk-debug-2.0.0/bin/llzk-opt ./differential/run-differential.sh --canonicalize differential/corpus`
  reports `21 pass (incl. expected-diverge), 0 fail` with 9 PASS cases,
  11 `EXPECTED-DIVERGE` canonical cases, and 1 `EXPECTED-LLZK-FAIL`.
- Target guard:
  the Phase 7 docs and adversarial evidence identify `registered_add_wrap.llzk`
  and `constant_fold_neg.llzk` as exact modular-reduction targets and preserve
  their reclassification evidence.

## Review Requirements

- The reviewer must verify that Phase 6 findings are closed before Phase 7
  implementation work starts.
- The reviewer must verify that the Phase 7 target is limited to
  registered-field modular reduction, not broad Strategy A acceptance.
- The reviewer must verify that expected-divergence polarity remains exact and
  marker-driven.
- Every Phase 7 finding must be dispositioned before the phase closes.

## Done Criteria

- Phase 7 bootstrap docs and review workspace exist in both llzk-lean and VeIR.
- `docs/harness/CURRENT.md` names Phase 7 as active.
- `docs/harness/SOURCES.md` records Phase 7 and the Phase 6 closeout evidence.
- Freshness, source truth, pin verification, strict doctor, skill validation,
  `lake build`, certificate smoke, and the clean-pin canonical differential
  baseline pass.
- The first Phase 7 implementation target is complete: the registered-field
  modular-reduction divergences are burned down without weakening the clean-pin
  baseline or broadening unproved Strategy A claims.
