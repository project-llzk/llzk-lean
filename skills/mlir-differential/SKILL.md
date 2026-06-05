# MLIR Differential

## When to use

Use this skill when running or reviewing Strategy A differential checks.

## Procedure

- Use `scripts/harness/diff-smoke.sh` for Phase 0 smoke status.
- Classify missing tools, parse failures, pass failures, semantic divergence,
  and expected divergence separately.
- Do not treat a missing `llzk-opt` skip as coverage.

## Validation

Run `scripts/harness/validate-skills.sh` and `scripts/harness/diff-smoke.sh`.
