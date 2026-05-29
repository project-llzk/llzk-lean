# Strategy A — Verified-output oracle

## Concrete picture

LLZK keeps running in production exactly as today. Independently, a
CI harness in this repo runs every test input through both `llzk-opt`
and `veir-opt`, normalizes the outputs through
`differential/run-differential.sh` (a thin wrapper over VEIR's
`scripts/llzk-diff.sh`), and asserts they are textually identical
modulo documented cosmetic differences.

**Today (v0)** the harness is a *parse-and-print round-trip
differential*: both tools parse the input and emit generic-MLIR,
which is then normalized and compared. This catches dialect-port
divergences but does not (yet) exercise either tool's
canonicalization pipeline.

**v1** will enable canonicalization on both sides
(`llzk-opt --canonicalize` and `veir-opt -p felt-combine`) so the
differential covers each tool's verified Felt-rewrite catalog. The
script today does *not* pass these flags — see "What this v1 needs"
below.

### Known alignment caveats (read before adding to the corpus)

Four structural gaps between LLZK and VEIR constrain what the
harness can actually demonstrate today — surfaced in the
external-alignment audit that drove commit `3c33115` ("Alignment
audit fixes: cert parity, parser incompatibility, schema gaps";
see `git log 3c33115^!` for the full rationale):

1. **LLZK has no canonicalization patterns for Felt ops.** A
   `grep -rn "getCanonicalizationPatterns" llzk-lib/lib/Dialect/Felt/`
   returns zero matches; the Felt dialect ships only `fold`
   implementations (`Ops.cpp:141-333`). VEIR's rewrites that *aren't*
   constant folds — e.g., `right_identity_zero_add` (x+0 → x) — have
   no LLZK counterpart. They are correct VEIR soundness claims, but
   the differential cannot demonstrate LLZK and VEIR producing
   identical canonical forms for them, because LLZK doesn't reduce.

2. **LLZK's binary folds require a registered field name.**
   `tryGetBinaryFoldData` (`Ops.cpp:57-79`) returns null unless both
   operands are `FeltConstAttr`s with matching, registered field
   names (one of `bn128`, `bn254`, `babybear`, `goldilocks`,
   `mersenne31`, `koalabear`, or a `#felt.field`-registered custom
   name). Our seed corpus `corpus/felt/const_identities.mlir` uses
   bare `!felt.type` — so LLZK's fold short-circuits to a no-op,
   and the parse-print round-trip is what the differential
   actually catches.

3. **Named-field FeltConstAttr is parser-incompatible.** VEIR's
   parser accepts `#felt<const N> : !felt.type<"name">` (field
   annotation on the outer type) but rejects LLZK's
   `#felt<const N : <"name">>` (field annotation inside the const).
   LLZK accepts both, but silently drops VEIR's outer annotation
   and fails verification on the result-type mismatch. Until one
   side fixes its parser, the corpus *cannot* include any
   named-field FeltConstAttr — both directions of the round-trip
   error out. `corpus/expected-divergence/named_field_const.mlir`
   documents this gap as an expected-divergence test.

4. **VEIR's folds don't apply modular reduction.** LLZK's
   `field->reduce(...)` (`Util/Field.cpp`) normalizes constants
   modulo the prime; VEIR's `constant_fold_add` stores the raw
   integer. For unnamed-field inputs this never bites (LLZK
   doesn't fold). For named-field inputs it would bite, but #3
   blocks that path.

The right v1 ordering, given these gaps:
   - First **fix the named-field parser incompatibility** in VEIR
     (one-side fix; smallest blast radius) so corpus expansion to
     named-field inputs is even possible.
   - *Then* add a Field registry on VEIR's side so its folds
     short-circuit-or-reduce consistent with LLZK.
   - *Then* enable canonicalization in the diff script and start
     mirroring `llzk-lib/test/Dialect/Felt/`.

Without that ordering, every named-field corpus addition just goes
into `expected-divergence/` and the harness, while honest, doesn't
demonstrate alignment.

When the outputs diverge, the harness reports the diff inline. The
divergence is then classified as one of:

1. A canonical-form mismatch (e.g., VEIR's folds don't apply modular
   reduction yet — see VEIR's `FELT_PARITY_ASSESSMENT_2026-05-28.md`
   §2.2 row #1 for the parity-gap list).
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

Current state (2026-05-28):
- ✅ `differential/run-differential.sh` wraps VEIR's diff script;
  recurses into directory args; plumbs `LOWER_FIRST=1` through to
  `--lower-first` for LLZK custom-asm inputs.
- 🌱 Seed input: `corpus/felt/const_identities.mlir` (one file).
  Corpus expansion is the headline v1 work item.
- ✅ VEIR has 15 verified rewrites in `Veir.Passes.Felt.Combine`.
- 🚧 Harness is a **parse-print round-trip differential**, not a
  pass-pipeline differential. v1 adds `--canonicalize` /
  `-p felt-combine` invocations (see #1 below).
- 🚧 CI workflow stubbed in `.github/workflows/differential.yml`.
  Skips green if `llzk-opt` not provisioned — CI provisioning is
  v1 work.

Outstanding work to reach v1:

1. **Enable canonicalization in the diff script.** Today's harness
   compares parse-print outputs. v1 invokes both tools with their
   canonicalize pipelines (`llzk-opt --canonicalize` and `veir-opt
   -p felt-combine`) so the differential covers each tool's verified
   Felt-rewrite catalog. Lands as an upstream PR to VEIR's
   `scripts/llzk-diff.sh`; this repo bumps the SHA pin to pull it.

2. **Corpus expansion.** Hand-author a Felt corpus that exercises every
   pattern in VEIR's `Combine.lean` against an equivalent LLZK input.
   Estimate: ~1-2 engineer-weeks. The 15 patterns each need at least
   one positive and one no-fire input.

3. **LLZK custom-asm ingestion.** Today the seed input is in
   generic-MLIR form because VEIR doesn't parse LLZK's custom assembly
   format (`%c = felt.add %a, %b : !felt.type`). Options:
   (a) Author corpus inputs in generic form (current approach).
   (b) Pipe LLZK inputs through `llzk-opt --mlir-print-op-generic`
       before comparison — supported via `LOWER_FIRST=1`
       (`run-differential.sh` plumbs it through to the diff script's
       `--lower-first` flag).
   (b) is cheaper to scale; (a) gives us VEIR-native authoring. Either
   way we can mirror `llzk-lib/test/Dialect/Felt/` quickly.

4. **Coverage reporting.** When a corpus input passes, record which
   VEIR patterns (and LLZK folders) it exercised. Surface "12 of 15
   VEIR patterns differentially confirmed; 4 of 18 LLZK folders".

5. **Failing-case corpus.** Programs LLZK rejects but VEIR accepts
   (or vice versa) belong in `corpus/expected-divergence/`. The
   harness inverts assertion polarity by directory location (no
   marker file required); each file carries a header comment citing
   the parity gap it documents. See
   [`differential/corpus/README.md`](../differential/corpus/README.md)
   for the polarity convention.

6. **Field-registry parity.** VEIR currently folds constants without
   modular reduction; LLZK does. Until VEIR ships a Field registry,
   any named-field constant arithmetic diverges textually. Tracked in
   [VEIR FELT_PARITY_ASSESSMENT_2026-05-28.md](https://github.com/alexanderlhicks/veir/blob/llzkfelt_test1/FELT_PARITY_ASSESSMENT_2026-05-28.md)
   — fix lives upstream in VEIR, not in llzk-lean.

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
  (`llzk-opt --canonicalize`, `veir-opt -p felt-combine`).
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
