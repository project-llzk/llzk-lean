// Minimal Felt proof-of-life for the differential harness.
//
// Two `felt.const` ops at module level. Exercises:
//   - Round-trip of `!felt.type` (unparameterized)
//   - Round-trip of `#felt<const N> : !felt.type` (structured attr)
//
// Both `llzk-opt --mlir-print-op-generic` and `veir-opt` should
// produce textually-identical output after the normalizer in
// VEIR's scripts/llzk-diff.sh handles known cosmetic divergences
// (empty block headers, block-arg spacing, scope-local block
// numbering).

"builtin.module"() ({
  %c1 = "felt.const"() <{value = #felt<const 42> : !felt.type}> : () -> !felt.type
  %c2 = "felt.const"() <{value = #felt<const 7> : !felt.type}> : () -> !felt.type
}) : () -> ()
