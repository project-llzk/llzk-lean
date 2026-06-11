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

### L-P0-005: Doctor treated bootstrap commit refs as immutable current HEADs

Severity: High

After Phase 0 was committed, `scripts/harness/doctor.sh` failed in both strict
and exploratory mode because the current llzk-lean and workspace VeIR HEADs no
longer matched the pre-Phase-0 bootstrap refs. A committed script cannot
reliably require its repository HEAD to equal a literal hash stored inside that
same commit. The harness should report HEAD drift, while keeping dependency pin
and dirty-state checks as hard failures.

Evidence:

- Direct rerun of `scripts/harness/doctor.sh` on 2026-06-05 after the Phase 0
  commit.
