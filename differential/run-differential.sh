#!/usr/bin/env bash
# Thin wrapper around VEIR's scripts/llzk-diff.sh, applied to the
# corpus under differential/corpus/. Reports PASS/DIVERGE per file
# and exits non-zero on any divergence.
#
# Usage:
#   ./differential/run-differential.sh                     # all corpus files
#   ./differential/run-differential.sh path/to/file.mlir   # one file
#   ./differential/run-differential.sh path/to/dir/        # all .mlir under dir
#
# Requires:
#   - VEIR built (via `lake build`); used through `lake exec veir-opt`.
#     First-run cost is the VEIR + Mathlib build inside .lake/packages/VeIR/
#     (~10 min). To reuse a pre-built VEIR checkout, symlink it in:
#       ln -sf /path/to/veir/.lake/build \
#           .lake/packages/VeIR/.lake/build
#   - llzk-opt on $PATH or via $LLZK_OPT.
#
# Environment toggles:
#   LOWER_FIRST=1     pass --lower-first to llzk-diff.sh so .llzk custom-asm
#                     inputs are normalized to generic-MLIR before comparison.
#                     Required for any input in LLZK's native textual form.
#
# See differential/README.md for the protocol and harness/differential.md
# in VEIR for the diff script's normalization rules.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORPUS="${ROOT}/differential/corpus"

# Locate VEIR's diff script in the Lake-managed dependency tree. After
# `lake update`, the VEIR source lives under `.lake/packages/VeIR/`.
VEIR_PACKAGE="${ROOT}/.lake/packages/VeIR"
DIFF="${VEIR_PACKAGE}/scripts/llzk-diff.sh"

if [[ ! -x "${DIFF}" ]]; then
  echo "ERROR: VEIR diff script not found at ${DIFF}" >&2
  echo "Run 'lake update' first to fetch the dependency. Note that the" >&2
  echo "veir-opt binary itself builds lazily on first 'lake exec veir-opt'" >&2
  echo "(triggered by this script), which is a multi-minute Mathlib build" >&2
  echo "the first time. Pre-warm by symlinking an existing VEIR build:" >&2
  echo "  ln -sf <path-to-veir>/.lake/build ${VEIR_PACKAGE}/.lake/build" >&2
  exit 2
fi

if [[ -z "${LLZK_OPT:-}" ]] && ! command -v llzk-opt >/dev/null 2>&1; then
  echo "ERROR: llzk-opt is not on \$PATH and \$LLZK_OPT is unset." >&2
  echo "Build llzk-lib (https://github.com/project-llzk/llzk-lib) and point us at it." >&2
  exit 2
fi

# Expand args into a list of .mlir files. Each arg may be a file (used as-is)
# or a directory (recursed into for *.mlir). With no args, scan the corpus dir.
TARGETS=()
expand_arg() {
  local a="$1"
  if [[ -f "$a" ]]; then
    TARGETS+=("$a")
  elif [[ -d "$a" ]]; then
    # Pick up both .mlir (generic-form) and .llzk (LLZK custom-asm)
    # inputs. The latter generally require `LOWER_FIRST=1` to be lowered
    # through `llzk-opt --mlir-print-op-generic` before the diff stage.
    while IFS= read -r f; do
      TARGETS+=("$f")
    done < <(find "$a" \( -name '*.mlir' -o -name '*.llzk' \) -type f | sort)
  else
    echo "WARN: $a is neither a file nor a directory; skipping" >&2
  fi
}

