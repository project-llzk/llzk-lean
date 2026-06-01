# llzk-lean — Independent Review: Status & Findings

> **Status:** in progress. Last updated 2026-06-01.
> **Reviewer note:** This is an independent, adversarial review conducted at
> the maintainer's request, aimed at making the work's guarantees, tradeoffs,
> and caveats legible — especially to readers who are *not* Lean experts.
> It is deliberately critical. It does **not** conclude the work is bad; it
> concludes the work is an honest prototype whose framing currently
> outruns what is mechanically proven, and it pins down exactly where.

---

## 1. Scope & method

Reviewed: the `llzk-lean` bridge in full (cert layer, emitter, C++ checker,
differential harness, CI, strategy/future docs), plus the VEIR-side Felt
*proof core* it depends on, plus LLZK's C++ Felt dialect for the
faithfulness comparison.

Method — grounded in reproduced fact, not reading alone:
- Full from-scratch `lake build` of `llzk-lean` (1244 jobs; Mathlib via
  `lake exe cache get`).
- `#print axioms` / `lean_verify` axiom audits.
- C++ checker built (`cmake` + `g++`, no MLIR) and `ctest` run.
- A structural-proof spike using the `lean-lsp` MCP server.

**Not yet reviewed** (tracked separately): the VEIR Felt-dialect *port itself*
— parser/printer, type system, op coverage, pass wiring, tests, differential
normalizer. See §8.

---

## 2. Phase 0 baseline (reproduced facts)

| Item | Finding | How confirmed |
|---|---|---|
| Build | `llzk-lean` builds clean (1244 jobs) under Lean v4.30.0 | full `lake build` |
| Toolchain split | `veir` pins `v4.30.0-rc2`, `llzk-lean` pins `v4.30.0`; did **not** break this build | observed |
| **Stale manifest (H4)** | `lake-manifest.json` pinned `alexanderlhicks/veir @ bf086362` (personal fork, **3 commits old, predates the parser fix `ab77c1c57`**) while `lakefile.toml` pins `project-llzk/veir @ 09d5f00f0`. A plain local `lake build` builds the wrong/older proof basis. | git ancestry; **remediated** by `lake update` (uncommitted) |
| 15 theorems | axiom-clean: `[propext, Quot.sound]` only — no `sorryAx` | axiom audit |
| 15 patterns + the `Combine` pass | carry `sorryAx`: `[propext, sorryAx, Classical.choice, Quot.sound]` | axiom audit |
| `Combine.lean` admissions | **140 `sorry` tokens** across the 15 patterns (`set_option warn.sorry false`) | count |
| Interpreter link | absent — `Veir.Data.Felt` is imported only by `Proofs.lean` + its own `Basic.lean` | grep |
| Catalog | 2 of 15 patterns; `#assertCatalogCoverage` lists the 13 uncovered | build output |
| C++ matcher | fail-closed stub ("MLIR not found"); the "26 tests" are internal `EXPECT`s across 2 ctest exes driven by a **mock** matcher — no real-IR matching is built or tested | cmake log + ctest |
| Strategy A | one positive corpus file, parse-print only (no canonicalization) | inspection |

---

## 3. Central finding — the assurance chain has three unproven joints

The headline is "15 verified Felt rewrites." What is actually established,
mechanically:

```
Veir.Data.Felt.<theorem>   (all 15)  →  [propext, Quot.sound]                          ← AXIOM-CLEAN
Veir.FeltPass.<pattern>    (all 15)  →  [propext, sorryAx, Classical.choice, Quot.sound]
Veir.FeltPass.Combine      (the pass)→  [propext, sorryAx, Classical.choice, Quot.sound] ← carries sorryAx
```

The detached algebraic lemmas are fully proven; the **executable rewriter
that `veir-opt -p felt-combine` actually runs — and that the certificates
point at — transitively depends on `sorryAx`.** What is verified and what
runs are different objects. The three joints between "a true lemma" and "LLZK
does the right thing" are:

