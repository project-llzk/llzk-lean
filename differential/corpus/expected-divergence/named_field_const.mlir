// EXPECTED-LLZK-FAIL — generic named-field FeltConstAttr remains
// parser/verifier-incompatible on the LLZK side.
//
// VEIR accepts this outer-typed generic form, but LLZK's parser/verifier path
// rejects it before a comparable output is produced. LLZK custom assembly
// named-field cases should use .llzk plus --lower-first instead.
// Tracked as a documented alignment gap; see docs/strategy-a-oracle.md.

"builtin.module"() ({
  "function.def"() <{sym_name = "test", function_type = () -> ()}> ({
    %c = "felt.const"() <{value = #felt<const 5> : !felt.type<"babybear">}> : () -> !felt.type<"babybear">
    "function.return"() : () -> ()
  }) : () -> ()
}) {llzk.lang} : () -> ()
