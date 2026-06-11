# Phase 4: Strategy A Differential Harness Bootstrap

Status: completed; superseded by Phase 5
Last reviewed: 2026-06-09
Repository: llzk-lean
Companion phase file: ../../../veir/docs/phases/PHASE-04-strategy-a-differential.md

## Objective

Bootstrap Strategy A as the active phase: make the llzk-lean differential
corpus and wrapper the canonical next workstream, record available test
infrastructure, and set the acceptance target for canonicalization-enabled
LLZK/VeIR differential runs.

This phase starts from the Phase 3 operation-gap ledger. It does not expand the
certificate catalog or claim differential acceptance. It prepares the concrete
implementation work: run `llzk-opt --canonicalize` and
`veir-opt -p=felt-combine` over a reviewed Felt corpus and classify every
divergence.

## Starting State

- llzk-lean HEAD at Phase 4 bootstrap:
  `617702beadfbad6be784945e2bd98e8a788d357c`.
- Workspace VeIR HEAD at Phase 4 bootstrap:
  `0c5280de5715dc0fa518e7e3782e784a5962d4d8`.
- Consumed VeIR dependency pin remains:
  `d4cc1bf2d31beeca17eb2e8c9c7181d04af013a3`.
- Accepted LLZK source commit remains:
  `db922857bc5a88a9107627ef6b36a8b5e57bc5c2`.
- Local `../llzk-lib` worktree remains stale at
  `30b0fa1eb77de154ff60c13fa88ef286d8b01c65`; source facts still use the
  accepted commit through `git show`.
- `llzk-opt` is not on `PATH`, but the accepted local binary is available at
  `/nix/store/awcw2wiypa02sl5vx4xm06qwji68xz3h-llzk-debug-2.0.0/bin/llzk-opt`.
- LLVM/MLIR test infrastructure is available at `~/llvm-project`, a clean
  checkout of `https://github.com/llvm/llvm-project.git` at
  `49f12af164138123589263fe75ea5f1d356e8780`, with
  `/home/alh/llvm-project/build/bin/mlir-opt` and
  `/home/alh/llvm-project/build/bin/llvm-config` reporting `23.0.0git`.
- `differential/run-differential.sh` wraps the consumed VeIR
  `scripts/llzk-diff.sh` by default and can explicitly consume the workspace
  VeIR script through `VEIR_DIFF=../veir/scripts/llzk-diff.sh`.
- Phase 4 workspace implementation adds canonicalization mode:
  `llzk-opt --canonicalize --mlir-print-op-generic` compared with
  `veir-opt -p=felt-combine`.
- `differential/corpus/` now contains parse/print and canonical positives plus
  classified expected divergences for generic named-field LLZK failure, DCE
  mismatch, modular reduction, and field-registry preconditions.
- Current worktree is dirty from Phase 2/3 harness documentation and Phase 4
  bootstrap edits. These are not Strategy A acceptance evidence.

## Non-Goals

- Do not implement missing VeIR Felt operations in this phase bootstrap.
- Do not expand Strategy E certificates or implement the runtime MLIR matcher.
- Do not change the accepted VeIR dependency pin.
- Do not treat parse/print agreement as canonicalization acceptance.
- Do not let missing `llzk-opt`, skipped runs, or expected-divergence polarity
  count as a passing Strategy A implementation gate.

## Artifacts To Create Or Update

- `docs/phases/PHASE-04-strategy-a-differential.md`: Phase 4 bootstrap.
- `docs/harness/CURRENT.md`: move the active phase to Phase 4.
- `docs/harness/SOURCES.md`: record the differential wrapper, corpus,
  `llzk-opt`, and `~/llvm-project` test infrastructure.
- `docs/harness/GATES.md`: document Phase 4 bootstrap and future Strategy A
  acceptance gates.
- `scripts/harness/check-doc-freshness.sh`: require Phase 4 to be active while
  preserving Phase 2 source-truth and Phase 3 operation-gap checks.
- `scripts/harness/doctor.sh`: require Phase 4 docs and review workspace.
- `reviews/PHASE-04/{request.md,findings.md,disposition.md,adversarial-review.md,evidence/}`:
  Phase 4 review workspace.

## Gates To Implement

- Bootstrap freshness:
  `scripts/harness/check-doc-freshness.sh` passes only when Phase 4 is active,
  the Phase 4 review workspace exists, the Phase 3 gap ledger remains intact,
  and the source ledger records the differential wrapper, corpus, and local test
  tools.
- Source truth:
  `scripts/harness/verify-llzk-source.sh --llzk-lib ../llzk-lib` continues to
  pass.
- Pin verification:
  `scripts/harness/verify-pins.sh --workspace-veir ../veir` continues to pass.
- Strict doctor:
  `scripts/harness/doctor.sh --workspace-veir ../veir` continues to pass.
- Build:
  `lake build` succeeds against the clean dependency checkout.
- Implementation gate:
  Strategy A acceptance requires a reviewed command that sets `LLZK_OPT` to the
  accepted binary and runs canonicalization on both tools over the accepted
  corpus. The workspace command is:
  `LLZK_OPT=/nix/store/awcw2wiypa02sl5vx4xm06qwji68xz3h-llzk-debug-2.0.0/bin/llzk-opt VEIR_DIFF=../veir/scripts/llzk-diff.sh ./differential/run-differential.sh --canonicalize differential/corpus`.
  Bootstrap does not satisfy this gate; the workspace implementation is seed
  evidence until the clean VeIR pin consumes the updated script.

## Review Requirements

- The reviewer must verify that Phase 4 is clearly scoped to Strategy A.
- The reviewer must verify that the docs do not claim differential acceptance
  before canonicalization and corpus evidence exist.
- The reviewer must verify that `~/llvm-project` and the Nix `llzk-opt` path are
  recorded as test infrastructure, not as proof state.
- The reviewer must verify that Phase 2 source-truth gates, Phase 3 gap-ledger
  evidence, and dependency pin gates still pass.
- Disposition every finding before closing the phase.

## Done Criteria

- Phase 4 bootstrap docs and review workspace exist in both llzk-lean and VeIR.
- `docs/harness/CURRENT.md` names Phase 4 as active.
- `docs/harness/SOURCES.md` records the differential wrapper, corpus, accepted
  `llzk-opt` path, and `~/llvm-project` build path.
- `check-doc-freshness.sh`, `verify-llzk-source.sh`, `verify-pins.sh`,
  `doctor.sh`, `validate-skills.sh`, and `lake build` pass after the bootstrap.
- The canonicalization-aware workspace execution path exists and the seed corpus
  is reclassified. The next task is to bump/consume a clean VeIR pin for this
  script and broaden the corpus toward the full Strategy A v1 bar.
