// SPDX-License-Identifier: Apache-2.0
//
// Certificate checker for LLZK-Lean (Strategy E).
//
// Validates that an MLIR rewrite performed by LLZK matches a certificate
// emitted by VEIR. The certificate is a structural description of a
// verified rewrite pattern; this checker matches LLZK's actual IR
// against that description and accepts or rejects.
//
// The checker is the trusted base of the certificate-validation
// pipeline. It does NOT re-execute the Lean proof. It validates that
// LLZK's actual transformation conforms to the shape the proof covers.
//
// See docs/strategy-e-certificates.md for the architecture.

#ifndef LLZK_LEAN_CERT_CHECKER_H
#define LLZK_LEAN_CERT_CHECKER_H

#include <string>
#include <vector>
#include <optional>

namespace mlir { class Operation; }

namespace llzk_lean {

/// Comparison operator for value-level side conditions. Added in
/// schema v0.2.0. Wire form is lowercase ("eq" / "ne" / ...).
enum class CompareOp { Eq, Ne, Lt, Le, Gt, Ge };

/// Shape descriptor for an operand position in a certificate pattern.
///
/// Schema v0.2.0 additions:
/// - `constValue`: optional literal-value constraint for Const
///   shapes. When set (`hasConstValue == true`), the shape matches
///   only constants whose value equals `constValue`.
/// - `commutative`: when `true` on an OpResult shape, the checker
///   may match operands in either order.
struct OperandShape {
  enum class Kind { Any, Const, OpResult };
  Kind kind;
  std::string opKind;                   ///< Populated for Const and OpResult.
  std::vector<OperandShape> operands;   ///< Populated for OpResult.
  bool hasConstValue = false;           ///< v0.2.0: Const value present?
  long long constValue = 0;             ///< v0.2.0: when hasConstValue, the literal.
  bool commutative = false;             ///< v0.2.0: OpResult order-insensitive?
};

/// One side condition checked structurally against LLZK's IR.
///
/// Schema v0.2.0 adds four new constructors. The C++ representation
/// is a tagged union: `kind` selects which fields are populated.
struct SideCondition {
  enum class Kind {
    SameValue,        ///< v0.1.x: two operand positions alias.
    ConstEquals,      ///< v0.1.x: constant at position equals value.
    SameAttr,         ///< v0.2.0: positions share a named attribute.
    AttrInRegistry,   ///< v0.2.0: attr value resolves in named registry.
    ConstCompare,     ///< v0.2.0: value comparison (eq/ne/lt/le/gt/ge).
    ResultTypeFromOperand, ///< v0.2.0: result type inferred from operand.
  };
  Kind kind;
  std::string lhs, rhs;                 ///< For SameValue: two operand positions.
  std::string pos;                      ///< For ConstEquals, ConstCompare,
                                        ///< AttrInRegistry, ResultTypeFromOperand.
  long long value = 0;                  ///< For ConstEquals, ConstCompare.
  std::string attr;                     ///< v0.2.0: For SameAttr, AttrInRegistry.
  std::vector<std::string> positions;   ///< v0.2.0: For SameAttr.
  std::string registry;                 ///< v0.2.0: For AttrInRegistry.
  CompareOp op = CompareOp::Eq;         ///< v0.2.0: For ConstCompare.
};

/// Scope assertion (v0.2.0): the cert is valid only when the matched
/// op lives inside a surrounding op carrying the named discardable
/// attribute. Captures LLZK's NotFieldNative context-gating (e.g.,
/// felt.bit_and is only valid inside a function.def with
/// `function.allow_non_native_field_ops`).
struct ScopeAssertion {
  enum class Kind { WithinAttr };
  Kind kind = Kind::WithinAttr;
  std::string attr;                     ///< The required discardable attribute name.
};

/// Classification of how a verified Lean rewrite relates to LLZK's
/// actual runtime behavior. The checker uses this to pick assertion
/// polarity at --verify-rewrites time. Added in cert schema v0.1.1.
enum class LlzkParityStatus {
  /// LLZK performs exactly this rewrite, same canonical output as the
  /// Lean spec. checkRewrite asserts LLZK's transformation matches.
  Aligned,
  /// LLZK performs this rewrite under additional conditions the Lean
  /// spec doesn't impose (e.g. field-name guard, modular reduction).
  /// checkRewrite asserts match-modulo-caveat; full alignment is a
  /// future-work item tracked per pattern.
  AlignedWithCaveats,
  /// LLZK has no matching fold or canonicalization pattern. The cert
  /// is a Lean-side soundness statement only. checkRewrite treats it
  /// as informational (logs the match; does not assert that LLZK
  /// exhibits this rewrite).
  VeirOnly,
};

/// A single certificate: one verified rewrite pattern.
struct Cert {
  std::string patternId;                ///< E.g. "right_identity_zero_add".
  std::string rootKind;                 ///< E.g. "felt.add".
  OperandShape lhs;                     ///< LHS shape (matched).
  OperandShape rhs;                     ///< RHS shape (produced by the rewrite).
  std::vector<SideCondition> conditions;
  std::string theoremName;              ///< Lean theorem name, for diagnostics only.
  LlzkParityStatus llzkParityStatus;    ///< Assertion polarity selector.
  /// v0.2.0: optional scope assertion. When set (hasScope == true),
  /// the cert is valid only when the matched op lives inside a
  /// surrounding op carrying scope.attr as a discardable attribute.
  bool hasScope = false;
  ScopeAssertion scope;
  std::string description;              ///< Human-readable summary.
};

/// Top-level catalog parsed from a `.cert.json` file.
struct CertCatalog {
  std::string schemaVersion;
  std::string source;
  std::vector<Cert> certs;
};

/// Load a certificate catalog from a JSON file. Returns nullopt on
/// parse error; diagnostics go through `errMsg` if provided.
///
/// Recommended behavior on `schemaVersion` mismatch (when implemented;
/// today's stub returns nullopt for every input):
///   - Cert's `schemaVersion < ` the checker's compiled-in version:
///     reject by default (the cert may rely on a constructor the
///     checker doesn't know about). The override flag
///     `--accept-schema=*` should let an operator force-accept old
///     formats at their own risk.
///   - Cert's `schemaVersion > ` (patch-higher): accept; ignore
///     unknown JSON keys. Required by the patch-bump policy in
///     docs/strategy-e-certificates.md §"Versioning policy".
///   - Lower-major: always reject.
///
/// Recommended behavior on a per-cert missing `llzkParityStatus`
/// field (i.e., a v0.1.0-or-older cert): reject the file, unless
/// `--accept-schema=*` is passed. The cert has no safe default for
/// the field; `Aligned` would over-assert, `VeirOnly` would
/// under-assert. The checker is allowed to refuse older formats
/// because it cannot infer the new field's value.
///
/// String → enum parsing must use the exhaustive-if-else-error
/// dispatch shape spelled out in docs/strategy-e-certificates.md
/// §"Versioning policy" / "Minor bumps". Permissive defaults
/// (e.g., parseKind returning Kind::Any on unknown input) would
/// let stale checkers accept rewrites they don't model. **Forbidden.**
std::optional<CertCatalog> loadCertCatalog(const std::string &path,
                                           std::string *errMsg = nullptr);

/// Result of checking a single rewrite against the catalog.
///
/// `accepted == true` means at least one cert justifies the rewrite
/// LLZK performed. The richer fields (added in W4B alongside polarity
/// dispatch) describe *how* it was accepted:
///
///   - `matchedParity == Aligned`: exact LHS + RHS + conditions match.
///     `caveatTriggered == false`.
///   - `matchedParity == AlignedWithCaveats` + `caveatTriggered == false`:
///     exact LHS + RHS + conditions match (best case for an
///     AlignedWithCaveats cert — no caveat was needed).
///   - `matchedParity == AlignedWithCaveats` + `caveatTriggered == true`:
///     LHS + conditions matched but LLZK's replacement differs from
///     the cert's RHS shape. The cert acknowledges this can happen
///     (e.g., LLZK applies field->reduce; VEIR doesn't); the
///     `caveatTriggered` flag surfaces the divergence in the pass
///     diagnostics.
///
/// `accepted == false` means no cert matched. `rejectReason` is a
/// human-readable summary.
///
/// VeirOnly certs are NOT iterated for acceptance — they describe
/// rewrites LLZK doesn't perform. If a future LLZK version starts
/// performing a previously-VeirOnly rewrite, the cert's parity
/// classification has become stale and should be promoted; the
/// `VerifyRewritesPass` is the right place to surface that diagnostic.
struct CheckResult {
  bool accepted = false;
  std::string matchedPatternId;       ///< If accepted, which pattern matched.
  std::string rejectReason;           ///< If !accepted, why.
  LlzkParityStatus matchedParity = LlzkParityStatus::Aligned;
  bool caveatTriggered = false;
};

/// Check that a rewrite from `original` to `replacement` is justified
/// by some certificate in the catalog. Both pointers must remain valid
/// for the duration of the call.
///
/// Returns CheckResult{accepted=true, matchedPatternId=...} if any cert
/// in the catalog matches the (LHS, RHS) shape and the side conditions
/// hold. Otherwise accepted=false and rejectReason names the issue.
CheckResult checkRewrite(const CertCatalog &catalog,
                         mlir::Operation *original,
                         mlir::Operation *replacement);

/// Matcher abstraction used by the polarity-dispatch orchestrator.
/// Decoupling the orchestrator from the actual MLIR-touching matchers
/// lets the polarity logic be tested without MLIR via mock matchers.
struct Matcher {
  virtual ~Matcher() = default;
  /// Returns true if `op` (and its operand chain) matches `shape`.
  virtual bool matchOpShape(const OperandShape &shape, mlir::Operation *op) const = 0;
  /// Returns true if all side conditions hold for the matched rewrite
  /// rooted at `original`.
  virtual bool checkConds(const std::vector<SideCondition> &conds,
                          mlir::Operation *original) const = 0;
};

/// Testing-friendly variant of `checkRewrite`: pure polarity-dispatch
/// orchestrator parameterized by a `Matcher`. The default
/// `checkRewrite` uses a `Matcher` that delegates to the MLIR-backed
/// `matchShape`/`checkConditions` (or fail-closed without MLIR).
///
/// This separation lets the test driver exercise the polarity logic
/// (Aligned / AlignedWithCaveats / VeirOnly skipping) by injecting a
/// scripted `Matcher` whose responses simulate the runtime matcher.
CheckResult checkRewriteWith(const CertCatalog &catalog,
                             mlir::Operation *original,
                             mlir::Operation *replacement,
                             const Matcher &matcher);

} // namespace llzk_lean

#endif // LLZK_LEAN_CERT_CHECKER_H
