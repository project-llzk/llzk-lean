# Phase 1: Reproducible Pins

Status: completed; superseded by Phase 2
Last reviewed: 2026-06-05
Repository: llzk-lean
Companion phase file: ../../../veir/docs/phases/PHASE-01-pins-and-repro.md

## Objective

Make llzk-lean's VeIR dependency clean, explicit, and reproducible.

At the end of this phase, `lakefile.toml`, `lake-manifest.json`, and
`.lake/packages/VeIR` must all identify the same accepted VeIR commit, and the
dependency checkout must be clean.

## Starting State

- llzk-lean HEAD at Phase 1 bootstrap:
  `336a5a221ae79d00e5d1346e09341232bdc4323d`.
- workspace veir HEAD at Phase 1 bootstrap:
  `039068b68552bb37f1a887ec509e9b9111d4d54a`.
- Lake files currently pin VeIR to:
  `09d5f00f0d2b4a8710afbe53dfdd7cf468578a04`.
- `.lake/packages/VeIR` is currently at:
  `09d5f00f0d2b4a8710afbe53dfdd7cf468578a04`.
- `.lake/packages/VeIR` is currently dirty:
  - modified `Veir/Passes/Felt/Combine.lean`
  - modified `Veir/Passes/Felt/Proofs.lean`
  - untracked `Veir/Passes/Felt/RewriteLemmas.lean`
- Phase 0 strict doctor intentionally fails on this dirty state.

## Non-Goals

- Do not port additional Felt operations.
- Do not change Lean theorem statements except as needed to make the dependency
  pin build cleanly.
- Do not make Strategy A or Strategy E acceptance claims.
- Do not use `--mode exploratory` output as acceptance evidence.

## Artifacts To Create Or Update

- `docs/harness/CURRENT.md`: record Phase 1 as active once implementation
  starts, and list the accepted VeIR pin mode.
- `docs/harness/SOURCES.md`: add the accepted VeIR commit, remote URL, and the
  evidence that the dependency checkout is clean.
- `docs/harness/GATES.md`: add reproducible-pin gates.
- `docs/harness/PINS.md`: document the intended VeIR rev, update procedure,
  rollback procedure, and what constitutes forbidden hidden state.
- `lakefile.toml`: update the `VeIR` rev deliberately after selecting the
  accepted commit.
- `lake-manifest.json`: update consistently with `lakefile.toml`.
- `.lake/packages/VeIR`: refresh to the accepted clean commit.
- `scripts/harness/verify-pins.sh`: verify Lake file URL/rev agreement,
  manifest `url`/`type`/`rev`/`inputRev`, dependency HEAD, dependency
  cleanliness, and optional workspace VeIR agreement.
- `reviews/PHASE-01/{request.md,findings.md,disposition.md,evidence/}`:
  adversarial review workspace for the pin transition.

## Gates To Implement

- `scripts/harness/verify-pins.sh` fails in the current starting state because
  `.lake/packages/VeIR` is dirty.
- `scripts/harness/doctor.sh` passes in strict mode only after the dependency
  checkout is clean and at the accepted rev.
- `git -C .lake/packages/VeIR status --short` is empty.
- `lakefile.toml` uses the accepted VeIR remote URL and accepted commit.
- `lake-manifest.json` uses the accepted VeIR remote URL, has `type: "git"`,
  and records the accepted commit in both `rev` and `inputRev`.
- `git -C .lake/packages/VeIR rev-parse HEAD` equals both the `lakefile.toml`
  rev and the `lake-manifest.json` rev/inputRev.
- If `../veir` is supplied, its HEAD equals the accepted rev or the mismatch is
  explicitly documented as a non-acceptance exploratory layout.
- `lake build` succeeds against the clean dependency.

## Review Requirements

- Capture exact command output under `reviews/PHASE-01/evidence/`.
- Review must include the Lake file diff, Lake source URL/type/inputRev,
  dependency checkout HEAD, dependency cleanliness, and the result of
  `lake build`.
- Review must explicitly reject any proof state that only exists in a dirty
  `.lake/packages/VeIR` checkout.
- Disposition every finding before closing the phase.

## Done Criteria

- `lakefile.toml` and `lake-manifest.json` pin the same accepted VeIR remote and
  commit, with manifest `type`, `rev`, and `inputRev` checked.
- `.lake/packages/VeIR` is clean and at that commit.
- `scripts/harness/verify-pins.sh` passes.
- `scripts/harness/doctor.sh` passes in strict mode.
- `lake build` succeeds without relying on dirty dependency files.
- Phase 1 review artifacts exist and contain fresh evidence.
