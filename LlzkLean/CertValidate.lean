import LlzkLean.Cert
import Veir.Passes.Felt.Combine
import Veir.Passes.Felt.Proofs

/-!
  # Build-time validation of the cert ↔ VEIR linkage

  Each cert in `LlzkLean.Cert.feltCombineCatalog` is anchored to two
  VEIR-side declarations:
  - `Veir.Passes.Felt.Combine.<patternId>` — the rewrite *pattern*
    (a `def` returning `Option (PatternRewriter OpCode)`).
  - `Veir.Data.Felt.<patternId>` — the soundness *theorem* (a `Prop`
    proven over `ZMod p`).

  This file enforces both linkages at build time:

  1. `#certThmExists "<theoremName>"` — checks the theorem name
     resolves in the imported environment. From Wave 3B.

  2. `#assertCatalogCoverage` — walks `Veir.Passes.Felt.Combine`'s
     namespace and reports any def whose `patternId` *isn't* in
     `feltCombineCatalog`. Today we treat missing coverage as a
     diagnostic (informational `logInfo`) rather than an error,
     because the catalog is intentionally a 2-of-15 stub. When the
     reflective-catalog work matures to mandate full coverage,
     flip this to `throwError`.

  ## What this does NOT do (vs the full W3C scope)

  - Does not auto-synthesize cert entries. Each cert still needs to
    be hand-authored in `feltCombineCatalog` with its structural
    fields (lhs, rhs, conditions, parity). This file only enforces
    that the *patternId* string matches a real VEIR def.
  - Does not verify the cert's structural claims match VEIR's
    pattern body. That would require deeper static analysis of
    the `def` body in VEIR; deferred to a future iteration once
    VEIR-side metadata (e.g., a `@[cert_spec ...]` attribute) lands.
-/

namespace LlzkLean.Cert

open Lean Elab Command in
/--
  Build-time assertion that the fully-qualified Lean name `nameStr`
  resolves to a declaration in the current environment.
-/
elab "#certThmExists " nameStr:str : command => do
  let env ← getEnv
  let n := nameStr.getString.toName
  unless env.contains n do
    throwError s!"cert.theoremName '{n}' does not resolve to any declaration in the imported environment. Either the VEIR pin in lakefile.toml is stale (re-fetch + bump the SHA), or `LlzkLean.Cert.feltCombineCatalog` references a theorem name that VEIR renamed/removed."

open Lean Elab Command in
/--
  Walks VEIR's pattern namespace (`Veir.FeltPass`, despite the file
  path `Veir/Passes/Felt/Combine.lean` — VEIR uses a flatter
  namespace) and reports which defs are *not* yet covered by a cert
  in `feltCombineCatalog`. Also catches the inverse: catalog entries
  whose `patternId` doesn't correspond to any VEIR def (would
  indicate a typo or a VEIR-side rename).

  Emits `logInfo` for missing coverage (informational; today's
  catalog is intentionally a 2-of-15 stub) and `throwError` for
  catalog entries pointing at non-existent VEIR defs (a real
  consistency violation).
-/
elab "#assertCatalogCoverage" : command => do
  let env ← getEnv
  -- VEIR's pattern defs live under `Veir.FeltPass`. The theorems
  -- live under `Veir.Data.Felt` (checked separately via
  -- #certThmExists). The file path is `Veir/Passes/Felt/Combine.lean`
  -- but Lean namespaces are independent of file paths.
  let nsPrefix : Name := `Veir.FeltPass
  -- Helper: the patterns we care about have *exactly one* dot
  -- segment after the namespace (Veir.FeltPass.<patternId>), not
  -- deeper (which would be e.g. Veir.FeltPass._auxLemma_42).
  let mut veirPatternIds : List String := []
  for (n, info) in env.constants.toList do
    match n, info with
    | .str parent baseName, .defnInfo _ =>
      -- Filter to rewrite-pattern defs only. VEIR's pattern namespace
      -- also contains:
      --   - `matchAdd`, `matchSub`, ... — helper matchers (start with
      --     "match"); these are infrastructure, not verified patterns.
      --   - `Combine` — the assembled Pass itself (combines the
      --     individual pattern functions).
      --   - `Combine.impl` — the pass body (compound name; filtered
      --     by the `Name.str parent baseName` pattern only matching
      --     single-segment names below the namespace).
      -- A rewrite pattern's base name doesn't start with `match` or
      -- `Combine` and isn't an internal `_*` name.
      let isHelper := baseName.startsWith "match"
      let isPass   := baseName == "Combine"
      let isInternal := baseName.startsWith "_"
      if parent == nsPrefix && !isHelper && !isPass && !isInternal then
        veirPatternIds := baseName :: veirPatternIds
    | _, _ => pure ()
  let catalogIds := feltCombineCatalog.map (·.patternId)
  -- Forward direction: which VEIR pattern defs lack a cert? (informational)
  let uncovered := veirPatternIds.filter (fun id => ¬ catalogIds.contains id)
  -- Reverse direction: which catalog entries point at a VEIR def
  -- that doesn't exist? (error — this is real rot)
  let stale := catalogIds.filter (fun id => ¬ veirPatternIds.contains id)
  if !stale.isEmpty then
    throwError s!"[#assertCatalogCoverage] FAIL: catalog entries reference patternId(s) that VEIR doesn't ship as a verified rewrite pattern: {stale}. This is a consistency violation — either the VEIR pin in lakefile.toml is stale, the patternId is a typo, or the def in question is a helper matcher (not a verified pattern) and shouldn't have a cert."
  logInfo s!"[#assertCatalogCoverage] {veirPatternIds.length} VEIR rewrite-pattern defs found in Veir.FeltPass; catalog covers {catalogIds.length} of them; {uncovered.length} uncovered (stub status; expected 13 today). Uncovered: {uncovered}"

-- v0.2.0 catalog has 2 certs. The `Cert.mk'` smart constructor in
-- `LlzkLean/Cert.lean` derives `theoremName` from `patternId` so
-- the two cannot drift. We still emit per-cert checks here so a
-- patternId pointing at a def that VEIR doesn't ship would surface
-- at build time.
#certThmExists "Veir.Data.Felt.right_identity_zero_add"
#certThmExists "Veir.Data.Felt.constant_fold_add"

-- Walks Veir.Passes.Felt.Combine and reports uncovered patterns
-- as a logInfo (not an error — see the elab's doc-comment).
#assertCatalogCoverage

end LlzkLean.Cert
