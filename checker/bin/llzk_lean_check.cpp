// SPDX-License-Identifier: Apache-2.0
//
// llzk-lean-check — standalone driver for the cert checker.
//
// Two modes:
//
//   --cert <path>                   Load a cert file and print a summary.
//                                   No MLIR required.
//
//   --cert <path> --mlir <path>     Load a cert file and an MLIR input,
//                                   exercise checkRewrite. **Requires MLIR**
//                                   at compile time; without MLIR, this
//                                   mode emits a clear "build with MLIR
//                                   for this mode" message and exits
//                                   non-zero.
//
// The summary mode is useful as a quick sanity check that a cert file
// loads under the current checker (and at what schema version). The
// MLIR mode is the actual verifier; it's the thing the
// `LLZKVerifyRewritesPass` will eventually wrap once the cert format
// stabilizes through use.

#include "CertChecker.h"

#include <cstdlib>
#include <cstring>
#include <iostream>
#include <string>

using namespace llzk_lean;

namespace {

const char *parityName(LlzkParityStatus p) {
  switch (p) {
    case LlzkParityStatus::Aligned: return "aligned";
    case LlzkParityStatus::AlignedWithCaveats: return "aligned-with-caveats";
    case LlzkParityStatus::VeirOnly: return "veir-only";
  }
  return "?";
}

const char *opShapeName(OperandShape::Kind k) {
  switch (k) {
    case OperandShape::Kind::Any: return "any";
    case OperandShape::Kind::Const: return "const";
    case OperandShape::Kind::OpResult: return "opResult";
  }
  return "?";
}

const char *sideCondName(SideCondition::Kind k) {
  switch (k) {
    case SideCondition::Kind::SameValue: return "sameValue";
    case SideCondition::Kind::ConstEquals: return "constEquals";
    case SideCondition::Kind::SameAttr: return "sameAttr";
    case SideCondition::Kind::AttrInRegistry: return "attrInRegistry";
    case SideCondition::Kind::ConstCompare: return "constCompare";
    case SideCondition::Kind::ResultTypeFromOperand: return "resultTypeFromOperand";
  }
  return "?";
}

void printCatalogSummary(const CertCatalog &cat) {
  std::cout << "Cert catalog summary\n";
  std::cout << "  schemaVersion: " << cat.schemaVersion << "\n";
  std::cout << "  source:        " << cat.source << "\n";
  std::cout << "  certs:         " << cat.certs.size() << "\n";
  for (size_t i = 0; i < cat.certs.size(); i++) {
    const Cert &c = cat.certs[i];
    std::cout << "\n  [" << i << "] " << c.patternId
              << " (rootKind: " << c.rootKind
              << ", parity: " << parityName(c.llzkParityStatus) << ")\n";
    std::cout << "       theorem: " << c.theoremName << "\n";
    std::cout << "       lhs:     " << opShapeName(c.lhs.kind);
    if (c.lhs.kind == OperandShape::Kind::OpResult) {
      std::cout << " " << c.lhs.opKind << " ("
                << c.lhs.operands.size() << " operands"
                << (c.lhs.commutative ? ", commutative" : "") << ")";
    }
    std::cout << "\n";
    std::cout << "       rhs:     " << opShapeName(c.rhs.kind) << "\n";
    std::cout << "       conds:   " << c.conditions.size();
    if (!c.conditions.empty()) {
      std::cout << " [";
      for (size_t j = 0; j < c.conditions.size(); j++) {
        if (j) std::cout << ", ";
        std::cout << sideCondName(c.conditions[j].kind);
      }
      std::cout << "]";
    }
    std::cout << "\n";
    if (c.hasScope) {
      std::cout << "       scope:   withinAttr(" << c.scope.attr << ")\n";
    }
  }
}

void printUsage(const char *argv0) {
  std::cerr << "Usage: " << argv0 << " --cert <path> [--mlir <path>]\n";
  std::cerr << "\n";
  std::cerr << "  --cert <path>   Load a cert file (v0.2.x schema) and print a summary.\n";
  std::cerr << "                  No MLIR dependency; useful as a cert smoke test.\n";
  std::cerr << "\n";
  std::cerr << "  --mlir <path>   Additionally load an MLIR input and run\n";
  std::cerr << "                  checkRewrite. Requires the binary to be built\n";
  std::cerr << "                  with MLIR headers (LLZK_HAVE_MLIR=1).\n";
}

}  // namespace

