# llzk-lean

> ⚠️ **Experimental — work in progress.** This repository is an early
> prototype exploring how Lean-backed verification can complement
> [LLZK](https://github.com/Veridise/llzk-lib). Schemas, interfaces, and
> infrastructure are unstable and may change without notice. Not for
> production use.

## Purpose

`llzk-lean` is a thin cooperation surface between LLZK and
[VEIR](https://github.com/project-llzk/veir) — a Lean 4 formalization of
MLIR — demonstrating two non-disruptive ways to raise the assurance of
LLZK's Felt dialect:

- **Strategy A — verified-output oracle (observational).** A
  differential harness runs both `llzk-opt` and `veir-opt -p
  felt-combine` against a shared corpus, normalizes their textual
  output, and asserts agreement. Divergences are either bugs or
  documented as expected with cited rationale.

- **Strategy E — proof certificates (runtime).** VEIR emits JSON
  certificates that describe each verified rewrite (LHS/RHS shape, side
  conditions, parity status). A C++ checker validates that LLZK's
  actual MLIR rewrites conform to the catalog at runtime, keeping Lean
  and Mathlib out of LLZK's runtime trusted base.

The 15 verified Felt-dialect rewrites the catalog references live in
VEIR on the [`llzkfelt_test1`](https://github.com/project-llzk/veir/tree/llzkfelt_test1)
branch.

## Repository contents

```
LlzkLean/           Lean modules (Cert types, build-time validation)
EmitCerts.lean      JSON certificate emitter
certs/              committed certificate snapshot for regression diffing
checker/            C++ runtime checker + tests (~1000 LoC)
differential/       Strategy A harness + MLIR corpus
docs/               strategy + future-integration documentation
```

## Documentation

The implemented strategies and longer-range integration paths are
documented under [`docs/`](docs/):

- [`docs/strategy-a-oracle.md`](docs/strategy-a-oracle.md) — Strategy
  A design + harness usage.
- [`docs/strategy-e-certificates.md`](docs/strategy-e-certificates.md)
  — Strategy E cert format, lifecycle, and checker design.
- [`docs/future-b-extraction.md`](docs/future-b-extraction.md) —
  Future: extract VEIR's verified rewriter to C++.
- [`docs/future-c-drop-in.md`](docs/future-c-drop-in.md) — Future:
  drop-in replacement for LLZK's Felt dialect.
- [`docs/future-d-ffi-plugin.md`](docs/future-d-ffi-plugin.md) —
  Future: FFI plugin for the Lean rewriter.
- [`docs/future-f-folders-only.md`](docs/future-f-folders-only.md) —
  Future: folder-only verified passes.

## Scope

Current coverage is the LLZK Felt dialect only. Other LLZK dialects are
not addressed by this repository.

## License

See [LICENSE](LICENSE).
