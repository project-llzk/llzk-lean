import LlzkLean.Cert

/-!
  Entry point for the `emit-certs` executable.

  Reads VEIR's verified Felt-rewrite catalog (via `LlzkLean.Cert`),
  serializes it to JSON on stdout. Pipe to `certs/felt-combine.cert.json`
  to refresh the committed snapshot.

  Usage:
    lake exec emit-certs > certs/felt-combine.cert.json
-/

open LlzkLean.Cert

/--
  Render an `OperandShape` as a minimal JSON object string. Hand-rolled
  rather than depending on a JSON library so this executable stays
  zero-dep beyond VEIR + Mathlib (already in the dep set).

  Schema v0.2.0 emits:
  - `const`: optional `"value": N` field when the shape pins a literal.
  - `opResult`: optional `"commutative": true` when the match is
    order-insensitive.

  Forward-compat with v0.1.x readers: these are absent-by-default and
  v0.1.x readers ignore the unknown keys per the §Versioning policy.
-/
partial def shapeToJson : OperandShape → String
  | .any => "{\"kind\":\"any\"}"
  | .const k none => s!"\{\"kind\":\"const\",\"opKind\":\"{k}\"}"
  | .const k (some v) => s!"\{\"kind\":\"const\",\"opKind\":\"{k}\",\"value\":{v}}"
  | .opResult k ops commutative =>
    let opStr := String.intercalate "," (ops.map shapeToJson)
    if commutative then
      s!"\{\"kind\":\"opResult\",\"opKind\":\"{k}\",\"operands\":[{opStr}],\"commutative\":true}"
    else
      s!"\{\"kind\":\"opResult\",\"opKind\":\"{k}\",\"operands\":[{opStr}]}"

/-- Render a JSON string list. -/
def stringListToJson (xs : List String) : String :=
  "[" ++ String.intercalate "," (xs.map (fun s => s!"\"{s}\"")) ++ "]"

def condToJson : SideCondition → String
  | .sameValue l r => s!"\{\"kind\":\"sameValue\",\"lhs\":\"{l}\",\"rhs\":\"{r}\"}"
  | .constEquals p v => s!"\{\"kind\":\"constEquals\",\"pos\":\"{p}\",\"value\":{v}}"
  | .sameAttr a ps =>
    s!"\{\"kind\":\"sameAttr\",\"attr\":\"{a}\",\"positions\":{stringListToJson ps}}"
  | .attrInRegistry p a r =>
    s!"\{\"kind\":\"attrInRegistry\",\"pos\":\"{p}\",\"attr\":\"{a}\",\"registry\":\"{r}\"}"
  | .constCompare p op v =>
    s!"\{\"kind\":\"constCompare\",\"pos\":\"{p}\",\"op\":\"{op.toJsonString}\",\"value\":{v}}"
  | .resultTypeFromOperand p =>
    s!"\{\"kind\":\"resultTypeFromOperand\",\"pos\":\"{p}\"}"

def scopeToJson : ScopeAssertion → String
  | .withinAttr a => s!"\{\"kind\":\"withinAttr\",\"attr\":\"{a}\"}"

def certToJson (c : Cert) : String :=
  let condsStr := String.intercalate "," (c.conditions.map condToJson)
  let scopeStr := match c.scope with
    | none => ""
    | some s => s!",\"scope\":{scopeToJson s}"
  s!"\{\
\"patternId\":\"{c.patternId}\",\
\"rootKind\":\"{c.rootKind}\",\
\"lhs\":{shapeToJson c.lhs},\
\"rhs\":{shapeToJson c.rhs},\
\"conditions\":[{condsStr}],\
\"theoremName\":\"{c.theoremName}\",\
\"llzkParityStatus\":\"{c.llzkParityStatus.toJsonString}\"{scopeStr},\
\"description\":\"{c.description}\"\
}"

/--
  Header for the emitted JSON. The `_note` is part of the wire format
  so the committed snapshot stays self-describing (without it,
  refreshing the file silently strips the stub-status disclaimer).
  Carries the count of certs so a reviewer can see at a glance whether
  the catalog is still a stub.

  Schema v0.2.0 (minor bump from v0.1.1; additive new constructors):
  adds `SideCondition` constructors `sameAttr`, `attrInRegistry`,
  `constCompare`, `resultTypeFromOperand`; `OperandShape.const.value`
  optional payload; `OperandShape.opResult.commutative` optional flag;
  per-cert `scope` field. All additions are encoded as new JSON
  constructors or optional keys; v0.1.x readers reject the file on
  encountering an unknown enum constructor (per the §Versioning policy
  in docs/strategy-e-certificates.md).
-/
def jsonHeader (certCount : Nat) : String :=
  s!"\{\n  \"schemaVersion\": \"0.2.0\",\n  \
\"source\": \"VEIR Veir.Passes.Felt.Combine (stub catalog — {certCount} of 15 patterns)\",\n  \
\"_note\": \"Hand-listed catalog. The full 15-pattern catalog will be derived reflectively from VEIR's Veir.Passes.Felt.Combine; today's source is LlzkLean.Cert.feltCombineCatalog.\",\n  \
\"_aboutLlzkParityStatus\": \"Per-cert tag indicating how a VEIR rewrite relates to LLZK's runtime: 'aligned' = LLZK performs the same rewrite exactly; 'aligned-with-caveats' = LLZK performs it under additional conditions (e.g. modular reduction, field-name guard); 'veir-only' = LLZK has no matching fold or canonicalization pattern, the cert is a Lean-side soundness statement only. The C++ checker uses this to pick assertion polarity.\",\n  \
\"certs\": [\n    "

def main : IO Unit := do
  let body := String.intercalate ",\n    " (feltCombineCatalog.map certToJson)
  let footer := "\n  ]\n}"
  IO.println (jsonHeader feltCombineCatalog.length ++ body ++ footer)
