#!/usr/bin/env bash
# Phase 10 bootstrap smoke for the external-driver Felt replacement path.
#
# This is not acceptance evidence by itself. It records the first executable
# shape: LLZK lowers custom assembly to generic MLIR, then LLZK and VEIR run
# comparable parse/print and canonicalization paths over that same input.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEFAULT_LLZK_OPT="/nix/store/awcw2wiypa02sl5vx4xm06qwji68xz3h-llzk-debug-2.0.0/bin/llzk-opt"
WORKSPACE_VEIR_DIR=""
if [[ -d "${ROOT}/../veir" ]]; then
  WORKSPACE_VEIR_DIR="$(cd "${ROOT}/../veir" && pwd)"
fi
STATUS=0

if [[ -z "${LLZK_OPT:-}" && -x "${DEFAULT_LLZK_OPT}" ]]; then
  export LLZK_OPT="${DEFAULT_LLZK_OPT}"
fi

if [[ -z "${LLZK_OPT:-}" ]]; then
  echo "ERROR: LLZK_OPT is unset and the accepted default llzk-opt was not found." >&2
  echo "Set LLZK_OPT=/path/to/llzk-opt and rerun." >&2
  exit 2
fi

if [[ -z "${VEIR_DIFF:-}" && -n "${WORKSPACE_VEIR_DIR}" &&
      -x "${WORKSPACE_VEIR_DIR}/scripts/llzk-diff.sh" ]]; then
  export VEIR_DIFF="${WORKSPACE_VEIR_DIR}/scripts/llzk-diff.sh"
fi

if [[ -n "${WORKSPACE_VEIR_DIR}" &&
      "${VEIR_DIFF:-}" == "${WORKSPACE_VEIR_DIR}/scripts/llzk-diff.sh" &&
      -z "${VEIR_OPT:-}" ]]; then
  build_log="$(mktemp -t phase10-veir-opt-build-XXXXXX)" || exit 2
  if (cd "${WORKSPACE_VEIR_DIR}" && lake build veir-opt >"${build_log}" 2>&1); then
    rm -f "${build_log}"
  else
    echo "ERROR: failed to refresh workspace veir-opt with 'lake build veir-opt'" >&2
    sed 's/^/  /' "${build_log}" >&2
    rm -f "${build_log}"
    exit 2
  fi
  export VEIR_OPT="${WORKSPACE_VEIR_DIR}/.lake/build/bin/veir-opt"
  echo "WORKSPACE-VEIR-OPT: lake build veir-opt succeeded for ${WORKSPACE_VEIR_DIR}"
fi

run_case() {
  local label="$1"
  local input="$2"
  shift 2

  echo
  echo "== ${label}: ${input} =="
  if "${ROOT}/differential/run-differential.sh" "$@" "${ROOT}/${input}"; then
    echo "SMOKE-PASS: ${label}: ${input}"
  else
    echo "SMOKE-FAIL: ${label}: ${input}" >&2
    STATUS=1
  fi
}

echo "Phase 10 external-driver smoke"
echo "LLZK_OPT=${LLZK_OPT}"
echo "VEIR_DIFF=${VEIR_DIFF:-<clean dependency default>}"
echo "lowering owner: llzk-opt --mlir-print-op-generic"
echo "C++ canonical path: llzk-opt --canonicalize --mlir-print-op-generic"
echo "VEIR canonical path: veir-opt -p=felt-combine,dce"
echo "current profile under smoke: enhanced VEIR felt-combine,dce"

run_case "parse-print aligned fold" "differential/corpus/felt/registered_add_fold.llzk"
run_case "canonical aligned fold" "differential/corpus/felt/registered_add_fold.llzk" --canonicalize
run_case "parse-print no-fire precondition" "differential/corpus/felt/unspecified_add_fold.llzk"
run_case "canonical no-fire precondition" "differential/corpus/felt/unspecified_add_fold.llzk" --canonicalize

exit "${STATUS}"
