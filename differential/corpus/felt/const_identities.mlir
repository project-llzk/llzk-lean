// Minimal Felt proof-of-life for the differential harness.
//
// Two live `felt.const` ops returned from a function. Exercises:
//   - Round-trip of `!felt.type` (unparameterized)
//   - Round-trip of `#felt<const N> : !felt.type` (structured attr)
//   - Canonicalization mode without letting LLZK erase unused module-level
//     constants before VEIR sees them.
//
// Both parse/print mode and canonicalization mode should produce
// textually-identical output after the normalizer in VEIR's
// scripts/llzk-diff.sh handles known cosmetic divergences (empty block
// headers, block-arg spacing, scope-local block numbering).

"builtin.module"() ({
  "function.def"() <{sym_name = "const_identities", function_type = () -> (!felt.type, !felt.type)}> ({
    %c1 = "felt.const"() <{value = #felt<const 42> : !felt.type}> : () -> !felt.type
    %c2 = "felt.const"() <{value = #felt<const 7> : !felt.type}> : () -> !felt.type
    "function.return"(%c1, %c2) : (!felt.type, !felt.type) -> ()
  }) : () -> ()
}) {llzk.lang} : () -> ()
