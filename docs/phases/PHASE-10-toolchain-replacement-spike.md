# Phase 10: Toolchain Replacement Spike

Status: bootstrap; not harness-active
Last reviewed: 2026-06-11
Repository: llzk-lean
Companion phase file: ../../../veir/docs/phases/PHASE-10-toolchain-replacement-spike.md

## Objective

Select and exercise the first executable replacement path for the Felt
drop-in effort, while preserving the distinction between the C++-parity
profile and the enhanced VEIR profile.

The first spike is an external-driver path. LLZK still owns custom-assembly
parsing and lowering to generic MLIR; VEIR owns the Felt canonicalization pass
under test; LLZK remains the comparison oracle for the C++ path.

## Starting State

- Phase 8 is the last accepted implementation milestone.
- Phase 9 completed the roadmap and claim reset.
- The differential wrapper already lowers `.llzk` inputs with
  `llzk-opt --mlir-print-op-generic` before invoking VEIR.
- The canonical comparison path currently runs:
  - C++ LLZK: `llzk-opt --canonicalize --mlir-print-op-generic`;
  - VEIR: `veir-opt -p=felt-combine,dce`.
- The current VEIR path is the enhanced profile. A C++-parity profile still
  needs to be implemented or configured in VEIR.

## Profile Policy

- **C++-parity profile:** adoption baseline. Divergences from C++ LLZK block
  this profile unless explicitly disabled or fixed.
- **Enhanced VEIR profile:** improvement path. Divergences from C++ LLZK may
  be accepted only with differential evidence, executable semantic claims, and
  downstream compatibility review.

Phase 10 should not treat the stronger current `felt-combine` behavior as a
problem by default. It should classify each difference as either a parity
blocker or an enhanced-profile candidate.

## Non-Goals

- Do not claim full Felt semantic parity.
- Do not claim replacement of the whole `llzk-opt` binary.
- Do not make the certificate route critical-path until the
  `constant_fold_add` prototype proves useful.
- Do not reclassify expected divergences without exact evidence and review.

## Artifacts To Create Or Update

- `scripts/harness/phase10-toolchain-smoke.sh`: one-command smoke for the
  external-driver spike.
- `docs/drop-in-roadmap.md`: roadmap and profile policy.
- `docs/harness/SOURCES.md`: Phase 10 bootstrap source rows.
- Phase 10 evidence under `reviews/PHASE-10/evidence/` once smoke runs are
  recorded.

## Gates To Implement

- Toolchain smoke:
  `scripts/harness/phase10-toolchain-smoke.sh`.
- Existing Phase 8 freshness:
  `scripts/harness/check-doc-freshness.sh`.
- Targeted VEIR proof build after proof/doc edits:
  `lake build Veir.Passes.Felt.Proofs` from the VEIR repository.

## Bootstrap Execution

The first Phase 10 smoke run exposed a workspace VEIR regression relative to
the accepted clean pin: after the upstream DCE side-effect API change, Felt
operations were conservatively treated as side-effecting, so
`veir-opt -p=felt-combine,dce` folded `registered_add_fold.llzk` but did not
erase the now-dead input constants. The clean dependency pin still passed.

The bootstrap fix is in VeIR `Veir/GlobalOpInfo.lean`: Felt operations are now
classified as side-effect-free for DCE. After rebuilding workspace `veir-opt`,
`scripts/harness/phase10-toolchain-smoke.sh` passes over the aligned fold and
no-fire precondition cases.

## Review Requirements

- Record exactly which command owns parsing, lowering, canonicalization, and
  printing.
- Identify whether the smoke exercised the clean dependency pin or workspace
  VEIR.
- Mark each observed divergence as parity blocker, enhanced-profile candidate,
  or unrelated tooling issue.

## Done Criteria

- One command runs the external-driver smoke over LLZK custom assembly and
  reports comparable output for both paths.
- The first VEIR implementation task is precise: add/configure the parity
  profile, or promote a named current divergence into the enhanced profile
  through review.
- Phase 10 evidence remains separate from Phase 8 acceptance evidence until
  the harness gates are deliberately advanced.
