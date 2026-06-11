#!/usr/bin/env bash
# Thin wrapper around VEIR's scripts/llzk-diff.sh, applied to the
# corpus under differential/corpus/. Reports a classified outcome per file
# and exits non-zero on any FAIL outcome.
#
# Usage:
#   ./differential/run-differential.sh                     # all corpus files
#   ./differential/run-differential.sh path/to/file.mlir   # one file
#   ./differential/run-differential.sh path/to/dir/        # all .mlir/.llzk under dir
#   ./differential/run-differential.sh --canonicalize      # canonical Phase 4 mode
#
# Requires:
#   - VEIR can build its `veir-opt` executable. The default clean dependency
#     path refreshes `.lake/packages/VeIR/.lake/build/bin/veir-opt` with
#     `lake build veir-opt` before comparing, so stale executable artifacts do
#     not become acceptance evidence. First-run cost is the VEIR + Mathlib build
#     inside .lake/packages/VeIR/ (~10 min). To reuse a pre-built VEIR checkout,
#     symlink it in:
#       ln -sf /path/to/veir/.lake/build \
#           .lake/packages/VeIR/.lake/build
#   - llzk-opt on $PATH or via $LLZK_OPT.
#
# Environment toggles:
#   VEIR_DIFF=/path   use an explicit VEIR scripts/llzk-diff.sh. By default
#                     the clean pinned Lake dependency is used.
#   CANONICALIZE=1    pass --canonicalize to llzk-diff.sh so it compares
#                     `llzk-opt --canonicalize` with `veir-opt -p=felt-combine,dce`.
#   LOWER_FIRST=1     force --lower-first for every input. The wrapper already
#                     applies --lower-first automatically to .llzk inputs.
#
# See differential/README.md for the protocol and docs/harness/GATES.md for the
# current smoke classification boundary. This is not Phase 1 acceptance evidence.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORPUS="${ROOT}/differential/corpus"

# Locate VEIR's diff script in the Lake-managed dependency tree. After
# `lake update`, the VEIR source lives under `.lake/packages/VeIR/`.
VEIR_PACKAGE="${ROOT}/.lake/packages/VeIR"
if [[ -n "${VEIR_DIFF:-}" ]]; then
  DIFF="${VEIR_DIFF}"
  CLEAN_DEPENDENCY_DIFF=0
else
  DIFF="${VEIR_PACKAGE}/scripts/llzk-diff.sh"
  CLEAN_DEPENDENCY_DIFF=1
fi

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
ARGS=()

abs_path() {
  local p="$1"
  local d b
  d="$(cd "$(dirname "$p")" && pwd)" || return 1
  b="$(basename "$p")"
  printf '%s/%s\n' "$d" "$b"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --canonicalize) CANONICALIZE=1; shift ;;
    --lower-first) LOWER_FIRST=1; shift ;;
    -h|--help)
      sed -n '1,25p' "$0" >&2
      exit 2
      ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do
        ARGS+=("$1")
        shift
      done
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ "${CANONICALIZE:-0}" == "1" ]] && ! grep -Fq -- "--canonicalize" "${DIFF}"; then
  echo "ERROR: selected VEIR diff script does not support --canonicalize: ${DIFF}" >&2
  echo "For the Phase 4 workspace run, set:" >&2
  echo "  VEIR_DIFF=../veir/scripts/llzk-diff.sh" >&2
  echo "or bump llzk-lean's clean VeIR dependency pin to a commit containing this flag." >&2
  exit 2
fi

refresh_clean_dependency_veir_opt() {
  if [[ "${CLEAN_DEPENDENCY_DIFF}" != "1" ]]; then
    return 0
  fi

  if [[ -n "${VEIR_OPT:-}" ]]; then
    echo "ERROR: VEIR_OPT override is incompatible with default clean dependency evidence." >&2
    echo "Unset VEIR_OPT for clean-pin evidence, or set VEIR_DIFF for an explicit workspace run." >&2
    return 2
  fi

  if [[ ! -d "${VEIR_PACKAGE}" ]]; then
    echo "ERROR: VEIR package checkout missing at ${VEIR_PACKAGE}" >&2
    return 2
  fi

  local build_log
  build_log="$(mktemp -t llzk-veir-opt-build-XXXXXX)" || return 2
  if (cd "${VEIR_PACKAGE}" && lake build veir-opt >"${build_log}" 2>&1); then
    rm -f "${build_log}"
  else
    echo "ERROR: failed to refresh pinned VeIR veir-opt with 'lake build veir-opt'" >&2
    sed 's/^/  /' "${build_log}" >&2
    rm -f "${build_log}"
    return 2
  fi

  if [[ ! -x "${VEIR_PACKAGE}/.lake/build/bin/veir-opt" ]]; then
    echo "ERROR: lake build veir-opt did not produce an executable at ${VEIR_PACKAGE}/.lake/build/bin/veir-opt" >&2
    return 2
  fi

  echo "CLEAN-VEIR-OPT: lake build veir-opt succeeded for ${VEIR_PACKAGE}"
}

