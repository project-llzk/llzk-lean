# Differential harness (Strategy A)

This directory carries the LLZK ↔ VEIR differential certification
harness. Each input under `corpus/` is parsed by both `llzk-opt` and
`veir-opt`, their outputs are normalized, and the normalized forms are
compared. Divergence = a divergence-of-record between the two
implementations on a Felt-affecting transform.

The differential script itself lives in VEIR
(`scripts/llzk-diff.sh`); this directory wraps it with an llzk-lean
specific corpus and reporting.

## Status

**Canonicalization-aware, clean-pin expanded corpus with Phase 6 burn-down.**
`run-differential.sh` wraps VEIR's script, supports parse/print mode
and canonicalization mode, and classifies output divergence, LLZK
failure, VEIR failure, missing tools, and mode-skipped corpus entries
separately. The Phase 6 clean-pin corpus covers all 15 current VeIR
Felt rewrite-pattern definitions as PASS or EXPECTED-DIVERGE, with
registered add/sub/mul constant folds reclassified to PASS after VeIR
canonical mode started running `felt-combine,dce`. This is not full
Strategy A acceptance coverage.

## Running locally

```bash
# From the repo root:
scripts/harness/verify-pins.sh --workspace-veir ../veir
lake build                # Builds llzk-lean's own Lean code
export LLZK_OPT=/path/to/llzk-opt
./differential/run-differential.sh

# Phase 6 clean-pin canonical evidence path:
./differential/run-differential.sh --canonicalize differential/corpus

# Historical Phase 4 workspace implementation run:
VEIR_DIFF=../veir/scripts/llzk-diff.sh \
  ./differential/run-differential.sh --canonicalize
```

**First-run cost.** The differential script prefers
`.lake/packages/VeIR/.lake/build/bin/veir-opt` when that executable is
present. On a cold checkout it falls back to `lake exec veir-opt` inside
`.lake/packages/VeIR/`, which builds VEIR (the Felt port + the IR machinery)
and its Mathlib dependency. Expect a multi-minute build the first time;
subsequent runs use the built executable and finish in seconds.

If you already have VEIR built elsewhere on the filesystem (say,
`~/veir`), you can skip the wait by reusing the existing build:

```bash
# From the llzk-lean root, after `lake update` has populated .lake/packages/VeIR/
ln -sf ~/veir/.lake/build .lake/packages/VeIR/.lake/build
```

The symlink must point at a `.lake/build` directory produced by a
VEIR checkout at the same SHA we've pinned (see `docs/harness/PINS.md`)
**and the same Lean toolchain** (see `lean-toolchain`). If your
VEIR clone's `lean-toolchain` differs (e.g., the pinned SHA carries
`v4.30.0-rc2` but your local VEIR checkout has advanced to
`v4.30.0`), the symlinked oleans will be kernel-incompatible and
lake will rebuild from scratch — which is the path the symlink is
trying to avoid. When that happens, refresh the dependency to the
accepted pin and rerun `scripts/harness/verify-pins.sh
--workspace-veir ../veir`. Mismatches otherwise produce a build that
diverges from the pinned proof basis.

The script prints PASS / DIVERGE / tool-failure classification per
input. Exit code is 0 if all inputs satisfy their declared polarity,
non-zero if any input lands in the FAIL column.

## Corpus expansion targets

Current Phase 6 bar:
- `corpus/felt/const_identities.mlir` — live const proof-of-life.
- `corpus/felt/types_smoke.llzk` — custom-asm lowering smoke.
- `corpus/felt/arithmetic_no_fold.llzk` — canonical no-fire arithmetic.
- `corpus/felt/add_const_swap.llzk` — positive coverage for the current
  rewrite pattern that both tools normalize the same way.
- `corpus/felt/registered_add_fold.llzk`,
  `corpus/felt/constant_fold_sub.llzk`, and
  `corpus/felt/constant_fold_mul.llzk` — Phase 6 positives closed by the
  clean `felt-combine,dce` pipeline.
