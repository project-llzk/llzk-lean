// EXPECT: DIVERGE — named-field FeltConstAttr is parser-incompatible.
// VEIR's parser doesn't accept LLZK's inner `#felt<const N : <"name">>`
// syntax; LLZK's parser silently strips VEIR's outer field annotation,
// which then fails the result-type-matches-value-type verifier.
// Tracked as a documented alignment gap; see docs/strategy-a-oracle.md.

"builtin.module"() ({
  "function.def"() <{sym_name = "test", function_type = () -> ()}> ({
    %c = "felt.const"() <{value = #felt<const 5> : !felt.type<"babybear">}> : () -> !felt.type<"babybear">
    "function.return"() : () -> ()
  }) : () -> ()
}) {llzk.lang} : () -> ()