expand_arg() {
  local a="$1"
  if [[ -f "$a" ]]; then
    TARGETS+=("$(abs_path "$a")")
  elif [[ -d "$a" ]]; then
    # Pick up both .mlir (generic-form) and .llzk (LLZK custom-asm)
    # inputs. The latter are lowered automatically through
    # `llzk-opt --mlir-print-op-generic` before the diff stage.
    while IFS= read -r f; do
      TARGETS+=("$(abs_path "$f")")
    done < <(find "$a" \( -name '*.mlir' -o -name '*.llzk' \) -type f | sort)
  else
    echo "WARN: $a is neither a file nor a directory; skipping" >&2
  fi
}

if (( ${#ARGS[@]} > 0 )); then
  for a in "${ARGS[@]}"; do expand_arg "$a"; done
else
  expand_arg "${CORPUS}"
fi

if (( ${#TARGETS[@]} == 0 )); then
  echo "ERROR: no .mlir/.llzk inputs to compare (looked under ${CORPUS} or args)." >&2
  echo "Add inputs under differential/corpus/, or pass a file/directory arg." >&2
  exit 2
fi

refresh_clean_dependency_veir_opt || exit 2

# Common flags for every input. Per-file flags are added in the loop below.
DIFF_ARGS=()
if [[ "${CANONICALIZE:-0}" == "1" ]]; then
  DIFF_ARGS+=(--canonicalize)
fi

PASS=0
FAIL=0
SKIP=0
MODE_SKIP=0
FAILED_FILES=()

# A file under `expected-divergence/` is a *negative* test. Its file header must
# declare exactly which inverted outcome is accepted:
#
#   EXPECTED-DIVERGE
#   EXPECTED-VEIR-FAIL
#   EXPECTED-LLZK-FAIL
#
# Treating the whole directory as a wildcard would let a compiler/parser crash
# pass as an expected output divergence, which is not acceptance evidence.
#
# llzk-diff.sh's exit-code contract (see scripts/llzk-diff.sh header):
#   0   identical (modulo normalization + allowlist)
#   1   differs (real divergence)
#   2   bad invocation / unreadable input (treat as ERROR; fail loud
#       regardless of directory polarity — an unreadable test is not
#       a documented divergence, it's a broken test)
#   3   veir-opt failed on the input or selected pipeline
#   4   llzk-opt failed on the input or selected pipeline
#   77  a required differential tool is unavailable (SKIP — counted
#       separately, neither PASS nor FAIL; surfaces as a warning)
#
# The previous wrapper conflated all non-zero exits as "DIVERGE",
# which silently passed real ERRORs under expected-divergence/.
is_expected_divergence() {
  case "$1" in
    */expected-divergence/*) return 0 ;;
    *) return 1 ;;
  esac
}

expected_marker() {
  local path="$1"
  grep -Eo 'EXPECTED-(DIVERGE|VEIR-FAIL|LLZK-FAIL)' "$path" | head -1
}

is_canonical_only() {
  case "$1" in
    */canonical/*) return 0 ;;
    *) return 1 ;;
  esac
}

is_parse_print_only() {
  case "$1" in
    */parse-print/*) return 0 ;;
    *) return 1 ;;
  esac
}

for t in "${TARGETS[@]}"; do
  if [[ "${CANONICALIZE:-0}" == "1" ]]; then
    if is_parse_print_only "$t"; then
      echo "MODE-SKIP: $t (parse/print-only input)"
      MODE_SKIP=$((MODE_SKIP+1))
      continue
    fi
  elif is_canonical_only "$t"; then
    echo "MODE-SKIP: $t (canonicalization-only input)"
    MODE_SKIP=$((MODE_SKIP+1))
    continue
  fi

  expected=""
  if is_expected_divergence "$t"; then
    expected="$(expected_marker "$t")"
    if [[ -z "$expected" ]]; then
      echo "ERROR: $t (expected-divergence input lacks EXPECTED-DIVERGE, EXPECTED-VEIR-FAIL, or EXPECTED-LLZK-FAIL marker)"
      FAIL=$((FAIL+1))
      FAILED_FILES+=("$t")
      continue
    fi
  fi

  target_args=("${DIFF_ARGS[@]}")
  if [[ "${LOWER_FIRST:-0}" == "1" || "$t" == *.llzk ]]; then
    target_args+=(--lower-first)
  fi

  "${DIFF}" "$t" "${target_args[@]}" >/dev/null 2>&1
  rc=$?
  case "$rc" in
    0)
      if [[ -n "$expected" ]]; then
        echo "UNEXPECTED-PASS: $t (declared ${expected}, got agreement — gap may be closed)"
        FAIL=$((FAIL+1))
        FAILED_FILES+=("$t")
      else
        echo "PASS: $t"
        PASS=$((PASS+1))
      fi
      ;;
    1)
      if [[ "$expected" == "EXPECTED-DIVERGE" ]]; then
        echo "EXPECTED-DIVERGE: $t"
        PASS=$((PASS+1))
      else
        echo "DIVERGE: $t"
        FAIL=$((FAIL+1))
        FAILED_FILES+=("$t")
        # Re-run with verbose to surface the diff inline. We rerun the whole
        # pipeline; on a large corpus consider extracting just the diff stage.
        VEIR_DIFF_VERBOSE=1 "${DIFF}" "$t" "${target_args[@]}" 2>&1 | sed 's/^/  /'
      fi
      ;;
    2)
      # ERROR — fail loud regardless of expected-divergence/. A broken
      # test is not a documented divergence.
      echo "ERROR: $t (llzk-diff.sh exit 2 — bad invocation or unreadable input)"
      FAIL=$((FAIL+1))
      FAILED_FILES+=("$t")
      VEIR_DIFF_VERBOSE=1 "${DIFF}" "$t" "${target_args[@]}" 2>&1 | sed 's/^/  /'
      ;;
    3|4)
      if [[ "$rc" == "3" ]]; then
        label="VEIR-FAIL"
      else
        label="LLZK-FAIL"
      fi
      if [[ "$expected" == "EXPECTED-${label}" ]]; then
        echo "EXPECTED-${label}: $t"
        PASS=$((PASS+1))
      else
        echo "${label}: $t"
        FAIL=$((FAIL+1))
        FAILED_FILES+=("$t")
        VEIR_DIFF_VERBOSE=1 "${DIFF}" "$t" "${target_args[@]}" 2>&1 | sed 's/^/  /'
      fi
      ;;
    77)
      echo "SKIP: $t (llzk-diff.sh exit 77 — required differential tool unavailable)"
      SKIP=$((SKIP+1))
      ;;
    *)
      # Any other exit code is unexpected. Treat as ERROR to be safe.
      echo "ERROR: $t (llzk-diff.sh exit $rc — unexpected)"
      FAIL=$((FAIL+1))
      FAILED_FILES+=("$t")
      VEIR_DIFF_VERBOSE=1 "${DIFF}" "$t" "${target_args[@]}" 2>&1 | sed 's/^/  /'
      ;;
  esac
done

echo
if (( SKIP > 0 || MODE_SKIP > 0 )); then
  echo "Summary: ${PASS} pass (incl. expected-diverge), ${FAIL} fail, ${SKIP} skip, ${MODE_SKIP} mode-skip (over ${#TARGETS[@]} inputs)"
else
  echo "Summary: ${PASS} pass (incl. expected-diverge), ${FAIL} fail (over ${#TARGETS[@]} inputs)"
fi

if (( PASS == 0 && FAIL == 0 && SKIP == 0 && MODE_SKIP > 0 )); then
  echo
  echo "ERROR: no inputs executed in the selected mode; rerun with --canonicalize or choose a parse/print corpus path."
  exit 2
fi

if (( SKIP > 0 )); then
  echo
  echo "ERROR: ${SKIP} input(s) skipped because required tools were unavailable; this is not acceptance evidence."
  exit 2
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
