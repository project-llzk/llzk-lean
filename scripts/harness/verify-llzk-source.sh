#!/usr/bin/env bash

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LLZK_LIB="${ROOT}/../llzk-lib"

ACCEPTED_LLZK_COMMIT="db922857bc5a88a9107627ef6b36a8b5e57bc5c2"
ACCEPTED_LLZK_SHORT="${ACCEPTED_LLZK_COMMIT:0:12}"
ACCEPTED_LLZK_REF="origin/main"
ACCEPTED_LLZK_REMOTE="git@github.com:project-llzk/llzk-lib.git"
ACCEPTED_VEIR_COMMIT="a0bb2fc8e6d38ab068247dfc6506ba63f5feb953"
ACCEPTED_VEIR_SHORT="${ACCEPTED_VEIR_COMMIT:0:12}"
FIELD_REGISTRY_PATH="lib/Util/Field.cpp"

LEDGER_PATHS=(
  include/llzk/Dialect/Felt/IR/Ops.td
  include/llzk/Dialect/Felt/IR/Types.td
  include/llzk/Dialect/Felt/IR/Attrs.td
  include/llzk/Dialect/Felt/IR/OpInterfaces.td
  lib/Dialect/Felt/IR/Ops.cpp
  "$FIELD_REGISTRY_PATH"
  test/Dialect/Felt/felt_arith_pass.llzk
  test/Dialect/Felt/felt_arith_fail.llzk
  test/Dialect/Felt/felt_const_fold.llzk
  test/Dialect/Felt/felt_spec_pass.llzk
  test/Dialect/Felt/types_pass.llzk
  unittests/IR/FeltFoldTests.cpp
)

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
  if grep -Fq "$ACCEPTED_LLZK_REMOTE" "$ledger"; then
    ok "LLZK source ledger records accepted remote ${ACCEPTED_LLZK_REMOTE}"
  else
    fail "LLZK source ledger does not record accepted remote ${ACCEPTED_LLZK_REMOTE}"
  fi
  if grep -Fq "$FIELD_REGISTRY_PATH" "$ledger"; then
    ok "LLZK source ledger records ${FIELD_REGISTRY_PATH}"
  else
    fail "LLZK source ledger does not record ${FIELD_REGISTRY_PATH}"
  fi
  for path in "${LEDGER_PATHS[@]}"; do
    if grep -Fq "$path" "$ledger"; then
      ok "LLZK source ledger records ${path}"
    else
      fail "LLZK source ledger does not record ${path}"
    fi
  done
else
  fail "missing docs/harness/LLZK_SOURCE.md"
fi

if [[ -n "$llzk" && -d "$llzk/.git" ]]; then
  echo "accepted LLZK source: ${ACCEPTED_LLZK_COMMIT} (${ACCEPTED_LLZK_REF}, ${ACCEPTED_LLZK_REMOTE})"

  origin_url="$(git -C "$llzk" remote get-url origin 2>/dev/null || true)"
  if [[ "$origin_url" == "$ACCEPTED_LLZK_REMOTE" ]]; then
    ok "llzk-lib origin remote matches ${ACCEPTED_LLZK_REMOTE}"
  else
    fail "llzk-lib origin remote ${origin_url:-<missing>} does not match ${ACCEPTED_LLZK_REMOTE}"
  fi

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

  check_source_text() {
    local path="$1"
    local needle="$2"
    local desc="$3"
    if get_source "$path" | grep -Fq -- "$needle"; then
      ok "$desc"
    else
      fail "$desc missing"
    fi
  }

  for path in "${LEDGER_PATHS[@]}"; do
    expect_path "$path"
  done

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

  check_source_text include/llzk/Dialect/Felt/IR/Attrs.td 'def LLZK_FeltConstAttr' "Felt attrs source defines FeltConstAttr"
  check_source_text include/llzk/Dialect/Felt/IR/Attrs.td 'let mnemonic = "const";' "Felt attrs source defines const mnemonic"
  check_source_text include/llzk/Dialect/Felt/IR/Attrs.td 'def LLZK_FieldSpecAttr' "Felt attrs source defines FieldSpecAttr"
  check_source_text include/llzk/Dialect/Felt/IR/Attrs.td 'let mnemonic = "field";' "Felt attrs source defines field mnemonic"
  check_source_text include/llzk/Dialect/Felt/IR/Attrs.td '::mlir::StringAttr getFieldName() const;' "Felt attrs source exposes getFieldName"
  check_source_text include/llzk/Dialect/Felt/IR/Attrs.td '- grumpkin' "Felt attrs source lists grumpkin as built-in"
  check_source_text include/llzk/Dialect/Felt/IR/Attrs.td '- koalabear' "Felt attrs source lists koalabear as built-in"
  check_source_text include/llzk/Dialect/Felt/IR/OpInterfaces.td 'def FeltBinaryOpInterface' "Felt op interface source defines binary interface"
  check_source_text include/llzk/Dialect/Felt/IR/OpInterfaces.td '"getLhs"' "Felt op interface source exposes getLhs"
  check_source_text include/llzk/Dialect/Felt/IR/OpInterfaces.td '"getRhs"' "Felt op interface source exposes getRhs"
  check_source_text lib/Dialect/Felt/IR/Ops.cpp 'tryGetBinaryFoldData' "Felt folder source has binary fold data helper"
  check_source_text lib/Dialect/Felt/IR/Ops.cpp 'Field::tryGetField' "Felt folder source resolves registered fields"
  check_source_text lib/Dialect/Felt/IR/Ops.cpp 'data->field->reduce(data->lhsVal + data->rhsVal)' "Felt folder source reduces add folds"
  check_source_text test/Dialect/Felt/felt_arith_fail.llzk "field 'moo' is not defined" "Felt verifier-failure test rejects unknown fields"
  check_source_text test/Dialect/Felt/felt_const_fold.llzk 'fold_add_wrap' "Felt fold test covers add wrap-around"
  check_source_text test/Dialect/Felt/felt_const_fold.llzk 'felt.sintdiv' "Felt fold test covers signed division"
  check_source_text test/Dialect/Felt/felt_spec_pass.llzk '#felt.field<"moo", 7>' "Felt field-spec test covers custom field syntax"
  check_source_text test/Dialect/Felt/types_pass.llzk '!felt.type' "Felt type test covers bare felt type syntax"
  check_source_text unittests/IR/FeltFoldTests.cpp 'AddNoFoldUnspecified' "Felt unit tests cover unspecified-field no-fold"
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

