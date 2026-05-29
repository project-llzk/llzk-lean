// SPDX-License-Identifier: Apache-2.0
//
// Smoke tests for the JSON parser + schema-aware cert loader.
// Runs as a standalone executable; no MLIR dependency. Returns
// non-zero on any test failure.
//
// Coverage:
//   - Happy path: load the committed snapshot, check field values
//   - Adversarial: malformed JSON, version mismatches, missing
//     required fields, unknown enum constructors, etc.
//
// Run with:
//   $ ./test_loader <path-to-felt-combine.cert.json>
// The path is the location of the committed snapshot relative to
// the test invocation. CMakeLists.txt passes the right path.

#include "CertChecker.h"
#include "JsonParser.h"
#include "OperandPath.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <unistd.h>  // for getpid() in writeTmp

using namespace llzk_lean;

// --- micro test framework --------------------------------------------------

static int gPassed = 0;
static int gFailed = 0;
static std::string gCurrentTest;

#define TEST(name)                                                       \
  static void name();                                                    \
  static void run_##name() {                                             \
    gCurrentTest = #name;                                                \
    std::cout << "[ RUN  ] " << #name << "\n";                           \
    int before = gFailed;                                                \
    name();                                                              \
    if (gFailed == before) {                                             \
      std::cout << "[ OK   ] " << #name << "\n";                         \
      gPassed++;                                                         \
    } else {                                                             \
      std::cout << "[ FAIL ] " << #name << "\n";                         \
    }                                                                    \
  }                                                                      \
  static void name()

#define EXPECT(cond, msg)                                                \
  do {                                                                   \
    if (!(cond)) {                                                       \
      std::cerr << "  EXPECT failed at " << __FILE__ << ":" << __LINE__  \
                << ": " << (msg) << "\n";                                \
      gFailed++;                                                         \
    }                                                                    \
  } while (0)

// --- helpers ---------------------------------------------------------------

// Write a temporary file containing `content` and return its path.
// Lifecycle: leaks the file (it's tiny + tests exit shortly after).
static std::string writeTmp(const std::string &content) {
  static int counter = 0;
  std::string path = "/tmp/llzk_lean_test_" +
                     std::to_string(::getpid()) + "_" +
                     std::to_string(counter++) + ".json";
  std::ofstream f(path);
  f << content;
  return path;
}

// Bind the snapshot path at startup.
static std::string gSnapshotPath;

// --- JSON parser tests -----------------------------------------------------

TEST(json_parse_atoms) {
  std::string err;
  auto null = parseJson("null", &err);
  EXPECT(null.has_value(), "parse 'null'");
  EXPECT(null && null->kind == JsonValue::Kind::Null, "null kind");

  auto t = parseJson("true", &err);
  EXPECT(t && t->kind == JsonValue::Kind::Bool && t->boolVal == true, "true");

  auto f = parseJson("false", &err);
  EXPECT(f && f->kind == JsonValue::Kind::Bool && f->boolVal == false, "false");

  auto n = parseJson("42", &err);
  EXPECT(n && n->kind == JsonValue::Kind::Int && n->intVal == 42, "42");

  auto neg = parseJson("-7", &err);
  EXPECT(neg && neg->intVal == -7, "-7");

  auto zero = parseJson("0", &err);
  EXPECT(zero && zero->intVal == 0, "0");
}

TEST(json_parse_strings) {
  std::string err;
  auto s = parseJson("\"hello\"", &err);
  EXPECT(s && s->kind == JsonValue::Kind::String && s->strVal == "hello", "basic string");

  auto esc = parseJson("\"a\\nb\\\"c\\\\d\"", &err);
  EXPECT(esc && esc->strVal == "a\nb\"c\\d", "escape sequences");

  // \uXXXX for the arrow character (U+2192).
  auto u = parseJson("\"\\u2192\"", &err);
  EXPECT(u && u->strVal == "\xe2\x86\x92", "\\u2192 → UTF-8");

  // Raw UTF-8 in string (the cert format uses this directly).
  auto raw = parseJson("\"x→y\"", &err);
  EXPECT(raw && raw->strVal == "x\xe2\x86\x92y", "raw UTF-8 →");
}