if [[ $# -gt 0 ]]; then
  for a in "$@"; do expand_arg "$a"; done
else
  expand_arg "${CORPUS}"
fi

if (( ${#TARGETS[@]} == 0 )); then
  echo "ERROR: no .mlir inputs to compare (looked under ${CORPUS} or args)." >&2
  echo "Add inputs under differential/corpus/, or pass a file/directory arg." >&2
  exit 2
fi

# Plumb LOWER_FIRST=1 through to the diff script as the --lower-first flag.
DIFF_ARGS=()
if [[ "${LOWER_FIRST:-0}" == "1" ]]; then
  DIFF_ARGS+=(--lower-first)
fi

PASS=0
FAIL=0
SKIP=0
FAILED_FILES=()

# A file under `expected-divergence/` is a *negative* test: we expect
# DIVERGE (exit 1) and treat PASS (exit 0) as a regression (the gap
# closed; update the doc and move the file). This lets the corpus
# document known alignment gaps without making CI red.
#
# llzk-diff.sh's exit-code contract (see scripts/llzk-diff.sh header):
#   0   identical (modulo normalization + allowlist)
#   1   differs (real divergence)
#   2   bad invocation / unreadable input (treat as ERROR; fail loud
#       regardless of directory polarity — an unreadable test is not
#       a documented divergence, it's a broken test)
#   77  llzk-opt or lake missing (SKIP — counted separately, neither
#       PASS nor FAIL; surfaces as a warning)
#
# The previous wrapper conflated all non-zero exits as "DIVERGE",
# which silently passed real ERRORs under expected-divergence/.
is_expected_divergence() {
  case "$1" in
    */expected-divergence/*) return 0 ;;
    *) return 1 ;;
  esac
}

for t in "${TARGETS[@]}"; do
  "${DIFF}" "$t" "${DIFF_ARGS[@]}" >/dev/null 2>&1
  rc=$?
  case "$rc" in
    0)
      if is_expected_divergence "$t"; then
        echo "UNEXPECTED-PASS: $t (expected divergence, got agreement — gap may be closed)"
        FAIL=$((FAIL+1))
        FAILED_FILES+=("$t")
      else
        echo "PASS: $t"
        PASS=$((PASS+1))
      fi
      ;;
    1)
      if is_expected_divergence "$t"; then
        echo "EXPECTED-DIVERGE: $t"
        PASS=$((PASS+1))
      else
        echo "DIVERGE: $t"
        FAIL=$((FAIL+1))
        FAILED_FILES+=("$t")
        # Re-run with verbose to surface the diff inline. We rerun the whole
        # pipeline; on a large corpus consider extracting just the diff stage.
        VEIR_DIFF_VERBOSE=1 "${DIFF}" "$t" "${DIFF_ARGS[@]}" 2>&1 | sed 's/^/  /'
      fi
      ;;
    2)
      # ERROR — fail loud regardless of expected-divergence/. A broken
      # test is not a documented divergence.
      echo "ERROR: $t (llzk-diff.sh exit 2 — bad invocation or unreadable input)"
      FAIL=$((FAIL+1))
      FAILED_FILES+=("$t")
      VEIR_DIFF_VERBOSE=1 "${DIFF}" "$t" "${DIFF_ARGS[@]}" 2>&1 | sed 's/^/  /'
      ;;
    77)
      echo "SKIP: $t (llzk-diff.sh exit 77 — llzk-opt or lake missing)"
      SKIP=$((SKIP+1))
      ;;
    *)
      # Any other exit code is unexpected. Treat as ERROR to be safe.
      echo "ERROR: $t (llzk-diff.sh exit $rc — unexpected)"
      FAIL=$((FAIL+1))
      FAILED_FILES+=("$t")
      VEIR_DIFF_VERBOSE=1 "${DIFF}" "$t" "${DIFF_ARGS[@]}" 2>&1 | sed 's/^/  /'
      ;;
  esac
done

echo
if (( SKIP > 0 )); then
  echo "Summary: ${PASS} pass (incl. expected-diverge), ${FAIL} fail, ${SKIP} skip (over ${#TARGETS[@]} inputs)"
else
  echo "Summary: ${PASS} pass (incl. expected-diverge), ${FAIL} fail (over ${#TARGETS[@]} inputs)"
fi

if (( FAIL > 0 )); then
  echo
  echo "Failed inputs (re-run with the specific path for the full diff;"
  echo "set VEIR_DIFF_KEEP=1 to retain tmp files for debugging):"
  for f in "${FAILED_FILES[@]}"; do
    echo "  - $f"
  done
  exit 1
fi
exit 0
