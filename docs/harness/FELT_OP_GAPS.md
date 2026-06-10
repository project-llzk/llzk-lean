# Felt Operation Gap Ledger

Last reviewed: 2026-06-10

## Source Basis

- Accepted LLZK source ledger: `docs/harness/LLZK_SOURCE.md`.
- Accepted LLZK source commit:
  `db922857bc5a88a9107627ef6b36a8b5e57bc5c2`.
- Accepted LLZK source remote:
  `git@github.com:project-llzk/llzk-lib.git`.
- Consumed VeIR dependency:
  `.lake/packages/VeIR` at
  `220cd215579b435c3c22ce86b34a3f4ce2ca276e`.
- Current certificate catalog:
  `LlzkLean/Cert.lean` and `certs/felt-combine.cert.json`.
- Current differential corpus:
  `differential/corpus/`.

## Phase 3 Rule

This ledger is not a Strategy A or Strategy E acceptance claim. It is the
current gap map that a future implementation phase must use before adding
corpus inputs, certificates, or checker behavior.

Any row that moves from `gap` to `covered` must have source evidence, a build,
and an adversarial review disposition.

## Current Operation Coverage

| LLZK mnemonic | Consumed VeIR semantic status | Strategy A differential status | Strategy E certificate status | Phase 3 status |
|---|---|---|---|---|
| `const` | Covered baseline in `Data.Felt.const` and `InterpModel.interpretConst` | Smoke corpus only; no acceptance claim | Used by existing cert shapes | Covered baseline |
| `add` | Covered baseline in `Data.Felt.add` and `InterpModel.interpretAdd` | Smoke corpus only; no acceptance claim | `right_identity_zero_add` and `constant_fold_add` certs exist | Covered with known LLZK modular-reduction caveat |
| `sub` | Covered baseline in `Data.Felt.sub` and `InterpModel.interpretSub` | No complete accepted corpus coverage | No committed cert yet for existing VeIR sub rewrites | Gap in Strategy A/E coverage |
| `mul` | Covered baseline in `Data.Felt.mul` and `InterpModel.interpretMul` | No complete accepted corpus coverage | No committed cert yet for existing VeIR mul rewrites | Gap in Strategy A/E coverage |
| `neg` | Covered baseline in `Data.Felt.neg` and `InterpModel.interpretNeg` | No complete accepted corpus coverage | No committed cert yet for existing VeIR neg rewrites | Gap in Strategy A/E coverage |
| `pow` | Missing from consumed VeIR `Data.Felt` and `InterpModel` | No complete accepted corpus coverage | No committed cert | Gap |
| `div` | Missing from consumed VeIR `Data.Felt` and `InterpModel` | No complete accepted corpus coverage | No committed cert | Gap |
| `uintdiv` | Missing from consumed VeIR `Data.Felt` and `InterpModel` | No complete accepted corpus coverage | No committed cert | Gap |
| `sintdiv` | Missing from consumed VeIR `Data.Felt` and `InterpModel` | No complete accepted corpus coverage | No committed cert | Gap |
| `umod` | Missing from consumed VeIR `Data.Felt` and `InterpModel` | No complete accepted corpus coverage | No committed cert | Gap |
| `smod` | Missing from consumed VeIR `Data.Felt` and `InterpModel` | No complete accepted corpus coverage | No committed cert | Gap |
| `inv` | Missing from consumed VeIR `Data.Felt` and `InterpModel` | No complete accepted corpus coverage | No committed cert | Gap |
| `bit_and` | Missing from consumed VeIR `Data.Felt` and `InterpModel` | No complete accepted corpus coverage | No committed cert | Gap |
| `bit_or` | Missing from consumed VeIR `Data.Felt` and `InterpModel` | No complete accepted corpus coverage | No committed cert | Gap |
| `bit_xor` | Missing from consumed VeIR `Data.Felt` and `InterpModel` | No complete accepted corpus coverage | No committed cert | Gap |
| `bit_not` | Missing from consumed VeIR `Data.Felt` and `InterpModel` | No complete accepted corpus coverage | No committed cert | Gap |
| `shl` | Missing from consumed VeIR `Data.Felt` and `InterpModel` | No complete accepted corpus coverage | No committed cert | Gap |
| `shr` | Missing from consumed VeIR `Data.Felt` and `InterpModel` | No complete accepted corpus coverage | No committed cert | Gap |

## Known Constraints

- `lake build` reports 15 VeIR Felt rewrite patterns, with 2 covered by the
  current certificate catalog and 13 intentionally uncovered today.
- `scripts/harness/diff-smoke.sh` classifies missing `llzk-opt` as exit 77 in
  this environment. That is not differential acceptance.
- The Strategy E checker still lacks the runtime MLIR matcher, so existing
  certificates prove schema/catalog consistency, not end-to-end LLZK rewrite
  acceptance.
- Phase 3 may refine this ledger and its gates, but must not mark a gap covered
  without source evidence and review disposition.