- `corpus/expected-divergence/canonical/*` — classified clean-pin
  canonicalization gaps for modular reduction, field-registry
  preconditions, and VeIR-only algebraic rewrites.
- `corpus/README.md` — the current 21-input inventory and 15-pattern
  rewrite coverage matrix.

Remaining Strategy A work:
- Mirror every input in `llzk-lib/test/Dialect/Felt/` (custom-asm
  form; `.llzk` inputs are lowered automatically).
- Keep every VeIR Felt rewrite-pattern definition mapped to a corpus
  file as VEIR changes.
- Reduce expected divergences and move closed gaps into `corpus/felt/`.
- Failing-case corpus: programs LLZK rejects but VEIR accepts, or
  vice versa, placed under `corpus/expected-divergence/` (the
  directory location flips the assertion polarity — see
  [`corpus/README.md`](corpus/README.md)).

The expansion plan is tracked in
[`../docs/strategy-a-oracle.md`](../docs/strategy-a-oracle.md).

## Exit-code semantics

The wrapper distinguishes these outcomes per input, derived from
`llzk-diff.sh`'s exit code:

| Exit | Wrapper label | Polarity inverted under `expected-divergence/`? | Counted as |
|---|---|---|---|
| 0 | `PASS` | yes → `UNEXPECTED-PASS` | pass / fail (inverted) |
| 1 | `DIVERGE` | only with an `EXPECTED-DIVERGE` file header | fail / pass when declared |
| 2 | `ERROR` | **no** | fail (always) |
| 3 | `VEIR-FAIL` | only with an `EXPECTED-VEIR-FAIL` file header | fail / pass when declared |
| 4 | `LLZK-FAIL` | only with an `EXPECTED-LLZK-FAIL` file header | fail / pass when declared |
| 77 | `SKIP` | no | skip, then wrapper failure |

Every input under `expected-divergence/` must declare one exact accepted
outcome in its header: `EXPECTED-DIVERGE`, `EXPECTED-VEIR-FAIL`, or
`EXPECTED-LLZK-FAIL`. The directory is not a wildcard. For example, a
canonical output-divergence test marked `EXPECTED-DIVERGE` fails if either
tool starts failing before comparable output exists.

ERROR (exit 2) is always-fail because it means the input is broken
(unreadable, malformed CLI args, etc.) — that's not a documented
alignment gap, it's a broken test. SKIP (exit 77) means a required
differential tool is unavailable; counted separately in the summary and then
treated as a wrapper failure so missing tools cannot produce acceptance
evidence.

Files under `expected-divergence/canonical/` are canonicalization-only.
Parse/print mode reports MODE-SKIP for them; canonicalization mode runs
and classifies them normally. A run that selects only mode-skipped inputs
exits non-zero because it produced no evidence in the selected mode.

The wrapper's overall exit code is non-zero iff any input ended up
in the FAIL column, any input was skipped because required tools were
unavailable, or no input executed because every selected input was
mode-skipped.

## Interpreting divergences

The normalizer in VEIR (`scripts/llzk-diff.sh`) handles known cosmetic
differences:
- VEIR emits `^N():` empty block headers; LLZK doesn't (elided before
  block-label numbering).
- VEIR uses `(%name : type)` for block args; LLZK uses `(%name: type)`
  (space stripped).
- Block-label numbering is scope-local per region (matches LLZK).

Any *remaining* difference after normalization is a real divergence
and either:

1. A canonical-form mismatch (e.g., VEIR emits `42` where LLZK emits
   `42 mod p` because VEIR's folds don't apply modular reduction —
   tracked in `../../veir/REVIEW.md` VH3)
   — fix on the VEIR side.
2. An LLZK bug — file against `llzk-lib`.
3. A spec disagreement — escalate to the strategy doc.
