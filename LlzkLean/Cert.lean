/-!
  # Certificate format (Strategy E)

  Each verified rewrite in VEIR's `Veir/Passes/Felt/Combine.lean` is
  paired with a soundness theorem in `Veir/Passes/Felt/Proofs.lean`.
  A **certificate** is a machine-readable record of that pairing,
  formatted so that an LLZK-side C++ checker can validate that an
  actual LLZK rewrite matches the verified template.

  The certificate is *not* the proof — the proof stays in Lean. The
  certificate is the *contract*: "this rewrite pattern is sound, by
  this theorem, under these side conditions." LLZK's checker
  validates that what LLZK *did* matches what the certificate
  *describes*; it does not re-check the proof.

  This file defines the certificate type and the hand-listed catalog.
  The JSON serialization is in `EmitCerts.lean`; the wire format is
  documented in `docs/strategy-e-certificates.md` §"Certificate format".
  The verified rewrite catalog this mirrors lives upstream in VEIR
  (`Veir/Passes/Felt/Combine.lean` + `Veir/Passes/Felt/Proofs.lean`);
  today's `feltCombineCatalog` below is a hand-listed stub mirroring 2
  of 15 patterns. Reflective derivation from VEIR is tracked as the
  next milestone.

  See `docs/strategy-e-certificates.md` for the architecture overview.
-/

namespace LlzkLean.Cert

