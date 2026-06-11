# Phase 4 Bootstrap and Implementation Adversarial Review

Repository: llzk-lean
Reviewed: 2026-06-09

## Scope

This review first covered the Phase 4 documentation and harness freshness
bootstrap. It now also records the follow-on workspace implementation of the
canonicalization-aware differential wrapper and seed corpus.

## Required Checks

- Confirm `docs/harness/CURRENT.md` names Phase 4 as active.
- Confirm `docs/phases/PHASE-04-strategy-a-differential.md` records the
  accepted `llzk-opt` path and local `~/llvm-project` test infrastructure.
- Confirm the bootstrap preserves Phase 2 LLZK source-truth checks, Phase 3
  Felt operation gap-ledger checks, and strict dependency pin checks.
- Confirm no Strategy A pass-pipeline acceptance is claimed before corpus and
  command evidence exist.

## Initial Result

Bootstrap documentation is ready for review once freshness, source, pin, doctor,
skill, and build gates pass.

## Final Bootstrap Result

Accepted as a Phase 4 bootstrap.

- `reviews/PHASE-04/evidence/check-doc-freshness.txt`: doc freshness summary is
  `0 fail`; the gate now requires Phase 4 to be active, the Phase 4 review
  workspace to exist, Phase 3 evidence to remain present, and the source ledger
  to record Strategy A test infrastructure.
- `reviews/PHASE-04/evidence/verify-llzk-source.txt`: LLZK source verification
  summary is `0 fail, 1 warn`; the warning is the known stale `../llzk-lib`
  worktree HEAD while the gate reads the accepted commit with `git show`.
- `reviews/PHASE-04/evidence/verify-pins.txt`: pin verification summary is
  `0 fail, 1 warn`; the warning records that workspace VeIR is a descendant of
  the accepted pin while `.lake/packages/VeIR` remains the source of truth.
- `reviews/PHASE-04/evidence/doctor-workspace.txt`: strict doctor summary is
  `0 fail, 0 warn`.
- `reviews/PHASE-04/evidence/validate-skills.txt`: skill validation summary is
  `0 fail over 5 skills`.
- `reviews/PHASE-04/evidence/lake-build.txt`: `lake build` completed
  successfully.
- `reviews/PHASE-04/evidence/adversarial-review.txt`: confirms the accepted
  `llzk-opt` binary is executable and `/home/alh/llvm-project` is clean at the
  recorded commit. It also records that the canonicalization-aware wrapper and
  corpus edits are dispositioned under this Phase 4 review workspace.

The bootstrap records Strategy A as the next active workstream and the local
test infrastructure now available. It does not claim pass-pipeline differential
acceptance.

## Implementation Result

The workspace implementation adds parse/print and canonicalization differential
evidence, automatic `.llzk` lowering, explicit workspace `VEIR_DIFF` support,
typed tool-failure classification, and canonical-only expected-divergence corpus
entries. It remains workspace evidence until llzk-lean consumes a clean VeIR pin
with the updated diff script.

## Fresh Adversarial Review Result

A fresh review of the Phase 4 implementation found two low-severity wrapper
issues, both dispositioned in `reviews/PHASE-04/findings.md` and
`reviews/PHASE-04/disposition.md`:

- Canonical mode with the default clean pinned VeIR script failed unclearly
  before the pin bump.
- Parse/print runs over only canonical-only files returned success despite
  executing no inputs.

Both issues are resolved. The normal parse/print and canonicalization corpus
runs still pass with the reviewed workspace `VEIR_DIFF` override.
