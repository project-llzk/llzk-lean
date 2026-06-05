# Harness Gates

Last reviewed: 2026-06-05

## Gate Inventory

| Gate | Command | Expected Phase 0 behavior | What it proves |
|---|---|---|---|
| Strict doctor | `scripts/harness/doctor.sh` | Fails while `.lake/packages/VeIR` is dirty | Dirty dependency state is not hidden |
| Exploratory doctor | `scripts/harness/doctor.sh --mode exploratory` | Passes with warnings when only repo HEAD or dirty dependency state differs from bootstrap inputs | Local investigation can continue with explicit dependency state |
| Workspace doctor | `scripts/harness/doctor.sh --mode exploratory --workspace-veir ../veir` | Passes with warnings if workspace VeIR differs from the bootstrap input | Companion repo state is explicit |
| Doc freshness | `scripts/harness/check-doc-freshness.sh` | Passes when canonical docs and review disposition exist | Phase metadata and review state are present |
| Differential smoke | `scripts/harness/diff-smoke.sh` | Exits 0 on real pass, 77 on missing `llzk-opt`, 1 on divergence, 2 on tool/parse/pass failure | Strategy A smoke status is classified |
| Certificate smoke | `scripts/harness/cert-smoke.sh` | Builds checker smoke binaries from source via CMake/CTest or direct `g++`, passes loader/schema smoke, and reports MLIR matcher active or absent | Strategy E smoke status is classified without pretending MLIR matching exists |
| Prebuilt certificate smoke | `CERT_SMOKE_ALLOW_PREBUILT=1 scripts/harness/cert-smoke.sh` | Uses existing `checker/build` binaries only when source-build tools are unavailable | Prebuilt evidence is explicit and not confused with source-build evidence |
| Skill validation | `scripts/harness/validate-skills.sh` | Passes when every repo-local skill has required sections | Repo-local skills are concise and auditable |

## Non-Claims

Phase 0 does not prove:

- Felt semantic parity.
- Complete differential corpus coverage.
- Runtime LLZK rewrite verification.
- Full Lean proof audit.
- CI coverage when external tooling is missing.
