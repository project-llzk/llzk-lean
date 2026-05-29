// SPDX-License-Identifier: Apache-2.0
//
// LLZKVerifyRewritesPass — MLIR pass that wires the certificate
// checker into `llzk-opt`'s canonicalize pipeline. Skeleton form.
//
// Intended landing place: llzk-lib/lib/Pass/LLZKVerifyRewritesPass.cpp
// gated on `--verify-rewrites` from llzk-opt's CLI.
//
// Architecture: the pass observes each rewrite performed by
// MLIR's canonicalizer (via a PatternRewriter listener), captures
// the (original, replacement) op pair, and calls `checkRewrite` on
// each pair. Mismatches abort the pass with a diagnostic naming the
// op kind, the location, and the catalog contents.
//
// This is a skeleton. The real implementation hooks into MLIR's
// `RewriterBase::Listener` and threads a `CertCatalog` reference
// through the pass options.

#include "CertChecker.h"

#include <cstdio>

namespace llzk_lean {

// Pass options (would map to MLIR PassOptions struct in the real
// upstreamed version).
struct VerifyRewritesPassOptions {
  std::string certCatalogPath;          ///< Path to .cert.json.
  bool failOnNoMatch = true;            ///< If false, log only.
};

// Skeleton lifecycle. The real version inherits from
// mlir::PassWrapper<...> and overrides runOnOperation().
class VerifyRewritesPass {
public:
  explicit VerifyRewritesPass(VerifyRewritesPassOptions opts)
      : opts_(std::move(opts)) {}

  // Called by MLIR's pass infrastructure (skeleton; real signature is
  // void runOnOperation()).
  //
  // Returns true if the pass should be treated as having succeeded
  // (catalog loaded, listener installed). Returns false on any error
  // path; callers MUST treat false as a failure (the real MLIR-side
  // version will call signalPassFailure()).
  //
  // The "fail-loud on loader error" posture is intentional: while the
  // catalog loader is a stub that always returns nullopt today, a
  // silent return would let a user think `--verify-rewrites` was
  // running when it wasn't. We loudly stderr + return false instead.
  bool run() {
    std::string err;
    auto catalog = loadCertCatalog(opts_.certCatalogPath, &err);
    if (!catalog) {
      // TODO(strategy-E): replace the fprintf with
      //   getOperation()->emitError() << err
      // once this is hosted in MLIR. The stderr write today is what a
      // standalone-driver build can observe.
      std::fprintf(stderr,
                   "LLZKVerifyRewritesPass: catalog load failed (%s): %s\n",
                   opts_.certCatalogPath.c_str(), err.c_str());
      return false;
    }
    // TODO(strategy-E): subscribe to pattern-rewriter events here.
    //   - mlir::RewriterBase::Listener overrides:
    //       notifyOperationInserted(...)  — track replacement ops
    //       notifyOperationErased(...)    — pair with original
    //       notifyOperationReplaced(...)  — for folds, where there's
    //                                       no insert/erase pair but
    //                                       an op.replaceAllUsesWith
    //                                       at a Value-level
    //   - On each pair, call checkRewrite(*catalog, original, replacement).
    //   - Branch on cert.llzkParityStatus to pick assertion polarity
    //     (see the doc-comment on LlzkParityStatus in CertChecker.h
    //     and the TODO at the top of checkRewrite() in CertChecker.cpp).
    //   - On reject, emit diagnostic; honor opts_.failOnNoMatch.
    return true;
  }

private:
  VerifyRewritesPassOptions opts_;
};

} // namespace llzk_lean
