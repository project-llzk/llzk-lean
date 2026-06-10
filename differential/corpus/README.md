# Differential corpus

Inputs the differential harness runs LLZK and VEIR against.

## Layout

- `felt/` — inputs that should produce *identical* normalized output
  from both tools. PASS = the implementations agree on this case.
- `expected-divergence/` — inputs that document *known* alignment
  gaps. Each file must declare the accepted outcome in a header comment:
  `EXPECTED-DIVERGE`, `EXPECTED-LLZK-FAIL`, or `EXPECTED-VEIR-FAIL`.
  `UNEXPECTED-PASS` means a gap was closed; move the file to `felt/`
  and update the docs.
- `expected-divergence/canonical/` — canonicalization-only gaps.
  Parse/print runs report MODE-SKIP for these files; canonical runs
  classify them normally.

## Polarity by location

The harness (`differential/run-differential.sh`) treats inputs by
their path:

| Path pattern | PASS outcome | DIVERGE outcome | Tool-failure outcome |
|---|---|---|---|
| `corpus/felt/*` | counted PASS | counted FAIL | counted FAIL |
| `corpus/expected-divergence/*` with `EXPECTED-DIVERGE` marker | counted FAIL (gap closed!) | counted PASS | counted FAIL |
| `corpus/expected-divergence/*` with `EXPECTED-LLZK-FAIL` marker | counted FAIL | counted FAIL | counted PASS only for LLZK failure |
| `corpus/expected-divergence/*` with `EXPECTED-VEIR-FAIL` marker | counted FAIL | counted FAIL | counted PASS only for VEIR failure |
| `corpus/expected-divergence/canonical/*` in parse/print mode | MODE-SKIP | MODE-SKIP | MODE-SKIP |

A FAIL in either column blocks the script's exit-0 return. SKIP also exits
non-zero because missing required differential tools are not acceptance
evidence. Selecting only mode-skipped inputs exits non-zero because the run
produced no parse/print or canonicalization evidence.

## Adding a positive-case input

1. Author the input under `felt/<short-name>.{mlir,llzk}`. Use
   `corpus/felt/const_identities.mlir` as a template for generic
   form. For LLZK native custom-asm (`%c = felt.add %a, %b :
   !felt.type`), the `.llzk` extension is conventional but not
   required — the harness picks up both extensions.
2. If the input is in LLZK custom-asm, use the `.llzk` extension. The
   wrapper automatically passes `--lower-first` for `.llzk` inputs so
   the diff script first lowers through `llzk-opt --mlir-print-op-generic`:
   ```bash
   ./differential/run-differential.sh differential/corpus/felt/your-file.llzk
   ```
3. Confirm parse/print mode and, when relevant, canonicalization mode
   report the new file as PASS:
   ```bash
   ./differential/run-differential.sh differential/corpus/felt/your-file.llzk
   ./differential/run-differential.sh --canonicalize \
       differential/corpus/felt/your-file.llzk
   ```

## Documenting an alignment gap

1. Author the input under `expected-divergence/<short-name>.{mlir,llzk}`.
   Use `expected-divergence/canonical/` for gaps that only appear when
   `--canonicalize` is enabled.
2. Add a file-header comment with the exact accepted label:
   `EXPECTED-DIVERGE`, `EXPECTED-LLZK-FAIL`, or `EXPECTED-VEIR-FAIL`.
   Explain *why* this input diverges or fails on one side, citing the
   relevant code/docs (e.g., field-registry parity, modular reduction,
   parser/verifier mismatch, normalizer gaps, etc.).
3. Confirm the harness reports the declared inverted outcome. A different
   nonzero result is a failure; for example, a file marked
   `EXPECTED-DIVERGE` must not pass just because one tool starts failing.
4. When the gap is closed upstream, the harness will report
   `UNEXPECTED-PASS` — move the file to `felt/` and update the doc
   that referenced the gap.

## Current corpus