/--
  Shape of an operand in a certificate's LHS or RHS pattern. The
  C++ checker matches concrete MLIR operands against this shape.

  Schema v0.2.0 additions:
  - `const.value` optional payload: when set, the shape matches only
    constants with the given integer value (today's `constEquals`
    side-condition supports this, but for shapes that always
    require a specific literal it's cleaner to push the value into
    the shape itself).
  - `opResult.commutative`: when `true`, the C++ checker is allowed
    to match operands in either order. Useful for `felt.add` /
    `felt.mul` / `bit_and|or|xor` (LLZK's `Commutative` trait). Old
    readers ignore the flag and fall through to strict-order
    matching (false reject, never false accept — safe).
-/
inductive OperandShape where
  /-- Matches any value. -/
  | any
  /-- Matches a constant of the given dialect-specific kind.
      `kind` is e.g. `"felt.const"`. `value` (added in v0.2.0) is
      an optional literal-value constraint; when `none` the shape
      matches any constant of that kind. -/
  | const (kind : String) (value : Option Int := none)
  /-- Matches a result of a specific op. `kind` is e.g. `"felt.add"`;
      `operands` describes operands recursively; `commutative`
      (added in v0.2.0) flags the operand list as order-insensitive. -/
  | opResult (kind : String) (operands : List OperandShape) (commutative : Bool := false)
deriving Inhabited, Repr

/--
  Comparison operator for value-level conditions. Added in v0.2.0 as
  a new constructor (`constCompare`) rather than mutating
  `constEquals` — mutating would silently misclassify in v0.1.x
  readers that ignore the new `op` field.
-/
inductive CompareOp where
  | eq | ne | lt | le | gt | ge
deriving Inhabited, Repr, DecidableEq

/-- Kebab-case wire form for `CompareOp`. -/
def CompareOp.toJsonString : CompareOp → String
  | .eq => "eq" | .ne => "ne" | .lt => "lt"
  | .le => "le" | .gt => "gt" | .ge => "ge"

/--
  A side condition that the C++ checker must verify before accepting
  the rewrite.

  Schema v0.2.0 additions (each is a *new* constructor; existing
  constructors retain v0.1.x semantics):
  - `sameAttr`: two operand positions carry the same value for a
    named attribute (e.g., `fieldName` on `FeltConstAttr`). Closes
    the field-name-match gap from `tryGetBinaryFoldData`.
  - `attrInRegistry`: the named attribute at the given position
    resolves to an entry in a registry. Used for "field name is one
    of the LLZK built-in fields."
  - `constCompare`: a value comparison (eq / ne / lt / le / gt / ge)
    between a constant operand's value and a literal. Use this for
    "non-zero divisor", "shift amount < bitwidth", etc.
  - `resultTypeFromOperand`: the rewrite's output type is inferred
    from a named operand position. Captures LLZK's
    `InferTypeOpAdaptor` discipline.
-/
inductive SideCondition where
  /-- The two named operand positions must alias (same SSA value). -/
  | sameValue (lhs rhs : String)
  /-- The constant at the named position must equal the given integer.
      v0.1.x semantics preserved; for richer comparisons use
      `constCompare`. -/
  | constEquals (pos : String) (val : Int)
  /-- (v0.2.0) Two operand positions must carry the same value for
      the named attribute. E.g. `attr = "fieldName"` for the LLZK
      `FeltConstAttr` field-name-match. -/
  | sameAttr (attr : String) (positions : List String)
  /-- (v0.2.0) The named attribute at the operand position must
      resolve as an entry in the named registry. E.g.
      `attr = "fieldName"`, `registry = "field"` for "field name is
      one of LLZK's built-in fields." -/
  | attrInRegistry (pos : String) (attr : String) (registry : String)
  /-- (v0.2.0) Value comparison on a constant operand. -/
  | constCompare (pos : String) (op : CompareOp) (val : Int)
  /-- (v0.2.0) The rewrite's result type equals the type of the
      named operand position (LLZK `InferTypeOpAdaptor` discipline). -/
  | resultTypeFromOperand (pos : String)
deriving Inhabited, Repr

/--
  Scope assertion: the cert is only valid inside a surrounding op
  carrying the named discardable attribute. Captures LLZK's
  `NotFieldNative` context-gating where (for example) felt.bit_and
  is only valid inside a `function.def` with the
  `function.allow_non_native_field_ops` attribute.

  Added in v0.2.0. Optional per cert (`none` = no scope assertion).
-/
inductive ScopeAssertion where
  | withinAttr (attr : String)
deriving Inhabited, Repr

/--
  Classification of how a verified Lean rewrite relates to LLZK's
  actual runtime behavior. The C++ checker uses this field to pick
  the assertion polarity at `--verify-rewrites` time:

  - `aligned`: LLZK performs *exactly* this rewrite, producing the
    same canonical output as the Lean spec. The checker asserts
    LLZK's transformation matches the cert.
  - `alignedWithCaveats`: LLZK performs this rewrite under additional
    conditions that the Lean spec doesn't impose (e.g. requires a
    registered field name, applies modular reduction). The cert's
    LHS/RHS describes the *semantic* identity; LLZK's *canonical
    form* may differ. The checker can assert match-modulo-caveat;
    full alignment is a future-work item.
  - `veirOnly`: LLZK does not perform this rewrite at all (no fold,
    no canonicalization pattern). The cert is a Lean-side soundness
    statement, not a contract on LLZK runtime behavior. The checker
    treats it as informational (logs it; does not assert LLZK
    exhibits it).

  This field replaces the bracketed English annotations that
  v0.1.0's `description` field carried. Added in schema v0.1.1.
-/
inductive LlzkParityStatus where
  | aligned
  | alignedWithCaveats
  | veirOnly
deriving Inhabited, Repr, DecidableEq

/-- JSON-encoding for `LlzkParityStatus`. The kebab-case strings are
    the wire format consumed by the C++ checker. -/
def LlzkParityStatus.toJsonString : LlzkParityStatus → String
  | .aligned => "aligned"
  | .alignedWithCaveats => "aligned-with-caveats"
  | .veirOnly => "veir-only"

/--
  One certificate. Identifies a rewrite pattern in VEIR's `Combine.lean`,
  the LHS/RHS shape, side conditions, and the name of the Lean theorem
  that justifies the rewrite. The C++ checker uses `theoremName` only as
  a label — it does not re-prove anything.
