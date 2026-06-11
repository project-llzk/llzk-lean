# Phase 10 Toolchain Smoke

Date: 2026-06-11

Command:

```bash
scripts/harness/phase10-toolchain-smoke.sh
```

Tool ownership recorded by the smoke:

- Lowering owner: `llzk-opt --mlir-print-op-generic`.
- C++ canonical path: `llzk-opt --canonicalize --mlir-print-op-generic`.
- VEIR canonical path: `veir-opt -p=felt-combine,dce`.
- Current profile under smoke: enhanced VEIR `felt-combine,dce`.

Initial finding:

- The workspace VEIR path diverged on
  `differential/corpus/felt/registered_add_fold.llzk`: `felt-combine` folded
  the add, but DCE did not erase the now-dead input constants.
- The clean pinned dependency passed the same input, so this was a workspace
  regression relative to the accepted Phase 8 proof basis.
- Root cause: after the upstream DCE side-effect API change, Felt operations
  were not listed as pure and defaulted to side-effecting.

Fix:

- `Veir/GlobalOpInfo.lean` now marks `.felt _` as side-effect-free for DCE.
- The smoke wrapper refreshes workspace `veir-opt` before using the neighboring
  VEIR checkout.

Final result:

```text
WORKSPACE-VEIR-OPT: lake build veir-opt succeeded for /home/alh/LLZK/veir
SMOKE-PASS: parse-print aligned fold: differential/corpus/felt/registered_add_fold.llzk
SMOKE-PASS: canonical aligned fold: differential/corpus/felt/registered_add_fold.llzk
SMOKE-PASS: parse-print no-fire precondition: differential/corpus/felt/unspecified_add_fold.llzk
SMOKE-PASS: canonical no-fire precondition: differential/corpus/felt/unspecified_add_fold.llzk
```