| File | Status | What it tests |
|---|---|---|
| `felt/add_const_swap.llzk` | PASS | Canonical positive for `add_const_swap`; both tools rewrite constant-on-left add to constant-on-right add |
| `felt/const_identities.mlir` | PASS | Generic-form live FeltConstAttr round-trip with unnamed `!felt.type`; passes parse/print and canonicalization |
| `felt/types_smoke.llzk` | PASS | LLZK custom-asm function type smoke; reclassified from expected divergence after normalizer fixes |
| `felt/arithmetic_no_fold.llzk` | PASS | Canonical no-fire coverage for live add/sub/mul/neg over non-constant inputs |
| `felt/registered_add_fold.llzk` | PASS | Registered-field add folds to 12; Phase 6 `felt-combine,dce` aligns VeIR with LLZK's dead-input cleanup |
| `felt/constant_fold_sub.llzk` | PASS | Registered-field subtraction folds to 5; Phase 6 `felt-combine,dce` aligns VeIR with LLZK's dead-input cleanup |
| `felt/constant_fold_mul.llzk` | PASS | Registered-field multiplication folds to 42; Phase 6 `felt-combine,dce` aligns VeIR with LLZK's dead-input cleanup |
| `felt/registered_add_wrap.llzk` | PASS | Registered-field add folds through babybear reduction; Phase 7 aligns VeIR with LLZK's reduced result |
| `felt/constant_fold_neg.llzk` | PASS | Registered-field negation folds through babybear reduction; Phase 7 aligns VeIR with LLZK's reduced result |
| `felt/unspecified_add_fold.llzk` | PASS | Bare `!felt.type` add remains unfired; Phase 8 aligns VeIR with LLZK's registered-field fold precondition |
| `expected-divergence/named_field_const.mlir` | EXPECTED-LLZK-FAIL | Generic named-field FeltConstAttr still fails on LLZK's parser/verifier path |
| `expected-divergence/canonical/add_neg_to_zero.llzk` | EXPECTED-DIVERGE | VeIR rewrites `x + (-x)` to zero; LLZK leaves the non-constant add/neg pair in place |
| `expected-divergence/canonical/add_sub_const_cancel.llzk` | EXPECTED-DIVERGE | VeIR rewrites `(x + c) - c` to `x`; LLZK leaves the add/sub pair in place |
| `expected-divergence/canonical/assoc_const_fold_add.llzk` | EXPECTED-DIVERGE | VeIR rewrites `(x + c1) + c2` to `x + (c1 + c2)`; LLZK leaves the nested add chain in place |
| `expected-divergence/canonical/assoc_const_fold_mul.llzk` | EXPECTED-DIVERGE | VeIR rewrites `(x * c1) * c2` to `x * (c1 * c2)`; LLZK leaves the nested multiplication chain in place |
| `expected-divergence/canonical/neg_neg_to_self.llzk` | EXPECTED-DIVERGE | VeIR rewrites double negation to `x`; LLZK leaves the outer negation chain in place |
| `expected-divergence/canonical/right_identity_one_mul.llzk` | EXPECTED-DIVERGE | VeIR rewrites `x * 1` to `x`; LLZK leaves the non-constant multiplication in place |
| `expected-divergence/canonical/right_identity_zero_add.llzk` | EXPECTED-DIVERGE | VeIR rewrites `x + 0` to `x`; LLZK leaves the non-constant add in place |
| `expected-divergence/canonical/right_zero_mul.llzk` | EXPECTED-DIVERGE | VeIR rewrites `x * 0` to zero; LLZK leaves the non-constant multiplication in place |
| `expected-divergence/canonical/self_subtraction_to_zero.llzk` | EXPECTED-DIVERGE | VeIR rewrites `x - x` to zero; LLZK leaves the non-constant subtraction in place |
| `expected-divergence/canonical/sub_add_const_cancel.llzk` | EXPECTED-DIVERGE | VeIR rewrites `(x - c) + c` to `x`; LLZK leaves the sub/add pair in place |

The current Phase 8 implementation clean-pin canonical corpus records 10 PASS cases,
10 `EXPECTED-DIVERGE` canonical cases, and 1 `EXPECTED-LLZK-FAIL`
parser/verifier gap. The run reports:

```text
Summary: 21 pass (incl. expected-diverge), 0 fail (over 21 inputs)
```

## Phase 8 implementation rewrite-pattern coverage

This matrix tracks coverage against the 15 `Veir.FeltPass` rewrite-pattern
definitions. It is not a Strategy A acceptance claim: `EXPECTED-DIVERGE` means
the corpus now records the gap explicitly under the canonicalized clean-pin
gate.

| VeIR pattern | Corpus status | Corpus file |
|---|---|---|
| `right_identity_zero_add` | EXPECTED-DIVERGE | `expected-divergence/canonical/right_identity_zero_add.llzk` |
| `constant_fold_add` | PASS | `felt/registered_add_fold.llzk`, `felt/registered_add_wrap.llzk`; no-fire precondition coverage in `felt/unspecified_add_fold.llzk` |
| `self_subtraction_to_zero` | EXPECTED-DIVERGE | `expected-divergence/canonical/self_subtraction_to_zero.llzk` |
| `assoc_const_fold_add` | EXPECTED-DIVERGE | `expected-divergence/canonical/assoc_const_fold_add.llzk` |
| `right_identity_one_mul` | EXPECTED-DIVERGE | `expected-divergence/canonical/right_identity_one_mul.llzk` |
| `right_zero_mul` | EXPECTED-DIVERGE | `expected-divergence/canonical/right_zero_mul.llzk` |
| `constant_fold_sub` | PASS | `felt/constant_fold_sub.llzk` |
| `constant_fold_mul` | PASS | `felt/constant_fold_mul.llzk` |
| `constant_fold_neg` | PASS | `felt/constant_fold_neg.llzk` |
| `add_neg_to_zero` | EXPECTED-DIVERGE | `expected-divergence/canonical/add_neg_to_zero.llzk` |
| `neg_neg_to_self` | EXPECTED-DIVERGE | `expected-divergence/canonical/neg_neg_to_self.llzk` |
| `add_const_swap` | PASS | `felt/add_const_swap.llzk` |
| `add_sub_const_cancel` | EXPECTED-DIVERGE | `expected-divergence/canonical/add_sub_const_cancel.llzk` |
| `sub_add_const_cancel` | EXPECTED-DIVERGE | `expected-divergence/canonical/sub_add_const_cancel.llzk` |
| `assoc_const_fold_mul` | EXPECTED-DIVERGE | `expected-divergence/canonical/assoc_const_fold_mul.llzk` |
