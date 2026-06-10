# Lean Axiom Audit

## When to use

Use this skill when reviewing Lean proof files, theorem claims, `axiom`, or
`sorry` usage.

## Procedure

- Audit the actual dependency checkout, not just the Lake pin.
- Record exact files and command evidence under the active phase review
  directory, e.g. `reviews/PHASE-01/evidence/` for the current pin phase.
- Do not treat dirty proof files as release evidence.

## Validation

Run `scripts/harness/validate-skills.sh` and
`scripts/harness/doctor.sh --workspace-veir ../veir`.