int main(int argc, char **argv) {
  std::string certPath;
  std::string mlirPath;

  for (int i = 1; i < argc; i++) {
    std::string arg = argv[i];
    if (arg == "-h" || arg == "--help") {
      printUsage(argv[0]);
      return 0;
    }
    if (arg == "--cert") {
      if (i + 1 >= argc) {
        std::cerr << "--cert requires a path argument\n";
        return 2;
      }
      certPath = argv[++i];
      continue;
    }
    if (arg == "--mlir") {
      if (i + 1 >= argc) {
        std::cerr << "--mlir requires a path argument\n";
        return 2;
      }
      mlirPath = argv[++i];
      continue;
    }
    std::cerr << "Unknown argument: " << arg << "\n";
    printUsage(argv[0]);
    return 2;
  }

  if (certPath.empty()) {
    std::cerr << "ERROR: --cert is required\n";
    printUsage(argv[0]);
    return 2;
  }

  std::string err;
  auto cat = loadCertCatalog(certPath, &err);
  if (!cat) {
    std::cerr << "ERROR: failed to load cert file '" << certPath << "'\n";
    std::cerr << "  " << err << "\n";
    return 1;
  }

  if (mlirPath.empty()) {
    // Cert-only mode: print the loaded catalog.
    printCatalogSummary(*cat);
    return 0;
  }

#ifndef LLZK_HAVE_MLIR
  std::cerr << "ERROR: --mlir mode requires this binary to be built with\n";
  std::cerr << "       MLIR headers (LLZK_HAVE_MLIR=1). Today's build:\n";
  std::cerr << "       MLIR was not detected by CMake's find_package.\n";
  std::cerr << "\n";
  std::cerr << "       Rebuild with:\n";
  std::cerr << "         cmake -B build \\\n";
  std::cerr << "           -DLLVM_DIR=\"$(llvm-config --cmakedir)\" \\\n";
  std::cerr << "           -DMLIR_DIR=\"$(llvm-config --prefix)/lib/cmake/mlir\"\n";
  std::cerr << "         cmake --build build\n";
  return 1;
#else
  // MLIR-available path: parse the MLIR input, walk the canonicalizer,
  // run checkRewrite per (original, replacement) pair. This is the
  // shape `LLZKVerifyRewritesPass` will eventually take in
  // llzk-lib/lib/Pass/. Until W4B's matchShape/checkConditions
  // bodies land, the inner check still fail-closes — so this mode
  // is here to validate the *plumbing* (loader → MLIR parse → check
  // dispatch) end-to-end, not the matcher correctness.
  //
  // TODO(W4B follow-up): when the real matcher lands, replace this
  // sketch with a working pattern-rewriter listener loop. Approximate
  // shape:
  //   mlir::MLIRContext ctx;
  //   // ... register LLZK dialects ...
  //   mlir::OwningOpRef<mlir::Operation*> module =
  //       mlir::parseSourceFile(mlirPath, &ctx);
  //   for (each rewrite event from canonicalizer):
  //     auto r = checkRewrite(*cat, original, replacement);
  //     if (!r.accepted) std::cerr << "DIVERGE: " << r.rejectReason;
  std::cerr << "INFO: --mlir mode plumbing is in place but the W4B\n";
  std::cerr << "      matcher body is still pending. This driver\n";
  std::cerr << "      currently exits 0 after a successful cert load\n";
  std::cerr << "      and a stub MLIR-input acknowledgement.\n";
  std::cerr << "      MLIR input path was: " << mlirPath << "\n";
  printCatalogSummary(*cat);
  return 0;
#endif
}
