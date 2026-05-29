# Differential corpus

Inputs the differential harness runs LLZK and VEIR against.

## Layout

- `felt/` — inputs that should produce *identical* normalized output
  from both tools. PASS = the implementations agree on this case.
- `expected-divergence/` — inputs that document *known* alignment
  gaps. EXPECTED-DIVERGE = the harness sees a difference (which is
  the expected outcome — the file exists to track the gap until
  it's closed). UNEXPECTED-PASS = a gap was closed; move the file
  to `felt/` and update the docs.

## Polarity by location

The harness (`differential/run-differential.sh`) treats inputs by
their path:

| Path pattern | PASS outcome | DIVERGE outcome |
|---|---|---|
| `corpus/felt/*` | counted PASS | counted FAIL |
| `corpus/expected-divergence/*` | counted FAIL (gap closed!) | counted PASS |

A FAIL in either column blocks the script's exit-0 return.

## Adding a positive-case input

1. Author the input under `felt/<short-name>.{mlir,llzk}`. Use
   `corpus/felt/const_identities.mlir` as a template for generic
   form. For LLZK native custom-asm (`%c = felt.add %a, %b :
   !felt.type`), the `.llzk` extension is conventional but not
   required — the harness picks up both extensions.
2. If the input is in LLZK custom-asm, set `LOWER_FIRST=1` so the
   diff script first lowers through
   `llzk-opt --mlir-print-op-generic`:
   ```bash
   LOWER_FIRST=1 ./differential/run-differential.sh \
       differential/corpus/felt/your-file.llzk
   ```
3. Confirm `./differential/run-differential.sh` reports the new
   file as PASS; commit.

## Documenting an alignment gap

1. Author the input under `expected-divergence/<short-name>.{mlir,llzk}`.
2. Add a file-header comment explaining *why* this input diverges
   and citing the relevant code/docs (e.g., the parser
   incompatibility, the field-registry guard, etc.).
3. Confirm the harness reports `EXPECTED-DIVERGE` for the new file
   (or `UNEXPECTED-PASS` if the gap turned out to not exist).
4. When the gap is closed upstream, the harness will report
   `UNEXPECTED-PASS` — move the file to `felt/` and update the doc
   that referenced the gap.

## Current corpus

| File | Status | What it tests |
|---|---|---|
| `felt/const_identities.mlir` | PASS | Generic-form FeltConstAttr round-trip with unnamed `!felt.type` |
| `expected-divergence/named_field_const.mlir` | EXPECTED-DIVERGE | VEIR's outer-annotated `#felt<const N> : !felt.type<"name">` vs LLZK's inner-annotated `#felt<const N : <"name">>` parser incompatibility |
| `expected-divergence/types_smoke.llzk` | EXPECTED-DIVERGE | `LOWER_FIRST=1` smoke test against an LLZK custom-asm input. Surfaces two normalizer gaps in `scripts/llzk-diff.sh`: discardable-attribute key quoting (`{sym_visibility = ...}` vs `{"sym_visibility" = ...}`) and empty-region-body whitespace formatting. Both are cosmetic VEIR-side gaps. |
