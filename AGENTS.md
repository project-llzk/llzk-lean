# llzk-lean Agent Entry

Treat `docs/harness/CURRENT.md` as the active source of truth before doing
dependency, differential, or certificate work in this repository.

Required first checks:

- Read `docs/harness/CURRENT.md`, `docs/harness/GATES.md`, and
  `docs/harness/SOURCES.md`.
- Run `scripts/harness/doctor.sh` from the repository root.
- If the known dirty `.lake/packages/VeIR` checkout is being used for local
  investigation, rerun with `--mode exploratory` and report that mode.

Policy:

- Do not rely on `.lake/packages/VeIR` as hidden proof state.
- Do not treat a missing `llzk-opt`, missing MLIR headers, or CI skip as
  Strategy A or Strategy E coverage.
- Keep phase evidence under `reviews/PHASE-00/evidence/` when changing
  canonical harness docs or gates.
