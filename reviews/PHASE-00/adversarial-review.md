# Adversarial Review Refresh

Reviewed: 2026-06-05
Repository: llzk-lean

## Scope

This refresh reviewed every Phase 0 artifact added or changed in this session:

- `AGENTS.md`
- `docs/harness/*.md`
- `docs/phases/*.md`
- `scripts/harness/*.sh`
- `differential/run-differential.sh`
- `skills/*/SKILL.md`
- `reviews/PHASE-00/*`

## Review Questions

- Can dirty `.lake/packages/VeIR` state be hidden by any strict gate?
- Do differential smoke failures distinguish missing tools from semantic
  divergence?
- Does certificate smoke build or identify its checker binary source clearly?
- Do canonical docs distinguish schema/loader evidence from MLIR matcher
  evidence?
- Are stale historical strategy docs marked as context rather than acceptance
  evidence?

## New Findings From Refresh

- L-P0-004 was added: the first certificate smoke fallback could rely on
  existing `checker/build` binaries when CMake/CTest were unavailable.
- `scripts/harness/cert-smoke.sh` now builds from source via CMake/CTest or
  direct `g++`. Prebuilt binaries require `CERT_SMOKE_ALLOW_PREBUILT=1`.
- `scripts/harness/check-doc-freshness.sh` now checks all canonical harness
  review dates and required evidence files.

## Residual Risk

`llzk-opt` is not available in this environment, so Strategy A differential
smoke records missing-tool status with exit 77. MLIR-backed certificate matching
is still absent and explicitly reported by the smoke gate.
