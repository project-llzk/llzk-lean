# Felt Drop-In Replacement Roadmap

Last reviewed: 2026-06-11

Status: planning baseline after Phase 8. This document is not acceptance
evidence by itself.

## Goal

The final goal is a high-assurance replacement for the C++ LLZK Felt dialect
path. In this roadmap, "drop-in replacement" means:

- existing Felt workloads can use the VEIR-backed path without changing their
  source programs;
- the selected VEIR pass profile produces output accepted by the same downstream
  LLZK consumers as the C++ path;
- every intended semantic difference from the C++ path is explicit, reviewed,
  and gated, with a rollback path;
- the assurance claim says exactly what was checked, what was proved, and what
  remains trusted.

This is not the same as immediately replacing all of `llzk-opt`. Full
`llzk-opt` replacement remains Strategy C and is still a multi-year,
LLZK-wide project. The active target is narrower: make the Felt dialect
implementation and Felt-affecting canonicalization path replaceable first.

## Replacement Profiles

The project has two related but distinct replacement profiles.

**C++-parity profile.** This is the adoption baseline. It should reproduce
the accepted C++ LLZK Felt behavior closely enough that existing callers can
opt in, compare results, bisect regressions, and fall back without ambiguity.
Parity does not mean the C++ behavior is ideal; it is the stable contract used
to make replacement low-risk.

**Enhanced VEIR profile.** This is the value case. It can run verified
canonicalizations that C++ LLZK does not currently perform, provided each
intentional output difference is explicitly accepted, covered by differential
tests, tied to executable VEIR semantics, and checked for downstream
compatibility.

Current `EXPECTED-DIVERGE` cases are therefore not automatically bad. They are
classified evidence. A divergence is a blocker for the parity profile unless
it is disabled there; the same divergence may be promoted to an enhanced-profile
feature once its semantic and toolchain claims are reviewed.

## Current Baseline

- `project-llzk/veir#1` is merged into `main` at merge commit
  `45d31a20b4ff10498f7caba3c8b635553cc93dea`; the merged head was
  `42db1ae3cbe76ca6c917501acc8e92a4f01cbc75`.
- `opencompl/veir#829` is closed unmerged. The working integration target is
  the `project-llzk/veir` fork.
- llzk-lean's accepted VEIR dependency pin is
  `d899d95004d4bd988c8456d686c33b11a7a5eb4a`.
- The accepted LLZK source basis is `project-llzk/llzk-lib` commit
  `db922857bc5a88a9107627ef6b36a8b5e57bc5c2`.
- The clean-pin canonical differential corpus currently records
  `21 pass (incl. expected-diverge), 0 fail`: 10 positive PASS cases, 10
  canonical `EXPECTED-DIVERGE` cases, and 1 `EXPECTED-LLZK-FAIL`.
- VEIR currently has 15 Felt rewrite patterns over 5 accepted Felt operations:
  `const`, `add`, `sub`, `mul`, and `neg`.
- The accepted LLZK Felt dialect has 18 operations. VEIR still lacks semantic
  models, interpreter cases, and folder parity for `pow`, `div`, `uintdiv`,
  `sintdiv`, `umod`, `smod`, `inv`, `bit_and`, `bit_or`, `bit_xor`,
  `bit_not`, `shl`, and `shr`.
- Strategy E certificates currently cover 2 of 15 VEIR Felt rewrite patterns.
  The C++ checker has a live JSON loader and polarity dispatcher, but the real
  MLIR matcher and `LLZKVerifyRewritesPass` are not implemented.

## Repository Responsibilities

`veir` provides the executable and proof-side implementation:

- LLZK Felt IR representation, parser/printer support, verifier shape checks,
  and the `felt-combine` pass.
- Lean proofs for arithmetic identities and IR structural rewrite
  well-formedness for the current 15 patterns.
- The standalone Felt runtime-value proof-of-concept in
  `Veir/Passes/Felt/InterpModel.lean`.
- The canonical diff driver `scripts/llzk-diff.sh`.

`veir` does not currently provide complete 18-operation semantics, a
C++-matching Felt canonicalization profile, a whole-program semantic theorem,
or a toolchain integration point that can replace the C++ Felt path directly.

`llzk-lean` provides the assurance and integration harness:

- exact source-truth and pin gates for the LLZK source and consumed VEIR proof
  basis;
- the differential corpus, expected-divergence polarity, and clean-pin
  canonical evidence path;
- the certificate schema, emitter, committed certificate snapshot, and C++
  checker prototype;
- review artifacts and non-claim documentation.

`llzk-lean` does not implement the Felt dialect itself and does not modify
upstream `llzk-lib` at runtime.

## Drop-In Definition Of Done

The Felt replacement is ready only when all of the following are true:

1. **Toolchain path selected.** There is a reviewed invocation path, either an
   out-of-tree replacement driver, an LLZK pass plugin, or an upstreamed
   `llzk-opt` integration. The path must define how existing callers opt into
   the VEIR-backed Felt implementation and how they fall back to C++.
2. **Replacement profiles are separated.** VEIR exposes a C++-parity profile
   for low-risk adoption and an enhanced VEIR profile for verified
   improvements. The current stronger algebraic-only `felt-combine` rewrites
   that LLZK does not perform must be disabled in the parity profile or
   promoted through explicit enhanced-profile acceptance.
3. **Full source coverage ledger.** Every accepted LLZK Felt op, type,
   attribute, trait, verifier rule, and folder behavior has a row mapping
   LLZK source to VEIR implementation, differential coverage, proof status, and
   known assumptions.
4. **Differential coverage is complete for the target surface.** The harness
   mirrors `llzk-lib/test/Dialect/Felt/` and representative project workloads,
   including positive, no-fire, verifier-reject, and expected-failure cases.
   Acceptance evidence has no tool skips.
5. **Runtime semantics are stated correctly.** Proof statements are tied to
   the executable matchers, side conditions, result constructors, field
   registry behavior, and runtime values. Arithmetic identities alone are
   documented only as supporting lemmas.
6. **Certificate route assessed by prototype.** At least one aligned C++/VEIR
   fold, initially `constant_fold_add`, is validated through a real MLIR
   matcher and rewrite listener. The prototype must state whether certificates
   add enough assurance to justify expanding Strategy E.
7. **Trusted base published.** The roadmap, harness docs, and repo READMEs list
   every trusted component and caveat: Lean kernel, Mathlib, VEIR IR model,
   runtime guards, LLZK source commit, field registry mirror, normalizer,
   `llzk-opt` binary, C++ checker, MLIR/LLVM APIs, and any wrapper or plugin.

## Roadmap

### Phase 9: Roadmap and Claim Reset

Deliverables:

- Make this roadmap the single source of truth for the drop-in objective.
- Update stale top-level pin and proof-boundary wording.
- Define the profile policy: C++ parity is the adoption baseline; enhanced
  VEIR is the improvement track.
- Keep Phase 8 as the last completed implementation milestone; do not claim
  Phase 9 implementation acceptance until new evidence exists.
- Bootstrap Phase 10 with a concrete toolchain smoke, while keeping the
  existing Phase 8 freshness gate intact until Phase 10 has real evidence.

Exit criteria:

- Both repos point to the roadmap.
- Current accepted pins and non-claims are consistent in live docs.
- The roadmap distinguishes parity failures from intentional enhanced-profile
  improvements.

### Phase 10: Toolchain Replacement Spike

Deliverables:

- Decide the first executable integration shape:
  external `veir-opt`/wrapper, MLIR pass plugin, or upstream `llzk-opt` pass.
- Exercise the existing lower-first wrapper as the initial external-driver
  spike, so LLZK custom assembly is lowered through `llzk-opt` before VEIR
  runs the selected Felt profile.
- Define the exact command sequence equivalent to the C++ path currently
  tested as `llzk-opt --canonicalize --mlir-print-op-generic`.
- Add a smoke wrapper that runs both the aligned fold path and the no-fire
  precondition path over LLZK custom assembly.
- Record which profile is being exercised. The bootstrap smoke uses the
  current enhanced `felt-combine,dce` path until a C++-parity profile exists.

Exit criteria:

- One command runs both paths over the same input and records comparable output.
- The command documents which side owns parsing, lowering, canonicalization,
  and printing.
- The next implementation issue is precise: either introduce the parity profile
  in VEIR, or explicitly accept a current enhanced-profile divergence.

### Phase 11: Full Coverage Ledger

Deliverables:

- Replace the current 18-row operation gap ledger with a drop-in matrix:
  syntax, verifier, trait, folder, parser/printer, differential, proof, and
  certificate status.
- Extract all C++ Felt folder cases from `Ops.cpp` and `FeltFoldTests.cpp`,
  including divide-by-zero no-fold cases, signed integer behavior, bitwidth
  behavior, `NotFieldNative` gating, and field-registry preconditions.

Exit criteria:

- Each C++ fold has a corresponding VEIR implementation status and at least one
  planned positive/no-fire corpus case.
- Missing coverage is quantified, not described narratively.

### Phase 12: LLZK-Parity VEIR Profile

Deliverables:

- Split the VEIR Felt pass surface into a C++-parity profile and a stronger
  verified-optimization profile.
- Port missing constant-fold behavior for the 13 unimplemented operations, in
  priority order: `inv`/`div`, `pow`, unsigned/signed div/mod, shifts, bit ops.
- Model LLZK's field registry, registered-field requirement, zero-divisor
  no-fold behavior, signed representative conversion, bitwidth, and
  `NotFieldNative` scope rules.

