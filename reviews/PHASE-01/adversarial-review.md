# Phase 1 Adversarial Review

Repository: llzk-lean

## Checks

- Dirty dependency rejection: `scripts/harness/verify-pins.sh --workspace-veir
  ../veir` was run before cleanup and failed while the dependency checkout was
  dirty and Lake files still named the old pin.
- Clean dependency acceptance: the same command was run after cleanup and
  passed only after `lakefile.toml`, `lake-manifest.json`, and
  `.lake/packages/VeIR` agreed on
  `d52917ca4a57c4094b1aa61dd413aca4e1c2a56e`.
- Source spoof rejection: a temp-copy Lakefile and manifest with the accepted
  commit but a non-canonical VeIR URL was rejected.
- Manifest inputRev rejection: a temp-copy manifest with accepted `rev` but
  stale `inputRev` was rejected.
- Build check: `lake build` was run after the dependency refresh to ensure the
  accepted pin is buildable without hidden local dependency edits.

## Result

The dirty `.lake/packages/VeIR` proof state was rejected as acceptance evidence.
The accepted Phase 1 state is the clean remote VeIR commit recorded in
`docs/harness/PINS.md`.
