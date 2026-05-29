// SPDX-License-Identifier: Apache-2.0
//
// Hand-rolled JSON parser. See JsonParser.h for scope and rationale.
//
// Implementation: recursive descent, byte-level tokenizer. The parser
// state is encapsulated in `Parser` (file-local); the public
// `parseJson` is a thin wrapper.
//
// UTF-8 handling: string literals copy raw multi-byte UTF-8 sequences
// (bytes >= 0x80) through verbatim. We do not decode them into
// codepoints; the cert format treats strings as opaque UTF-8 blobs
// (the C++ checker doesn't interpret string content). We DO reject
// control characters (0x00 - 0x1F) inside string literals per RFC
// 8259 §7, and we reject lone `\u` escapes that would form a
// surrogate pair (the cert format uses raw UTF-8, not escape pairs).

#include "JsonParser.h"

#include <cstdint>
#include <sstream>

namespace llzk_lean {

namespace {

// File-local parser. Tracks the source string + a current position
// + line/column for diagnostics. Methods return `false` on failure
// and set `errMsg_` (if provided).
class Parser {
 public:
  Parser(const std::string &src, std::string *errMsg)
      : src_(src), errMsg_(errMsg) {}

  std::optional<JsonValue> parse() {
    skipWhitespace();
    JsonValue root;
    if (!parseValue(root)) return std::nullopt;
    skipWhitespace();
    if (pos_ != src_.size()) {
      fail("trailing content after top-level value");
      return std::nullopt;
    }
    return root;
  }

 private:
  // --- bookkeeping ----------------------------------------------------------

  // Advance one byte. Updates line/col for ASCII; UTF-8 continuation
  // bytes (0x80-0xBF) do not advance column count (we track logical
  // columns where one multi-byte char = one column).
  void advance() {
    if (pos_ >= src_.size()) return;
    char c = src_[pos_];
    pos_++;
    if (c == '\n') {
      line_++;
      col_ = 1;
    } else {
      // ASCII or UTF-8 start byte (0xC0-0xFF): advance column.
      // Continuation bytes (0x80-0xBF): don't.
      unsigned char uc = static_cast<unsigned char>(c);
      if (uc < 0x80 || uc >= 0xC0) col_++;
    }
  }

  char peek() const {
    return pos_ < src_.size() ? src_[pos_] : '\0';
  }

  bool eof() const { return pos_ >= src_.size(); }

  // Report a diagnostic of the form `"line N, col M: <reason>"` and
  // return false. The first caller's reason wins (we don't overwrite
  // a more-specific message with a generic one further up the stack).
  bool fail(const std::string &reason) {
    if (errMsg_ && errMsg_->empty()) {
      std::ostringstream oss;
      oss << "line " << line_ << ", col " << col_ << ": " << reason;
      *errMsg_ = oss.str();
    }
    return false;
  }

  void skipWhitespace() {
    while (!eof()) {
      char c = peek();
      if (c == ' ' || c == '\t' || c == '\n' || c == '\r') advance();
      else break;
    }
  }

  // --- value-level dispatch -------------------------------------------------

  // Populate `out` from the next JSON value. Returns false on syntax
  // error.
  bool parseValue(JsonValue &out) {
    skipWhitespace();
    if (eof()) return fail("unexpected end of input where value was expected");
    out.line = line_;
    out.col = col_;
    char c = peek();
    if (c == '{') return parseObject(out);
    if (c == '[') return parseArray(out);
    if (c == '"') return parseString(out);
    if (c == '-' || (c >= '0' && c <= '9')) return parseNumber(out);
    if (c == 't' || c == 'f') return parseBool(out);
    if (c == 'n') return parseNull(out);
    return fail("unexpected character '" + std::string(1, c) + "' at start of value");
  }

  // --- object: `{` (string `:` value (`,` string `:` value)*)? `}` ----------

  bool parseObject(JsonValue &out) {
    advance();  // consume '{'
    out.kind = JsonValue::Kind::Object;
    skipWhitespace();
    if (peek() == '}') {
      advance();
      return true;
    }
    while (true) {
      skipWhitespace();
      if (peek() != '"') return fail("expected string key in object");
      JsonValue keyVal;
      if (!parseString(keyVal)) return false;
      skipWhitespace();
      if (peek() != ':') return fail("expected ':' after object key");
      advance();
      JsonValue val;
      if (!parseValue(val)) return false;
      // Duplicate-key policy: last writer wins (matches what most
      // JSON consumers do; the cert format never produces duplicates).
      out.objectVal[keyVal.strVal] = std::move(val);
      skipWhitespace();
      if (peek() == ',') { advance(); continue; }
      if (peek() == '}') { advance(); return true; }
      return fail("expected ',' or '}' in object");
    }
  }

  // --- array: `[` (value (`,` value)*)? `]` ---------------------------------

  bool parseArray(JsonValue &out) {
    advance();  // consume '['
    out.kind = JsonValue::Kind::Array;
    skipWhitespace();
    if (peek() == ']') {
      advance();
      return true;
    }
    while (true) {
      JsonValue elem;
      if (!parseValue(elem)) return false;
      out.arrayVal.push_back(std::move(elem));
      skipWhitespace();
      if (peek() == ',') { advance(); continue; }
      if (peek() == ']') { advance(); return true; }
      return fail("expected ',' or ']' in array");
    }
  }

  // --- string: `"` char* `"` -----------------------------------------------