TEST(json_parse_arrays_objects) {
  std::string err;
  auto a = parseJson("[1, 2, 3]", &err);
  EXPECT(a && a->kind == JsonValue::Kind::Array, "array kind");
  EXPECT(a && a->arrayVal.size() == 3, "array size");
  EXPECT(a && a->arrayVal[0].intVal == 1 && a->arrayVal[2].intVal == 3, "array values");

  auto o = parseJson("{\"a\": 1, \"b\": \"x\"}", &err);
  EXPECT(o && o->kind == JsonValue::Kind::Object, "object kind");
  const JsonValue *aV = o->find("a");
  EXPECT(aV && aV->intVal == 1, "object .a == 1");
  const JsonValue *bV = o->find("b");
  EXPECT(bV && bV->strVal == "x", "object .b == \"x\"");
  EXPECT(o->find("c") == nullptr, "object .c missing");

  auto empty = parseJson("{}", &err);
  EXPECT(empty && empty->kind == JsonValue::Kind::Object && empty->objectVal.empty(),
         "empty object");
  auto emptyArr = parseJson("[]", &err);
  EXPECT(emptyArr && emptyArr->kind == JsonValue::Kind::Array && emptyArr->arrayVal.empty(),
         "empty array");
}

TEST(json_parse_nested) {
  std::string err;
  auto v = parseJson("{\"outer\": {\"inner\": [1, [2, 3]]}}", &err);
  EXPECT(v.has_value(), "parse nested");
  const JsonValue *inner = v ? v->find("outer") : nullptr;
  EXPECT(inner != nullptr, "find outer");
  const JsonValue *arr = inner ? inner->find("inner") : nullptr;
  EXPECT(arr && arr->kind == JsonValue::Kind::Array && arr->arrayVal.size() == 2,
         "inner array");
  EXPECT(arr && arr->arrayVal[1].arrayVal.size() == 2 &&
             arr->arrayVal[1].arrayVal[1].intVal == 3,
         "deeply nested");
}

TEST(json_parse_rejects_malformed) {
  std::string err;
  EXPECT(!parseJson("", &err).has_value(), "empty input rejected");
  EXPECT(!parseJson("{", &err).has_value(), "unterminated object");
  EXPECT(!parseJson("[1, 2,", &err).has_value(), "unterminated array");
  EXPECT(!parseJson("\"abc", &err).has_value(), "unterminated string");
  EXPECT(!parseJson("1.5", &err).has_value(), "float rejected");
  EXPECT(!parseJson("1e10", &err).has_value(), "exponent rejected");
  EXPECT(!parseJson("nul", &err).has_value(), "partial keyword");
  EXPECT(!parseJson("{\"a\": }", &err).has_value(), "missing value");
  EXPECT(!parseJson("{\"a\" 1}", &err).has_value(), "missing colon");
  // Trailing garbage:
  EXPECT(!parseJson("42garbage", &err).has_value(), "trailing garbage");
  // Diagnostics include line/col:
  err.clear();
  parseJson("\n\n[1,2,xx]", &err);
  EXPECT(err.find("line 3") != std::string::npos, "diagnostic includes line");
}

// --- schema-aware loader tests --------------------------------------------

