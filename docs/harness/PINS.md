# Dependency Pins

Last reviewed: 2026-06-06

## Accepted VeIR Pin

- Commit: `d4cc1bf2d31beeca17eb2e8c9c7181d04af013a3`
- Short ref: `d4cc1bf2d31b`
- Remote: `https://github.com/project-llzk/veir.git`
- Branch at selection time: `felt-review-structural-close`
- Mode: remote commit pinned through Lake metadata and a clean Lake package
  checkout

This commit is a descendant of the Phase 1 accepted pin
`d52917ca4a57c4094b1aa61dd413aca4e1c2a56e`, which was itself a descendant of
the previous Lake pin `09d5f00f0d2b4a8710afbe53dfdd7cf468578a04`.

This pin includes the Phase 2 VeIR field-registry update and source-truth gate.

## Required State

The following must all identify the accepted commit:

- `lakefile.toml` `git` and `rev`
- `lake-manifest.json` `url`, `type`, `rev`, and `inputRev`
- `.lake/packages/VeIR` HEAD

`git -C .lake/packages/VeIR status --short` must be empty.

## Allowed Modes

- Strict acceptance: Lake files and dependency checkout all match the accepted
  commit, the dependency checkout is clean, and any supplied `../veir`
  workspace either points at the accepted commit or is a descendant used only
  for repo-local metadata. The dependency checkout remains the source of truth.
- Local layout: `scripts/harness/doctor.sh` may run without `--workspace-veir`
  and emit a warning. This is useful for local checks but is not full
  acceptance evidence.
- Exploratory workspace: `scripts/harness/verify-pins.sh --mode exploratory
  --workspace-veir PATH` may warn about a workspace mismatch. This output must
  not be used to close Phase 2.

## Forbidden Hidden State

Do not rely on:

- Modified, staged, deleted, or untracked files under `.lake/packages/VeIR`.
- Local commits in `.lake/packages/VeIR` that are not the recorded accepted
  commit.
- A workspace path override as the source of truth.
- `lake update` output that changes the VeIR rev without a deliberate review
  evidence update.

## Update Procedure

1. Select a new VeIR commit and verify that it is available from the accepted
   remote.
2. Record the branch, remote, and exact commit under `docs/harness/SOURCES.md`
   and Phase review evidence.
3. Update `lakefile.toml` and `lake-manifest.json` to the exact commit.
4. Refresh `.lake/packages/VeIR` to that commit and ensure it is clean.
5. Run `scripts/harness/verify-pins.sh --workspace-veir ../veir`.
6. Run `lake build`.
7. Record all command output under `reviews/PHASE-XX/evidence/`.

## Rollback Procedure

1. Restore `lakefile.toml` and `lake-manifest.json` to the previous accepted
   commit.
2. Refresh `.lake/packages/VeIR` to that commit.
3. Confirm `git -C .lake/packages/VeIR status --short` is empty.
4. Re-run `scripts/harness/verify-pins.sh --workspace-veir ../veir` and
   `lake build`.
5. Record the rollback evidence and disposition the reason for rollback.
