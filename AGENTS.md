# llzk-lean Agent Entry

Treat `docs/harness/CURRENT.md` as the active source of truth before doing
dependency, differential, or certificate work in this repository.

Required first checks:

- Read `docs/harness/CURRENT.md`, `docs/harness/GATES.md`, and
  `docs/harness/SOURCES.md`; read `docs/harness/PINS.md` before touching
  Lake metadata or `.lake/packages/VeIR`.
- Run `scripts/harness/doctor.sh --workspace-veir ../veir` from the repository
  root when the companion checkout exists. If `../veir` is unavailable, run the
  strict doctor without the workspace argument and report that the result is not
  full acceptance evidence.
- Run `scripts/harness/verify-pins.sh --workspace-veir ../veir` for any
  dependency, review, or phase-close work.

Policy:

- Do not rely on `.lake/packages/VeIR` as hidden proof state.
- Dirty dependency state is never acceptance evidence. Use `--mode exploratory`
  only to investigate a mismatch, and report that mode explicitly.
- Do not treat a missing `llzk-opt`, missing MLIR headers, or CI skip as
  Strategy A or Strategy E coverage.
- Keep phase evidence under the active phase directory
  (`reviews/PHASE-01/evidence/` for the current pin phase) when changing
  canonical harness docs, pins, or gates.
