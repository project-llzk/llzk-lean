# llzk-lean Dependency Audit

## When to use

Use this skill when a task depends on `.lake/packages/VeIR`, the Lake pin, or
the workspace VeIR checkout.

## Procedure

- Start from `docs/harness/CURRENT.md` and `docs/harness/SOURCES.md`.
- Compare `lakefile.toml`, `lake-manifest.json`, and the actual dependency
  checkout.
- Treat dirty dependency state as exploratory unless a phase explicitly accepts
  it.

## Validation

Run `scripts/harness/doctor.sh` or
`scripts/harness/doctor.sh --mode exploratory`.
