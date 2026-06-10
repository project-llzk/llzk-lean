# Phase 3: Felt Operation Semantics Gap Ledger

Status: active
Last reviewed: 2026-06-06
Repository: llzk-lean
Companion phase file: ../../../veir/docs/phases/PHASE-03-felt-op-gap-ledger.md

## Objective

Create a source-grounded ledger that maps every accepted LLZK Felt operation to
the consumed VeIR pin, Strategy A differential status, Strategy E certificate
status, and known gaps.

This phase is a documentation and gate phase. It prepares the next independent
implementation phase by making operation coverage explicit and mechanically
fresh without expanding the certificate catalog or differential corpus yet.

## Starting State

- llzk-lean HEAD at Phase 3 bootstrap:
  `617702beadfbad6be784945e2bd98e8a788d357c`.
- Workspace VeIR HEAD at Phase 3 bootstrap:
  `0c5280de5715dc0fa518e7e3782e784a5962d4d8`.
- Consumed VeIR dependency pin:
  `d4cc1bf2d31beeca17eb2e8c9c7181d04af013a3`.
- Accepted LLZK source remote:
  `git@github.com:project-llzk/llzk-lib.git`.
- Accepted LLZK source commit:
  `db922857bc5a88a9107627ef6b36a8b5e57bc5c2`.
- Local `../llzk-lib` checkout remains stale at
  `30b0fa1eb77de154ff60c13fa88ef286d8b01c65`; Phase 3 source facts must use
  the accepted commit through `git show`.
- Phase 2 gates prove the accepted 18-op LLZK Felt source set, accepted field
  registry, and consumed VeIR `feltPrime` mirror.
- Current certificate catalog covers 2 of 15 VeIR Felt rewrite patterns and
  reports 13 uncovered at build time.
- Current Strategy A smoke classifies missing `llzk-opt` as exit 77 in this
  environment and does not prove differential acceptance.
- Current worktree is dirty from Phase 2 close-out documentation/harness fixes
  and separate pre-existing root/differential/skill documentation edits. These
  are not Phase 3 semantic implementation evidence.

## Non-Goals

- Do not expand the certificate catalog in this phase.
- Do not implement the Strategy E runtime MLIR matcher in this phase.
- Do not add differential corpus inputs in this phase.
- Do not port missing VeIR Felt operations in this phase.
- Do not change the accepted VeIR dependency pin.
- Do not claim Strategy A or Strategy E acceptance.

## Artifacts To Create Or Update

- `docs/harness/FELT_OP_GAPS.md`: canonical operation coverage and gap ledger.
- `docs/harness/CURRENT.md`: move the active phase to Phase 3.
- `docs/harness/SOURCES.md`: record the Phase 3 ledger as trusted local source.
- `docs/harness/GATES.md`: document the Phase 3 documentation gate.
- `scripts/harness/check-doc-freshness.sh`: require the Phase 3 phase file,
  review workspace, and operation-gap ledger.
- `reviews/PHASE-03/{request.md,findings.md,disposition.md,adversarial-review.md,evidence/}`:
  adversarial review workspace.

## Gates To Implement

- `scripts/harness/check-doc-freshness.sh` fails if Phase 3 is not active, if
  `docs/harness/FELT_OP_GAPS.md` is missing, or if the ledger omits any accepted
  LLZK Felt mnemonic.
- `scripts/harness/verify-llzk-source.sh --llzk-lib ../llzk-lib` continues to
  pass, proving the operation ledger is grounded in the accepted LLZK source
  and the consumed VeIR dependency.
- `scripts/harness/verify-pins.sh --workspace-veir ../veir` continues to pass.
- `scripts/harness/doctor.sh --workspace-veir ../veir` continues to pass.
- `lake build` succeeds after documentation changes.

## Review Requirements

- Every operation-coverage claim must cite an exact local source file or the
  accepted LLZK source ledger.
- The reviewer must verify that the 18 LLZK Felt op mnemonics are all present
  in `docs/harness/FELT_OP_GAPS.md`.
- The reviewer must verify that Strategy A and Strategy E status is described
  as current coverage or a gap, not as acceptance.
- The reviewer must verify that Phase 3 does not smuggle in certificate,
  differential, or semantic implementation changes.
- Disposition every finding before closing the phase.

## Done Criteria

- `docs/harness/FELT_OP_GAPS.md` records all 18 accepted LLZK Felt operations.
- The ledger distinguishes consumed VeIR semantic coverage from missing or
  unclassified operations.
- The ledger records current certificate and differential coverage without
  claiming acceptance for incomplete paths.
- `check-doc-freshness.sh`, `verify-llzk-source.sh`, pin checks, and
  `lake build` pass.
- Phase 3 review artifacts contain fresh adversarial evidence.
