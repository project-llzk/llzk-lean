# Phase 0 Findings

Reviewed: 2026-06-05
Repository: llzk-lean

## Findings

### L-P0-001: Dirty Lake dependency can hide proof state

Severity: Critical

`.lake/packages/VeIR` is dirty at bootstrap. Any review that relies only on
`lakefile.toml` or `lake-manifest.json` would miss local modifications to proof
and rewrite files.

Evidence:

- `reviews/PHASE-00/evidence/dependency-status.txt`

### L-P0-002: Differential smoke must not count missing llzk-opt as pass

Severity: High

Strategy A depends on `llzk-opt`. Missing `llzk-opt` must be classified as a
tool skip or missing-tool status, not as differential agreement.

Evidence:

- `reviews/PHASE-00/evidence/diff-smoke.txt`

### L-P0-003: Certificate checker smoke does not prove MLIR rewrite matching

Severity: Medium

The checker loader and schema tests are meaningful, but `DefaultMatcher` still
contains W4B TODOs. Phase 0 must report MLIR matcher absence rather than
claiming runtime LLZK rewrite verification.

Evidence:

- `reviews/PHASE-00/evidence/cert-smoke.txt`

### L-P0-004: Certificate smoke must not silently trust stale build artifacts

Severity: High

The first Phase 0 `cert-smoke.sh` fallback used existing
`checker/build/{test_loader,llzk-lean-check}` binaries when CMake/CTest were
unavailable. Those binaries may be stale relative to the edited source, so they
are weak evidence unless explicitly requested.

Evidence:

- `reviews/PHASE-00/evidence/cert-smoke.txt`
