# Phase 6: Strategy A Divergence Burn-Down

Status: completed; superseded by Phase 7
Last reviewed: 2026-06-10
Repository: llzk-lean
Companion phase file: ../../../veir/docs/phases/PHASE-06-strategy-a-divergence-burndown.md

## Objective

Bootstrap the next Strategy A workstream after the Phase 5 clean-pin corpus:
turn the exact-polarity 21-input corpus into a reviewed divergence burn-down
track by reducing or reclassifying expected divergences without weakening the
clean-pin, source-truth, or expected-failure gates.

This phase starts from Phase 5's accepted clean dependency pin and exact
`EXPECTED-*` polarity checks. Phase 6 must preserve that baseline while making
the next implementation target explicit.

## Starting State

- llzk-lean HEAD at Phase 6 bootstrap:
  `617702beadfbad6be784945e2bd98e8a788d357c`.
- Workspace VeIR HEAD at Phase 6 bootstrap:
  `220cd215579b435c3c22ce86b34a3f4ce2ca276e`.
- Consumed VeIR dependency pin at bootstrap:
  `220cd215579b435c3c22ce86b34a3f4ce2ca276e`.
- Accepted LLZK source commit remains:
  `db922857bc5a88a9107627ef6b36a8b5e57bc5c2`.
- Phase 5 clean-pin canonical corpus evidence records 21 inputs:
  4 positive PASS cases, 16 `EXPECTED-DIVERGE` canonical cases, and
  1 `EXPECTED-LLZK-FAIL` named-field parser/verifier gap.
- Phase 5 final review fixed exact expected-divergence polarity so a canonical
  output-divergence test no longer passes on a wrong LLZK/VEIR failure mode.

## Phase 6 Implementation Update

- First burn-down VeIR commit:
  `a0bb2fc8e6d38ab068247dfc6506ba63f5feb953`.
- llzk-lean now consumes that clean VeIR pin through Lake metadata and a clean
  `.lake/packages/VeIR` checkout.
- VeIR canonical differential mode now compares `llzk-opt --canonicalize`
  against `veir-opt -p=felt-combine,dce`, aligning VeIR's diff path with
  LLZK's dead-input cleanup after constant folds.
- The clean-pin corpus still has 21 inputs and `0 fail`, but the classification
  is now 7 PASS cases, 13 `EXPECTED-DIVERGE` canonical cases, and
  1 `EXPECTED-LLZK-FAIL` named-field parser/verifier gap.
- Reclassified positives:
  `felt/registered_add_fold.llzk`, `felt/constant_fold_sub.llzk`, and
  `felt/constant_fold_mul.llzk`.

## Non-Goals

- Do not change the accepted LLZK source commit or field-registry facts.
- Do not change the accepted VeIR pin unless a reviewed Phase 6 implementation
  needs a new clean dependency commit.
- Do not claim full Strategy A acceptance from the current 21-input corpus.
- Do not implement Strategy E certificates or the runtime MLIR matcher in this
  phase bootstrap.
- Do not port missing Felt operations as part of bootstrap paperwork.

## Artifacts To Create Or Update

- `docs/phases/PHASE-06-strategy-a-divergence-burndown.md`: Phase 6 bootstrap.
- `docs/phases/PHASE-05-strategy-a-pin-and-corpus.md`: mark Phase 5 completed.
- `docs/harness/CURRENT.md`: move the active phase to Phase 6 and record the
  Phase 5 closeout baseline.
- `docs/harness/SOURCES.md`: record the Phase 6 phase file and Phase 5
  exact-polarity closeout evidence.
- `docs/harness/GATES.md`: document Phase 6 bootstrap and divergence burn-down
  gates.
- `lakefile.toml`, `lake-manifest.json`, and `.lake/packages/VeIR`: consume the
  Phase 6 DCE-enabled VeIR pin.
- `scripts/harness/check-doc-freshness.sh`: require Phase 6 to be active while
  preserving Phase 2 through Phase 5 evidence checks.
- `scripts/harness/doctor.sh`: require Phase 6 docs and review workspace.
- `reviews/PHASE-06/{request.md,findings.md,disposition.md,adversarial-review.md,evidence/}`:
  Phase 6 review workspace.

## Gates To Implement

- Bootstrap freshness:
  `scripts/harness/check-doc-freshness.sh` passes only when Phase 6 is active,
  the Phase 6 review workspace exists, Phase 5 is marked complete, and Phase 5
  clean-pin plus exact-polarity evidence remains present.
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
  `LLZK_OPT=/nix/store/awcw2wiypa02sl5vx4xm06qwji68xz3h-llzk-debug-2.0.0/bin/llzk-opt ./differential/run-differential.sh --canonicalize differential/corpus`
  reports `21 pass (incl. expected-diverge), 0 fail` with the Phase 6
  reclassification above.

## Review Requirements

- The reviewer must verify that Phase 5 findings are closed before Phase 6
  implementation work starts.
- The reviewer must verify that expected-divergence polarity remains exact and
  marker-driven.
- The reviewer must verify that Phase 6 docs do not claim full Strategy A
  acceptance.
- Every Phase 6 finding must be dispositioned before the phase closes.

## Done Criteria

- Phase 6 bootstrap docs and review workspace exist in both llzk-lean and VeIR.
- `docs/harness/CURRENT.md` names Phase 6 as active.
- `docs/harness/SOURCES.md` records Phase 6 and the Phase 5 exact-polarity
  closeout evidence.
- Freshness, source truth, pin verification, strict doctor, skill validation,
  `lake build`, and the clean-pin canonical differential baseline pass.
- The first Phase 6 implementation target is complete: reclassify the three
  DCE-only constant-fold divergences without broadening unproved Strategy A
  claims.
