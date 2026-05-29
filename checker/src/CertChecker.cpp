// SPDX-License-Identifier: Apache-2.0
//
// Certificate checker — see CertChecker.h.

#include "CertChecker.h"
#include "JsonParser.h"

#include <fstream>
#include <sstream>

namespace llzk_lean {

namespace {

// --- error helper -----------------------------------------------------------

bool fail(std::string *errMsg, const std::string &reason) {
  if (errMsg && errMsg->empty()) *errMsg = reason;
  return false;
}

// --- schema-version handling ------------------------------------------------

// Parses a "MAJOR.MINOR.PATCH" string into a tuple. Returns false on
// malformed input.
bool parseSemver(const std::string &v, int &major, int &minor, int &patch) {
  size_t a = v.find('.');
  if (a == std::string::npos) return false;
  size_t b = v.find('.', a + 1);
  if (b == std::string::npos) return false;
  try {
    major = std::stoi(v.substr(0, a));
    minor = std::stoi(v.substr(a + 1, b - a - 1));
    patch = std::stoi(v.substr(b + 1));
    return true;
  } catch (...) {
    return false;
  }
}

// The lowest schema version this checker understands. Cert files at
// versions below this are rejected because they lack fields the
// checker depends on (notably `llzkParityStatus`, which v0.1.0
// encoded only as English in `description`).
constexpr int MIN_MAJOR = 0;
constexpr int MIN_MINOR = 2;
// (PATCH = anything; patch-higher is accepted with unknown-key tolerance.)

// --- enum dispatchers (strict; reject unknown variants) --------------------
//
// Per docs/strategy-e-certificates.md §"Versioning policy", a reader
// at an older minor version that encounters an unknown enum
// constructor MUST reject the file. The functions below implement
// that as an exhaustive if-else-error chain — the recommended dispatch
// shape from the policy. Permissive defaults are an anti-pattern.

bool parseOperandShapeKind(const std::string &s, OperandShape::Kind &out,
                           std::string *errMsg) {
  if      (s == "any")      { out = OperandShape::Kind::Any;      return true; }
  else if (s == "const")    { out = OperandShape::Kind::Const;    return true; }
  else if (s == "opResult") { out = OperandShape::Kind::OpResult; return true; }
  return fail(errMsg, "unknown OperandShape.kind '" + s + "'");
}

bool parseSideConditionKind(const std::string &s, SideCondition::Kind &out,
                            std::string *errMsg) {
  if      (s == "sameValue")             { out = SideCondition::Kind::SameValue;             return true; }
  else if (s == "constEquals")           { out = SideCondition::Kind::ConstEquals;           return true; }
  else if (s == "sameAttr")              { out = SideCondition::Kind::SameAttr;              return true; }
  else if (s == "attrInRegistry")        { out = SideCondition::Kind::AttrInRegistry;        return true; }
  else if (s == "constCompare")          { out = SideCondition::Kind::ConstCompare;          return true; }
  else if (s == "resultTypeFromOperand") { out = SideCondition::Kind::ResultTypeFromOperand; return true; }
  return fail(errMsg, "unknown SideCondition.kind '" + s + "'");
}

bool parseCompareOp(const std::string &s, CompareOp &out, std::string *errMsg) {
  if      (s == "eq") { out = CompareOp::Eq; return true; }
  else if (s == "ne") { out = CompareOp::Ne; return true; }
  else if (s == "lt") { out = CompareOp::Lt; return true; }
  else if (s == "le") { out = CompareOp::Le; return true; }
  else if (s == "gt") { out = CompareOp::Gt; return true; }
  else if (s == "ge") { out = CompareOp::Ge; return true; }
  return fail(errMsg, "unknown CompareOp '" + s + "' (expected eq/ne/lt/le/gt/ge)");
}

bool parseLlzkParityStatus(const std::string &s, LlzkParityStatus &out,
                           std::string *errMsg) {
  if      (s == "aligned")              { out = LlzkParityStatus::Aligned;            return true; }
  else if (s == "aligned-with-caveats") { out = LlzkParityStatus::AlignedWithCaveats; return true; }
  else if (s == "veir-only")            { out = LlzkParityStatus::VeirOnly;           return true; }
  return fail(errMsg, "unknown llzkParityStatus '" + s + "'");
}

// --- shape / condition / scope loaders --------------------------------------

bool loadOperandShape(const JsonValue &v, OperandShape &out,
                      const std::string &path, std::string *errMsg);

bool loadOperandShape(const JsonValue &v, OperandShape &out,
                      const std::string &path, std::string *errMsg) {
  if (v.kind != JsonValue::Kind::Object) {
    return fail(errMsg, path + ": expected JSON object for OperandShape");
  }
  const JsonValue *kindV = v.find("kind");
  if (!kindV || kindV->kind != JsonValue::Kind::String) {
    return fail(errMsg, path + ": OperandShape missing required string field 'kind'");
  }
  if (!parseOperandShapeKind(kindV->strVal, out.kind, errMsg)) {
    return fail(errMsg, path + ".kind: " + (errMsg ? *errMsg : ""));
  }
  switch (out.kind) {
    case OperandShape::Kind::Any:
      // No additional fields.
      return true;
    case OperandShape::Kind::Const: {
      const JsonValue *opKindV = v.find("opKind");
      if (!opKindV || opKindV->kind != JsonValue::Kind::String) {
        return fail(errMsg, path + ": OperandShape.const missing required 'opKind'");
      }
      out.opKind = opKindV->strVal;
      // Optional `value` field (v0.2.0).
      if (const JsonValue *vv = v.find("value")) {
        if (vv->kind != JsonValue::Kind::Int) {
          return fail(errMsg, path + ".value: expected integer");
        }
        out.hasConstValue = true;
        out.constValue = vv->intVal;
      }
      return true;
    }
    case OperandShape::Kind::OpResult: {
      const JsonValue *opKindV = v.find("opKind");
      if (!opKindV || opKindV->kind != JsonValue::Kind::String) {
        return fail(errMsg, path + ": OperandShape.opResult missing required 'opKind'");
      }
      out.opKind = opKindV->strVal;
      const JsonValue *opsV = v.find("operands");
      if (!opsV || opsV->kind != JsonValue::Kind::Array) {
        return fail(errMsg, path + ": OperandShape.opResult missing required array 'operands'");
      }
      out.operands.resize(opsV->arrayVal.size());
      for (size_t i = 0; i < opsV->arrayVal.size(); i++) {
        std::string subPath = path + ".operands[" + std::to_string(i) + "]";
        if (!loadOperandShape(opsV->arrayVal[i], out.operands[i], subPath, errMsg)) {
          return false;
        }
      }
      // Optional `commutative` flag (v0.2.0).
      if (const JsonValue *cv = v.find("commutative")) {
        if (cv->kind != JsonValue::Kind::Bool) {
          return fail(errMsg, path + ".commutative: expected boolean");
        }
        out.commutative = cv->boolVal;
      }
      return true;
    }
  }
  return false;  // unreachable
}

bool loadSideCondition(const JsonValue &v, SideCondition &out,
                       const std::string &path, std::string *errMsg) {
  if (v.kind != JsonValue::Kind::Object) {
    return fail(errMsg, path + ": expected JSON object for SideCondition");
  }
  const JsonValue *kindV = v.find("kind");
  if (!kindV || kindV->kind != JsonValue::Kind::String) {
    return fail(errMsg, path + ": SideCondition missing required string field 'kind'");
  }
  if (!parseSideConditionKind(kindV->strVal, out.kind, errMsg)) {
    return fail(errMsg, path + ".kind: " + (errMsg ? *errMsg : ""));
  }

  auto getStr = [&](const char *field, std::string &dst) {
    const JsonValue *fv = v.find(field);
    if (!fv || fv->kind != JsonValue::Kind::String) {
      return fail(errMsg, path + ": SideCondition." + kindV->strVal +
                              " missing required string field '" + field + "'");
    }
    dst = fv->strVal;
    return true;
  };
  auto getInt = [&](const char *field, long long &dst) {
    const JsonValue *fv = v.find(field);
    if (!fv || fv->kind != JsonValue::Kind::Int) {
      return fail(errMsg, path + ": SideCondition." + kindV->strVal +
                              " missing required integer field '" + field + "'");
    }
    dst = fv->intVal;
    return true;
  };

  switch (out.kind) {
    case SideCondition::Kind::SameValue:
      if (!getStr("lhs", out.lhs)) return false;
      if (!getStr("rhs", out.rhs)) return false;
      return true;
    case SideCondition::Kind::ConstEquals:
      if (!getStr("pos", out.pos)) return false;
      if (!getInt("value", out.value)) return false;
      return true;
    case SideCondition::Kind::SameAttr: {
      if (!getStr("attr", out.attr)) return false;
      const JsonValue *psV = v.find("positions");
      if (!psV || psV->kind != JsonValue::Kind::Array) {
        return fail(errMsg, path + ": SideCondition.sameAttr missing required array 'positions'");
      }
      for (size_t i = 0; i < psV->arrayVal.size(); i++) {
        if (psV->arrayVal[i].kind != JsonValue::Kind::String) {
          return fail(errMsg, path + ".positions[" + std::to_string(i) +
                                  "]: expected string");
        }
        out.positions.push_back(psV->arrayVal[i].strVal);
      }
      return true;
    }
    case SideCondition::Kind::AttrInRegistry:
      if (!getStr("pos", out.pos)) return false;
      if (!getStr("attr", out.attr)) return false;
      if (!getStr("registry", out.registry)) return false;
      return true;
    case SideCondition::Kind::ConstCompare: {
      if (!getStr("pos", out.pos)) return false;
      std::string opStr;
      if (!getStr("op", opStr)) return false;
      if (!parseCompareOp(opStr, out.op, errMsg)) {
        return fail(errMsg, path + ".op: " + (errMsg ? *errMsg : ""));
      }
      if (!getInt("value", out.value)) return false;
      return true;
    }
    case SideCondition::Kind::ResultTypeFromOperand:
      if (!getStr("pos", out.pos)) return false;
      return true;
  }
  return false;  // unreachable
}

bool loadScopeAssertion(const JsonValue &v, ScopeAssertion &out,
                        const std::string &path, std::string *errMsg) {
  if (v.kind != JsonValue::Kind::Object) {
    return fail(errMsg, path + ": expected JSON object for scope");
  }
  const JsonValue *kindV = v.find("kind");
  if (!kindV || kindV->kind != JsonValue::Kind::String) {
    return fail(errMsg, path + ": scope missing required string field 'kind'");
  }
  if (kindV->strVal != "withinAttr") {
    return fail(errMsg, path + ": unknown scope kind '" + kindV->strVal +
                            "' (expected 'withinAttr')");
  }
  out.kind = ScopeAssertion::Kind::WithinAttr;
  const JsonValue *attrV = v.find("attr");
  if (!attrV || attrV->kind != JsonValue::Kind::String) {
    return fail(errMsg, path + ": scope.withinAttr missing required string field 'attr'");
  }
  out.attr = attrV->strVal;
  return true;
}

bool loadCert(const JsonValue &v, Cert &out, const std::string &path,
              std::string *errMsg) {
  if (v.kind != JsonValue::Kind::Object) {
    return fail(errMsg, path + ": expected JSON object for cert");
  }

  auto getStr = [&](const char *field, std::string &dst) {
    const JsonValue *fv = v.find(field);
    if (!fv || fv->kind != JsonValue::Kind::String) {
      return fail(errMsg, path + ": cert missing required string field '" +
                              std::string(field) + "'");
    }
    dst = fv->strVal;
    return true;
  };

  if (!getStr("patternId", out.patternId)) return false;
  if (!getStr("rootKind", out.rootKind)) return false;
  if (!getStr("theoremName", out.theoremName)) return false;
  if (!getStr("description", out.description)) return false;

  // llzkParityStatus is REQUIRED at v0.2.0. (Was added in v0.1.1.)
  std::string parityStr;
  if (!getStr("llzkParityStatus", parityStr)) return false;
  if (!parseLlzkParityStatus(parityStr, out.llzkParityStatus, errMsg)) {
    return fail(errMsg, path + ".llzkParityStatus: " + (errMsg ? *errMsg : ""));
  }

  // lhs / rhs shapes.
  const JsonValue *lhsV = v.find("lhs");
  if (!lhsV) return fail(errMsg, path + ": cert missing required field 'lhs'");
  if (!loadOperandShape(*lhsV, out.lhs, path + ".lhs", errMsg)) return false;

  const JsonValue *rhsV = v.find("rhs");
  if (!rhsV) return fail(errMsg, path + ": cert missing required field 'rhs'");
  if (!loadOperandShape(*rhsV, out.rhs, path + ".rhs", errMsg)) return false;

  // conditions (array, possibly empty).
  const JsonValue *condsV = v.find("conditions");
  if (!condsV) return fail(errMsg, path + ": cert missing required field 'conditions'");
  if (condsV->kind != JsonValue::Kind::Array) {
    return fail(errMsg, path + ".conditions: expected array");
  }
  out.conditions.resize(condsV->arrayVal.size());
  for (size_t i = 0; i < condsV->arrayVal.size(); i++) {
    std::string subPath = path + ".conditions[" + std::to_string(i) + "]";
    if (!loadSideCondition(condsV->arrayVal[i], out.conditions[i], subPath, errMsg)) {
      return false;
    }
  }

  // scope (optional, v0.2.0).
  if (const JsonValue *scopeV = v.find("scope")) {
    out.hasScope = true;
    if (!loadScopeAssertion(*scopeV, out.scope, path + ".scope", errMsg)) {
      return false;
    }
  }
  return true;
}

}  // namespace

std::optional<CertCatalog> loadCertCatalog(const std::string &path,
                                           std::string *errMsg) {
  if (errMsg) errMsg->clear();

  std::ifstream in(path);
  if (!in.is_open()) {
    fail(errMsg, "cannot open certificate file: " + path);
    return std::nullopt;
  }
  std::stringstream buf;
  buf << in.rdbuf();
  std::string src = buf.str();

  std::string jsonErr;
  auto root = parseJson(src, &jsonErr);
  if (!root) {
    fail(errMsg, "JSON parse error: " + jsonErr);
    return std::nullopt;
  }

  // The top level must be an object with at least `schemaVersion` and
  // `certs`. `source`, `_note`, and any other `_`-prefixed keys are
  // informational (per the v0.2.0 versioning policy).
  if (root->kind != JsonValue::Kind::Object) {
    fail(errMsg, "cert file top-level value must be a JSON object");
    return std::nullopt;
  }

  // schemaVersion enforcement.
  const JsonValue *svV = root->find("schemaVersion");
  if (!svV || svV->kind != JsonValue::Kind::String) {
    fail(errMsg, "cert file missing required string field 'schemaVersion'");
    return std::nullopt;
  }
  int major = 0, minor = 0, patch = 0;
  if (!parseSemver(svV->strVal, major, minor, patch)) {
    fail(errMsg, "schemaVersion '" + svV->strVal +
                     "' is not in MAJOR.MINOR.PATCH form");
    return std::nullopt;
  }
  // Reject lower-major.
  if (major != MIN_MAJOR) {
    fail(errMsg, "schemaVersion '" + svV->strVal +
                     "' has different major version; this checker compiled "
                     "for " + std::to_string(MIN_MAJOR) + ".x");
    return std::nullopt;
  }
  // Reject lower-minor: the lower-minor cert may use the v0.1.x encoding
  // of llzkParityStatus (English in `description`) which the v0.2.0 loader
  // doesn't grok, OR it may lack the llzkParityStatus field entirely.
  // Either way, we can't infer assertion polarity safely.
  if (minor < MIN_MINOR) {
    fail(errMsg, "schemaVersion '" + svV->strVal +
                     "' is below " + std::to_string(MIN_MAJOR) + "." +
                     std::to_string(MIN_MINOR) +
                     ".0; this checker requires v0.2.0 or higher "
                     "(see docs/strategy-e-certificates.md §Versioning policy)");
    return std::nullopt;
  }
  // Higher-minor or higher-patch: accept with unknown-key tolerance.
  // The strict per-field enum dispatchers will reject any unknown
  // enum constructor encountered.

  CertCatalog cat;
  cat.schemaVersion = svV->strVal;

  if (const JsonValue *sourceV = root->find("source")) {
    if (sourceV->kind != JsonValue::Kind::String) {
      fail(errMsg, "'source' field must be a string");
      return std::nullopt;
    }
    cat.source = sourceV->strVal;
  }

  // certs array.
  const JsonValue *certsV = root->find("certs");
  if (!certsV) {
    fail(errMsg, "cert file missing required field 'certs'");
    return std::nullopt;
  }
  if (certsV->kind != JsonValue::Kind::Array) {
    fail(errMsg, "'certs' field must be a JSON array");
    return std::nullopt;
  }
  cat.certs.resize(certsV->arrayVal.size());
  for (size_t i = 0; i < certsV->arrayVal.size(); i++) {
    std::string subPath = "certs[" + std::to_string(i) + "]";
    if (!loadCert(certsV->arrayVal[i], cat.certs[i], subPath, errMsg)) {
      return std::nullopt;
    }
  }

  // _note, _aboutLlzkParityStatus, and any other `_`-prefixed keys
  // are informational; we ignore them by design. Likewise any
  // unknown top-level key is ignored per the patch-bump forward-
  // compat rule.

  return cat;
}

// --- runtime check ---------------------------------------------------------
//
// Architecture:
//   - `checkRewriteWith` is the pure orchestrator. It iterates the
//     catalog, dispatches on each cert's `llzkParityStatus`, and asks
//     a `Matcher` whether the candidate rewrite matches. The
//     orchestrator is pure C++ (no MLIR dependency) and is exercised
//     by the test suite via a scripted mock `Matcher`.
//   - `DefaultMatcher` (below) implements the `Matcher` interface
//     against the real MLIR API, guarded by `LLZK_HAVE_MLIR`. Without
//     MLIR, the matcher's methods fail closed so the checker rejects
//     all rewrites — same posture as the prior stub.
//   - `checkRewrite` is the public entry point: constructs a
//     `DefaultMatcher`, delegates to `checkRewriteWith`.

// Per-cert polarity-dispatch logic. Returns the per-cert outcome
// without committing to "is this the match"; the caller picks the
// first successful match.
namespace {

// Polarity-dispatch outcome for a single cert candidate.
enum class CandidateOutcome {
  NotApplicable,        ///< Skip this cert (VeirOnly).
  Reject,               ///< Cert doesn't apply (LHS/conditions failed).
  AcceptedExact,        ///< Aligned-style: LHS+RHS+conditions all match.
  AcceptedWithCaveat,   ///< AlignedWithCaveats: LHS+conditions match; RHS may diverge.
};

CandidateOutcome dispatchCert(const Cert &cert,
                              mlir::Operation *original,
                              mlir::Operation *replacement,
                              const Matcher &matcher) {
  // VeirOnly certs describe rewrites LLZK doesn't perform; they are
  // informational soundness statements only. Skip them in the
  // acceptance path. (If LLZK ever does perform a VeirOnly rewrite,
  // the cert's parity classification has become stale; surfacing
  // that diagnostic is the VerifyRewritesPass's job, not the
  // orchestrator's — to keep the orchestrator's outcome semantics
  // crisp.)
  if (cert.llzkParityStatus == LlzkParityStatus::VeirOnly) {
    return CandidateOutcome::NotApplicable;
  }
  // LHS must match the original op for the cert to be applicable at all.
  if (!matcher.matchOpShape(cert.lhs, original)) {
    return CandidateOutcome::Reject;
  }
  // Side conditions are part of the cert's applicability premise.
  // Failing here means "this cert doesn't describe LLZK's rewrite"
  // — distinct from "the cert applies but LLZK produced a divergent
  // result", which is the caveat case.
  if (!matcher.checkConds(cert.conditions, original)) {
    return CandidateOutcome::Reject;
  }
  // RHS check. Behavior depends on parity:
  //   - Aligned: require exact RHS match. Mismatch = reject (caller
  //     keeps looking for another cert).
  //   - AlignedWithCaveats: mismatch is acceptable (the cert
  //     acknowledges LLZK might produce a divergent RHS due to
  //     documented caveats); accept with caveatTriggered.
  bool rhsMatch = matcher.matchOpShape(cert.rhs, replacement);
  if (cert.llzkParityStatus == LlzkParityStatus::Aligned) {
    return rhsMatch ? CandidateOutcome::AcceptedExact
                    : CandidateOutcome::Reject;
  }
  // AlignedWithCaveats:
  return rhsMatch ? CandidateOutcome::AcceptedExact
                  : CandidateOutcome::AcceptedWithCaveat;
}

}  // namespace

CheckResult checkRewriteWith(const CertCatalog &catalog,
                             mlir::Operation *original,
                             mlir::Operation *replacement,
                             const Matcher &matcher) {
  // O(N) over catalog. For 15 patterns that's fine; a larger catalog
  // would index by `rootKind` (the first thing the matcher checks).
  for (const auto &cert : catalog.certs) {
    CandidateOutcome co = dispatchCert(cert, original, replacement, matcher);
    if (co == CandidateOutcome::AcceptedExact) {
      return CheckResult{
          /*accepted=*/true,
          /*matchedPatternId=*/cert.patternId,
          /*rejectReason=*/"",
          /*matchedParity=*/cert.llzkParityStatus,
          /*caveatTriggered=*/false,
      };
    }
    if (co == CandidateOutcome::AcceptedWithCaveat) {
      return CheckResult{
          /*accepted=*/true,
          /*matchedPatternId=*/cert.patternId,
          /*rejectReason=*/"",
          /*matchedParity=*/cert.llzkParityStatus,
          /*caveatTriggered=*/true,
      };
    }
    // NotApplicable / Reject: keep iterating.
  }
  return CheckResult{
      /*accepted=*/false,
      /*matchedPatternId=*/"",
      /*rejectReason=*/"no certificate matched this rewrite",
      /*matchedParity=*/LlzkParityStatus::Aligned,
      /*caveatTriggered=*/false,
  };
}

// --- DefaultMatcher: MLIR-backed (when available), fail-closed otherwise --

namespace {

class DefaultMatcher : public Matcher {
 public:
  bool matchOpShape(const OperandShape & /*shape*/,
                    mlir::Operation * /*op*/) const override {
#ifdef LLZK_HAVE_MLIR
    // TODO(W4B follow-up): walk `op`'s operand chain matching against
    // `shape`. Sketch:
    //   - For `shape.kind == Any`: return true.
    //   - For `shape.kind == Const`: return op->getName().getStringRef() == shape.opKind
    //     && (!shape.hasConstValue || op->getAttrOfType<...>("value") == shape.constValue).
    //   - For `shape.kind == OpResult`:
    //       check op->getName().getStringRef() == shape.opKind
    //       check op->getNumOperands() == shape.operands.size()
    //       for each operand, recursively match against
    //         op->getOperand(i).getDefiningOp() (or null for block args).
    //       If shape.commutative && operands.size() == 2, also try swapped order.
    // Real implementation lands when a build with MLIR headers is set
    // up and the lit-test corpus (LLZK MLIR inputs) is in place.
    return false;
#else
    return false;
#endif
  }

