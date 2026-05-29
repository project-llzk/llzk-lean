# Strategy D — Lean MLIR dialect plugin via FFI (future)

## Concrete picture

Compile Lean 4 to a shared library (`.so`) that exposes MLIR's
dialect-registry interface. `llzk-opt` loads it at startup *instead
of* a statically-linked C++ Felt dialect. When MLIR's pass manager
invokes `FeltConstOp::fold()`, it crosses an FFI boundary into Lean
code running our verified `constant_fold_add`.

Architecturally elegant: Lean *is* the dialect. Practically:
non-trivial because the Lean runtime and Mathlib's machinery have to
load into `llzk-opt`'s process.

## Trusted base

Lean's runtime (GC + scheduler), the Lean→C FFI bridge, Mathlib
(because our `ZMod p` model imports it). Considerably larger than
Strategies A, E, or B. Mathlib at runtime is unprecedented and pulls
~600 MB of oleans into LLZK's binary.

## Assurance

Lean's verified rewrites *are* LLZK's canonicalizer. The theorems in
`Veir.Passes.Felt.Proofs` are operational — they're what executes. No
separate checker, no certificate-format drift.

## Functionality

LLZK with a Lean-based Felt dialect plugin. End users see no semantic
difference; just a bigger binary and slower startup.

The rest of `llzk-lib` (Bool, Cast, Struct, Polymorphic, backends)
continues consuming Felt through the same C++ type symbols
(`AddFeltOp`, `FeltConstAttr`, ...) — the plugin presents the
same headers, with different implementations behind them.

## Cost

**Felt-only**: 3-5 engineer-months for a proof of concept.
**LLZK-wide**: 18-30 engineer-months (one plugin per dialect, plus
MLIR pass-manager integration).

## Why this is future work, not initial

- MLIR has no stable dialect-plugin ABI.
- Lean→MLIR FFI bridges are research-grade; no productized story
  for exposing Lean structures as opaque MLIR types through C++ vtables.
- Mathlib in LLZK's process is fragile and politically fraught — most
  production teams will reject the dependency.

Revisit Strategy D if Veridise becomes strategically interested in
hosting verified-Lean code *inside* LLZK and is willing to absorb the
runtime cost. Strategy E provides comparable assurance without the
runtime coupling.
