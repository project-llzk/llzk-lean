# llzk-lean Dependency Audit

## When to use

Use this skill when a task depends on `.lake/packages/VeIR`, the Lake pin, or
the workspace VeIR checkout.

## Procedure

- Start from `docs/harness/CURRENT.md`, `docs/harness/SOURCES.md`, and
  `docs/harness/PINS.md`.
- Compare `lakefile.toml`, `lake-manifest.json`, and the actual dependency
  checkout, including remote URL, manifest `type`, `rev`, and `inputRev`.
- Treat dirty dependency state as exploratory only; it is not acceptance
  evidence.

## Validation

Run `scripts/harness/verify-pins.sh --workspace-veir ../veir` and
`scripts/harness/doctor.sh --workspace-veir ../veir`.