check_felt_prime_file() {
  local path="$1"
  local desc="$2"
  if [[ ! -f "$path" ]]; then
    fail "${desc} feltPrime file is missing at ${path}"
    return
  fi

  if grep -Fq "lib/Util/Field.cpp::initKnownFields" "$path"; then
    ok "${desc} feltPrime cites current LLZK registry path"
  else
    fail "${desc} feltPrime does not cite lib/Util/Field.cpp::initKnownFields"
  fi
  for entry in bn128 bn254 grumpkin babybear goldilocks mersenne31 koalabear; do
    if grep -Fq "$entry" "$path"; then
      ok "${desc} feltPrime mentions ${entry}"
    else
      fail "${desc} feltPrime missing ${entry}"
    fi
  done

  check_felt_prime_case() {
    local field="$1"
    local prime="$2"
    if awk -v field="$field" -v prime="$prime" '
      $0 ~ "if n = \"" field "\"\\.toUTF8 then" {
        found = 1
        if ($0 ~ "some[[:space:]]+" prime) {
          matched = 1
        } else if ((getline nextline) > 0 && nextline ~ "some[[:space:]]+" prime) {
          matched = 1
        }
      }
      END { exit(found && matched ? 0 : 1) }
    ' "$path"; then
      ok "${desc} feltPrime maps ${field} to accepted prime"
    else
      fail "${desc} feltPrime does not map ${field} to accepted prime ${prime}"
    fi
  }
  check_felt_prime_case "bn254" "21888242871839275222246405745257275088548364400416034343698204186575808495617"
  check_felt_prime_case "bn128" "21888242871839275222246405745257275088548364400416034343698204186575808495617"
  check_felt_prime_case "grumpkin" "21888242871839275222246405745257275088696311157297823662689037894645226208583"
  check_felt_prime_case "babybear" "2013265921"
  check_felt_prime_case "goldilocks" "18446744069414584321"
  check_felt_prime_case "mersenne31" "2147483647"
  check_felt_prime_case "koalabear" "2130706433"
}

veir_dep="${ROOT}/.lake/packages/VeIR"
if [[ -d "${veir_dep}/.git" ]]; then
  dep_head="$(git -C "$veir_dep" rev-parse HEAD 2>/dev/null || true)"
  if [[ "$dep_head" == "$ACCEPTED_VEIR_COMMIT" ]]; then
    ok "pinned VeIR dependency HEAD is ${ACCEPTED_VEIR_SHORT}"
  else
    fail "pinned VeIR dependency HEAD ${dep_head:-<missing>} does not match ${ACCEPTED_VEIR_COMMIT}"
  fi
else
  fail "pinned VeIR dependency checkout missing at ${veir_dep}"
fi
check_felt_prime_file "${veir_dep}/Veir/Passes/Felt/InterpModel.lean" "pinned VeIR dependency"

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