  bool parseString(JsonValue &out) {
    if (peek() != '"') return fail("expected string");
    advance();  // consume opening '"'
    out.kind = JsonValue::Kind::String;
    out.strVal.clear();
    while (!eof()) {
      unsigned char uc = static_cast<unsigned char>(peek());
      if (uc == '"') {
        advance();
        return true;
      }
      if (uc < 0x20) {
        return fail("unescaped control character in string");
      }
      if (uc == '\\') {
        advance();
        if (eof()) return fail("trailing backslash in string");
        char esc = peek();
        advance();
        switch (esc) {
          case '"': out.strVal.push_back('"'); break;
          case '\\': out.strVal.push_back('\\'); break;
          case '/': out.strVal.push_back('/'); break;
          case 'b': out.strVal.push_back('\b'); break;
          case 'f': out.strVal.push_back('\f'); break;
          case 'n': out.strVal.push_back('\n'); break;
          case 'r': out.strVal.push_back('\r'); break;
          case 't': out.strVal.push_back('\t'); break;
          case 'u': {
            // \uXXXX — decode 4 hex digits as a Unicode codepoint,
            // re-encode as UTF-8.
            uint32_t cp = 0;
            for (int i = 0; i < 4; i++) {
              if (eof()) return fail("truncated \\u escape");
              char h = peek();
              advance();
              cp <<= 4;
              if (h >= '0' && h <= '9') cp |= (h - '0');
              else if (h >= 'a' && h <= 'f') cp |= (h - 'a' + 10);
              else if (h >= 'A' && h <= 'F') cp |= (h - 'A' + 10);
              else return fail("non-hex character in \\u escape");
            }
            // Reject surrogate halves (would need pair handling, not
            // supported per the file-header scope).
            if (cp >= 0xD800 && cp <= 0xDFFF) {
              return fail("\\u surrogate halves not supported; use raw UTF-8");
            }
            // Encode codepoint as UTF-8.
            if (cp < 0x80) {
              out.strVal.push_back(static_cast<char>(cp));
            } else if (cp < 0x800) {
              out.strVal.push_back(static_cast<char>(0xC0 | (cp >> 6)));
              out.strVal.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
            } else {
              out.strVal.push_back(static_cast<char>(0xE0 | (cp >> 12)));
              out.strVal.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3F)));
              out.strVal.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
            }
            break;
          }
          default:
            return fail("unknown escape sequence \\" + std::string(1, esc));
        }
      } else {
        // ASCII or raw UTF-8 byte — copy through. Multi-byte UTF-8
        // sequences pass through as multiple iterations; we don't
        // validate well-formedness beyond rejecting unescaped
        // control characters.
        out.strVal.push_back(peek());
        advance();
      }
    }
    return fail("unterminated string literal");
  }

  // --- number: `-`? `0` | `1-9` digit* (integer only; no exponents) --------

  bool parseNumber(JsonValue &out) {
    out.kind = JsonValue::Kind::Int;
    bool negative = false;
    if (peek() == '-') { negative = true; advance(); }
    if (eof()) return fail("truncated number");
    long long val = 0;
    if (peek() == '0') {
      advance();
      // After leading zero, only end-of-number characters are valid.
    } else if (peek() >= '1' && peek() <= '9') {
      while (!eof() && peek() >= '0' && peek() <= '9') {
        // Overflow check.
        long long d = peek() - '0';
        if (val > (LLONG_MAX_REL_LIMIT - d) / 10) {
          return fail("integer overflow (cert format uses int64-range values)");
        }
        val = val * 10 + d;
        advance();
      }
    } else {
      return fail("expected digit at start of number");
    }
    // Reject decimal point / exponent — cert format is integer-only.
    if (peek() == '.' || peek() == 'e' || peek() == 'E') {
      return fail("floating-point numbers not supported by the cert format");
    }
    out.intVal = negative ? -val : val;
    return true;
  }

  // Conservative pre-multiply overflow bound: LLONG_MAX / 10
  // approximation. Using a constant to keep the parse loop fast.
  // 9223372036854775807 / 10 = 922337203685477580.
  static constexpr long long LLONG_MAX_REL_LIMIT = 9223372036854775807LL;

  // --- literals: true / false / null ----------------------------------------

  bool parseBool(JsonValue &out) {
    if (matchKeyword("true")) {
      out.kind = JsonValue::Kind::Bool;
      out.boolVal = true;
      return true;
    }
    if (matchKeyword("false")) {
      out.kind = JsonValue::Kind::Bool;
      out.boolVal = false;
      return true;
    }
    return fail("expected 'true' or 'false'");
  }

  bool parseNull(JsonValue &out) {
    if (matchKeyword("null")) {
      out.kind = JsonValue::Kind::Null;
      return true;
    }
    return fail("expected 'null'");
  }

  bool matchKeyword(const char *kw) {
    size_t len = 0;
    while (kw[len]) len++;
    if (pos_ + len > src_.size()) return false;
    for (size_t i = 0; i < len; i++) {
      if (src_[pos_ + i] != kw[i]) return false;
    }
    for (size_t i = 0; i < len; i++) advance();
    return true;
  }

  // --- state ---------------------------------------------------------------

  const std::string &src_;
  std::string *errMsg_;
  size_t pos_ = 0;
  int line_ = 1;
  int col_ = 1;
};

}  // namespace

std::optional<JsonValue> parseJson(const std::string &src,
                                   std::string *errMsg) {
  if (errMsg) errMsg->clear();
  Parser p(src, errMsg);
  return p.parse();
}

}  // namespace llzk_lean
