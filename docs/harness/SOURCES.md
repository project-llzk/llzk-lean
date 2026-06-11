# Source Ledger

Last reviewed: 2026-06-10

## Trusted Local Sources

| Source | Ref or retrieval | Use |
|---|---:|---|
| `docs/phases/PHASE-01-pins-and-repro.md` | local file, 2026-06-05 | Phase 1 objective, artifacts, gates, done criteria |
| Accepted VeIR pin | `d899d95004d4bd988c8456d686c33b11a7a5eb4a` | Dependency commit consumed by llzk-lean |
| Accepted VeIR branch | `felt-review-structural-close` | Remote branch containing the accepted commit |
| Accepted VeIR remote | `https://github.com/project-llzk/veir.git` | Canonical source repository for the accepted pin |
| `lakefile.toml` | local file, 2026-06-05 | Declared `VeIR` dependency pin |
| `lake-manifest.json` | local file, 2026-06-05 | Resolved `VeIR` dependency pin |
| `.lake/packages/VeIR` | clean checkout at accepted pin | Actual dependency state used by `lake build` |
| `scripts/harness/verify-pins.sh` | local file, 2026-06-05 | Phase 1 pin agreement and cleanliness gate |
| `scripts/harness/doctor.sh` | local file, 2026-06-05 | Strict harness wrapper around pin and layout gates |
| `docs/phases/PHASE-02-llzk-source-truth.md` | local file, 2026-06-06 | Phase 2 source-truth objective, artifacts, gates, and done criteria |
| `docs/harness/LLZK_SOURCE.md` | local file, 2026-06-06 | Accepted LLZK Felt source ledger |
| Accepted LLZK source commit | `db922857bc5a88a9107627ef6b36a8b5e57bc5c2` | Exact `llzk-lib` source commit for Phase 2 Felt source facts |
| Accepted LLZK source remote | `git@github.com:project-llzk/llzk-lib.git` | Canonical local source remote for the accepted LLZK source ref |
| Accepted LLZK source ref | `../llzk-lib origin/main` | Fetched source ref selected for Phase 2 |
| Accepted LLZK field registry | `lib/Util/Field.cpp` at `db922857bc5a88a9107627ef6b36a8b5e57bc5c2` | Built-in field registry facts |
| Accepted LLZK Felt ops | `include/llzk/Dialect/Felt/IR/Ops.td` at `db922857bc5a88a9107627ef6b36a8b5e57bc5c2` | Felt op mnemonic ledger |
| `scripts/harness/verify-llzk-source.sh` | local file, 2026-06-06 | Phase 2 LLZK source-truth gate |
| `docs/phases/PHASE-03-felt-op-gap-ledger.md` | local file, 2026-06-06 | Phase 3 operation-gap objective, artifacts, gates, and done criteria |
| `docs/harness/FELT_OP_GAPS.md` | local file, 2026-06-06 | Phase 3 accepted Felt operation coverage and gap ledger |
| `docs/phases/PHASE-04-strategy-a-differential.md` | local file, 2026-06-09 | Phase 4 Strategy A differential objective, artifacts, gates, and done criteria |
| `docs/phases/PHASE-05-strategy-a-pin-and-corpus.md` | local file, 2026-06-10 | Completed Phase 5 clean-pin consumption and corpus-expansion objective, artifacts, gates, and done criteria |
| `docs/phases/PHASE-06-strategy-a-divergence-burndown.md` | local file, 2026-06-10 | Completed Phase 6 divergence burn-down objective, artifacts, gates, and done criteria |
| `docs/phases/PHASE-07-strategy-a-modular-reduction.md` | local file, 2026-06-10 | Completed Phase 7 registered-field modular-reduction objective, artifacts, gates, and done criteria |
| `docs/phases/PHASE-08-strategy-a-field-preconditions.md` | local file, 2026-06-10 | Active Phase 8 field-precondition objective, artifacts, gates, and done criteria |
| `differential/run-differential.sh` | local file, 2026-06-09 | llzk-lean corpus wrapper around the consumed VeIR diff script |
| `differential/corpus/` | local files, 2026-06-09 | Current Strategy A corpus and expected-divergence classification |
| Consumed VeIR `scripts/llzk-diff.sh` | `.lake/packages/VeIR/scripts/llzk-diff.sh` at accepted pin | Default clean dependency driver with canonicalization support; Phase 6 canonical mode runs `felt-combine,dce`, the accepted Phase 7 pin includes registered-field fold-result reduction, and the accepted Phase 8 pin skips folds whose field name does not resolve |
| Workspace VeIR `scripts/llzk-diff.sh` | `../veir/scripts/llzk-diff.sh`, local file, 2026-06-09 | Phase 4 canonicalization-aware driver used explicitly through `VEIR_DIFF=../veir/scripts/llzk-diff.sh` |
| Phase 4 canonical differential evidence | `reviews/PHASE-04/evidence/differential-canonicalize.txt` | Reviewed workspace Strategy A seed evidence; not clean-pin acceptance |
| Phase 4 fresh adversarial review evidence | `reviews/PHASE-04/evidence/adversarial-review-fresh.txt` | Confirms Phase 4 wrapper findings were resolved before Phase 5 |
| Phase 5 clean-pin canonical differential evidence | `reviews/PHASE-05/evidence/differential-clean-pin-canonicalize.txt` | Expanded corpus canonical run through the default clean dependency driver |
| Phase 5 exact-polarity guard evidence | `reviews/PHASE-05/evidence/polarity-guard.txt` | Proves a canonical `EXPECTED-DIVERGE` input fails on the wrong LLZK failure mode |
| Phase 6 review workspace | `reviews/PHASE-06/` | Completed Phase 6 request, findings, disposition, adversarial review, implementation evidence, and burn-down disposition |
| Phase 7 review workspace | `reviews/PHASE-07/` | Completed Phase 7 request, findings, disposition, adversarial review, implementation evidence, and modular-reduction target |
| Phase 8 review workspace | `reviews/PHASE-08/` | Active Phase 8 request, findings, disposition, adversarial review, implementation evidence, and field-precondition target |
| Accepted local `llzk-opt` binary | `/nix/store/awcw2wiypa02sl5vx4xm06qwji68xz3h-llzk-debug-2.0.0/bin/llzk-opt` | LLZK executable for Strategy A differential testing |
| Local LLVM/MLIR checkout | `/home/alh/llvm-project` at `49f12af164138123589263fe75ea5f1d356e8780` | Source and build tree for local MLIR/LLVM testing support |
| Local `mlir-opt` | `/home/alh/llvm-project/build/bin/mlir-opt`, version `23.0.0git` | Local MLIR tool available for Strategy A testing |
| Local `llvm-config` | `/home/alh/llvm-project/build/bin/llvm-config`, version `23.0.0git` | Local LLVM configuration tool available for Strategy A testing |

