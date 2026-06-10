#!/usr/bin/env bash

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODE="strict"
WORKSPACE_VEIR=""

EXPECTED_LLZK_LEAN_HEAD="617702beadfb"

FAIL=0
WARN=0

usage() {
  cat <<'USAGE'
usage: scripts/harness/doctor.sh [--mode strict|exploratory] [--workspace-veir PATH]

Validates the current llzk-lean harness. Strict mode requires a clean
.lake/packages/VeIR checkout at the accepted reproducible pin. Exploratory mode
only downgrades an optional workspace VeIR mismatch.
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
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    --workspace-veir)
      WORKSPACE_VEIR="${2:-}"
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

case "$MODE" in
  strict|exploratory) ;;
  *)
    fail "invalid mode: ${MODE}"
    exit 2
    ;;
esac

require_file() {
  local path="$1"
  if [[ -f "${ROOT}/${path}" ]]; then
    ok "found ${path}"
  else
    fail "missing ${path}"
  fi
}

require_executable() {
  local path="$1"
  if [[ -x "${ROOT}/${path}" ]]; then
    ok "executable ${path}"
  else
    fail "missing executable ${path}"
  fi
}

require_tool() {
  local tool="$1"
  if command -v "$tool" >/dev/null 2>&1; then
    ok "tool ${tool} is available"
  else
    fail "required tool ${tool} is not available"
  fi
}

optional_tool() {
  local tool="$1"
  if command -v "$tool" >/dev/null 2>&1; then
    ok "optional tool ${tool} is available"
  else
    warn "optional tool ${tool} is not available"
  fi
}

require_tool git
require_tool lake
optional_tool cmake
optional_tool ctest

git_root="$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null || true)"
if [[ "$git_root" == "$ROOT" ]]; then
  ok "git root is ${ROOT}"
else
  fail "expected git root ${ROOT}, got ${git_root:-<none>}"
fi

head_short="$(git -C "$ROOT" rev-parse --short=12 HEAD 2>/dev/null || true)"
if [[ "$head_short" == "$EXPECTED_LLZK_LEAN_HEAD" ]]; then
  ok "llzk-lean HEAD matches bootstrap input ${EXPECTED_LLZK_LEAN_HEAD}"
else
  warn "llzk-lean HEAD ${head_short:-<none>} differs from bootstrap input ${EXPECTED_LLZK_LEAN_HEAD}"
fi

require_file AGENTS.md
require_file docs/phases/PHASE-00-harness-reset.md
require_file docs/phases/PHASE-01-pins-and-repro.md
require_file docs/phases/PHASE-02-llzk-source-truth.md
require_file docs/phases/PHASE-03-felt-op-gap-ledger.md
require_file docs/phases/PHASE-04-strategy-a-differential.md
require_file docs/phases/PHASE-05-strategy-a-pin-and-corpus.md
require_file docs/phases/PHASE-06-strategy-a-divergence-burndown.md
require_file docs/phases/PHASE_TEMPLATE.md
require_file docs/harness/CURRENT.md
require_file docs/harness/SOURCES.md
require_file docs/harness/GATES.md
require_file docs/harness/FELT_OP_GAPS.md
require_file docs/harness/LLZK_SOURCE.md
require_file docs/harness/PINS.md
require_file docs/harness/REVIEWS.md
require_file reviews/PHASE-00/request.md
require_file reviews/PHASE-00/findings.md
require_file reviews/PHASE-00/disposition.md
require_file reviews/PHASE-00/adversarial-review.md
require_file reviews/PHASE-01/request.md
require_file reviews/PHASE-01/findings.md
require_file reviews/PHASE-01/disposition.md
require_file reviews/PHASE-01/adversarial-review.md
require_file reviews/PHASE-02/request.md
require_file reviews/PHASE-02/findings.md
require_file reviews/PHASE-02/disposition.md
require_file reviews/PHASE-02/adversarial-review.md
require_file reviews/PHASE-03/request.md
require_file reviews/PHASE-03/findings.md
require_file reviews/PHASE-03/disposition.md
require_file reviews/PHASE-03/adversarial-review.md
require_file reviews/PHASE-04/request.md
require_file reviews/PHASE-04/findings.md
require_file reviews/PHASE-04/disposition.md
require_file reviews/PHASE-04/adversarial-review.md
require_file reviews/PHASE-05/request.md
require_file reviews/PHASE-05/findings.md
require_file reviews/PHASE-05/disposition.md
require_file reviews/PHASE-05/adversarial-review.md
require_file reviews/PHASE-06/request.md
require_file reviews/PHASE-06/findings.md
require_file reviews/PHASE-06/disposition.md
require_file reviews/PHASE-06/adversarial-review.md
require_executable scripts/harness/check-doc-freshness.sh
require_executable scripts/harness/diff-smoke.sh
require_executable scripts/harness/cert-smoke.sh
require_executable scripts/harness/verify-pins.sh
require_executable scripts/harness/verify-llzk-source.sh
require_executable scripts/harness/validate-skills.sh

pin_args=(--mode "$MODE")
if [[ -n "$WORKSPACE_VEIR" ]]; then
  pin_args+=(--workspace-veir "$WORKSPACE_VEIR")
fi
if "${ROOT}/scripts/harness/verify-pins.sh" "${pin_args[@]}"; then
    ok "pin verification passed"
else
    fail "pin verification failed"
fi

if [[ -d "${ROOT}/reviews/PHASE-00/evidence" ]]; then
  ok "found reviews/PHASE-00/evidence"
else
  fail "missing reviews/PHASE-00/evidence"
fi

if [[ -d "${ROOT}/reviews/PHASE-01/evidence" ]]; then
  ok "found reviews/PHASE-01/evidence"
else
  fail "missing reviews/PHASE-01/evidence"
fi

if [[ -d "${ROOT}/reviews/PHASE-02/evidence" ]]; then
  ok "found reviews/PHASE-02/evidence"
else
  fail "missing reviews/PHASE-02/evidence"
fi

if [[ -d "${ROOT}/reviews/PHASE-03/evidence" ]]; then
  ok "found reviews/PHASE-03/evidence"
else
  fail "missing reviews/PHASE-03/evidence"
fi

if [[ -d "${ROOT}/reviews/PHASE-04/evidence" ]]; then
  ok "found reviews/PHASE-04/evidence"
else
  fail "missing reviews/PHASE-04/evidence"
fi

if [[ -d "${ROOT}/reviews/PHASE-05/evidence" ]]; then
  ok "found reviews/PHASE-05/evidence"
else
  fail "missing reviews/PHASE-05/evidence"
fi

if [[ -d "${ROOT}/reviews/PHASE-06/evidence" ]]; then
  ok "found reviews/PHASE-06/evidence"
else
  fail "missing reviews/PHASE-06/evidence"
fi

echo
echo "doctor summary: ${FAIL} fail, ${WARN} warn, mode=${MODE}"
if [[ "$FAIL" -ne 0 ]]; then
  exit 1
fi
exit 0
