# Phase 9: Drop-In Roadmap And Claim Reset

Status: completed; superseded by Phase 10 bootstrap
Last reviewed: 2026-06-11
Repository: llzk-lean
Companion phase file: ../../../veir/docs/phases/PHASE-09-drop-in-roadmap.md

## Objective

Turn the post-Phase-8 state into a single drop-in replacement roadmap with
clear claims, repository responsibilities, profile boundaries, assumptions,
and trusted-base caveats.

This phase is documentation and planning work. It does not claim new Felt
operation coverage, new runtime certificate coverage, or a new accepted
differential baseline.

## Starting State

- llzk-lean HEAD at bootstrap:
  `aa0ceebf6952cd7027d889b5184dba4061687960`.
- Workspace VeIR HEAD at bootstrap:
  `42db1ae3cbe76ca6c917501acc8e92a4f01cbc75`.
- `project-llzk/veir#1` is merged into `main` at merge commit
  `45d31a20b4ff10498f7caba3c8b635553cc93dea`.
- `opencompl/veir#829` is closed unmerged.
- Phase 8 remains the last completed implementation milestone.
- The clean-pin canonical corpus remains
  `21 pass (incl. expected-diverge), 0 fail`.

## Claim Reset

- The active goal is a high-assurance replacement for the C++ LLZK Felt
  dialect path, not a full `llzk-opt` binary replacement.
- C++ parity is the adoption and debugging baseline.
- Enhanced VEIR is the improvement path. It may intentionally differ from C++
  LLZK when the difference is reviewed, covered, semantically justified, and
  downstream-compatible.
- Arithmetic identities are supporting lemmas only. Runtime claims must cite
  executable matchers, side conditions, result constructors, field registry
  behavior, and concrete runtime values.

## Non-Goals

- Do not mark Phase 9 as a new implementation acceptance phase.
- Do not update the clean VEIR dependency pin.
- Do not reclassify any `EXPECTED-DIVERGE` corpus case.
- Do not claim that the certificate route proves compiler equivalence.

## Artifacts Created Or Updated

- `docs/drop-in-roadmap.md`: canonical project-wide roadmap.
- `README.md` and `docs/README.md`: pointers to the roadmap.
- `docs/future-c-drop-in.md`: clarified as full `llzk-opt` replacement, not
  the current Felt-only target.
- `docs/strategy-e-certificates.md`: updated current proof-basis language.
- `docs/harness/SOURCES.md`: records the roadmap as planning context, not
  phase acceptance evidence.

## Gates

- Existing Phase 8 freshness gate must still pass unchanged.
- No new Phase 9 implementation gate exists.

## Done Criteria

- Both repos point to the roadmap.
- Profile policy distinguishes C++ parity from enhanced VEIR improvements.
- Public docs state the current non-claims and trusted-base assumptions.
- Phase 10 has a concrete bootstrap target.
