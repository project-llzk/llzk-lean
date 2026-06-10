# Certificate Checker Review

## When to use

Use this skill when reviewing Strategy E certificate schema, checker behavior,
or MLIR matcher status.

## Procedure

- Use `scripts/harness/cert-smoke.sh` for smoke classification; do not treat
  the smoke result as Phase 1 acceptance evidence.
- Distinguish schema validation, theorem metadata coverage, driver behavior,
  and MLIR matcher coverage.
- Treat MLIR matcher absence as a reported status, not as runtime verification.

## Validation

Run `scripts/harness/validate-skills.sh` and `scripts/harness/cert-smoke.sh`.
