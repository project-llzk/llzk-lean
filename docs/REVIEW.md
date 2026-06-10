# llzk-lean — Independent Review: Status & Findings

> **Status:** in progress. Last updated 2026-06-05 (Phase 1 reproducible pins
> active; accepted VEIR pin recorded below).
> **Reviewer note:** This is an independent, adversarial review conducted at
> the maintainer's request, aimed at making the work's guarantees, tradeoffs,
> and caveats legible — especially to readers who are *not* Lean experts.
> It is deliberately critical. It does **not** conclude the work is bad; it
> concludes the work is an honest prototype whose framing currently
> outruns what is mechanically proven, and it pins down exactly where.

---

## 0. Phase 1 update — reproducible proof basis (2026-06-05)

The current accepted VEIR proof basis is
`project-llzk/veir@d4cc1bf2d31beeca17eb2e8c9c7181d04af013a3`, selected from
branch `felt-review-structural-close` and documented in
`docs/harness/PINS.md`. `lakefile.toml`, `lake-manifest.json`, and
`.lake/packages/VeIR` are now expected to agree on that commit and on the
accepted remote URL; the manifest `type`, `rev`, and `inputRev` are checked by
`scripts/harness/verify-pins.sh`.

Current Phase 1 evidence establishes:

- the dependency checkout is clean and at the accepted commit;
- `lake build` succeeds against that clean dependency;
- the Lean catalog scan sees 15 Felt pattern definitions, with 2 covered by the
  hand-authored certificate catalog and 13 intentionally reported as uncovered;
- all 15 VEIR Felt patterns remain structurally sorry-free and axiom-clean under
  the accepted pin.

This closes the old H4 stale-manifest risk. It does **not** close the remaining
assurance joints: theorem↔pattern linkage is still by convention, the Strategy E
catalog is still hand-authored for 2 of 15 patterns, Strategy A remains a
minimal parse/print differential rather than acceptance coverage, and the
interpreter work is still value-level rather than a whole-program rewrite
soundness theorem.

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

## 2. Baseline and current reproduced facts

| Item | Finding | How confirmed |
|---|---|---|
| Build | `llzk-lean` builds clean (1244 jobs) under Lean v4.30.0 | full `lake build` |
| Toolchain split | `veir` pins `v4.30.0-rc2`, `llzk-lean` pins `v4.30.0`; did **not** break this build | observed |
| **Stale manifest (H4)** | **RESOLVED by Phase 1.** `lakefile.toml`, `lake-manifest.json`, and `.lake/packages/VeIR` now point at `project-llzk/veir @ d4cc1bf2d31beeca17eb2e8c9c7181d04af013a3`; the gate also checks manifest `url`, `type`, `rev`, and `inputRev`. | `scripts/harness/verify-pins.sh --workspace-veir ../veir` |
| 15 theorems | axiom-clean: `[propext, Quot.sound]` only — no `sorryAx` | axiom audit |
| 15 patterns + the `Combine` pass | ~~carry `sorryAx`~~ **RESOLVED (F1, 2026-06-02):** all 15 patterns now axiom-clean `[propext, Classical.choice, Quot.sound]` — no `sorryAx`, no `WfIRContext.Dom`. See §3 joint 2. | axiom audit (veir `lake build` + `#print axioms`) |
| `Combine.lean` admissions | ~~140 `sorry` tokens~~ **0 (F1):** every rewriter precondition discharged in `RewriteLemmas.lean` (no `set_option warn.sorry false`) | count |
| Interpreter link | partially started — VEIR now has a value-level `add x 0 → x` interpreter bridge, but no whole-program rewrite soundness theorem and no full 18-op Felt interpreter | `veir/FOLLOWUP.md` §F2 |
| Catalog | 2 of 15 patterns; `#assertCatalogCoverage` lists the 13 uncovered | build output |
| C++ matcher | fail-closed stub ("MLIR not found"); the "26 tests" are internal `EXPECT`s across 2 ctest exes driven by a **mock** matcher — no real-IR matching is built or tested | cmake log + ctest |
| Strategy A | seed corpus now covers parse/print and canonicalization mode, with positives plus classified expected divergences; still not complete coverage | inspection + Phase 4 differential runs |

---

## 3. Central finding — the assurance chain has three unproven joints

The headline is "15 verified Felt rewrites." What is actually established,
mechanically:

```
Veir.Data.Felt.<theorem>   (all 15)  →  [propext, Quot.sound]                       ← AXIOM-CLEAN
Veir.FeltPass.<pattern>    (all 15)  →  [propext, Classical.choice, Quot.sound]     ← AXIOM-CLEAN (F1, 2026-06-02)
Veir.FeltPass.Combine      (the pass)→  [propext, Classical.choice, Quot.sound]     ← AXIOM-CLEAN (F1)
```

**Update (F1, 2026-06-02):** joint 2 below is now CLOSED. The executable
rewriter that `veir-opt -p=felt-combine` actually runs no longer depends on
`sorryAx` — all 15 patterns and the pass are axiom-clean (no `sorryAx`, no
`WfIRContext.Dom`), verified by a full `lake build` of the veir source +
`#print axioms` on each. Joints **1 and 3 remain open** (the theorem↔pattern
link is still by naming convention, and there is still no algebra↔interpreter
bridge). So "verified" now means *arithmetic identity + IR well-formedness
preservation* — still **not** semantic preservation. The three joints between
"a true lemma" and "LLZK does the right thing" are:

