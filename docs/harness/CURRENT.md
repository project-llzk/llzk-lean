# Current Harness State

Last reviewed: 2026-06-06

## Active Phase

- Active phase: Phase 2, LLZK source truth and field registry parity.
- Phase bootstrap file: `docs/phases/PHASE-02-llzk-source-truth.md`.
- Companion repository: `../veir`.
- Companion phase file: `../veir/docs/phases/PHASE-02-llzk-source-truth.md`.

## Accepted VeIR Pin

- Accepted VeIR commit:
  `d4cc1bf2d31beeca17eb2e8c9c7181d04af013a3`.
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
- Strategy A and Strategy E smoke gates still classify their own tool status,
  but Phase 1 does not make new semantic, differential, or certificate
  acceptance claims.
- The local `../llzk-lib` worktree is behind fetched `origin/main`. Current
  Phase 2 source claims use `git show origin/main:...` at
  `db922857bc5a88a9107627ef6b36a8b5e57bc5c2`, not stale worktree files.

## Acceptance Rule

Phase 2 is current only when:

- `scripts/harness/verify-llzk-source.sh --llzk-lib ../llzk-lib` passes.
- `scripts/harness/verify-pins.sh --workspace-veir ../veir` passes.
- `scripts/harness/doctor.sh --workspace-veir ../veir` passes in strict mode.
- `lake build` succeeds against the clean dependency checkout.
- `scripts/harness/check-doc-freshness.sh` passes.
- `scripts/harness/validate-skills.sh` passes.