TEST(load_committed_snapshot) {
  std::string err;
  auto catalog = loadCertCatalog(gSnapshotPath, &err);
  EXPECT(catalog.has_value(), "committed snapshot loads: " + err);
  if (!catalog) return;

  EXPECT(catalog->schemaVersion == "0.2.0",
         "schemaVersion is 0.2.0, got: " + catalog->schemaVersion);
  EXPECT(catalog->certs.size() == 2,
         "2 certs; got " + std::to_string(catalog->certs.size()));

  // Spot-check cert[0]: right_identity_zero_add
  const Cert &c0 = catalog->certs[0];
  EXPECT(c0.patternId == "right_identity_zero_add", "cert[0] patternId");
  EXPECT(c0.theoremName == "Veir.Data.Felt.right_identity_zero_add",
         "cert[0] theoremName");
  EXPECT(c0.llzkParityStatus == LlzkParityStatus::VeirOnly, "cert[0] parity");
  EXPECT(c0.lhs.kind == OperandShape::Kind::OpResult, "cert[0] lhs kind");
  EXPECT(c0.lhs.commutative == true, "cert[0] lhs commutative");
  EXPECT(c0.lhs.operands.size() == 2, "cert[0] lhs operand count");
  EXPECT(c0.lhs.operands[1].hasConstValue && c0.lhs.operands[1].constValue == 0,
         "cert[0] lhs.operands[1].value == 0");

  // Spot-check cert[1]: constant_fold_add
  const Cert &c1 = catalog->certs[1];
  EXPECT(c1.patternId == "constant_fold_add", "cert[1] patternId");
  EXPECT(c1.llzkParityStatus == LlzkParityStatus::AlignedWithCaveats,
         "cert[1] parity");
  EXPECT(c1.conditions.size() == 2, "cert[1] has 2 conditions");
  EXPECT(c1.conditions[0].kind == SideCondition::Kind::SameAttr,
         "cert[1] cond[0] sameAttr");
  EXPECT(c1.conditions[0].attr == "fieldName", "cert[1] cond[0] attr");
  EXPECT(c1.conditions[0].positions.size() == 2, "cert[1] cond[0] positions");
  EXPECT(c1.conditions[1].kind == SideCondition::Kind::AttrInRegistry,
         "cert[1] cond[1] attrInRegistry");
  EXPECT(c1.conditions[1].registry == "field", "cert[1] cond[1] registry");
}

TEST(load_rejects_low_schema_version) {
  std::string err;
  std::string p = writeTmp(R"({
    "schemaVersion": "0.1.1",
    "certs": []
  })");
  auto c = loadCertCatalog(p, &err);
  EXPECT(!c.has_value(), "v0.1.1 cert rejected");
  EXPECT(err.find("below 0.2.0") != std::string::npos,
         "diagnostic mentions minimum version; got: " + err);
}

TEST(load_accepts_higher_patch_version) {
  std::string err;
  std::string p = writeTmp(R"({
    "schemaVersion": "0.2.7",
    "certs": []
  })");
  auto c = loadCertCatalog(p, &err);
  EXPECT(c.has_value(), "v0.2.7 (patch-higher) accepted; got: " + err);
  EXPECT(c && c->schemaVersion == "0.2.7", "schemaVersion preserved");
}

TEST(load_ignores_unknown_keys) {
  std::string err;
  std::string p = writeTmp(R"({
    "schemaVersion": "0.2.0",
    "_note": "informational",
    "_aboutFuture": "still informational",
    "unknownKey": 42,
    "certs": []
  })");
  auto c = loadCertCatalog(p, &err);
  EXPECT(c.has_value(),
         "unknown top-level keys ignored per patch-bump policy; got: " + err);
}

TEST(load_rejects_unknown_enum_constructor) {
  std::string err;
  std::string p = writeTmp(R"({
    "schemaVersion": "0.2.0",
    "certs": [{
      "patternId": "x", "rootKind": "felt.add",
      "lhs": {"kind": "newFangledKind"},
      "rhs": {"kind": "any"},
      "conditions": [],
      "theoremName": "X.y",
      "llzkParityStatus": "veir-only",
      "description": "test"
    }]
  })");
  auto c = loadCertCatalog(p, &err);
  EXPECT(!c.has_value(), "unknown OperandShape.kind rejected");
  EXPECT(err.find("newFangledKind") != std::string::npos,
         "diagnostic names the unknown kind: " + err);
}

