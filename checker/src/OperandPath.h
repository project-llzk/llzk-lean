// SPDX-License-Identifier: Apache-2.0
//
// Resolver for the `pos` mini-language used in cert side-conditions
// to address operand positions in nested LHS patterns.
//
// Grammar (per docs/strategy-e-certificates.md §"pos mini-language"):
//
//   path    := root ("." segment)*
//   root    := "lhs" | "rhs"
//   segment := "operand[" digit+ "]"
//
// Examples:
//   "lhs"                       → root.operand(0)
//   "rhs"                       → root.operand(1)
//   "lhs.operand[0]"            → root.operand(0).operand(0)
//   "rhs.operand[1].operand[0]" → root.operand(1).operand(1).operand(0)
//
// "lhs" is conventionally the first operand of the matched root op;
// "rhs" is the second. This matches LLZK's binary-op vocabulary
// (`AddFeltOp`, etc.). For unary roots, only "lhs" is meaningful;
// "rhs" against a unary op resolves to an out-of-bounds error.
//
// The resolver does NOT touch MLIR. It produces a list of operand
// indices; consumers walk an `mlir::Operation*` (or any equivalent
// tree) using those indices.

#ifndef LLZK_LEAN_OPERAND_PATH_H
#define LLZK_LEAN_OPERAND_PATH_H

#include <optional>
#include <string>
#include <vector>

namespace llzk_lean {

/// Parsed `pos` path: a sequence of operand-index steps from a root
/// operation. The first step is 0 ("lhs") or 1 ("rhs"); subsequent
/// steps come from `.operand[N]` segments and may be any non-negative
/// integer.
struct OperandPath {
  std::vector<int> steps;

  /// Parse a `pos` string per the mini-language grammar in the file
  /// header. Returns std::nullopt on syntax error; writes a
  /// human-readable diagnostic to *errMsg if non-null.
  static std::optional<OperandPath> parse(const std::string &posStr,
                                          std::string *errMsg = nullptr);

  /// Render this path back to the canonical wire form (for diagnostics).
  std::string toString() const;
};

}  // namespace llzk_lean

#endif  // LLZK_LEAN_OPERAND_PATH_H
