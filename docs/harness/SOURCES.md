# Source Ledger

Last reviewed: 2026-06-05

## Trusted Local Sources

| Source | Ref or retrieval | Use |
|---|---:|---|
| `docs/phases/PHASE-00-harness-reset.md` | local file, 2026-06-05 | Phase 0 objective, artifacts, gates, done criteria |
| llzk-lean repository HEAD | `ea2363f87bcc` | Bootstrap llzk-lean source state |
| Workspace VeIR repository HEAD | `4b0978bddec0` | Companion source state |
| `lakefile.toml` | local file, 2026-06-05 | Declared `VeIR` dependency pin |
| `lake-manifest.json` | local file, 2026-06-05 | Resolved `VeIR` dependency pin |
| `.lake/packages/VeIR` | `09d5f00f0d2b`, dirty | Actual dependency checkout state |
| `differential/run-differential.sh` | local file, 2026-06-05 | Strategy A wrapper behavior |
| `checker/CMakeLists.txt` | local file, 2026-06-05 | Strategy E CMake build/test surface |
| `checker/src/CertChecker.cpp` | local file, 2026-06-05 | MLIR matcher status |
| `checker/tests/test_loader.cpp` | local file, 2026-06-05 | Certificate loader and dispatch smoke tests |
| `checker/bin/llzk_lean_check.cpp` | local file, 2026-06-05 | Certificate summary driver smoke test |
| `certs/felt-combine.cert.json` | local file, 2026-06-05 | Certificate schema and theorem metadata smoke input |

Evidence for the bootstrap state is captured under
`reviews/PHASE-00/evidence/`.

## External Sources

No external web source is trusted as canonical for Phase 0. Future phases may
add upstream LLZK, MLIR, Lean, or GitHub Actions references, but each must list
an exact URL or commit and retrieval date here.

## Stale Historical Material

These files are design context, not Phase 0 acceptance evidence unless a claim
is revalidated against current refs:

- `README.md`
- `docs/README.md`
- `docs/strategy-a-oracle.md`
- `docs/strategy-e-certificates.md`
- `docs/future-*.md`
- `docs/REVIEW.md`
- `.github/workflows/differential.yml`
- `.github/workflows/certify.yml`
- Historical references to `llzkfelt_test1` and dates before 2026-06-05

When using any of these, cite the exact local file and explain whether the claim
was revalidated.