TEST(load_rejects_missing_required_field) {
  std::string err;
  // Missing rootKind.
  std::string p = writeTmp(R"({
    "schemaVersion": "0.2.0",
    "certs": [{
      "patternId": "x",
      "lhs": {"kind": "any"},
      "rhs": {"kind": "any"},
      "conditions": [],
      "theoremName": "X.y",
      "llzkParityStatus": "veir-only",
      "description": "test"
    }]
  })");
  auto c = loadCertCatalog(p, &err);
  EXPECT(!c.has_value(), "missing rootKind rejected");
  EXPECT(err.find("rootKind") != std::string::npos,
         "diagnostic names the missing field: " + err);
}

TEST(load_rejects_bad_parity_status) {
  std::string err;
  std::string p = writeTmp(R"({
    "schemaVersion": "0.2.0",
    "certs": [{
      "patternId": "x", "rootKind": "felt.add",
      "lhs": {"kind": "any"}, "rhs": {"kind": "any"},
      "conditions": [],
      "theoremName": "X.y",
      "llzkParityStatus": "mostly-aligned-maybe",
      "description": "test"
    }]
  })");
  auto c = loadCertCatalog(p, &err);
  EXPECT(!c.has_value(), "unknown parity rejected");
  EXPECT(err.find("mostly-aligned-maybe") != std::string::npos,
         "diagnostic names the bad parity: " + err);
}

TEST(load_handles_all_v020_constructs) {
  // A cert exercising every v0.2.0 schema feature in one shot.
  std::string err;
  std::string p = writeTmp(R"({
    "schemaVersion": "0.2.0",
    "certs": [{
      "patternId": "kitchen_sink",
      "rootKind": "felt.div",
      "lhs": {
        "kind": "opResult",
        "opKind": "felt.div",
        "operands": [
          {"kind": "any"},
          {"kind": "const", "opKind": "felt.const", "value": 7}
        ],
        "commutative": false
      },
      "rhs": {"kind": "const", "opKind": "felt.const", "value": 0},
      "conditions": [
        {"kind": "sameValue", "lhs": "lhs", "rhs": "rhs"},
        {"kind": "constEquals", "pos": "rhs", "value": 7},
        {"kind": "sameAttr", "attr": "fieldName", "positions": ["lhs", "rhs"]},
        {"kind": "attrInRegistry", "pos": "lhs", "attr": "fieldName", "registry": "field"},
        {"kind": "constCompare", "pos": "rhs", "op": "ne", "value": 0},
        {"kind": "resultTypeFromOperand", "pos": "lhs"}
      ],
      "theoremName": "Test.kitchen_sink",
      "llzkParityStatus": "aligned-with-caveats",
      "scope": {"kind": "withinAttr", "attr": "function.allow_non_native_field_ops"},
      "description": "Exercises every v0.2.0 schema constructor in a single cert."
    }]
  })");
  auto c = loadCertCatalog(p, &err);
  EXPECT(c.has_value(), "kitchen-sink cert loads: " + err);
  if (!c) return;
  EXPECT(c->certs.size() == 1, "1 cert");
  const Cert &cert = c->certs[0];
  EXPECT(cert.conditions.size() == 6, "6 conditions");
  EXPECT(cert.conditions[4].kind == SideCondition::Kind::ConstCompare,
         "conditions[4] kind");
  EXPECT(cert.conditions[4].op == CompareOp::Ne, "conditions[4] op == Ne");
  EXPECT(cert.lhs.operands[1].hasConstValue && cert.lhs.operands[1].constValue == 7,
         "lhs.operands[1].value == 7");
  EXPECT(cert.hasScope == true && cert.scope.attr == "function.allow_non_native_field_ops",
         "scope");
}

// --- OperandPath tests ----------------------------------------------------

