#!/usr/bin/env bash

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LLZK_LIB="${ROOT}/../llzk-lib"

ACCEPTED_LLZK_COMMIT="db922857bc5a88a9107627ef6b36a8b5e57bc5c2"
ACCEPTED_LLZK_SHORT="${ACCEPTED_LLZK_COMMIT:0:12}"
ACCEPTED_LLZK_REF="origin/main"
FIELD_REGISTRY_PATH="lib/Util/Field.cpp"

EXPECTED_OPS=(
  const
  add
  sub
  mul
  pow
  div
  uintdiv
  sintdiv
  umod
  smod
  neg
  inv
  bit_and
  bit_or
  bit_xor
  bit_not
  shl
  shr
)

FAIL=0
WARN=0

usage() {
  cat <<'USAGE'
usage: scripts/harness/verify-llzk-source.sh [--llzk-lib PATH]

Verifies the accepted Phase 2 LLZK Felt source ref, source paths, Felt op
mnemonics, and built-in field registry facts.
USAGE
}

ok() {
  echo "PASS: $*"
}

warn() {
  echo "WARN: $*" >&2
  WARN=$((WARN + 1))
}

fail() {
  echo "FAIL: $*" >&2
  FAIL=$((FAIL + 1))
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --llzk-lib)
      LLZK_LIB="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      usage
      exit 2
      ;;
  esac
done

llzk="$(cd "$ROOT" && cd "$LLZK_LIB" 2>/dev/null && pwd || true)"
if [[ -z "$llzk" || ! -d "$llzk/.git" ]]; then
  fail "llzk-lib path is not a readable git checkout: ${LLZK_LIB}"
else
  ok "llzk-lib path is ${llzk}"
fi

ledger="${ROOT}/docs/harness/LLZK_SOURCE.md"
if [[ -f "$ledger" ]]; then
  ok "found docs/harness/LLZK_SOURCE.md"
  if grep -Fq "$ACCEPTED_LLZK_COMMIT" "$ledger"; then
    ok "LLZK source ledger records ${ACCEPTED_LLZK_SHORT}"
  else
    fail "LLZK source ledger does not record ${ACCEPTED_LLZK_COMMIT}"
  fi
  if grep -Fq "$FIELD_REGISTRY_PATH" "$ledger"; then
    ok "LLZK source ledger records ${FIELD_REGISTRY_PATH}"
  else
    fail "LLZK source ledger does not record ${FIELD_REGISTRY_PATH}"
  fi
else
  fail "missing docs/harness/LLZK_SOURCE.md"
fi

