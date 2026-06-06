# Harness Gates

Last reviewed: 2026-06-06

## Gate Inventory

| Gate | Command | Expected behavior | What it proves |
|---|---|---|---|
| LLZK source truth | `scripts/harness/verify-llzk-source.sh --llzk-lib ../llzk-lib` | Passes only when the accepted LLZK source commit is available, `origin/main` equals the accepted commit, the source ledger records the accepted commit, the accepted Felt op set matches the ledger, and checker registry comments enumerate the accepted built-ins | Phase 2 source facts are exact-ref based and certificate/checker comments match the LLZK source registry |
| Pin verification | `scripts/harness/verify-pins.sh --workspace-veir ../veir` | Passes only when Lake file URLs/revs, manifest `type`/`inputRev`, and dependency HEAD agree on the accepted commit, the dependency is clean, and workspace VeIR is either the accepted commit or a descendant used only for metadata context | llzk-lean is not relying on hidden `.lake/packages/VeIR` edits or a spoofed source |
| Strict doctor | `scripts/harness/doctor.sh --workspace-veir ../veir` | Passes after the pin gate and layout checks pass | Phase 1 harness state is complete and strict |
| Local doctor | `scripts/harness/doctor.sh` | Passes with a warning that workspace VeIR was not checked | Local layout is valid, but the run is not full acceptance evidence |
| Lake build | `lake build` | Builds against the clean accepted VeIR dependency | The selected pin is buildable by llzk-lean |
| Doc freshness | `scripts/harness/check-doc-freshness.sh` | Passes when Phase 1 docs and review evidence are present | Canonical phase metadata and evidence are current |
| Differential smoke | `scripts/harness/diff-smoke.sh` | Keeps smoke status classification behavior | Strategy A status remains classified without becoming a Phase 1 acceptance claim |
| Certificate smoke | `scripts/harness/cert-smoke.sh` | Keeps smoke status classification behavior | Strategy E status remains classified without becoming a Phase 1 acceptance claim |
| Skill validation | `scripts/harness/validate-skills.sh` | Passes when repo-local skills have required sections | Repo-local skills remain auditable |

## Reproducible-Pin Failures

## LLZK Source-Truth Failures

`scripts/harness/verify-llzk-source.sh --llzk-lib ../llzk-lib` must fail if:

- `../llzk-lib` is missing or not a git checkout.
- The accepted source commit
  `db922857bc5a88a9107627ef6b36a8b5e57bc5c2` is unavailable.
- `../llzk-lib origin/main` differs from the accepted source commit.
- `docs/harness/LLZK_SOURCE.md` does not record the accepted source commit or
  `lib/Util/Field.cpp`.
- `include/llzk/Dialect/Felt/IR/Ops.td` does not define the accepted 18-op
  Felt ledger: `const`, `add`, `sub`, `mul`, `pow`, `div`, `uintdiv`,
  `sintdiv`, `umod`, `smod`, `neg`, `inv`, `bit_and`, `bit_or`, `bit_xor`,
  `bit_not`, `shl`, `shr`.
- `lib/Util/Field.cpp::initKnownFields` does not define `bn128`, `bn254`,
  `grumpkin`, `babybear`, `goldilocks`, `mersenne31`, and `koalabear` as
  recorded in `docs/harness/LLZK_SOURCE.md`.
- Checker registry comments omit an accepted built-in field.

`scripts/harness/verify-pins.sh` must fail if:

- `lakefile.toml` and `lake-manifest.json` disagree.
- `lakefile.toml` or `lake-manifest.json` names a VeIR source URL other than
  `https://github.com/project-llzk/veir.git`.
- `lake-manifest.json` does not record VeIR as a `git` dependency.
- Either Lake file names a commit other than
  `d4cc1bf2d31beeca17eb2e8c9c7181d04af013a3`.
- `lake-manifest.json` records a VeIR `inputRev` other than
  `d4cc1bf2d31beeca17eb2e8c9c7181d04af013a3`.
- `.lake/packages/VeIR` HEAD differs from the manifest rev.
- `.lake/packages/VeIR` has any modified, deleted, staged, or untracked file.
- A supplied workspace VeIR path neither equals nor descends from the accepted
  rev in strict mode.

## Non-Claims

Phase 1 does not prove:

- Felt semantic parity.
- Complete differential corpus coverage.
- Runtime LLZK rewrite verification.
- Full Lean proof audit beyond buildability of the selected pin.
- CI coverage when external tooling is missing.
- Missing Felt operation semantics beyond the registry source facts. Phase 2
  does not port additional Felt operations.
