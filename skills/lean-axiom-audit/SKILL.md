# Lean Axiom Audit

## When to use

Use this skill when reviewing Lean proof files, theorem claims, `axiom`, or
`sorry` usage.

## Procedure

- Audit the actual dependency checkout, not just the Lake pin.
- Record exact files and command evidence under `reviews/PHASE-00/evidence/`
  when the claim affects Phase 0.
- Do not treat dirty proof files as release evidence.

## Validation

Run `scripts/harness/validate-skills.sh` and
`scripts/harness/doctor.sh --mode exploratory`.