Evidence for the dirty bootstrap state and the refreshed clean state is
captured under `reviews/PHASE-01/evidence/`.

## External Sources

The accepted remote branch was checked with `git ls-remote origin
refs/heads/felt-review-structural-close` from the VeIR repository and recorded
under `../veir/reviews/PHASE-01/evidence/accepted-remote-branch.txt`.

No web page, issue, or mutable branch name is trusted without the exact commit
hash above. For LLZK source facts, `origin/main` is accepted only through the
exact commit `db922857bc5a88a9107627ef6b36a8b5e57bc5c2` and the recorded
`project-llzk/llzk-lib` origin remote.

The local LLVM checkout is used as test infrastructure, not as source truth for
LLZK or VeIR semantics.

## Contextual Non-Canonical Material

These files remain design and review context, not Phase 1 pin evidence unless a
specific claim is revalidated against the accepted commit and recorded under
Phase 1 evidence:

- `README.md`
- `docs/README.md`
- `docs/strategy-a-oracle.md`
- `docs/strategy-e-certificates.md`
- `docs/future-*.md`
- `docs/REVIEW.md`
- `.github/workflows/*.yml`
- Historical references to `llzkfelt_test1` in archived evidence or old notes
- Local `../llzk-lib` worktree files while the worktree remains at
  `30b0fa1eb77de154ff60c13fa88ef286d8b01c65`
