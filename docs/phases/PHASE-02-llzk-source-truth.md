# Phase 2: LLZK Source Truth And Field Registry Parity

Status: active
Last reviewed: 2026-06-06
Repository: llzk-lean
Companion phase file: ../../../veir/docs/phases/PHASE-02-llzk-source-truth.md

## Objective

Ground llzk-lean's Felt certificates, documentation, and checker assumptions in
a fresh LLZK Felt source ledger, and keep them aligned with the VeIR field
registry selected by Phase 2.

This phase does not make Strategy A or Strategy E complete. It ensures the
source facts those strategies depend on are current and mechanically checked.

## Starting State

- llzk-lean HEAD at Phase 2 bootstrap:
  `6b4a7ec3aa38e2da7e1de23fb347b5c2cbac6386`.
- Workspace VeIR HEAD at Phase 2 bootstrap:
  `d52917ca4a57c4094b1aa61dd413aca4e1c2a56e`.
- llzk-lean currently pins VeIR to:
  `d52917ca4a57c4094b1aa61dd413aca4e1c2a56e`.
- Local `llzk-lib` checkout after fetch:
  - local `main`: `30b0fa1eb77de154ff60c13fa88ef286d8b01c65`
  - fetched `origin/main`: `db922857bc5a88a9107627ef6b36a8b5e57bc5c2`
  - local checkout is behind `origin/main` and must not be treated as current
    source truth without an explicit checkout or `git show origin/main:...`.
- Fetched `llzk-lib origin/main` changes Felt source truth relative to local
  `main`:
  - `lib/Util/Field.cpp` separates `bn128`/`bn254` from `grumpkin`.
  - `include/llzk/Dialect/Felt/IR/Attrs.td` lists `grumpkin` as built-in.
  - `include/llzk/Dialect/Felt/IR/Ops.td` documents shift semantics.
- Current llzk-lean comments and checker TODOs mention built-in fields but do
  not yet have a Phase 2 source-ledger gate.

## Non-Goals

- Do not expand the certificate catalog beyond source-ledger maintenance.
- Do not implement the MLIR runtime matcher.
- Do not claim Strategy A differential acceptance.
- Do not port missing VeIR Felt operations.
- Do not use stale local `llzk-lib` files as source truth.

## Artifacts To Create Or Update

- `docs/harness/LLZK_SOURCE.md`: source ledger for accepted LLZK Felt files and
  exact source ref.
- `docs/harness/SOURCES.md`: add Phase 2 LLZK source refs.
- `docs/harness/GATES.md`: add source-truth gates.
- `docs/strategy-a-oracle.md`, `docs/strategy-e-certificates.md`,
  `LlzkLean/Cert.lean`, and checker comments as needed to remove stale field
  registry assumptions.
- `scripts/harness/verify-llzk-source.sh`: verify accepted LLZK source ref,
  Felt op set, and built-in field registry facts.
- `reviews/PHASE-02/{request.md,findings.md,disposition.md,evidence/}`:
  adversarial review workspace.

## Source Files To Ledger

Use `../llzk-lib` as the local repository, but use fetched `origin/main` as the
initial source truth until a newer source ref is deliberately selected.

- `include/llzk/Dialect/Felt/IR/Ops.td`
- `include/llzk/Dialect/Felt/IR/Types.td`
- `include/llzk/Dialect/Felt/IR/Attrs.td`
- `lib/Dialect/Felt/IR/Ops.cpp`
- `lib/Util/Field.cpp`
- `test/Dialect/Felt/*`

## Field Registry Target

The initial accepted LLZK source ref defines these built-in fields:

- `bn128`:
  `21888242871839275222246405745257275088548364400416034343698204186575808495617`
- `bn254`:
  `21888242871839275222246405745257275088548364400416034343698204186575808495617`
- `grumpkin`:
  `21888242871839275222246405745257275088696311157297823662689037894645226208583`
- `babybear`: `2013265921`
- `goldilocks`: `18446744069414584321`
- `mersenne31`: `2147483647`
- `koalabear`: `2130706433`

## Gates To Implement

- `scripts/harness/verify-llzk-source.sh --llzk-lib ../llzk-lib` fails if the
  accepted source ref is unavailable or unrecorded.
- The source gate checks the 18 Felt op mnemonics:
  `const`, `add`, `sub`, `mul`, `pow`, `div`, `uintdiv`, `sintdiv`, `umod`,
  `smod`, `neg`, `inv`, `bit_and`, `bit_or`, `bit_xor`, `bit_not`, `shl`,
  `shr`.
- The source gate checks the built-in field registry facts above.
- `scripts/harness/verify-pins.sh --workspace-veir ../veir` continues to pass.
- `lake build` succeeds after any documentation or certificate metadata
  updates.

## Review Requirements

- Every LLZK source claim must cite an exact `llzk-lib` commit and file path.
- Review evidence must include `git -C ../llzk-lib rev-parse HEAD origin/main`
  and source extraction output.
- The reviewer must explicitly reject stale local `llzk-lib` checkout facts
  unless they match the accepted source ref.
- The reviewer must confirm llzk-lean docs and checker comments include
  `grumpkin` and `koalabear` where they enumerate built-in fields.
- Disposition every finding before closing the phase.

## Done Criteria

- `docs/harness/LLZK_SOURCE.md` records the accepted LLZK Felt source ref and
  files.
- llzk-lean docs and checker assumptions match the accepted source ledger.
- A source-truth gate catches missing `grumpkin`, missing `koalabear`, or
  stale `bn128`/`bn254` registry facts.
- `scripts/harness/verify-pins.sh --workspace-veir ../veir` passes.
- `lake build` succeeds.
- Phase 2 review artifacts contain fresh adversarial evidence.
