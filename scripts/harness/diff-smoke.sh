#!/usr/bin/env bash

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TARGET="${1:-${ROOT}/differential/corpus/felt/const_identities.mlir}"
DIFF_WRAPPER="${ROOT}/differential/run-differential.sh"
VEIR_DIFF="${ROOT}/.lake/packages/VeIR/scripts/llzk-diff.sh"

if [[ ! -r "$TARGET" ]]; then
  echo "TOOL-FAIL: target is not readable: ${TARGET}" >&2
  exit 2
fi

if [[ ! -x "$DIFF_WRAPPER" ]]; then
  echo "TOOL-FAIL: differential wrapper is not executable: ${DIFF_WRAPPER}" >&2
  exit 2
fi

if [[ ! -x "$VEIR_DIFF" ]]; then
  echo "TOOL-FAIL: VeIR diff script is not executable: ${VEIR_DIFF}" >&2
  exit 2
fi

if ! command -v lake >/dev/null 2>&1; then
  echo "TOOL-MISSING: lake is not available" >&2
  exit 77
fi

if [[ -z "${LLZK_OPT:-}" ]] && ! command -v llzk-opt >/dev/null 2>&1; then
  echo "TOOL-MISSING: llzk-opt is not on PATH and LLZK_OPT is unset" >&2
  exit 77
fi

TMPDIR_LOCAL="$(mktemp -d -t llzk-lean-diff-smoke-XXXXXX)"
cleanup() {
  rm -rf "$TMPDIR_LOCAL"
}
trap cleanup EXIT

"$DIFF_WRAPPER" "$TARGET" >"${TMPDIR_LOCAL}/out" 2>&1
rc=$?

cat "${TMPDIR_LOCAL}/out"
case "$rc" in
  0)
    if grep -q '^EXPECTED-DIVERGE:' "${TMPDIR_LOCAL}/out"; then
      echo "DIFF-SMOKE: expected divergence classified"
    else
      echo "DIFF-SMOKE: pass"
    fi
    exit 0
    ;;
  1)
    if grep -Eq '^(DIVERGE|UNEXPECTED-PASS):' "${TMPDIR_LOCAL}/out"; then
      echo "DIFF-SMOKE: semantic divergence or unexpected pass" >&2
    else
      echo "DIFF-SMOKE: wrapper failure" >&2
    fi
    exit 1
    ;;
  2)
    echo "DIFF-SMOKE: tool, parse, pass, or invocation failure" >&2
    exit 2
    ;;
  77)
    echo "DIFF-SMOKE: tool missing" >&2
    exit 77
    ;;
  *)
    echo "DIFF-SMOKE: unexpected exit ${rc}" >&2
    exit 2
    ;;
esac