if [[ -n "$llzk" && -d "$llzk/.git" ]]; then
  echo "accepted LLZK source: ${ACCEPTED_LLZK_COMMIT} (${ACCEPTED_LLZK_REF})"

  if git -C "$llzk" cat-file -e "${ACCEPTED_LLZK_COMMIT}^{commit}" 2>/dev/null; then
    ok "accepted LLZK commit exists locally"
  else
    fail "accepted LLZK commit ${ACCEPTED_LLZK_COMMIT} is unavailable"
  fi

  origin_head="$(git -C "$llzk" rev-parse "$ACCEPTED_LLZK_REF" 2>/dev/null || true)"
  if [[ "$origin_head" == "$ACCEPTED_LLZK_COMMIT" ]]; then
    ok "${ACCEPTED_LLZK_REF} equals accepted LLZK source ${ACCEPTED_LLZK_SHORT}"
  else
    fail "${ACCEPTED_LLZK_REF} is ${origin_head:-<missing>}, expected ${ACCEPTED_LLZK_COMMIT}"
  fi

  worktree_head="$(git -C "$llzk" rev-parse HEAD 2>/dev/null || true)"
  if [[ "$worktree_head" == "$ACCEPTED_LLZK_COMMIT" ]]; then
    ok "llzk-lib worktree HEAD also equals accepted source"
  else
    warn "llzk-lib worktree HEAD ${worktree_head:-<missing>} differs; gate reads ${ACCEPTED_LLZK_COMMIT} with git show"
  fi

  expect_path() {
    local path="$1"
    if git -C "$llzk" cat-file -e "${ACCEPTED_LLZK_COMMIT}:${path}" 2>/dev/null; then
      ok "accepted source contains ${path}"
    else
      fail "accepted source missing ${path}"
    fi
  }

  reject_path() {
    local path="$1"
    if git -C "$llzk" cat-file -e "${ACCEPTED_LLZK_COMMIT}:${path}" 2>/dev/null; then
      fail "accepted source still contains stale ${path}"
    else
      ok "accepted source does not contain stale ${path}"
    fi
  }

  get_source() {
    git -C "$llzk" show "${ACCEPTED_LLZK_COMMIT}:$1" 2>/dev/null
  }

  expect_path include/llzk/Dialect/Felt/IR/Ops.td
  expect_path include/llzk/Dialect/Felt/IR/Types.td
  expect_path include/llzk/Dialect/Felt/IR/Attrs.td
  expect_path lib/Dialect/Felt/IR/Ops.cpp
  expect_path "$FIELD_REGISTRY_PATH"
  expect_path test/Dialect/Felt/felt_arith_pass.llzk
  expect_path unittests/IR/FeltFoldTests.cpp

  actual_ops="$(
    get_source include/llzk/Dialect/Felt/IR/Ops.td |
      sed -n 's/.*FeltDialect[A-Za-z]*Op<"\([^"]*\)".*/\1/p'
  )"
  expected_ops="$(printf '%s\n' "${EXPECTED_OPS[@]}")"
  if [[ "$actual_ops" == "$expected_ops" ]]; then
    ok "accepted Felt op mnemonics match Phase 2 ledger"
  else
    fail "accepted Felt op mnemonics differ from Phase 2 ledger"
    echo "expected:" >&2
    printf '%s\n' "$expected_ops" >&2
    echo "actual:" >&2
    printf '%s\n' "$actual_ops" >&2
  fi

  field_src="$(get_source "$FIELD_REGISTRY_PATH")"
  check_field_text() {
    local needle="$1"
    local desc="$2"
    if grep -Fq "$needle" <<<"$field_src"; then
      ok "$desc"
    else
      fail "$desc missing"
    fi
  }
  reject_field_text() {
    local needle="$1"
    local desc="$2"
    if grep -Fq "$needle" <<<"$field_src"; then
      fail "$desc present"
    else
      ok "$desc absent"
    fi
  }

  check_field_text 'BN128[] = "bn128"' "registry declares bn128"
  check_field_text 'BN254[] = "bn254"' "registry declares bn254"
  check_field_text 'GRUMPKIN[] = "grumpkin"' "registry declares grumpkin"
  check_field_text 'BABYBEAR[] = "babybear"' "registry declares babybear"
  check_field_text 'GOLDILOCKS[] = "goldilocks"' "registry declares goldilocks"
  check_field_text 'MERSENNE31[] = "mersenne31"' "registry declares mersenne31"
  check_field_text 'KOALABEAR[] = "koalabear"' "registry declares koalabear"
  check_field_text 'insert(BN128, "21888242871839275222246405745257275088548364400416034343698204186575808495617")' "registry maps bn128 to accepted prime"
  check_field_text 'insert(BN254, "21888242871839275222246405745257275088548364400416034343698204186575808495617")' "registry maps bn254 to accepted prime"
  check_field_text 'insert(GRUMPKIN, "21888242871839275222246405745257275088696311157297823662689037894645226208583")' "registry maps grumpkin to accepted prime"
  check_field_text 'insert(BABYBEAR, "2013265921")' "registry maps babybear to accepted prime"
  check_field_text 'insert(GOLDILOCKS, "18446744069414584321")' "registry maps goldilocks to accepted prime"
  check_field_text 'insert(MERSENNE31, "2147483647")' "registry maps mersenne31 to accepted prime"
  check_field_text 'insert(KOALABEAR, "2130706433")' "registry maps koalabear to accepted prime"

  types_src="$(get_source include/llzk/Dialect/Felt/IR/Types.td)"
  if grep -Fq 'let mnemonic = "type";' <<<"$types_src"; then
    ok "Felt type source defines !felt.type"
  else
    fail "Felt type source does not define !felt.type"
  fi
  if grep -Fq 'OptionalParameter<"::mlir::StringAttr">:$fieldName' <<<"$types_src"; then
    ok "Felt type source carries optional field-name parameter"
  else
    fail "Felt type source missing optional field-name parameter"
  fi
fi

check_local_text() {
  local path="$1"
  local needle="$2"
  local desc="$3"
  if [[ ! -f "${ROOT}/${path}" ]]; then
    fail "missing ${path}"
    return
  fi
  if grep -Fq "$needle" "${ROOT}/${path}"; then
    ok "$desc"
  else
    fail "$desc missing"
  fi
}

check_field_list() {
  local path="$1"
  local desc="$2"
  for expected in bn128 bn254 grumpkin babybear goldilocks mersenne31 koalabear; do
    check_local_text "$path" "$expected" "${desc} mentions ${expected}"
  done
}

check_field_list checker/src/CertChecker.cpp "checker registry comment block"
check_field_list docs/strategy-a-oracle.md "Strategy A registered-field source claim"
check_field_list docs/harness/LLZK_SOURCE.md "LLZK source ledger"

check_local_text docs/strategy-e-certificates.md '"sameAttr"' "Strategy E documents sameAttr side condition"
check_local_text docs/strategy-e-certificates.md '"attrInRegistry"' "Strategy E documents attrInRegistry side condition"
check_local_text LlzkLean/Cert.lean '(patternId := "constant_fold_add")' "Lean cert catalog contains constant_fold_add"
check_local_text LlzkLean/Cert.lean '.sameAttr "fieldName" ["lhs", "rhs"]' "Lean cert catalog requires same fieldName"
check_local_text LlzkLean/Cert.lean '.attrInRegistry "lhs" "fieldName" "field"' "Lean cert catalog requires registered fieldName"
check_local_text LlzkLean/Cert.lean '(llzkParityStatus := .alignedWithCaveats)' "Lean cert catalog marks constant_fold_add aligned-with-caveats"
check_local_text certs/felt-combine.cert.json '"patternId":"constant_fold_add"' "cert snapshot contains constant_fold_add"
check_local_text certs/felt-combine.cert.json '"llzkParityStatus":"aligned-with-caveats"' "cert snapshot records aligned-with-caveats"
check_local_text certs/felt-combine.cert.json '"kind":"sameAttr","attr":"fieldName","positions":["lhs","rhs"]' "cert snapshot requires same fieldName"
check_local_text certs/felt-combine.cert.json '"kind":"attrInRegistry","pos":"lhs","attr":"fieldName","registry":"field"' "cert snapshot requires registered fieldName"

echo
echo "LLZK source verification summary: ${FAIL} fail, ${WARN} warn"
if [[ "$FAIL" -ne 0 ]]; then
  exit 1
fi
exit 0
