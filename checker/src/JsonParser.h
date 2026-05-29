// SPDX-License-Identifier: Apache-2.0
//
// Minimal JSON parser for the llzk-lean cert format. Hand-rolled to
// keep the trusted base small — the alternative (a third-party JSON
// library) would pull in a non-trivial dependency whose correctness
// would gate the certificate checker's soundness.
//
// Scope:
//   - Parses the strict JSON subset that `EmitCerts.lean` produces:
//     `null`, `true`, `false`, integers, strings, arrays, objects.
//   - Floating-point numbers are NOT supported (the cert format
//     doesn't use them; rejecting at parse time is safer than
//     silently lossy double conversion).
//   - String literals support standard JSON escapes (`\"`, `\\`,
//     `\/`, `\b`, `\f`, `\n`, `\r`, `\t`, `\uXXXX`) and raw UTF-8
//     multi-byte sequences (the cert format uses `→` U+2192 in
//     description text; that's a valid raw UTF-8 sequence in JSON
//     strings per RFC 8259 §7).
//   - Line/column tracking for diagnostics.
//
// Out of scope:
//   - Floats / exponential numbers.
//   - Surrogate-pair `\uXXXX\uYYYY` decoding (rejected; cert text is
//     plain UTF-8, not UTF-16-escaped).
//   - Streaming / incremental parsing.
//
// Diagnostics: on failure, `parseJson` returns `std::nullopt` and
// (if `errMsg` is non-null) writes a one-line human-readable message
// of the form `"line N, col M: <reason>"`.

#ifndef LLZK_LEAN_JSON_PARSER_H
#define LLZK_LEAN_JSON_PARSER_H

#include <memory>
#include <optional>
#include <string>
#include <unordered_map>
#include <vector>

namespace llzk_lean {

/// A parsed JSON value. Lightweight tagged union: the `kind` field
/// selects which of the other fields is meaningful. Composite values
/// (Array, Object) own their children directly.
struct JsonValue {
  enum class Kind { Null, Bool, Int, String, Array, Object };
  Kind kind = Kind::Null;

  // Atomic fields, populated per `kind`:
  bool boolVal = false;
  long long intVal = 0;
  std::string strVal;

  // Composite fields:
  std::vector<JsonValue> arrayVal;
  // Object key order is not preserved (we use a hash map for O(1)
  // lookup). The cert format doesn't depend on key order, and the
  // emitter writes in a fixed canonical order anyway.
  std::unordered_map<std::string, JsonValue> objectVal;

  // Position of the value's first character in the source, for
  // diagnostics. 1-indexed.
  int line = 0;
  int col = 0;

  // Convenience accessors that return std::nullopt on type mismatch
  // (rather than throwing). The schema loader uses these to write
  // strict-typed validation in a compact style.

  /// Get the value of a string field. Returns nullopt if `kind` is
  /// not String.
  std::optional<std::string> asString() const {
    return kind == Kind::String ? std::make_optional(strVal) : std::nullopt;
  }

  /// Get the value of an integer field. Returns nullopt if `kind` is
  /// not Int.
  std::optional<long long> asInt() const {
    return kind == Kind::Int ? std::make_optional(intVal) : std::nullopt;
  }

  /// Get the value of a bool field. Returns nullopt if `kind` is not
  /// Bool.
  std::optional<bool> asBool() const {
    return kind == Kind::Bool ? std::make_optional(boolVal) : std::nullopt;
  }

  /// Get a pointer to the array's elements. Returns nullptr if `kind`
  /// is not Array.
  const std::vector<JsonValue> *asArray() const {
    return kind == Kind::Array ? &arrayVal : nullptr;
  }

  /// Get a pointer to a named member of an Object. Returns nullptr if
  /// `kind` is not Object or the key doesn't exist.
  const JsonValue *find(const std::string &key) const {
    if (kind != Kind::Object) return nullptr;
    auto it = objectVal.find(key);
    return it == objectVal.end() ? nullptr : &it->second;
  }

  /// True iff this is an Object that contains the given key.
  bool has(const std::string &key) const { return find(key) != nullptr; }
};

/// Parse a JSON document from a UTF-8-encoded source string. Returns
/// std::nullopt on syntax error (with `*errMsg` set to a diagnostic
/// if non-null). Successfully parses the strict subset documented in
/// the file header.
std::optional<JsonValue> parseJson(const std::string &src,
                                   std::string *errMsg = nullptr);

}  // namespace llzk_lean

#endif  // LLZK_LEAN_JSON_PARSER_H