1. **Theorem ↔ pattern**: by naming convention only. `CertValidate.lean`
   checks the theorem *name resolves*; it does **not** check the theorem says
   anything about what the pattern does. (`#certThmExists "X"` would pass for
   `theorem X : True`.)
2. **Pattern preconditions**: every rewriter well-formedness obligation is
   `sorry`'d (140 of them).
3. **Algebra ↔ IR semantics**: the abstract `Veir.Data.Felt.add` (a thin
   `ZMod p` wrapper) is never connected to the IR op `OpCode.felt Felt.add`'s
   interpreter meaning. No such bridge exists anywhere in VEIR.

Two framing caveats worth stating to non-Lean readers:
- **The verified subset is the *easy* subset.** All 15 are commutative-ring
  identities holding for *any* `ZMod p` (incl. `p = 0, 1` — so "field" is a
  misnomer; primality is unused). The operations where field/prime semantics
  are load-bearing — `div`, `inv`, `pow`, the bit ops, int-div/mod — have
  **no pattern and no proof**.
- **Implementation folds over unbounded `Int`; proofs are over `ZMod p`.** The
  reconciliation ("unreduced `Int` coerced into `ZMod p` equals the reduced
  value") is true but asserted in prose, not proved.

---

## 4. Findings catalog

**Critical** (assurance-defining; must be made explicit, not necessarily "fixed"):
- **C1** The three unproven joints (§3). "Verified" overclaims relative to the
  `sorry`'d preconditions and the missing interpreter link.
- **C2** Cert structural fields (`lhs`/`rhs`/`conditions`/`parity`/`scope`) are
  hand-authored and unvalidated against either VEIR or LLZK — yet Strategy E's
  entire value rests on their accuracy.
- **C3** The C++ checker (the designated trusted base) has no working matcher
  and is untested against any real IR.

**High:**
- **H1** Live cert↔pattern drift: `right_identity_zero_add`'s cert sets
  `commutative: true`, but the VEIR pattern matches only `add x (const 0)`
  (one-sided). Harmless today (it's `veir-only`) but a real instance of the
  C2 risk that nothing catches.
- **H2** `#certThmExists` is a weak invariant (name-resolution only).
- **H3** Strategy A demonstrates little yet: 1 file, parse-print only; LLZK has
  zero Felt canonicalizers and its folds no-op on unnamed fields, so
  fold-agreement is currently unreachable (named-field path parser-blocked).
- **H4** Stale `lake-manifest.json` (see §2) — **remediated** (uncommitted).

**Medium:** M1 no CI axiom-gate / `warn.sorry false` hides admits; M2
`#assertCatalogCoverage` uses fragile base-name heuristics; M3 three namespaces
for one unit (`Veir.FeltPass` / `Veir.Data.Felt` / path `Passes/Felt`); M4
`constant_fold_add` "aligned-with-caveats" understates that VEIR folds
unconditionally while LLZK requires a registered field name.

**Low:** L1 `JsonParser` `LLONG_MAX_REL_LIMIT` misnamed + most-negative-int64
edge; L2 README "26 tests / 15 verified" reads as more coverage than the stubs
deliver; L3 VEIR README still references the dropped `llzkfelt_test1` branch.

---

## 5. Verdict — salvage and re-sequence, do not restart

Nothing found is *incorrect*. The proven core is real and axiom-clean; the
VEIR substrate already ships a sorry-free `WfRewriter` layer that
`PatternRewriter` wraps (its `replaceValue`/`eraseOp`/… take `:= by grind`
default-arg preconditions — the Felt patterns simply passed `sorry` instead of
discharging them). So:

- **Keep:** the 15 theorems, the VEIR Felt IR, the cert schema + versioning
  discipline, the JSON parser/loader, the polarity orchestrator, the
  differential harness, the docs.
- **Add (incremental):** discharge the preconditions via `WfRewriter`; derive
  cert structural fields from the patterns (kills C2/H1/H2 by construction);
  a working C++ matcher; reframed claims.
- **Add (research):** the one load-bearing bridge — `eval(IR op) =
  Veir.Data.Felt.op` — which is net-new under *any* plan.

The legitimate worry is **sequencing**, not quality: the project built
horizontal scaffolding around a vertical hole (no single rewrite has a closed
IR→semantics→algebra chain). Fix by going **depth-first**: close one rewrite
end-to-end, then widen.

**Strategic caveat (not about this repo):** the ceiling on "fully verified
rewrites" is set by VEIR. Its README marks the peephole rewriter "Complete"
but *not* "Verified"; no VEIR pass has a closed rewrite→interpreter theorem;
felt isn't in the interpreter; the interpreter's value domain is fixed-width
`LLVM.Int`/`BitVec`, not `ZMod p`; and `!felt.type` pins no prime, so there is
no canonical runtime meaning to bridge to. How deep a guarantee is reachable
is a VEIR-maturity question, identical whether this code is kept or rewritten.

---

## 6. Spike — structural close: DONE (both shapes, landed in veir)

The salvage thesis was tested, not asserted, and the result is now landed in
the veir repo: **2 of 15 Felt patterns are fully sorry-free and axiom-clean**
(`[propext, Classical.choice, Quot.sound]` — no `sorryAx`, no `WfIRContext.Dom`
axiom), one per structural shape:
- `right_identity_zero_add` — projection shape (`replaceValue` + `eraseOp`).
- `constant_fold_add` — synthesis shape (`createOp` + `replaceOp`).

Both live in `veir/Veir/Passes/Felt/RewriteLemmas.lean` with a reusable lemma
library (matchOp specs; `replaceValue`/`createOp` postcondition wrappers);
`Combine.lean` imports them. Verified by a full `lake build` under veir's
`v4.30.0-rc2` toolchain + `#print axioms`.

**Refined finding (corrects the earlier "just assembly" framing).** Discharging
the IR-mutation preconditions needs three facts `WfIRContext` does **not** carry:
the matched op's region count, SSA acyclicity (result ≠ operand), and the op
having a parent block. VEIR supplies SSA acyclicity only via the
**`axiom WfIRContext.Dom`**. We avoid that axiom with sound **defensive runtime
guards** (each only skips the rewrite in states impossible in well-formed IR).
So the structural close is achievable and axiom-clean — but it is *not* free
assembly; it surfaces that VEIR's well-formedness model omits per-opcode shape
constraints and SSA dominance (a substrate limitation, not a Felt defect — it's
why every VEIR pass `sorry`s these). The remaining 13 patterns are mechanical
follow-up on the same library + recipe. See `veir/REVIEW.md` §0 and
`veir/FOLLOWUP.md`.

---

## 7. Working-tree state / housekeeping

- `lake-manifest.json` — **modified** (the H4 fix; `lake update` repointed it
  to `project-llzk/veir @ 09d5f00f0`).
- The structural-close lemmas + the 2 verified patterns now live in the veir
  repo (`Veir/Passes/Felt/RewriteLemmas.lean`); the `Spike*.lean` scratch files
  used to develop them have been removed.
- `.mcp.json` (at the `/home/alh/LLZK` session root, not in this repo) — adds
  the `lean-lsp` MCP server pinned to this project.

### veir repo changes (companion)
- `Veir/Passes/Felt/RewriteLemmas.lean` — **new**; verified patterns + lemma library.
- `Veir/Passes/Felt/Combine.lean` — VC1 docstring, VC3 guards, imports + uses the
  verified patterns (old sorry-laden defs removed).
- `Veir/Passes/Felt/Proofs.lean` — VM1 citation fix.
- `REVIEW.md`, `FOLLOWUP.md` — **new** (veir findings + backlog).

---

## 8. Not yet covered — the VEIR Felt-dialect port

The *proof core* of the VEIR port is well-understood and validated above. The
*dialect plumbing* is essentially un-reviewed: the FeltConstAttr / FeltType
parser & printer, op coverage (18 opcodes declared vs. ~5 wired through),
pass registration, the FileCheck tests, and the differential normalizer. A
dedicated, adversarial review of the VEIR Felt port is the next workstream
(see the accompanying veir review plan).
