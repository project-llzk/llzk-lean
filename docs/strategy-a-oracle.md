# Strategy A — Verified-output oracle

## Concrete picture

LLZK keeps running in production exactly as today. Independently, a
CI harness in this repo runs every test input through both `llzk-opt`
and `veir-opt`, normalizes the outputs through
`differential/run-differential.sh` (a thin wrapper over VEIR's
`scripts/llzk-diff.sh`), and asserts they are textually identical
modulo documented cosmetic differences.

The harness supports two modes:

- parse/print mode: both tools parse the input and emit generic MLIR,
  which is then normalized and compared.
- canonicalization mode: `llzk-opt --canonicalize` is compared against
  `veir-opt -p=felt-combine,dce`.

The clean llzk-lean VeIR dependency now implements canonicalization mode, so
the default evidence path uses the pinned dependency script without a
`VEIR_DIFF=../veir/scripts/llzk-diff.sh` override. Historical Phase 4
workspace evidence still records that override as seed implementation context.

### Known alignment caveats (read before adding to the corpus)

Four structural gaps between LLZK and VEIR constrain what the
harness can actually demonstrate today. Phase 2 re-baselines those
claims to `llzk-lib` commit
`db922857bc5a88a9107627ef6b36a8b5e57bc5c2`:

1. **LLZK has no canonicalization patterns for Felt ops.** VEIR
   rewrites that *aren't* constant folds, e.g.
   `right_identity_zero_add` (x+0 → x), have no LLZK counterpart.
   They are correct VEIR soundness claims, but the differential
   cannot demonstrate LLZK and VEIR producing identical canonical
   forms for them, because LLZK doesn't reduce.

2. **LLZK's binary folds require a registered field name.**
   `tryGetBinaryFoldData` in `lib/Dialect/Felt/IR/Ops.cpp` returns
   null unless both operands are `FeltConstAttr`s with matching,
   registered field names. The accepted built-ins are `bn128`,
   `bn254`, `grumpkin`, `babybear`, `goldilocks`, `mersenne31`, and
   `koalabear`; custom fields can be specified with `#felt.field`.
   Bare `!felt.type` inputs short-circuit to a no-op, and the
   parse-print round-trip is what the differential actually catches.

3. **Named-field generic MLIR still has an LLZK parser/verifier edge.**
   LLZK custom assembly lowered through `llzk-opt --mlir-print-op-generic`
   is the preferred named-field corpus path. A hand-authored generic
   outer-typed named-field `FeltConstAttr` remains classified as
   EXPECTED-LLZK-FAIL.

4. **Registered-field folds now apply modular reduction.** Phase 7
   aligns VeIR's registered-field add-wrap and negation folds with LLZK's
   `Field::reduce` behavior. Phase 8 aligns VeIR with LLZK's
   bare/unknown-field fold precondition for
   `unspecified_add_fold.llzk`.

The Phase 4 ordering is now:
   - Re-test the named-field corpus and keep the generic parser edge
     classified as EXPECTED-LLZK-FAIL.
   - Enable canonicalization in the diff script and classify the first
     canonical divergences.
   - Add field-registry and modular-reduction parity on VEIR's side so
     closed corpus cases can move from expected-divergence to positive
     coverage.

Without that ordering, named-field corpus additions will mostly document
the known field-registry/precondition gaps rather than demonstrate alignment.

When the outputs diverge, the harness reports the diff inline. The
divergence is then classified as one of:

1. A canonical-form mismatch, such as a remaining field-registry or
   rewrite-precondition parity gap.
2. An LLZK bug to file against `llzk-lib`.
3. A spec disagreement to escalate.

## Trusted base added

None. This is observational. The harness reads LLZK's output and
VEIR's output and compares them. If either tool is buggy, the
divergence shows up; you can't trust either side blindly, but their
*agreement* is meaningful evidence that both implement the same
function.

## Assurance gained

**Behavioral evidence**, on the test corpus, that LLZK's
Felt-affecting transforms behave per a Lean spec. Not a runtime
guarantee — it's a continuous regression-catcher.

