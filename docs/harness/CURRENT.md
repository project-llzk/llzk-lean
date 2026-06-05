# Current Harness State

Last reviewed: 2026-06-05

## Active Phase

- Active phase: Phase 0, harness reset.
- Phase bootstrap file: `docs/phases/PHASE-00-harness-reset.md`.
- Companion repository: `../veir`.
- Companion phase file: `../veir/docs/phases/PHASE-00-harness-reset.md`.

## Refs

- llzk-lean bootstrap HEAD: `ea2363f87bcc`.
- Workspace VeIR bootstrap HEAD: `4b0978bddec0`.
- Lake `VeIR` dependency pin: `09d5f00f0d2b4a8710afbe53dfdd7cf468578a04`.
- Lake `VeIR` dependency checkout observed at: `09d5f00f0d2b`.

These refs are Phase 0 bootstrap inputs, not a self-referential pin on the
commit that contains this file. The doctor reports repository HEAD drift from
these inputs as a warning. Dependency pin mismatches and hidden dirty dependency
state remain hard failures. If a later phase relies on a newer ref for a
semantic claim, update this file, `docs/harness/SOURCES.md`, and review
evidence before treating that claim as current.

## Dependency Mode

The Lake dependency checkout `.lake/packages/VeIR` is dirty at bootstrap:

- `Veir/Passes/Felt/Combine.lean`
- `Veir/Passes/Felt/Proofs.lean`
- `Veir/Passes/Felt/RewriteLemmas.lean`

Strict harness runs fail on this state. Exploratory runs may continue with
`--mode exploratory`, but exploratory output is not release or acceptance
evidence.

## Known Hazards

- `differential/run-differential.sh` depends on `.lake/packages/VeIR` and
  `llzk-opt`. Missing `llzk-opt` is a tool skip, not a differential pass.
- The certificate checker smoke gate validates schema, theorem metadata,
  loader behavior, and dispatch tests from source when CMake/CTest or `g++` is
  available. Existing `checker/build` binaries are not used unless
  `CERT_SMOKE_ALLOW_PREBUILT=1` is set. Real MLIR-backed matching remains
  absent while `DefaultMatcher` is TODO/fail-closed.
- Strategy docs under `docs/` predate Phase 0. They are design context, not
  acceptance evidence unless `docs/harness/SOURCES.md` revalidates a claim.
- CI warnings about skipped external tooling do not count as Strategy A or
  Strategy E coverage.

## Acceptance Rule

Phase 0 is current only when:

- `scripts/harness/doctor.sh` fails in strict mode on the known dirty
  dependency and prints exact files.
- `scripts/harness/doctor.sh --mode exploratory` passes while reporting the
  same dirty dependency.
- `scripts/harness/check-doc-freshness.sh` passes.
- `scripts/harness/validate-skills.sh` passes.
- `scripts/harness/diff-smoke.sh` and `scripts/harness/cert-smoke.sh` report
  precise status without claiming skipped or absent tooling as coverage.