  bool checkConds(const std::vector<SideCondition> & /*conds*/,
                  mlir::Operation * /*original*/) const override {
#ifdef LLZK_HAVE_MLIR
    // TODO(W4B follow-up): implement the six side-condition kinds:
    //   - SameValue: resolve `lhs`/`rhs` paths via OperandPath, compare
    //     mlir::Value pointer equality.
    //   - ConstEquals: resolve `pos`, check it's a constant of expected value.
    //   - SameAttr: resolve each position, extract named attribute, compare.
    //   - AttrInRegistry: resolve `pos`, extract attr, check against
    //     a hardcoded LLZK Field registry (initial: the six built-in
    //     fields {bn128, bn254, babybear, goldilocks, mersenne31,
    //     koalabear}). Pluggable registries are a v0.3 feature.
    //   - ConstCompare: like ConstEquals, with CompareOp dispatch.
    //   - ResultTypeFromOperand: resolve `pos`, compare mlir::Type.
    // OperandPath (checker/src/OperandPath.h) is the pos-resolver
    // these all share.
    return false;
#else
    return false;
#endif
  }
};

}  // namespace

CheckResult checkRewrite(const CertCatalog &catalog,
                         mlir::Operation *original,
                         mlir::Operation *replacement) {
  DefaultMatcher m;
  return checkRewriteWith(catalog, original, replacement, m);
}

}  // namespace llzk_lean
