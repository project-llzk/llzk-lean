# Certificate checker (C++ side, Strategy E)

This directory contains the reference C++ implementation of the
certificate checker. It is the LLZK-side counterpart to the Lean
certificate emitter in `../LlzkLean/Cert.lean`.

## Status

**Loader live; polarity dispatch live; matcher MLIR-gated.**

- **JSON parser + cert-catalog loader** (`src/JsonParser.{h,cpp}` +
  `src/CertChecker.cpp`'s `loadCertCatalog`): real, exercised by 13
  loader tests against the committed cert snapshot. Hand-rolled
  recursive-descent parser; no JSON library dependency. Schema
  v0.2.0 enforcement with the dispatch semantics documented in
  [`../docs/strategy-e-certificates.md`](../docs/strategy-e-certificates.md)
  §Versioning policy.
- **`OperandPath` `pos`-resolver** (`src/OperandPath.{h,cpp}`):
  pure-C++ parser for the dotted-bracket grammar
  (`lhs|rhs.operand[N]`). 4 unit tests.
- **Polarity dispatch** (`src/CertChecker.cpp`'s `checkRewriteWith`):
  real, exercised by 9 dispatcher tests via a scripted-`Matcher`
  mock. Implements the assertion polarity per `LlzkParityStatus`:
  Aligned (strict LHS+RHS+conds), AlignedWithCaveats (LHS+conds;
  RHS divergence allowed with `caveatTriggered` flag), VeirOnly
  (skipped — informational cert).
- **Pattern matcher** (`src/CertChecker.cpp`'s `DefaultMatcher`):
  MLIR-guarded via `#ifdef LLZK_HAVE_MLIR`. Without MLIR, returns
  fail-closed (existing posture). With MLIR (the build sets
  `LLZK_HAVE_MLIR=1` when `find_package(MLIR)` succeeds), the body
  is the structured matcher described inline in the source — a
  TODO comment block specifying the exact MLIR API surface to use.
  Real body lands when MLIR is on the build machine and we have
  a corpus of LLZK MLIR inputs to test against.
- **Standalone driver** (`bin/llzk_lean_check.cpp`,
  `llzk-lean-check`): CLI tool. `--cert <path>` loads a cert file
  and prints a human-readable summary (no MLIR required;
  end-to-end exercise of loader + dispatch). `--mlir <path>`
  additionally loads an MLIR input and runs `checkRewrite` per
  rewrite event (gated on MLIR build).
- **`LLZKVerifyRewritesPass`** (`src/VerifyRewritesPass.cpp`):
  skeleton; PRs into `llzk-lib/lib/Pass/` once the matcher body
  lands and the cert format stabilizes through use.

**26 tests pass under `ctest`** as of W4B: 13 loader tests + 4
OperandPath tests + 9 polarity-dispatch tests. None require MLIR.

## Building (standalone)

```bash
cd checker
cmake -B build \
  -DLLVM_DIR="$(llvm-config --cmakedir)" \
  -DMLIR_DIR="$(llvm-config --prefix)/lib/cmake/mlir"
cmake --build build
ctest --test-dir build --output-on-failure -V
```

MLIR's CMake package ships under `${LLVM_PREFIX}/lib/cmake/mlir`;
there is no separate `mlir-config` binary. The cert loader + JSON
parser compile and test without MLIR — `find_package(MLIR CONFIG
QUIET)` in `CMakeLists.txt` is non-required, and the loader's
surface is pure C++. So a bare `cmake -B build && cmake --build
build && ctest --test-dir build` runs the full loader test suite
without an MLIR install. MLIR headers become required only when
the W4B pattern matcher lands and starts dereferencing
`mlir::Operation`.

`ctest --output-on-failure` runs `test_loader` against the
committed cert snapshot. As of v0.2.0: 13 tests, ~0.01 s.

## Layout

- `src/JsonParser.{h,cpp}` — hand-rolled JSON parser. Strict
  validation; UTF-8 string-literal support; line/col diagnostics.
  Strictly the JSON subset `EmitCerts.lean` produces (no floats /
  exponents).
- `src/OperandPath.{h,cpp}` — `pos`-mini-language parser.
- `src/CertChecker.h` — public API of the checker (cert types +
  `loadCertCatalog` + `checkRewrite` + `checkRewriteWith` for
  testability + `Matcher` interface).
- `src/CertChecker.cpp` — schema-aware loader (live), polarity
  dispatch (live), and the `DefaultMatcher` whose body is
  MLIR-guarded.
- `src/VerifyRewritesPass.cpp` — MLIR pass skeleton that would
  live in `llzk-lib/lib/Pass/` after upstreaming.
- `bin/llzk_lean_check.cpp` — standalone CLI driver
  (`llzk-lean-check`).
- `tests/test_loader.cpp` — 26 self-contained tests. Run via
  `ctest`.
- `CMakeLists.txt` — standalone build + `ctest` integration.

## Trust boundary

The checker is **the trusted base** for Strategy E. Its correctness
determines whether the Lean theorems' guarantees transfer to LLZK's
runtime behavior. Design goals, in order:

1. **Small.** ~600 LoC total today, ~half of which is the JSON
   parser. Target ≤1000 LoC total once the W4B matcher lands.
   Pattern matching is structural only; no SMT, no rewriting, no
   recursive descent into op semantics.
2. **Auditable.** A single C++ author + reviewer should be able to
   read the whole thing in one sitting. The JSON parser is split
   into its own translation unit so it can be reviewed in
   isolation.
3. **Stateless per rewrite.** Each cert check is independent. No
   accumulator state.
4. **Strict-on-unknown.** Per the v0.2.0 versioning policy, an
   unknown enum constructor in a cert file is a hard reject (the
   recommended dispatch shape is the exhaustive-if-else-error
   chain spelled out in
   [`../docs/strategy-e-certificates.md`](../docs/strategy-e-certificates.md)
   §Versioning policy; permissive defaults would let a stale
   checker accept rewrites it doesn't model).

## Loader-side schema enforcement

The loader rejects:
- Cert files with `schemaVersion` outside the checker's
  understood range (today: `0.2.x` only; lower-major or
  lower-minor is rejected because the older formats lack
  `llzkParityStatus`).
- Any unknown enum constructor in `OperandShape.kind`,
  `SideCondition.kind`, `CompareOp`, `LlzkParityStatus`, or
  `ScopeAssertion.kind`.
- Missing required fields per the cert type (`patternId`,
  `rootKind`, `lhs`, `rhs`, `conditions`, `theoremName`,
  `llzkParityStatus`, `description`).
- Malformed JSON (with line/column diagnostics).

The loader ignores (per the patch-bump policy):
- Unknown top-level keys (e.g., `_note`, `_aboutLlzkParityStatus`,
  any future `_`-prefixed informational key).
- Unknown per-cert keys at JSON-object level (e.g., a future
  optional field that v0.2.x readers don't know about).

The test suite (`tests/test_loader.cpp`) exercises both
strict-reject and ignore-tolerantly paths.
