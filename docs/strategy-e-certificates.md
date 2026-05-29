# Strategy E — Proof-certificate generator

## Concrete picture

A new flag for LLZK: `llzk-opt --verify-rewrites=<cert.json>`. When
set, LLZK loads the certificate catalog and registers a pattern-rewriter
listener; every time the canonicalizer applies a rewrite, the listener
calls into a small C++ checker that verifies the rewrite conforms to
one of the certificates. Mismatches abort the pass with a precise
diagnostic.

The certificates are produced from VEIR's verified Lean theorems by
this repo's `emit-certs` executable:

```bash
lake exec emit-certs > certs/felt-combine.cert.json
```

Each entry in the certificate file describes one verified rewrite
pattern: identifier, LHS shape, RHS shape, side conditions, and the
name of the Lean theorem that justifies it.

## Architecture

```
            ┌──────────────────────────┐
            │ Veir/Passes/Felt/        │   Lean: verified rewrite catalog
            │   Combine.lean           │   + paired theorems
            │   Proofs.lean            │
            └────────────┬─────────────┘
                         │
                         │  lake exec emit-certs
                         ▼
            ┌──────────────────────────┐
            │ certs/felt-combine.      │   JSON: certificate catalog
            │   cert.json              │   (committed for review)
            └────────────┬─────────────┘
                         │
                         │  consumed by llzk-opt at startup
                         ▼
            ┌──────────────────────────┐
            │ LLZKVerifyRewritesPass   │   C++: pattern-rewriter listener
            │   (in llzk-lib after     │   + structural checker
            │    upstreaming)          │   = the *trusted base*
            └──────────────────────────┘
```

## Trusted base added

The **C++ checker** (`checker/src/CertChecker.{h,cpp}`, ~500 LoC
when complete). Lean's kernel produces certificates that are *re-checked
structurally* by the C++ code; the Lean side is not in the runtime TCB.

This is the canonical "small TCB" architecture, used by:
- Coq's CompCert (certificates from Coq, checked by an OCaml-extracted
  validator)
- HOL Light's proof-export pipelines
- Most "verified compiler" success stories with a non-trusted output
  stage

## Assurance gained

LLZK's runtime behavior on every covered rewrite is *certifiably
equivalent* to the Lean spec. Stronger than Strategy A on two axes:

1. **Coverage**: every invocation of LLZK is checked, not just the
   curated CI corpus.