Exit criteria:

- The parity profile does not produce the 10 current nonconstant algebraic
  expected divergences unless those divergences are promoted through explicit
  acceptance review.
- Every implemented folder has matching differential tests against the C++
  source behavior.

### Phase 13: Corpus Expansion and Dashboard

Deliverables:

- Mirror all `llzk-lib/test/Dialect/Felt/` inputs or generic equivalents.
- Add representative workload corpora from `llzk-benchmarks` where Felt
  operations appear in realistic contexts.
- Generate a coverage dashboard from the corpus and ledger.

Exit criteria:

- Clean-pin canonical differential evidence has no skips and no unreviewed
  failures.
- Dashboard reports coverage by LLZK op, C++ folder, VEIR pattern, and known
  expected divergence.

### Phase 14: Proof-Certificate Prototype

Deliverables:

- Implement the MLIR-backed matcher for the current certificate schema.
- Wire a minimal rewrite-listener prototype for one aligned fold, starting with
  `constant_fold_add`.
- Replace hand-authored cert shape for the prototype with VEIR-side metadata or
  another auditable derivation mechanism.

Exit criteria:

- A real LLZK/MLIR rewrite event is accepted or rejected by the checker using
  the committed cert snapshot.
- The prototype report states what assurance the certificate adds beyond the
  differential harness and what remains in the TCB.

### Phase 15: Proof Statement Hardening

Deliverables:

- Extend value-level runtime lemmas beyond `right_identity_zero_add` to every
  parity folder that will ship in the drop-in profile.
- Prove or document bridges between canonical `Nat` runtime values,
  `ZMod p` supporting lemmas, and LLZK's `Field::reduce` behavior.
- Keep whole-program `interpret(after) = interpret(before)` out of the
  critical path unless separately funded; if pursued, state its dependency on
  VEIR dominance assumptions.

Exit criteria:

- Each proof-backed runtime claim cites the executable pattern or folder, the
  side conditions, the field-registry assumptions, and the exact theorem layer.
- No public claim relies on a ring identity without tying it to the compiler
  operation that actually runs.

### Phase 16: Drop-In Readiness Review

Deliverables:

- Run the selected toolchain path on the full differential corpus and selected
  benchmark workloads.
- Publish the final TCB and assumptions list.
- Decide whether the integration should remain a project-llzk fork feature,
  land as an out-of-tree plugin, or be proposed upstream to LLZK maintainers.

Exit criteria:

- A reviewer can reproduce the replacement run from a clean checkout and see
  exactly which evidence supports each claim.
- The rollback path to the C++ Felt dialect remains documented and tested.

## Certificate Route Assessment

Proof certificates are useful only where they validate runtime behavior that
actually occurs in the replacement path. They add assurance by checking every
covered rewrite event against a small structural contract. They do not prove
complete compiler equivalence, they do not cover operations without certs, and
they do not replace differential coverage.

The initial certificate proof of concept should therefore stay narrow:

- choose one aligned fold whose C++ and VEIR behavior already agree, preferably
  `constant_fold_add`;
- implement the real MLIR matcher and listener;
- demonstrate one accepted good rewrite and one rejected bad rewrite;
- document the extra trusted code introduced by the checker.

If the prototype is clear and small, expand to the rest of the C++-parity
folders. If it becomes large or ambiguous, continue with differential coverage
and value-level proofs instead of forcing Strategy E into the critical path.

## Trusted Base And Assumptions

Current trusted components:

- Accepted LLZK Felt source at `db922857bc5a88a9107627ef6b36a8b5e57bc5c2`,
  including `Ops.td`, `Ops.cpp`, `FeltFoldTests.cpp`, and `Field.cpp`.
- Accepted VEIR pin `d899d95004d4bd988c8456d686c33b11a7a5eb4a` for current
  llzk-lean evidence.
- Lean kernel, imported Mathlib facts, and any axioms reported by
  `#print axioms`.
- VEIR's IR model, parser/printer, verifier, pass manager, pattern rewriter,
  and defensive runtime guards.
- The differential normalizer and its documented cosmetic rewrites.
- The selected `llzk-opt` binary and LLVM/MLIR toolchain used for evidence.
- For Strategy E, the C++ JSON parser, cert loader, matcher, listener wiring,
  schema policy, and MLIR APIs.

Assumptions to keep explicit:

- The LLZK source commit is the behavioral ground truth until the accepted
  source pin moves.
- Field names and primes must match the accepted LLZK registry.
- Bare or unknown Felt fields are not interpreted as concrete field elements.
- Differential equality is observational evidence over the selected corpus, not
  a proof for all programs.
- Value-level proofs justify runtime values under stated side conditions; they
  are not automatically whole-program semantic preservation theorems.