-/
structure Cert where
  /-- Identifier for this pattern, matches the Lean def in
      `Veir/Passes/Felt/Combine.lean`. E.g.
      `"right_identity_zero_add"`. -/
  patternId : String
  /-- The op kind this pattern matches at its root.
      E.g. `"felt.add"`. -/
  rootKind : String
  /-- Shape of the LHS (the matched op's operand pattern). -/
  lhs : OperandShape
  /-- Shape of the RHS (what the LHS is rewritten to). The C++ checker
      verifies the rewritten IR has this shape. -/
  rhs : OperandShape
  /-- Side conditions the C++ checker validates structurally. -/
  conditions : List SideCondition
  /-- Fully-qualified Lean theorem name (e.g.
      `Veir.Data.Felt.right_identity_zero_add`) that proves LHS = RHS
      semantically. Theorems live in `Veir/Passes/Felt/Proofs.lean`
      inside the `Veir.Data.Felt` namespace. The checker uses this as
      a label only — it does not re-execute the proof. -/
  theoremName : String
  /-- LLZK-parity classification — see `LlzkParityStatus`. Added in
      schema v0.1.1; the C++ checker uses this to pick assertion
      polarity at `--verify-rewrites` time. -/
  llzkParityStatus : LlzkParityStatus
  /-- Optional scope assertion (added in v0.2.0): the cert is valid
      only when the matched op lives inside a surrounding op
      carrying the named discardable attribute. `none` means the
      cert applies in any scope. -/
  scope : Option ScopeAssertion := none
  /-- Free-form description for human readers of the cert file.
      As of v0.1.1, parity-status framing lives in
      `llzkParityStatus`, not in the description. -/
  description : String
deriving Inhabited, Repr

/--
  Smart constructor for `Cert` that derives `theoremName` from
  `patternId`. Convention: a Felt rewrite `def <patternId>` in
  `Veir/Passes/Felt/Combine.lean` is paired with a theorem
  `theorem <patternId>` in `Veir/Passes/Felt/Proofs.lean` inside
  the `Veir.Data.Felt` namespace.

  Using `Cert.mk'` instead of the raw `Cert` constructor enforces
  that `patternId` and `theoremName` cannot drift apart by typo —
  rename one, the other follows. The raw constructor is still
  available for any future cert that breaks the naming convention,
  but the catalog below should use `Cert.mk'` exclusively.
-/
def Cert.mk' (patternId : String) (rootKind : String)
    (lhs rhs : OperandShape) (conditions : List SideCondition)
    (llzkParityStatus : LlzkParityStatus)
    (description : String)
    (scope : Option ScopeAssertion := none) : Cert :=
  { patternId, rootKind, lhs, rhs, conditions
    theoremName := "Veir.Data.Felt." ++ patternId
    llzkParityStatus, scope, description }

/--
  The catalog of certificates for VEIR's Felt rewrites. One cert
  per verified pattern in VEIR's `Veir.FeltPass` namespace; each
  cert pairs with a theorem in `Veir.Data.Felt`.

  **Status**: 2-of-15 stub. The remaining 13 verified VEIR patterns
  don't yet have catalog entries. `LlzkLean.CertValidate` reports the
  exact uncovered list as an `info:` message at build time.

  ## Adding an entry

  Use `Cert.mk'` (defined above) so `theoremName` is auto-derived
  from `patternId` — the two cannot drift apart by typo. The build
  enforces three linkage invariants:
  - The cert's `patternId` must match a `def` in VEIR's
    `Veir.FeltPass` namespace (checked by
    `#assertCatalogCoverage` in `LlzkLean/CertValidate.lean`).
  - The derived `theoremName` must resolve to a `Prop` in VEIR's
    `Veir.Data.Felt` namespace (checked by `#certThmExists`).
  - The structural fields (`lhs`, `rhs`, `conditions`,
    `llzkParityStatus`, `scope`) describe what the rewrite does;
    these are not currently auto-derived from the VEIR pattern
    body. That would require VEIR-side metadata (e.g., a
    `@[cert_spec ...]` attribute on each pattern) and is the
    natural next step once VEIR cooperates.
-/
def feltCombineCatalog : List Cert := [
  -- VEIR-side soundness claim with no current LLZK counterpart.
  -- LLZK's `AddFeltOp::fold` (lib/Dialect/Felt/IR/Ops.cpp:141-149)
  -- only folds when *both* operands are FeltConstAttrs with
  -- matching, registered field names; LLZK registers no
  -- canonicalization patterns for AddFeltOp. So this cert is a
  -- VEIR-only soundness statement, not a contract on LLZK runtime
  -- behavior. Strategy-E's checker should treat veir-only certs as
  -- informational (label them in --verify-rewrites output, do not
  -- assert LLZK ever exhibits the rewrite).
  -- v0.2.0: `.const "felt.const" (some 0)` pins the literal value
  -- in the shape itself rather than via a separate constEquals
  -- condition. `commutative := true` flags felt.add as
  -- order-insensitive (matches LLZK's Commutative trait), so the
  -- checker accepts both `add x 0` and `add 0 x`.
  Cert.mk'
    (patternId := "right_identity_zero_add")
    (rootKind := "felt.add")
    (lhs := .opResult "felt.add" [.any, .const "felt.const" (some 0)] (commutative := true))
    (rhs := .any)
    (conditions := [])
    (llzkParityStatus := .veirOnly)
    (description := "felt.add x (felt.const 0) → x. Sound over any ZMod p."),
  -- LLZK does this fold (Ops.cpp:141-149) but with two caveats VEIR
  -- doesn't share today:
  --   (a) LLZK short-circuits unless both operands have a registered
  --       field name (tryGetBinaryFoldData, Ops.cpp:57-79); VEIR's
  --       fold has no field-name guard.
  --   (b) LLZK applies modular reduction (field->reduce); VEIR's
  --       implementation stores c1+c2 as an unreduced Int.
  -- Both gaps are tracked in VEIR's FELT_PARITY_ASSESSMENT.
  -- v0.2.0 expresses LLZK's actual fold conditions structurally:
  --   - both operands' fieldName attrs must match (sameAttr) —
  --     this is `lhsFieldName == rhsFieldName` in
  --     llzk-lib/lib/Dialect/Felt/IR/Ops.cpp:66
  --   - the shared fieldName must resolve in LLZK's Field
  --     registry (attrInRegistry) — i.e. Field::tryGetField at
  --     Ops.cpp:70-73 succeeds
  -- With these conditions in place, this cert correctly describes
  -- LLZK's fold *when the inputs are named-field*. (For unnamed
  -- !felt.type operands LLZK still short-circuits to a no-op;
  -- VEIR's fold fires unconditionally — that gap remains and
  -- requires the Field-registry parity work on the VEIR side.)
  Cert.mk'
    (patternId := "constant_fold_add")
    (rootKind := "felt.add")
    (lhs := .opResult "felt.add" [.const "felt.const", .const "felt.const"] (commutative := true))
    (rhs := .const "felt.const")
    (conditions := [
      .sameAttr "fieldName" ["lhs", "rhs"],
      .attrInRegistry "lhs" "fieldName" "field"
    ])
    (llzkParityStatus := .alignedWithCaveats)
    (description := "felt.add (felt.const c1) (felt.const c2) → felt.const (c1+c2). Sound over any ZMod p. Caveat: LLZK applies modular reduction (field->reduce); VEIR's runtime fold stores c1+c2 unreduced. Otherwise aligned.")
  -- TODO: derive the remaining 13 entries from
  --   Veir.Passes.Felt.Combine reflectively. Hand-listed here as
  --   stub-quality scaffolding — the real emitter walks the Lean
  --   definitions. Each entry must carry an LLZK-parity annotation
  --   like the two above (VEIR-only / aligned-with-caveats /
  --   exactly-aligned) so the C++ checker can pick the right
  --   assertion polarity.
]

end LlzkLean.Cert