2. **Formality**: the LLZK↔Lean equivalence is by proof (the
   certificate is the proof's contract; the checker re-validates it),
   not by observation.

The proof's content stays in Lean. The checker only verifies the
*shape* of LLZK's transformation matches what the proof covered.

## Functionality delivered

LLZK gains an opt-in `--verify-rewrites` flag. Users who care about
audit trails turn it on (with a runtime cost: an extra structural
check per rewrite). Users who don't, see no change.

A by-product: the certificate catalog itself is a machine-readable
description of LLZK's verified rewrite contract, useful for:
- Documentation (each cert has a `description` field).
- External tooling that wants to know what LLZK is guaranteed to do.
- Cross-checking against other implementations (a third Felt
  implementation can validate against the same certs).

## Certificate format (v0.2.0)

JSON, hand-rolled rather than depending on a JSON library to keep the
checker TCB small.

```json
{
  "schemaVersion": "0.2.0",
  "source": "VEIR Veir.Passes.Felt.Combine (stub catalog — 2 of 15 patterns)",
  "_note": "Hand-listed catalog. The full 15-pattern catalog will be derived reflectively...",
  "_aboutLlzkParityStatus": "Per-cert tag indicating how a VEIR rewrite relates to LLZK's runtime...",
  "certs": [
    {
      "patternId": "constant_fold_add",
      "rootKind": "felt.add",
      "lhs": {
        "kind": "opResult",
        "opKind": "felt.add",
        "operands": [
          {"kind": "const", "opKind": "felt.const"},
          {"kind": "const", "opKind": "felt.const"}
        ],
        "commutative": true
      },
      "rhs": {"kind": "const", "opKind": "felt.const"},
      "conditions": [
        {"kind": "sameAttr", "attr": "fieldName", "positions": ["lhs", "rhs"]},
        {"kind": "attrInRegistry", "pos": "lhs", "attr": "fieldName", "registry": "field"}
      ],
      "theoremName": "Veir.Data.Felt.constant_fold_add",
      "llzkParityStatus": "aligned-with-caveats",
      "description": "felt.add (felt.const c1) (felt.const c2) → felt.const (c1+c2). Caveat: LLZK applies modular reduction; VEIR's runtime fold stores c1+c2 unreduced."
    },
    ...
  ]
}
```

Top-level keys:
- `schemaVersion` — see §"Versioning policy" below for semantics.
- `source` — free-form string identifying the emitter; the emitter
  appends a `(stub catalog — N of 15 patterns)` suffix while the
  catalog is still hand-listed.
- `_note` and `_aboutLlzkParityStatus` — informational header
  fields. Per §"Versioning policy", keys starting with `_` are
  informational; emitters MAY add or remove them across patch
  versions; readers MUST ignore them.
- `certs` — the per-pattern array.

Per-cert fields:

- `patternId` — stable identifier; matches the Lean `def` in
  `Veir/Passes/Felt/Combine.lean`. Updates to the pattern require a
  matching `patternId` change so old certs are detected as stale.
- `rootKind` — the op kind at the root of the LHS match. Indexed by
  the checker for O(1) dispatch on `mlir::Operation::getName()`.
- `lhs`, `rhs` — `OperandShape` trees. See below.
- `conditions` — array of side conditions. See below.
- `theoremName` — Lean theorem name. **For diagnostics only**; the
  checker does not re-execute the proof.
- `llzkParityStatus` *(added in v0.1.1)* — assertion polarity
  selector. One of `"aligned"`, `"aligned-with-caveats"`, or
  `"veir-only"`.
- `scope` *(added in v0.2.0, optional)* — scope assertion. Today's
  sole constructor is `{"kind": "withinAttr", "attr": "<attr-name>"}`,
  expressing "the matched op must live inside a surrounding op
  carrying this discardable attribute." Captures LLZK's
  `NotFieldNative` context-gating.
- `description` — free-form human-readable summary. As of v0.1.1,
  parity-status framing belongs in `llzkParityStatus`, not in this
  field.

### `OperandShape` constructors

| `kind` | Other fields | Semantics |
|---|---|---|
| `"any"` | — | Matches any value. |
| `"const"` | `opKind`, optional `value` *(v0.2.0)* | Matches a constant of `opKind`; when `value` is present, the constant must equal `value`. |
| `"opResult"` | `opKind`, `operands[]`, optional `commutative` *(v0.2.0)* | Matches a result of `opKind` whose operands recursively match `operands[]`. When `commutative` is `true`, operands may match in any order. |

### `SideCondition` constructors

| `kind` | Other fields | Semantics |
|---|---|---|
| `"sameValue"` | `lhs`, `rhs` | The two named positions must alias (same SSA value). |
| `"constEquals"` | `pos`, `value` | Constant at `pos` must equal `value`. *(v0.1.x.)* |
| `"sameAttr"` *(v0.2.0)* | `attr`, `positions[]` | Each position must carry the same value for the named attribute. Used for field-name match across LLZK `FeltConstAttr`s. |
| `"attrInRegistry"` *(v0.2.0)* | `pos`, `attr`, `registry` | The attribute at `pos` must resolve to an entry in the named registry. Used for "field name is one of LLZK's built-in fields." |
| `"constCompare"` *(v0.2.0)* | `pos`, `op`, `value` | Value comparison where `op ∈ {eq, ne, lt, le, gt, ge}`. Used for non-zero divisor, shift bound, etc. **New constructor** rather than a mutation of `constEquals` — see §Versioning policy for why. |
| `"resultTypeFromOperand"` *(v0.2.0)* | `pos` | The rewrite's result type equals the type of the named operand. Captures LLZK's `InferTypeOpAdaptor` discipline. |

### `pos` mini-language

The `pos` field on `constEquals`, `constCompare`, `attrInRegistry`,
and `resultTypeFromOperand` is a dotted-bracket path:

```
path    := root ("." segment)*
root    := "lhs" | "rhs"
segment := "operand[" digit+ "]"
```

Examples:
- `"rhs"` — the RHS operand of the matched root op.
- `"lhs"` — the LHS operand.
- `"lhs.operand[0]"` — the LHS, then its first operand (for nested
  patterns like `felt.add (felt.add x c1) c2`).

When v0.3.0 needs a richer query language, it will add a new field
`pathV2` rather than redefining `pos`.

## Versioning policy

The cert file's `schemaVersion` follows semver:

- **Patch bumps** (`0.1.0` → `0.1.1`): additive only. New fields
  added; existing fields keep their semantics. A v0.1.0-only reader
  consuming a v0.1.1 file is required to **ignore unknown JSON
  keys**; the v0.1.1-only field `llzkParityStatus` does not change
  the semantics of fields that v0.1.0 understood.

  **Safety condition on additive fields**: a patch bump must not
  add a field whose *absence* would silently flip a default in
  older readers in an unsafe direction. Concretely: if some older
  reader picked assertion polarity by grepping `description` for
  the bracketed `[VEIR-only]` token (v0.1.0's encoding), then a
  v0.1.1 cert whose description no longer carries that token but
  whose `llzkParityStatus` is `veir-only` could be silently
  misclassified by the older reader as `aligned`. This is OK
  *only* if the older reader's default was already fail-closed
  (always assert exact match). For v0.1.1 specifically: no v0.1.0
  reader was ever shipped, so this is moot — but as a forward
  principle, additive fields must come with a stated default that
  older readers can safely assume.

- **Informational `_`-prefixed keys**: keys whose name begins
  with `_` (e.g., `_note`, `_aboutLlzkParityStatus`) are
  informational. Emitters MAY add or remove them across patch
  versions without bumping `schemaVersion`; readers MUST ignore
  them. These exist for self-describing the wire format to a
  human inspecting the JSON; they are not load-bearing for the
  C++ checker.

- **Minor bumps** (`0.1.x` → `0.2.0`): may introduce new
  constructors for the open enums (`OperandShape.Kind`,
  `SideCondition.Kind`, `LlzkParityStatus`). A reader at an older
  minor version that encounters an unknown constructor **must**
  reject the file (return an error from `loadCertCatalog`) rather
  than silently treat as default — silent default would let a
  stale checker accept a rewrite a new cert doesn't actually
  justify.

  **Recommended dispatch shape** (for the C++ checker's
  enum-parsing code, to prevent permissive defaults from sneaking
  in):
  ```cpp
  if      (s == "any")      return Kind::Any;
  else if (s == "const")    return Kind::Const;
  else if (s == "opResult") return Kind::OpResult;
  else { *errMsg = "unknown OperandShape.kind: " + s; return std::nullopt; }
  ```
  An exhaustive `if`/`else if` chain terminating in a `nullopt` /
  error return is the correct shape. A `switch` on a pre-parsed
  enum after a string→enum lookup table is equivalent. **Forbidden
  anti-patterns**: `Kind k = parseKind(s); // returns Any on
  unknown` would let stale checkers accept rewrites they don't
  model.

- **Major bumps** (`0.x` → `1.0`): may break field semantics. Old
  readers must reject.

The checker stance (when implemented): default rejects
`schemaVersion` lower than the checker's compiled-in version (the
cert may rely on a constructor the checker doesn't know about) and
lower-major versions. Accept patch-higher versions and ignore
unknown keys. An override flag `--accept-schema=*` may be added
later for explicit downgrades.

## What this v1 needs

Current state (2026-05-29):
- ✅ Schema v0.2.0 (defined here + `LlzkLean/Cert.lean`). Closes
  the v0.1.1 known schema gaps; see "Schema gaps closed in v0.2.0"
  below for the audit trail.
- ✅ Emitter (`EmitCerts.lean`) writes 2 of 15 patterns at v0.2.0.
  Reflective derivation from VEIR's `Combine.lean` is the next
  catalog-expansion deliverable (see "Outstanding work" #1).
- ✅ Committed snapshot at `certs/felt-combine.cert.json` matches
  emitter output exactly (`.github/workflows/certify.yml` enforces
  this with a `diff`).
- ✅ C++ checker skeleton (`checker/src/`) compiles; exposes the
  `loadCertCatalog` and `checkRewrite` API; fail-closed by default —
  JSON parser returns `nullopt` and the structural matchers return
  `false` unconditionally until the real implementations land.

### Schema gaps closed in v0.2.0

The external-alignment audit (commit `3c33115`) identified seven
gaps in v0.1.1. The v0.2.0 schema resolves all of them:

- **Field-name-match side condition** → `sameAttr` constructor with
  `positions[]`. E.g.
  `{"kind":"sameAttr","attr":"fieldName","positions":["lhs","rhs"]}`.
- **Field-resolves-in-registry condition** → `attrInRegistry`
  constructor. E.g.
  `{"kind":"attrInRegistry","pos":"lhs","attr":"fieldName","registry":"field"}`.
- **Operand-is-nonzero condition** → `constCompare` constructor
  with `op ∈ {eq,ne,lt,le,gt,ge}`. E.g.
  `{"kind":"constCompare","pos":"rhs","op":"ne","value":0}`.
  (Introduced as a **new constructor** rather than mutating
  `constEquals` — mutating would let v0.1.x readers silently
  misclassify; see §Versioning policy.)
- **Shift-amount-bounded condition** → reuse `constCompare` with
  `"op":"ge"` against the bitwidth constant.
- **Inferred-result-type assertion** → `resultTypeFromOperand`
  constructor.
- **Commutative-trait-aware matching** → optional
  `"commutative": true` flag on `OperandShape.opResult`. Old
  readers ignoring the flag reject commutative matches harmlessly
  (false reject, never false accept).
- **`NotFieldNative` scope assertion** → optional per-cert `scope`
  field with the `withinAttr` constructor.

`LlzkParityStatus` was the eighth gap, closed earlier in v0.1.1.

A v0.3.0 will be needed if/when we want richer `pos` queries
beyond the dotted-bracket grammar documented above, or if the
`OperandShape.const.value` payload grows beyond integers.

Outstanding work to reach v1:

1. **Reflective derivation of the catalog** from VEIR's
   `Veir.Passes.Felt.Combine` so adding a new pattern in Lean
   automatically produces a new certificate. Today the catalog is
   hand-listed in `LlzkLean/Cert.lean:feltCombineCatalog`. Estimate:
   ~1 engineer-week.

2. **Complete the C++ checker.** Implement `matchShape` against
   `mlir::Operation`'s generic interface (`getName()`, `getOperand()`,
   `getDefiningOp()`, `getValue()` for constants). Estimate: ~2
   engineer-weeks.

3. **Hand-roll the JSON parser** (~150 LoC). Removes the JSON library
   from the TCB.

4. **LLZKVerifyRewritesPass.** Wire the checker as an MLIR pass that
   subscribes to pattern-rewriter events. Estimate: ~1 engineer-week.

5. **PR `llzk-lib`** to add the `--verify-rewrites` flag, the pass,
   and the checker library. **Requires Veridise cooperation.**

6. **Integration tests.** A small lit suite that feeds known-good
   inputs through `llzk-opt --verify-rewrites=...` and asserts the
   pass terminates cleanly; another that feeds inputs that *should*
   reject and asserts the pass exits non-zero with the right
   diagnostic.

## Effort

**3-5 engineer-months to reach v1** for the Felt dialect, contingent
on Veridise accepting the upstream PR. The technical scope is
well-understood (Coq/HOL have done this exact pattern); the schedule
risk is upstream alignment.

## Dependence on Veridise / LLZK maintainers

**High.** The C++ checker has to land in `llzk-lib` for the
end-to-end story to work. We can ship a fork or out-of-tree pass
plugin as a backup, but the demonstrated win is when `llzk-opt
--verify-rewrites` works on the canonical distribution.

A conservative path: build the checker + pass out-of-tree under
`checker/` here, demonstrate it standalone (with a small `llzk-opt`-
equivalent driver that links our pass), and only then PR `llzk-lib`
with the upstream-ready version.

## Why this is the recommended second step

- Lifts Strategy A's evidence into a runtime guarantee.
- Small TCB addition (~500 LoC of well-scoped C++).
- Each Lean theorem in `Veir.Passes.Felt.Proofs` automatically
  becomes a runtime contract on LLZK; adding a new verified pattern
  in Lean automatically gives LLZK a new verified canonicalizer
  (modulo a re-emit + cert-file commit).
- The work product is composable: if downstream tooling wants
  guarantees about LLZK's behavior, they can read the cert catalog.

## Acceptance criteria for v1

- `lake exec emit-certs` produces a complete catalog for the 15
  current VEIR Felt patterns.
- C++ checker validates every entry in that catalog when applied to
  hand-authored test inputs.
- `LLZKVerifyRewritesPass` lands in `llzk-lib` (PRed or vendored)
  and is exercised by lit tests.
- Documentation describes the trust boundary and the auditing
  procedure.