The 15 verified Lean theorems (in VEIR's `Veir/Passes/Felt/Proofs.lean`)
become an automatically-checked contract on LLZK's output: every
canonical form LLZK produces is independently re-derived by VEIR. CI
catches the next time LLZK ships a folder change that diverges.

## Functionality delivered

- A CI artifact (badge: `LLZK ↔ VEIR differential: passing / failing`).
- A public report listing the input corpus the agreement covers.
- A development tool: when a divergence appears during VEIR's Felt
  parity work, the report points at the exact input.

No user-visible change to `llzk-opt`.

## What this v1 needs

Current state (2026-06-09):
- ✅ `differential/run-differential.sh` wraps VEIR's diff script;
  recurses into directory args; resolves targets to absolute paths; applies
  `--lower-first` automatically to `.llzk` inputs; and supports
  `--canonicalize`.
- 🌱 Seed corpus: live const/type positives, canonical no-fire arithmetic,
  and canonical-only expected divergences for DCE, modular reduction, and
  field-registry preconditions.
- ✅ VEIR has 15 Felt rewrite patterns whose structural preconditions are
  sorry-free and axiom-clean under the accepted Phase 1 pin. This still does
  not close the theorem↔pattern or IR-semantics joints; see
  `docs/REVIEW.md`.
- ✅ Clean-pin harness has a canonicalization mode. Phase 6's first burn-down
  pin runs VeIR `felt-combine,dce`, which reclassifies registered add/sub/mul
  constant folds from expected divergence to positive coverage. Phase 7 now
  reclassifies registered-field modular reduction for add-wrap and negation.
  Phase 8 reclassifies the bare/unknown-field fold-precondition gap.
- 🚧 CI workflow stubbed in `.github/workflows/differential.yml`.
  Skips green if `llzk-opt` not provisioned — CI provisioning is
  v1 work.

Outstanding work to reach v1:

1. **Continue burning down classified divergences.** The consumed clean pin now
   invokes both tools with their canonicalize pipelines
   (`llzk-opt --canonicalize` and `veir-opt -p=felt-combine,dce`). The next
   VeIR-side targets are the remaining classified algebraic divergences after
   the Phase 8 `unspecified_add_fold.llzk` field-precondition target moved to
   positive no-fold coverage.

2. **Corpus expansion.** Hand-author a Felt corpus that exercises every
   pattern in VEIR's `Combine.lean` against an equivalent LLZK input.
   Estimate: ~1-2 engineer-weeks. The 15 patterns each need at least
   one positive and one no-fire input.

3. **LLZK custom-asm ingestion.** Today the seed input is in
   generic-MLIR form because VEIR doesn't parse LLZK's custom assembly
   format (`%c = felt.add %a, %b : !felt.type`). Options:
   (a) Author corpus inputs in generic form (current approach).
   (b) Pipe LLZK inputs through `llzk-opt --mlir-print-op-generic`
       before comparison — automatic for `.llzk` corpus inputs.
   (b) is cheaper to scale; (a) gives us VEIR-native authoring. Either
   way we can mirror `llzk-lib/test/Dialect/Felt/` quickly.

4. **Coverage reporting.** When a corpus input passes, record which
   VEIR patterns and LLZK folders it exercised. Surface "12 of 15
   VEIR patterns differentially confirmed; N of 18 LLZK Felt ops
   covered by corpus inputs".

5. **Failing-case corpus.** Programs LLZK rejects but VEIR accepts
   (or vice versa) belong in `corpus/expected-divergence/`. The
   harness inverts assertion polarity by directory location (no
   marker file required); each file carries a header comment citing
   the parity gap it documents. See
   [`differential/corpus/README.md`](../differential/corpus/README.md)
   for the polarity convention.

6. **Field-registry parity.** VEIR now reduces registered-field fold results
   and skips bare or unknown-field constant folds in cases LLZK leaves
   unresolved. Remaining Strategy A work is the classified nonconstant
   algebraic rewrite matrix.

## Effort

**2-4 engineer-months to reach v1** (every VEIR pattern mirrored by at
least one differential test, CI green with `llzk-opt` provisioned, and
the canonicalize-enabled diff script landed upstream).

## Dependence on Veridise / LLZK maintainers

**None for v1.** The harness is observational and lives outside
`llzk-lib`. If we later want LLZK to publish a CI badge linked to our
divergence dashboard, that's a one-line README change in `llzk-lib` and
not a code change.

## Why this is the recommended starting point

- Already 80% in place (VEIR's harness exists; we wrap it).
- Independent of upstream willingness — we *observe* LLZK, we don't
  modify it.
- Immediate value: every parity gap in VEIR shows up as a tracked
  divergence; the harness becomes a TODO list for the VEIR side.
- Natural ramp into Strategy E: once a pattern's differential is
  green, it's a candidate for certificate-validation upgrade.

## Acceptance criteria for v1

- Diff script invokes both tools with canonicalization enabled
  (`llzk-opt --canonicalize`, `veir-opt -p=felt-combine,dce`).
- Every input under `llzk-lib/test/Dialect/Felt/` (or its
  generic-form equivalent) passes the differential.
- Every pattern in VEIR's `Veir.Passes.Felt.Combine` is exercised by
  at least one positive corpus input.
- CI runs the harness on every PR with `llzk-opt` provisioned (no
  silent skips). Cron is in the workflow but only meaningful once the
  Lake pin is moved to a branch (currently SHA-pinned for proof-basis
  stability, so `lake update` is a no-op).
- A divergence dashboard (markdown, regenerated by CI) tracks current
  divergences with severity classification.
