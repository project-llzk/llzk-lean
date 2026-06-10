# Phase 5: Strategy A Pin and Corpus

Status: completed; superseded by Phase 6
Last reviewed: 2026-06-10
Repository: llzk-lean
Companion phase file: ../../../veir/docs/phases/PHASE-05-strategy-a-pin-and-corpus.md

## Objective

Bootstrap the next Strategy A workstream after the Phase 4 workspace
differential: consume the canonicalization-aware VeIR diff script through a
clean llzk-lean dependency pin, then expand the reviewed corpus toward the
Strategy A v1 bar.

This phase starts from Phase 4's seed evidence. Bootstrap did not change the
accepted VeIR pin or claim full Strategy A acceptance. Phase 5 execution now
selects a clean VeIR pin that contains the canonicalization-aware diff driver;
the clean-pin corpus now covers all 15 VeIR Felt rewrite-pattern definitions as
either positives or expected divergences.

## Starting State

- llzk-lean HEAD at Phase 5 bootstrap:
  `617702beadfbad6be784945e2bd98e8a788d357c`.
- Workspace VeIR HEAD at Phase 5 bootstrap:
  `0c5280de5715dc0fa518e7e3782e784a5962d4d8`.
- Consumed VeIR dependency pin at bootstrap:
  `d4cc1bf2d31beeca17eb2e8c9c7181d04af013a3`.
- Phase 5 clean-pin target:
  `220cd215579b435c3c22ce86b34a3f4ce2ca276e`.
- Accepted LLZK source commit remains:
  `db922857bc5a88a9107627ef6b36a8b5e57bc5c2`.
- Local `../llzk-lib` worktree remains stale at
  `30b0fa1eb77de154ff60c13fa88ef286d8b01c65`; source facts still use the
  accepted commit through `git show`.
- Phase 4 produced reviewed workspace evidence for:
  `LLZK_OPT=/nix/store/awcw2wiypa02sl5vx4xm06qwji68xz3h-llzk-debug-2.0.0/bin/llzk-opt VEIR_DIFF=../veir/scripts/llzk-diff.sh ./differential/run-differential.sh --canonicalize differential/corpus`.
- The default clean pinned VeIR dependency script now supports canonicalization,
  so `./differential/run-differential.sh --canonicalize ...` must run without a
  `VEIR_DIFF` workspace override.
- Current worktree is dirty from Phase 2/3 harness documentation, Phase 4
  differential implementation, and Phase 5 bootstrap docs. These are not pin
  acceptance evidence.

## Non-Goals

- Do not silently treat `VEIR_DIFF=../veir/scripts/llzk-diff.sh` as clean pin
  acceptance.
- Do not broaden the corpus by moving expected divergences to positives without
  a passing canonical run and review disposition.
- Do not implement missing VeIR Felt operations or Strategy E certificates in
  this phase bootstrap.
- Do not change the accepted LLZK source commit or field registry facts.

## Artifacts To Create Or Update

- `docs/phases/PHASE-05-strategy-a-pin-and-corpus.md`: Phase 5 bootstrap.
- `docs/harness/CURRENT.md`: move the active phase to Phase 5.
- `docs/harness/SOURCES.md`: record Phase 5, Phase 4 evidence, the default
  clean VeIR diff-script state, and local test infrastructure.
- `docs/harness/GATES.md`: document Phase 5 bootstrap and clean-pin Strategy A
  implementation gates.
- `lakefile.toml`, `lake-manifest.json`, and `.lake/packages/VeIR`: pin and
  consume the clean VeIR commit that carries canonical diff support.
- `scripts/harness/check-doc-freshness.sh`: require Phase 5 to be active while
  preserving Phase 2, Phase 3, and Phase 4 evidence checks.
- `scripts/harness/doctor.sh`: require Phase 5 docs and review workspace.
- `reviews/PHASE-05/{request.md,findings.md,disposition.md,adversarial-review.md,evidence/}`:
  Phase 5 review workspace.

## Gates To Implement

- Bootstrap freshness:
  `scripts/harness/check-doc-freshness.sh` passes only when Phase 5 is active,
  the Phase 5 review workspace exists, Phase 4 evidence remains present, and
  source ledgers record the Phase 5 target.
- Pin verification:
  `scripts/harness/verify-pins.sh --workspace-veir ../veir` passes with the
  clean dependency pin at `220cd215579b435c3c22ce86b34a3f4ce2ca276e`.
- Strict doctor:
  `scripts/harness/doctor.sh --workspace-veir ../veir` continues to pass.
- Build:
  `lake build` succeeds against the clean dependency checkout.
- Phase 5 implementation gate:
  after the pin bump, canonicalization must run through the default dependency
  path with no workspace override:
  `LLZK_OPT=/nix/store/awcw2wiypa02sl5vx4xm06qwji68xz3h-llzk-debug-2.0.0/bin/llzk-opt ./differential/run-differential.sh --canonicalize differential/corpus`.
  Clean-pin expanded corpus evidence covers the 15 VeIR Felt rewrite-pattern
  definitions and still separates passing cases from expected divergences.
  Reducing expected divergences and any future reclassification remain open
  Phase 5 work.

## Review Requirements

- The reviewer must verify that Phase 5 is scoped to clean pin consumption and
  corpus expansion, not general Strategy A acceptance.
- The reviewer must verify that docs distinguish workspace evidence from clean
  dependency evidence.
- The reviewer must verify that Phase 4 adversarial findings are closed before
  Phase 5 implementation work starts.
- The reviewer must verify that existing source-truth, pin, doctor, skill, and
  build gates still pass.
- Disposition every finding before closing the phase.

## Done Criteria

- Phase 5 bootstrap docs and review workspace exist in both llzk-lean and VeIR.
- `docs/harness/CURRENT.md` names Phase 5 as active.
- `docs/harness/SOURCES.md` records the Phase 5 phase file and Phase 4
  canonical differential evidence.
- `check-doc-freshness.sh`, `verify-llzk-source.sh`, `verify-pins.sh`,
  `doctor.sh`, `validate-skills.sh`, and `lake build` pass after the bootstrap.
- The clean VeIR pin consumes the canonicalization-aware diff script, and the
  clean-pin corpus matrix covers all 15 VeIR Felt rewrite-pattern definitions
  as either PASS or EXPECTED-DIVERGE under the canonicalized gate.
