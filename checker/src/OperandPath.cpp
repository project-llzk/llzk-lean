// SPDX-License-Identifier: Apache-2.0
//
// OperandPath parser. See OperandPath.h for grammar.

#include "OperandPath.h"

#include <sstream>

namespace llzk_lean {

namespace {

bool fail(std::string *errMsg, const std::string &reason) {
  if (errMsg && errMsg->empty()) *errMsg = reason;
  return false;
}

}  // namespace

std::optional<OperandPath> OperandPath::parse(const std::string &posStr,
                                              std::string *errMsg) {
  if (errMsg) errMsg->clear();
  if (posStr.empty()) {
    fail(errMsg, "empty pos string");
    return std::nullopt;
  }

  OperandPath out;
  size_t i = 0;

  // --- root ---------------------------------------------------------------
  // Identify "lhs" or "rhs" prefix.
  if (posStr.compare(i, 3, "lhs") == 0) {
    out.steps.push_back(0);
    i += 3;
  } else if (posStr.compare(i, 3, "rhs") == 0) {
    out.steps.push_back(1);
    i += 3;
  } else {
    fail(errMsg, "pos path must start with 'lhs' or 'rhs', got: " + posStr);
    return std::nullopt;
  }

  // --- segments -----------------------------------------------------------
  // Each segment is ".operand[N]". Loop until end of string.
  while (i < posStr.size()) {
    if (posStr[i] != '.') {
      fail(errMsg, "expected '.' separator at position " + std::to_string(i) +
                       " in pos: " + posStr);
      return std::nullopt;
    }
    i++;  // consume '.'
    static const std::string kOperandPrefix = "operand[";
    if (posStr.compare(i, kOperandPrefix.size(), kOperandPrefix) != 0) {
      fail(errMsg, "expected 'operand[' after '.' at position " +
                       std::to_string(i) + " in pos: " + posStr);
      return std::nullopt;
    }
    i += kOperandPrefix.size();
    // Parse digits up to ']'.
    size_t numStart = i;
    while (i < posStr.size() && posStr[i] >= '0' && posStr[i] <= '9') i++;
    if (i == numStart) {
      fail(errMsg, "expected digit in operand[...] at position " +
                       std::to_string(numStart) + " in pos: " + posStr);
      return std::nullopt;
    }
    if (i >= posStr.size() || posStr[i] != ']') {
      fail(errMsg, "expected ']' at position " + std::to_string(i) +
                       " in pos: " + posStr);
      return std::nullopt;
    }
    int idx = 0;
    for (size_t j = numStart; j < i; j++) {
      // Overflow-safe accumulation: indices in cert files are tiny.
      idx = idx * 10 + (posStr[j] - '0');
      if (idx > 1000) {
        fail(errMsg, "operand[N] index too large; cert format is for small N");
        return std::nullopt;
      }
    }
    out.steps.push_back(idx);
    i++;  // consume ']'
  }

  return out;
}

std::string OperandPath::toString() const {
  if (steps.empty()) return "";
  std::ostringstream oss;
  oss << (steps[0] == 0 ? "lhs" : (steps[0] == 1 ? "rhs" : "?"));
  for (size_t i = 1; i < steps.size(); i++) {
    oss << ".operand[" << steps[i] << "]";
  }
  return oss.str();
}

}  // namespace llzk_lean
