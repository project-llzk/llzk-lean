# Strategy B — Lean → C++ extraction (future)

## Concrete picture

Build a tool that translates a restricted subset of Lean 4 (no
Mathlib tactics at runtime, no metaprogramming, monomorphic types)
into idiomatic C++ that compiles into `llzk-lib`. The verified
`felt-combine` patterns in VEIR's `Veir/Passes/Felt/Combine.lean` come
out as C++ functions that LLZK's canonicalizer dispatches to.

Same architecture as Coq's extraction-to-OCaml or
[CompCert](https://compcert.org)'s OCaml output.

## Trusted base

The extractor tool itself, plus the Lean subset it consumes. Lean's
kernel is *not* runtime-trusted (used only at proof time). Smaller TCB
than Strategy D, slightly larger than Strategy E.

## Assurance

LLZK's canonicalizer C++ is *generated from* verified Lean. Anyone can
compare the generated C++ to the Lean source and trace provenance.

## Functionality

LLZK ships with extracted-from-Lean canonicalizers, indistinguishable
from hand-written C++ at the user level.

## Cost

**Felt-only**: 4-7 engineer-months. Requires building a
domain-specific extractor targeting MLIR's pattern-rewriter API, then
rewriting our 15 rewrites in the restricted Lean subset (Mathlib
tactics like `ring` and `push_cast` produce tactic-generated proofs
that can't be extracted — we'd need hand-proofs).

**LLZK-wide**: 24+ engineer-months. The extractor scales, but the
*input* doesn't — we'd need to write all of LLZK's verified passes in
Lean first.

## Why this is future work, not initial

- Mathlib boundary is the gotcha. Our current 15 rewrites use Mathlib
  tactics; rewriting them in extraction-friendly form is itself work.
- Lean 4 extraction is an active research area but not productized.
  Pioneering it for this project is a research project of its own,
  not an engineering one.
- Strategy E achieves comparable assurance with a smaller upfront cost
  by checking certificates rather than extracting code.

Revisit Strategy B if (a) Strategy E lands and we want a tighter
integration with LLZK's pass infrastructure, or (b) Lean 4 extraction
matures to where it can handle Mathlib-using code.
