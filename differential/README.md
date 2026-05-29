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

**Wired but minimal.** `run-differential.sh` works as a thin wrapper
over VEIR's script. The corpus starts small (a handful of Felt
identities); it grows as the strategy matures.

## Running locally

```bash
# From the repo root:
lake update               # Fetches the VEIR dependency (incl. Mathlib via VEIR)
lake build                # Builds llzk-lean's own Lean code
export LLZK_OPT=/path/to/llzk-opt
./differential/run-differential.sh
```

**First-run cost.** The differential script invokes
`lake exec veir-opt` inside `.lake/packages/VeIR/`, which on a cold
checkout builds VEIR (the Felt port + the IR machinery) and its
Mathlib dependency. Expect ~10 minutes the first time on a typical
laptop; subsequent runs hit the build cache and finish in seconds.

If you already have VEIR built elsewhere on the filesystem (say,
`~/veir`), you can skip the wait by reusing the existing build:

```bash
# From the llzk-lean root, after `lake update` has populated .lake/packages/VeIR/
ln -sf ~/veir/.lake/build .lake/packages/VeIR/.lake/build
```

The symlink must point at a `.lake/build` directory produced by a
VEIR checkout at the same SHA we've pinned (see `lakefile.toml`)
**and the same Lean toolchain** (see `lean-toolchain`). If your
VEIR clone's `lean-toolchain` differs (e.g., the pinned SHA carries
`v4.30.0-rc2` but your local VEIR checkout has advanced to
`v4.30.0`), the symlinked oleans will be kernel-incompatible and
lake will rebuild from scratch — which is the path the symlink is
trying to avoid. When that happens, the cleanest fix is to run
`lake update` from inside llzk-lean (drops the symlink, populates
.lake/packages/VeIR from scratch at the pinned SHA). Mismatches
otherwise silently produce a build that diverges from the pinned
proof basis.

The script prints PASS / DIVERGE per input. Exit code is 0 if all
inputs pass, non-zero if any diverge.

## Corpus expansion targets

Initial bar (this scaffold):
- `corpus/felt/const_identities.mlir` — minimal proof-of-life.

Strategy A v1 deliverable bar:
- Mirror every input in `llzk-lib/test/Dialect/Felt/` (custom-asm
  form; pass through `LOWER_FIRST=1`).
- Cover every fold in VEIR's `Veir.Passes.Felt.Combine` against a
  representative LLZK input.
- Failing-case corpus: programs LLZK rejects but VEIR accepts, or
  vice versa, placed under `corpus/expected-divergence/` (the
  directory location flips the assertion polarity — see
  [`corpus/README.md`](corpus/README.md)).

The expansion plan is tracked in
[`../docs/strategy-a-oracle.md`](../docs/strategy-a-oracle.md).

## Exit-code semantics

The wrapper distinguishes four outcomes per input, derived from
`llzk-diff.sh`'s exit code:

| Exit | Wrapper label | Polarity inverted under `expected-divergence/`? | Counted as |
|---|---|---|---|
| 0 | `PASS` | yes → `UNEXPECTED-PASS` | pass / fail (inverted) |
| 1 | `DIVERGE` | yes → `EXPECTED-DIVERGE` | fail / pass (inverted) |
| 2 | `ERROR` | **no** | fail (always) |
| 77 | `SKIP` | no | skip (separate bucket) |

ERROR (exit 2) is always-fail because it means the input is broken
(unreadable, malformed CLI args, etc.) — that's not a documented
alignment gap, it's a broken test. SKIP (exit 77) means `llzk-opt`
or `lake` isn't available; counted separately so the summary
distinguishes "nothing ran" from "everything passed".

The wrapper's overall exit code is non-zero iff any input ended up
in the FAIL column.

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
   tracked as Felt parity gap #1 in VEIR's
   [`FELT_PARITY_ASSESSMENT_2026-05-28.md`](https://github.com/alexanderlhicks/veir/blob/llzkfelt_test1/FELT_PARITY_ASSESSMENT_2026-05-28.md))
   — fix on the VEIR side.
2. An LLZK bug — file against `llzk-lib`.
3. A spec disagreement — escalate to the strategy doc.