TEST(operand_path_atoms) {
  std::string err;
  auto p = OperandPath::parse("lhs", &err);
  EXPECT(p && p->steps == std::vector<int>{0}, "lhs → [0]");

  auto q = OperandPath::parse("rhs", &err);
  EXPECT(q && q->steps == std::vector<int>{1}, "rhs → [1]");
}

TEST(operand_path_nested) {
  std::string err;
  auto p = OperandPath::parse("lhs.operand[0]", &err);
  EXPECT(p && p->steps == (std::vector<int>{0, 0}), "lhs.operand[0] → [0,0]");

  auto q = OperandPath::parse("rhs.operand[1].operand[0]", &err);
  EXPECT(q && q->steps == (std::vector<int>{1, 1, 0}),
         "rhs.operand[1].operand[0] → [1,1,0]");

  auto r = OperandPath::parse("lhs.operand[42]", &err);
  EXPECT(r && r->steps == (std::vector<int>{0, 42}), "operand[42]");
}

TEST(operand_path_roundtrip) {
  for (const char *input : {"lhs", "rhs", "lhs.operand[0]",
                            "rhs.operand[1].operand[0]"}) {
    std::string err;
    auto p = OperandPath::parse(input, &err);
    EXPECT(p.has_value(), std::string("parse ") + input);
    EXPECT(p && p->toString() == input, std::string("roundtrip ") + input);
  }
}

TEST(operand_path_rejects_malformed) {
  std::string err;
  EXPECT(!OperandPath::parse("", &err).has_value(), "empty rejected");
  EXPECT(!OperandPath::parse("foo", &err).has_value(), "bad root");
  EXPECT(!OperandPath::parse("lhs.operand", &err).has_value(),
         "missing bracket");
  EXPECT(!OperandPath::parse("lhs.operand[]", &err).has_value(), "empty index");
  EXPECT(!OperandPath::parse("lhs.operand[1", &err).has_value(),
         "unterminated bracket");
  EXPECT(!OperandPath::parse("lhs.operand[a]", &err).has_value(),
         "non-digit in index");
  EXPECT(!OperandPath::parse("lhsoperand[0]", &err).has_value(),
         "missing dot separator");
  EXPECT(!OperandPath::parse("lhs.foo[0]", &err).has_value(),
         "unknown segment kind");
}

// --- Polarity-dispatch tests via mock Matcher -----------------------------
//
// The orchestrator `checkRewriteWith` doesn't touch MLIR; it takes a
// `Matcher` interface and asks it questions. We can exercise the
// dispatch logic by scripting the matcher's responses.

// A scripted matcher: take vectors of expected (lhs/rhs/conditions)
// answers in order, return them. Useful for unit-testing the dispatcher.
class ScriptedMatcher : public Matcher {
 public:
  std::vector<bool> shapeAnswers;
  std::vector<bool> condAnswers;
  mutable size_t shapeIdx = 0;
  mutable size_t condIdx = 0;
  bool matchOpShape(const OperandShape & /*shape*/,
                    mlir::Operation * /*op*/) const override {
    if (shapeIdx >= shapeAnswers.size()) return false;
    return shapeAnswers[shapeIdx++];
  }
  bool checkConds(const std::vector<SideCondition> & /*conds*/,
                  mlir::Operation * /*original*/) const override {
    if (condIdx >= condAnswers.size()) return false;
    return condAnswers[condIdx++];
  }
};

// Helper: build a one-cert catalog with the given parity.
static CertCatalog makeCatalog(LlzkParityStatus parity, const std::string &patternId = "p") {
  Cert c;
  c.patternId = patternId;
  c.rootKind = "felt.add";
  c.lhs.kind = OperandShape::Kind::Any;
  c.rhs.kind = OperandShape::Kind::Any;
  c.theoremName = "Veir.Data.Felt." + patternId;
  c.llzkParityStatus = parity;
  c.description = "test";
  CertCatalog cat;
  cat.schemaVersion = "0.2.0";
  cat.certs.push_back(std::move(c));
  return cat;
}

