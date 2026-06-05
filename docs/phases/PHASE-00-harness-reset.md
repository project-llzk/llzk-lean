# Phase 0: Harness Reset

Status: bootstrap
Last reviewed: 2026-06-05
Repository: llzk-lean
Companion phase file: ../../../veir/docs/phases/PHASE-00-harness-reset.md

## Objective

Replace the current ad hoc agent documentation and review setup with a small,
repo-local harness that makes llzk-lean's dependency on VeIR explicit,
auditable, and reproducible.

Phase 0 is a prerequisite for accepting further integration work. The main
failure mode to eliminate is proving or reviewing against hidden local state in
`.lake/packages/VeIR`.

## Starting State

- llzk-lean HEAD at bootstrap time: `ea2363f87bcc`.
- workspace veir HEAD at bootstrap time: `4b0978bddec0`.
- Lake dependency `VeIR` at bootstrap time: `09d5f00f0d2b`.
- Lake dependency `VeIR` is dirty at bootstrap time:
  - modified `Veir/Passes/Felt/Combine.lean`
  - modified `Veir/Passes/Felt/Proofs.lean`
  - untracked `Veir/Passes/Felt/RewriteLemmas.lean`
- llzk-lean has no repo-local `AGENTS.md`, no skill directory, and no
  `docs/harness` source of truth.
- `differential/run-differential.sh` uses `.lake/packages/VeIR` and currently
  cannot be treated as a high-assurance oracle without exit-code and tool-state
  hardening.

## Non-Goals

- Do not change Felt semantics or proofs in this phase.
- Do not add new differential cases except smoke cases needed to validate the
  harness itself.
- Do not accept a dirty Lake dependency as normal release or review state.
- Do not let CI skips count as evidence that Strategy A or Strategy E works.

## Artifacts To Create

- `AGENTS.md`: concise entrypoint for agents working in this repository.
- `docs/harness/CURRENT.md`: active phase, refs, dependency mode, known hazards,
  and allowed exploratory states.
- `docs/harness/SOURCES.md`: trusted source ledger for LLZK, VeIR, MLIR, Lean,
  and local Strategy A/E documents.
- `docs/harness/GATES.md`: executable gate inventory and what each gate proves.
- `docs/harness/REVIEWS.md`: independent review protocol, severity definitions,
  and finding disposition rules.
- `docs/phases/PHASE_TEMPLATE.md`: template for future phase bootstrap files.
- `reviews/PHASE-00/{request.md,findings.md,disposition.md,evidence/}`:
  adversarial review workspace for this phase.
- `scripts/harness/doctor.sh`: validate dependency pin, dirty state, local tool
  availability, CI assumptions, and expected repo layout.
- `scripts/harness/check-doc-freshness.sh`: reject stale phase metadata and
  unreviewed canonical-doc changes.
- `scripts/harness/diff-smoke.sh`: run a minimal differential check and classify
  tool failure separately from semantic divergence.
- `scripts/harness/cert-smoke.sh`: run a minimal Strategy E checker smoke test
  and report whether MLIR-backed matching is active or absent.
- `scripts/harness/validate-skills.sh`: validate any repo-local skills.

## Skill Infrastructure

Create repo-local skills only when they encode repeatable project behavior.
Initial candidates:

- `skills/llzk-lean-dependency-audit/SKILL.md`
- `skills/lean-axiom-audit/SKILL.md`
- `skills/mlir-differential/SKILL.md`
- `skills/cert-checker-review/SKILL.md`
- `skills/phase-bootstrap/SKILL.md`

Each skill must be concise, include when to use it, point to exact scripts or
references, and have a validation path in `scripts/harness/validate-skills.sh`.

## Gates To Implement

- `scripts/harness/doctor.sh` passes from the llzk-lean root only when the VeIR
  dependency state is explicit and acceptable for the selected mode.
- Dirty `.lake/packages/VeIR` state is detected and reported with exact files.
- Differential smoke checks distinguish missing tools, parse failures, pass
  failures, semantic divergence, and expected divergence.
- Certificate smoke checks distinguish schema validation, theorem metadata
  coverage, and real MLIR matcher coverage.
- CI workflows do not silently treat skipped external tooling as proof of
  Strategy A or Strategy E coverage.

## Review Requirements

- Every Phase 0 claim must cite either a local file, a command output captured
  under `reviews/PHASE-00/evidence/`, or an explicitly trusted external source.
- The reviewer must run the harness gates from a clean shell and record the
  commands used.
- Findings must be dispositioned as fixed, accepted-risk, deferred, or invalid.
- Phase 0 cannot close while dependency state is ambiguous or hidden.

## Done Criteria

- `AGENTS.md` exists and points to canonical harness docs.
- `docs/harness/CURRENT.md` is the single source of truth for active phase,
  refs, dependency mode, and dirty-state policy.
- Harness gates fail on the known dirty dependency state unless explicitly run
  in an exploratory mode.
- Strategy A and Strategy E smoke gates report precise status instead of
  producing misleading success.
- Phase 0 review artifacts exist and contain an independent findings pass.
- Future phase bootstrap files can be generated from `PHASE_TEMPLATE.md`.