1. **Theorem ↔ pattern**: by naming convention only. `CertValidate.lean`
   checks the theorem *name resolves*; it does **not** check the theorem says
   anything about what the pattern does. (`#certThmExists "X"` would pass for
   `theorem X : True`.)
2. **Pattern preconditions**: ~~every rewriter well-formedness obligation is
   `sorry`'d (140 of them).~~ **CLOSED (F1, 2026-06-02):** all 140 discharged
   in `RewriteLemmas.lean` via three reusable precondition-discharging tails
   (`projectToOperand`, `replaceWithNewOp`, `replaceWithBinOpOfConst`) + a
   per-matcher in-bounds lemma library; the three facts `WfIRContext` does not
   carry (region count, result≠operand, op-has-parent) are supplied by sound
   defensive runtime guards (no `WfIRContext.Dom`). This establishes IR
   *well-formedness* preservation, not semantic preservation (joint 3).
3. **Algebra ↔ IR semantics**: the abstract `Veir.Data.Felt.add` (a thin
   `ZMod p` wrapper) is still not connected to a whole-program
   `interpret(after rewrite) = interpret(before rewrite)` theorem. VEIR now has
   a value-level PoC for `add x 0 → x` (`Veir/Passes/Felt/InterpModel.lean`),
   but that is not a general rewrite-soundness bridge.

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
- **C1** The unproven joints (§3). **Joint 2 (sorry'd preconditions) is now
  CLOSED (F1, 2026-06-02).** Joints 1 (theorem↔pattern by naming) and 3
  (missing interpreter link) remain — "verified" still means arithmetic
  identity + IR well-formedness, not semantic preservation.
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
- **H3** Strategy A is still seed coverage: Phase 4 now runs a
  canonicalization-aware differential over a reviewed small corpus, but the
  corpus is not close to full `llzk-lib/test/Dialect/Felt/` coverage. The next
  blockers are clean-pin consumption, field-registry/modular-reduction parity,
  and broader fold/no-fire cases.
- **H4** Stale `lake-manifest.json` (see §2) — **resolved by Phase 1 gates**.

**Medium:** M1 no CI axiom-gate (the `warn.sorry false` admits are gone as of
F1, but a CI `#print axioms` gate to *prevent regressions* is still absent); M2
`#assertCatalogCoverage` remains a shape heuristic rather than reflective
metadata; M3 three namespaces for one unit (`Veir.FeltPass` /
`Veir.Data.Felt` / path `Passes/Felt`); M4 `constant_fold_add` is now marked
`aligned` under registered-field side conditions, but the cert is still
hand-authored rather than derived from the VEIR pattern body.

**Low:** L1 `JsonParser` `LLONG_MAX_REL_LIMIT` misnamed + most-negative-int64
edge; L2 README "26 tests / 15 verified" reads as more coverage than the stubs
deliver; L3 historical branch references should stay confined to historical
evidence, not live setup docs.

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
- **Add (research):** widen the value-level interpreter bridge and, if needed,
  build the much larger whole-program rewrite-soundness framework.

The legitimate worry is **sequencing**, not quality: the project built
horizontal scaffolding around a vertical hole (no single rewrite has a closed
IR→semantics→algebra chain). Fix by going **depth-first**: close one rewrite
end-to-end, then widen.

**Strategic caveat (not about this repo):** the ceiling on "fully verified
rewrites" is set by VEIR. Its README marks the peephole rewriter "Complete"
but *not* "Verified"; no VEIR pass has a closed rewrite→interpreter theorem.
The current Felt interpreter work is a scoped value-level model with a
name→prime registry, not a complete whole-program semantics story for all 18
Felt ops. How deep a guarantee is reachable is a VEIR-maturity question,
identical whether this code is kept or rewritten.

---

## 6. Historical spike — structural close superseded by 15/15 closure

The salvage thesis was tested, not asserted, and the result is now landed in
the veir repo. This section records the original 2-pattern spike, which has now
been superseded by the F1 close: **all 15 of 15 Felt patterns are fully
sorry-free and axiom-clean** (`[propext, Classical.choice, Quot.sound]` — no
`sorryAx`, no `WfIRContext.Dom` axiom). The original spike covered one pattern
per structural shape:
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
why every VEIR pass `sorry`s these). The remaining 13 patterns were completed
with the same library + recipe. See `veir/REVIEW.md` §0 and `veir/FOLLOWUP.md`.

---

## 7. Working-tree state / housekeeping

- Phase 1 pin state is explicit: `lakefile.toml`, `lake-manifest.json`, and
  `.lake/packages/VeIR` are expected to agree on
  `project-llzk/veir@d4cc1bf2d31beeca17eb2e8c9c7181d04af013a3`.
- The structural-close lemmas + all 15 verified patterns now live in the veir
  repo (`Veir/Passes/Felt/RewriteLemmas.lean`); the `Spike*.lean` scratch files
  used to develop them have been removed.
- `.mcp.json` (at the `/home/alh/LLZK` session root, not in this repo) — adds
  the `lean-lsp` MCP server pinned to this project.

### veir repo changes (companion)
- `Veir/Passes/Felt/RewriteLemmas.lean` — verified patterns + lemma library.
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
