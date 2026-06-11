#!/usr/bin/env bash

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="${CHECKER_BUILD_DIR:-${ROOT}/checker/build}"
CERT="${1:-${ROOT}/certs/felt-combine.cert.json}"

if [[ ! -r "$CERT" ]]; then
  echo "CERT-SMOKE: cert snapshot is not readable: ${CERT}" >&2
  exit 2
fi

TMPDIR_LOCAL="$(mktemp -d -t llzk-lean-cert-smoke-XXXXXX)"
cleanup() {
  rm -rf "$TMPDIR_LOCAL"
}
trap cleanup EXIT

loader="${BUILD_DIR}/test_loader"
driver="${BUILD_DIR}/llzk-lean-check"
build_mode=""

if command -v cmake >/dev/null 2>&1 && command -v ctest >/dev/null 2>&1; then
  if ! cmake -S "${ROOT}/checker" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Debug >"${TMPDIR_LOCAL}/configure.log" 2>&1; then
    cat "${TMPDIR_LOCAL}/configure.log" >&2
    echo "CERT-SMOKE: cmake configure failed" >&2
    exit 2
  fi

  if ! cmake --build "$BUILD_DIR" >"${TMPDIR_LOCAL}/build.log" 2>&1; then
    cat "${TMPDIR_LOCAL}/build.log" >&2
    echo "CERT-SMOKE: checker build failed" >&2
    exit 2
  fi

  if ! ctest --test-dir "$BUILD_DIR" --output-on-failure >"${TMPDIR_LOCAL}/ctest.log" 2>&1; then
    cat "${TMPDIR_LOCAL}/ctest.log" >&2
    echo "CERT-SMOKE: schema/loader tests failed" >&2
    exit 1
  fi
  echo "CERT-SMOKE: ctest schema/loader tests passed"
  build_mode="cmake"
elif command -v g++ >/dev/null 2>&1; then
  src_build="${TMPDIR_LOCAL}/source-build"
  mkdir -p "$src_build"
  common_sources=(
    "${ROOT}/checker/src/JsonParser.cpp"
    "${ROOT}/checker/src/OperandPath.cpp"
    "${ROOT}/checker/src/CertChecker.cpp"
  )
  if ! g++ -std=c++17 -I"${ROOT}/checker/src" \
      "${common_sources[@]}" "${ROOT}/checker/tests/test_loader.cpp" \
      -o "${src_build}/test_loader" >"${TMPDIR_LOCAL}/gxx-loader.log" 2>&1; then
    cat "${TMPDIR_LOCAL}/gxx-loader.log" >&2
    echo "CERT-SMOKE: g++ loader build failed" >&2
    exit 2
  fi
  if ! g++ -std=c++17 -I"${ROOT}/checker/src" \
      "${common_sources[@]}" "${ROOT}/checker/bin/llzk_lean_check.cpp" \
      -o "${src_build}/llzk-lean-check" >"${TMPDIR_LOCAL}/gxx-driver.log" 2>&1; then
    cat "${TMPDIR_LOCAL}/gxx-driver.log" >&2
    echo "CERT-SMOKE: g++ driver build failed" >&2
    exit 2
  fi
  loader="${src_build}/test_loader"
  driver="${src_build}/llzk-lean-check"
  echo "CERT-SMOKE: cmake/ctest unavailable; built checker from source with g++"
  if ! "$loader" "$CERT" >"${TMPDIR_LOCAL}/loader.log" 2>&1; then
    cat "${TMPDIR_LOCAL}/loader.log" >&2
    echo "CERT-SMOKE: g++ loader tests failed" >&2
    exit 1
  fi
  echo "CERT-SMOKE: g++ schema/loader tests passed"
  build_mode="g++"
elif [[ "${CERT_SMOKE_ALLOW_PREBUILT:-0}" == "1" && -x "$loader" && -x "$driver" ]]; then
  echo "CERT-SMOKE: using prebuilt checker binaries because CERT_SMOKE_ALLOW_PREBUILT=1"
  if ! "$loader" "$CERT" >"${TMPDIR_LOCAL}/loader.log" 2>&1; then
    cat "${TMPDIR_LOCAL}/loader.log" >&2
    echo "CERT-SMOKE: prebuilt loader tests failed" >&2
    exit 1
  fi
  echo "CERT-SMOKE: prebuilt schema/loader tests passed"
  build_mode="prebuilt"
else
  echo "TOOL-MISSING: cmake/ctest and g++ unavailable" >&2
  echo "Set CERT_SMOKE_ALLOW_PREBUILT=1 to use existing checker/build binaries as non-source-build evidence." >&2
  exit 77
fi

pattern_count="$(grep -c '"patternId"' "$CERT" || true)"
theorem_count="$(grep -c '"theoremName"' "$CERT" || true)"
if [[ "$pattern_count" -gt 0 && "$pattern_count" -eq "$theorem_count" ]]; then
  echo "CERT-SMOKE: theorem metadata present for ${theorem_count}/${pattern_count} certs"
else
  echo "CERT-SMOKE: theorem metadata mismatch (${theorem_count}/${pattern_count})" >&2
  exit 1
fi

if [[ -x "$driver" ]]; then
  if ! "$driver" --cert "$CERT" >"${TMPDIR_LOCAL}/driver.log" 2>&1; then
    cat "${TMPDIR_LOCAL}/driver.log" >&2
    echo "CERT-SMOKE: driver cert summary failed" >&2
    exit 1
  fi
  echo "CERT-SMOKE: driver cert summary passed"
else
  echo "CERT-SMOKE: driver executable missing after build" >&2
  exit 2
fi

if grep -q 'TODO(W4B follow-up)' "${ROOT}/checker/src/CertChecker.cpp"; then
  echo "CERT-SMOKE: MLIR matcher absent; DefaultMatcher still has W4B TODOs"
elif [[ "$build_mode" == "cmake" ]] && grep -q 'MLIR found' "${TMPDIR_LOCAL}/configure.log"; then
  echo "CERT-SMOKE: MLIR matcher configured active"
else
  echo "CERT-SMOKE: MLIR matcher absent in ${build_mode} smoke mode"
fi

echo "CERT-SMOKE: schema validation passed"
exit 0
