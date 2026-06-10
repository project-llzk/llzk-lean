# Current Harness State

Last reviewed: 2026-06-10

## Active Phase

- Active phase: Phase 6, Strategy A divergence burn-down.
- Phase bootstrap file: `docs/phases/PHASE-06-strategy-a-divergence-burndown.md`.
- Companion repository: `../veir`.
- Companion phase file: `../veir/docs/phases/PHASE-06-strategy-a-divergence-burndown.md`.

## Accepted VeIR Pin

- Accepted VeIR commit:
  `a0bb2fc8e6d38ab068247dfc6506ba63f5feb953`.
- Accepted source branch: `felt-review-structural-close`.
- Accepted source remote: `https://github.com/project-llzk/veir.git`.
- Pin mode: remote commit, consumed through Lake metadata and a clean
  `.lake/packages/VeIR` checkout.

## Accepted LLZK Source

- Accepted `llzk-lib` commit:
  `db922857bc5a88a9107627ef6b36a8b5e57bc5c2`.
- Accepted source ref: `origin/main`.
- Accepted source checkout: `../llzk-lib`.
- Source ledger: `docs/harness/LLZK_SOURCE.md`.
- Operation gap ledger: `docs/harness/FELT_OP_GAPS.md`.

## Strategy A Test Infrastructure

- Accepted local `llzk-opt` binary:
  `/nix/store/awcw2wiypa02sl5vx4xm06qwji68xz3h-llzk-debug-2.0.0/bin/llzk-opt`.
- Local LLVM/MLIR checkout: `/home/alh/llvm-project`.
- LLVM checkout commit:
  `49f12af164138123589263fe75ea5f1d356e8780`.
- LLVM tools available:
  `/home/alh/llvm-project/build/bin/mlir-opt` and
  `/home/alh/llvm-project/build/bin/llvm-config`, both reporting
  `23.0.0git`.

## Refs

- llzk-lean Phase 1 bootstrap HEAD:
  `336a5a221ae79d00e5d1346e09341232bdc4323d`.
- Workspace VeIR Phase 1 bootstrap HEAD:
  `039068b68552bb37f1a887ec509e9b9111d4d54a`.
- llzk-lean implementation HEAD when Phase 1 started locally:
  `6b4a7ec3aa38e2da7e1de23fb347b5c2cbac6386`.
- Workspace VeIR implementation HEAD when Phase 1 started locally:
  `d4cc1bf2d31beeca17eb2e8c9c7181d04af013a3`.

The bootstrap refs are historical inputs from the phase file. The accepted
VeIR pin above is the dependency state this repository is allowed to treat as
acceptance evidence.

## Dependency Policy

`lakefile.toml`, `lake-manifest.json`, and `.lake/packages/VeIR` must all name
the accepted VeIR commit. The dependency checkout must be clean.

Dirty files under `.lake/packages/VeIR`, local patches, stashes, or a workspace
path override are not acceptance evidence. A workspace VeIR descendant may be
reported as context when repo-local metadata has moved past the accepted pin;
the clean dependency checkout remains the source of truth.

## Known Hazards

- The Phase 1 bootstrap state included a dirty dependency checkout containing
  partial Felt proof cleanup. That state is preserved under
  `reviews/PHASE-01/evidence/` and must not be relied on after the pin is
  refreshed.
- Strategy A and Strategy E smoke gates still classify their own tool status.
  Phase 4 reviewed workspace canonicalization evidence for the seed corpus.
  Phase 5 consumed the canonicalization-aware VeIR driver through the clean
  dependency pin and recorded the expanded 21-input canonical corpus on that
  path. Phase 6 starts from that exact-polarity baseline and has reclassified
  the DCE-only registered add/sub/mul fold cases after the clean VeIR driver
  began running `felt-combine,dce`. The corpus covers all 15 current VeIR Felt
  rewrite-pattern definitions as PASS or EXPECTED-DIVERGE, plus one
  EXPECTED-LLZK-FAIL parser/verifier gap, but this is not full Strategy A
  acceptance.
- The local `../llzk-lib` worktree is behind fetched `origin/main`. Current
  source claims use `git show origin/main:...` at
  `db922857bc5a88a9107627ef6b36a8b5e57bc5c2`, not stale worktree files.
- Phase 3 closed the operation-gap ledger. Phase 4 added seed canonical
  differential coverage through a workspace `VEIR_DIFF` override. Phase 5 pinned
  the canonicalization-aware VeIR driver, recorded expanded corpus evidence on
  the clean dependency path, and fixed expected-divergence polarity to exact
  file-header markers. Phase 6's first burn-down target aligns VeIR's canonical
  diff path with LLZK's dead-input cleanup by consuming the DCE-enabled VeIR
  pin.

## Acceptance Rule

Phase 6 bootstrap is current only when:

- `docs/harness/FELT_OP_GAPS.md` records every accepted LLZK Felt mnemonic and
  explicitly marks unsupported Strategy A/E coverage as gaps.
- `docs/phases/PHASE-06-strategy-a-divergence-burndown.md` exists and
  `docs/harness/CURRENT.md` names Phase 6 as active.
- `docs/harness/SOURCES.md` records `differential/run-differential.sh`, the
  Phase 6 phase file, Phase 5 exact-polarity guard evidence, the accepted
  `llzk-opt` binary path, and `/home/alh/llvm-project`.
- `scripts/harness/verify-llzk-source.sh --llzk-lib ../llzk-lib` passes.
- `scripts/harness/verify-pins.sh --workspace-veir ../veir` passes.
- `scripts/harness/doctor.sh --workspace-veir ../veir` passes in strict mode.
- `lake build` succeeds against the clean dependency checkout.
- `scripts/harness/check-doc-freshness.sh` passes.
- `scripts/harness/validate-skills.sh` passes.

Phase 6 implementation evidence additionally requires reducing or reclassifying
expected divergences without weakening the clean-pin canonical baseline. The
current clean-pin canonical run remains `21 pass (incl. expected-diverge), 0
fail` and records 7 PASS cases, 13 `EXPECTED-DIVERGE` canonical cases, and 1
`EXPECTED-LLZK-FAIL` parser/verifier gap.