TEST(dispatch_aligned_exact_match) {
  // Aligned cert, LHS+RHS+conds all match → accept exact.
  auto cat = makeCatalog(LlzkParityStatus::Aligned);
  ScriptedMatcher m;
  m.shapeAnswers = {true, true};  // LHS, RHS
  m.condAnswers = {true};
  auto r = checkRewriteWith(cat, nullptr, nullptr, m);
  EXPECT(r.accepted == true, "aligned + all match → accepted");
  EXPECT(r.matchedPatternId == "p", "patternId");
  EXPECT(r.caveatTriggered == false, "no caveat for exact aligned");
  EXPECT(r.matchedParity == LlzkParityStatus::Aligned, "parity recorded");
}

TEST(dispatch_aligned_rhs_mismatch_rejects) {
  // Aligned cert, RHS doesn't match → reject (caller would look at next cert).
  auto cat = makeCatalog(LlzkParityStatus::Aligned);
  ScriptedMatcher m;
  m.shapeAnswers = {true, false};  // LHS yes, RHS no
  m.condAnswers = {true};
  auto r = checkRewriteWith(cat, nullptr, nullptr, m);
  EXPECT(r.accepted == false, "aligned + RHS mismatch → reject");
}

TEST(dispatch_aligned_lhs_mismatch_rejects) {
  auto cat = makeCatalog(LlzkParityStatus::Aligned);
  ScriptedMatcher m;
  m.shapeAnswers = {false};  // LHS no — short-circuit
  m.condAnswers = {};
  auto r = checkRewriteWith(cat, nullptr, nullptr, m);
  EXPECT(r.accepted == false, "aligned + LHS mismatch → reject");
}

TEST(dispatch_aligned_conds_fail_rejects) {
  auto cat = makeCatalog(LlzkParityStatus::Aligned);
  ScriptedMatcher m;
  m.shapeAnswers = {true};  // LHS yes
  m.condAnswers = {false};  // conds fail — short-circuit before RHS check
  auto r = checkRewriteWith(cat, nullptr, nullptr, m);
  EXPECT(r.accepted == false, "aligned + conds fail → reject");
}

TEST(dispatch_caveat_with_rhs_match_accepts_exact) {
  // AlignedWithCaveats + LHS+RHS+conds all match → accept exact (no caveat).
  auto cat = makeCatalog(LlzkParityStatus::AlignedWithCaveats);
  ScriptedMatcher m;
  m.shapeAnswers = {true, true};
  m.condAnswers = {true};
  auto r = checkRewriteWith(cat, nullptr, nullptr, m);
  EXPECT(r.accepted == true, "caveat + all match → accepted");
  EXPECT(r.caveatTriggered == false, "no caveat needed when RHS matches");
  EXPECT(r.matchedParity == LlzkParityStatus::AlignedWithCaveats, "parity recorded");
}

TEST(dispatch_caveat_with_rhs_mismatch_accepts_with_caveat) {
  // AlignedWithCaveats + LHS+conds match but RHS mismatch → accept with caveat.
  auto cat = makeCatalog(LlzkParityStatus::AlignedWithCaveats);
  ScriptedMatcher m;
  m.shapeAnswers = {true, false};  // LHS yes, RHS no
  m.condAnswers = {true};
  auto r = checkRewriteWith(cat, nullptr, nullptr, m);
  EXPECT(r.accepted == true, "caveat + RHS mismatch → accepted-with-caveat");
  EXPECT(r.caveatTriggered == true, "caveat flag set");
  EXPECT(r.matchedParity == LlzkParityStatus::AlignedWithCaveats, "parity");
}

