# Phase 0 Disposition

Reviewed: 2026-06-05
Repository: llzk-lean

## Disposition

- L-P0-001: fixed. `scripts/harness/doctor.sh` fails in strict mode on dirty
  `.lake/packages/VeIR` state and reports exact files. Exploratory mode is
  explicit.
- L-P0-002: fixed. `scripts/harness/diff-smoke.sh` preflights `llzk-opt` and
  exits 77 for missing-tool status.
- L-P0-003: fixed. `scripts/harness/cert-smoke.sh` reports schema/loader
  status separately from MLIR matcher status.
- L-P0-004: fixed. `scripts/harness/cert-smoke.sh` now source-builds through
  CMake/CTest when available or direct `g++` otherwise. Prebuilt
  `checker/build` binaries require `CERT_SMOKE_ALLOW_PREBUILT=1` and are
  reported explicitly.
- L-P0-005: fixed. `scripts/harness/doctor.sh` now reports repository HEAD
  drift from bootstrap inputs as a warning. Dependency pin mismatches and dirty
  `.lake/packages/VeIR` state remain hard failures.