TEST(dispatch_caveat_lhs_fails_rejects) {
  // AlignedWithCaveats requires LHS+conds to match; LHS failure → reject.
  auto cat = makeCatalog(LlzkParityStatus::AlignedWithCaveats);
  ScriptedMatcher m;
  m.shapeAnswers = {false};
  m.condAnswers = {};
  auto r = checkRewriteWith(cat, nullptr, nullptr, m);
  EXPECT(r.accepted == false, "caveat + LHS fail → reject");
}

TEST(dispatch_veir_only_never_matches) {
  // VeirOnly certs are skipped entirely — even if everything would match.
  auto cat = makeCatalog(LlzkParityStatus::VeirOnly);
  ScriptedMatcher m;
  m.shapeAnswers = {true, true};  // would match
  m.condAnswers = {true};
  auto r = checkRewriteWith(cat, nullptr, nullptr, m);
  EXPECT(r.accepted == false, "veir-only is skipped (not iterated)");
  EXPECT(r.rejectReason.find("no certificate matched") != std::string::npos,
         "rejection reason is the generic no-match");
}

TEST(dispatch_first_match_wins) {
  // Two-cert catalog: first rejects, second accepts → return second's match.
  CertCatalog cat;
  cat.schemaVersion = "0.2.0";
  Cert c1, c2;
  c1.patternId = "first";  c1.llzkParityStatus = LlzkParityStatus::Aligned;
  c1.lhs.kind = OperandShape::Kind::Any; c1.rhs.kind = OperandShape::Kind::Any;
  c2.patternId = "second"; c2.llzkParityStatus = LlzkParityStatus::Aligned;
  c2.lhs.kind = OperandShape::Kind::Any; c2.rhs.kind = OperandShape::Kind::Any;
  cat.certs = {c1, c2};

  ScriptedMatcher m;
  // First cert: LHS yes, conds yes, RHS no → reject
  // Second cert: LHS yes, conds yes, RHS yes → accept
  m.shapeAnswers = {true, false, true, true};
  m.condAnswers  = {true,        true};
  auto r = checkRewriteWith(cat, nullptr, nullptr, m);
  EXPECT(r.accepted == true, "second cert accepts");
  EXPECT(r.matchedPatternId == "second", "patternId == 'second'");
}

// --- main ------------------------------------------------------------------

int main(int argc, char **argv) {
  if (argc != 2) {
    std::cerr << "Usage: " << argv[0]
              << " <path-to-felt-combine.cert.json>\n";
    return 2;
  }
  gSnapshotPath = argv[1];

  run_json_parse_atoms();
  run_json_parse_strings();
  run_json_parse_arrays_objects();
  run_json_parse_nested();
  run_json_parse_rejects_malformed();
  run_load_committed_snapshot();
  run_load_rejects_low_schema_version();
  run_load_accepts_higher_patch_version();
  run_load_ignores_unknown_keys();
  run_load_rejects_unknown_enum_constructor();
  run_load_rejects_missing_required_field();
  run_load_rejects_bad_parity_status();
  run_load_handles_all_v020_constructs();

  // OperandPath unit tests:
  run_operand_path_atoms();
  run_operand_path_nested();
  run_operand_path_roundtrip();
  run_operand_path_rejects_malformed();

  // Polarity-dispatch tests (mock-Matcher driven):
  run_dispatch_aligned_exact_match();
  run_dispatch_aligned_rhs_mismatch_rejects();
  run_dispatch_aligned_lhs_mismatch_rejects();
  run_dispatch_aligned_conds_fail_rejects();
  run_dispatch_caveat_with_rhs_match_accepts_exact();
  run_dispatch_caveat_with_rhs_mismatch_accepts_with_caveat();
  run_dispatch_caveat_lhs_fails_rejects();
  run_dispatch_veir_only_never_matches();
  run_dispatch_first_match_wins();

  std::cout << "\n[SUMMARY] " << gPassed << " passed, " << gFailed << " failed\n";
  return gFailed == 0 ? 0 : 1;
}
