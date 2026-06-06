#!/usr/bin/env bash

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODE="strict"
WORKSPACE_VEIR=""

ACCEPTED_VEIR_COMMIT="d4cc1bf2d31beeca17eb2e8c9c7181d04af013a3"
ACCEPTED_VEIR_SHORT="${ACCEPTED_VEIR_COMMIT:0:12}"
ACCEPTED_VEIR_REMOTE="https://github.com/project-llzk/veir.git"
ACCEPTED_VEIR_BRANCH="felt-review-structural-close"

FAIL=0
WARN=0

usage() {
  cat <<'USAGE'
usage: scripts/harness/verify-pins.sh [--mode strict|exploratory] [--workspace-veir PATH]

Verifies that lakefile.toml, lake-manifest.json, and .lake/packages/VeIR all
identify the accepted VeIR commit, and that the dependency checkout is clean.
Exploratory mode only downgrades an optional workspace VeIR mismatch.
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

extract_lakefile_field() {
  local field="$1"
  awk -v wanted="$field" '
    function emit() {
      if (wanted == "rev") print rev
      else if (wanted == "git") print git
      else exit 1
    }
    /^\[\[require\]\]/ {
      if (in_req && name == "VeIR") { emit(); found = 1; exit }
      in_req = 1; name = ""; rev = ""; git = ""; next
    }
    /^\[\[/ {
      if (in_req && name == "VeIR") { emit(); found = 1; exit }
      in_req = 0
    }
    in_req && /^[[:space:]]*name[[:space:]]*=/ {
      line = $0; sub(/^[^"]*"/, "", line); sub(/".*/, "", line); name = line
    }
    in_req && /^[[:space:]]*git[[:space:]]*=/ {
      line = $0; sub(/^[^"]*"/, "", line); sub(/".*/, "", line); git = line
    }
    in_req && /^[[:space:]]*rev[[:space:]]*=/ {
      line = $0; sub(/^[^"]*"/, "", line); sub(/".*/, "", line); rev = line
    }
    END { if (!found && in_req && name == "VeIR") emit() }
  ' "${ROOT}/lakefile.toml"
}

extract_manifest_field() {
  local field="$1"
  awk -v wanted="$field" '
    function json_value(line, key, value) {
      value = line
      sub(".*\"" key "\"[[:space:]]*:[[:space:]]*\"", "", value)
      sub("\".*", "", value)
      return value
    }
    function emit() {
      if (wanted == "url") print url
      else if (wanted == "type") print type
      else if (wanted == "rev") print rev
      else if (wanted == "inputRev") print inputRev
      else exit 1
    }
    /"packages"[[:space:]]*:/ { in_packages = 1 }
    in_packages && /\{/ { in_obj = 1; name = ""; url = ""; type = ""; rev = ""; inputRev = "" }
    in_obj && /"url"[[:space:]]*:/ { url = json_value($0, "url") }
    in_obj && /"type"[[:space:]]*:/ { type = json_value($0, "type") }
    in_obj && /"rev"[[:space:]]*:/ { rev = json_value($0, "rev") }
    in_obj && /"inputRev"[[:space:]]*:/ { inputRev = json_value($0, "inputRev") }
    in_obj && /"name"[[:space:]]*:/ {
      name = json_value($0, "name")
    }
    in_obj && /\}/ {
      if (name == "VeIR") { emit(); found = 1; exit }
      in_obj = 0
    }
    END { if (!found) exit 1 }
  ' "${ROOT}/lake-manifest.json"
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

echo "accepted VeIR pin: ${ACCEPTED_VEIR_COMMIT}"
echo "accepted VeIR source: ${ACCEPTED_VEIR_REMOTE} ${ACCEPTED_VEIR_BRANCH}"

lakefile_url="$(extract_lakefile_field git 2>/dev/null || true)"
lakefile_rev="$(extract_lakefile_field rev 2>/dev/null || true)"
manifest_url="$(extract_manifest_field url 2>/dev/null || true)"
manifest_type="$(extract_manifest_field type 2>/dev/null || true)"
manifest_rev="$(extract_manifest_field rev 2>/dev/null || true)"
manifest_input_rev="$(extract_manifest_field inputRev 2>/dev/null || true)"

if [[ "$lakefile_url" == "$ACCEPTED_VEIR_REMOTE" ]]; then
  ok "lakefile.toml uses accepted VeIR remote ${ACCEPTED_VEIR_REMOTE}"
else
  fail "lakefile.toml VeIR git URL ${lakefile_url:-<none>} does not match ${ACCEPTED_VEIR_REMOTE}"
fi

if [[ "$lakefile_rev" == "$ACCEPTED_VEIR_COMMIT" ]]; then
  ok "lakefile.toml pins VeIR ${ACCEPTED_VEIR_SHORT}"
else
  fail "lakefile.toml VeIR rev ${lakefile_rev:-<none>} does not match ${ACCEPTED_VEIR_COMMIT}"
fi

if [[ "$manifest_rev" == "$ACCEPTED_VEIR_COMMIT" ]]; then
  ok "lake-manifest.json pins VeIR ${ACCEPTED_VEIR_SHORT}"
else
  fail "lake-manifest.json VeIR rev ${manifest_rev:-<none>} does not match ${ACCEPTED_VEIR_COMMIT}"
fi

if [[ "$manifest_input_rev" == "$ACCEPTED_VEIR_COMMIT" ]]; then
  ok "lake-manifest.json inputRev pins VeIR ${ACCEPTED_VEIR_SHORT}"
else
  fail "lake-manifest.json VeIR inputRev ${manifest_input_rev:-<none>} does not match ${ACCEPTED_VEIR_COMMIT}"
fi

if [[ "$manifest_url" == "$ACCEPTED_VEIR_REMOTE" ]]; then
  ok "lake-manifest.json uses accepted VeIR remote ${ACCEPTED_VEIR_REMOTE}"
else
  fail "lake-manifest.json VeIR URL ${manifest_url:-<none>} does not match ${ACCEPTED_VEIR_REMOTE}"
fi

if [[ "$manifest_type" == "git" ]]; then
  ok "lake-manifest.json records VeIR as a git dependency"
else
  fail "lake-manifest.json VeIR type ${manifest_type:-<none>} is not git"
fi

if [[ -n "$lakefile_rev" && -n "$manifest_rev" && "$lakefile_rev" == "$manifest_rev" ]]; then
  ok "Lake files agree on VeIR ${lakefile_rev:0:12}"
else
  fail "Lake files disagree on VeIR rev: lakefile=${lakefile_rev:-<none>} manifest=${manifest_rev:-<none>}"
fi

dep="${ROOT}/.lake/packages/VeIR"
if [[ -d "$dep/.git" ]]; then
  dep_head="$(git -C "$dep" rev-parse HEAD 2>/dev/null || true)"
  if [[ "$dep_head" == "$ACCEPTED_VEIR_COMMIT" ]]; then
    ok "dependency checkout HEAD is ${ACCEPTED_VEIR_SHORT}"
  else
    fail "dependency checkout HEAD ${dep_head:-<none>} does not match ${ACCEPTED_VEIR_COMMIT}"
  fi

  if [[ -n "$manifest_rev" && "$dep_head" == "$manifest_rev" ]]; then
    ok "dependency checkout HEAD equals manifest rev"
  else
    fail "dependency checkout HEAD does not equal manifest rev ${manifest_rev:-<none>}"
  fi

  dep_status="$(git -C "$dep" status --short 2>/dev/null || true)"
  if [[ -z "$dep_status" ]]; then
    ok "dependency checkout is clean"
  else
    fail "dependency checkout is dirty:"
    printf '%s\n' "$dep_status" >&2
  fi
else
  fail "dependency checkout missing at ${dep}"
fi

if [[ -n "$WORKSPACE_VEIR" ]]; then
  workspace="$(cd "$ROOT" && cd "$WORKSPACE_VEIR" 2>/dev/null && pwd || true)"
  if [[ -z "$workspace" ]]; then
    fail "workspace VeIR path is not readable: ${WORKSPACE_VEIR}"
  else
    workspace_head="$(git -C "$workspace" rev-parse HEAD 2>/dev/null || true)"
    if [[ "$workspace_head" == "$ACCEPTED_VEIR_COMMIT" ]]; then
      ok "workspace VeIR HEAD equals accepted pin ${ACCEPTED_VEIR_SHORT}"
    elif git -C "$workspace" merge-base --is-ancestor "$ACCEPTED_VEIR_COMMIT" HEAD 2>/dev/null; then
      warn "workspace VeIR HEAD ${workspace_head:-<none>} is a descendant of accepted pin ${ACCEPTED_VEIR_COMMIT}; dependency checkout remains the source of truth"
    elif [[ "$MODE" == "exploratory" ]]; then
      warn "workspace VeIR HEAD ${workspace_head:-<none>} differs from accepted pin ${ACCEPTED_VEIR_COMMIT}; exploratory layout only"
    else
      fail "workspace VeIR HEAD ${workspace_head:-<none>} differs from accepted pin ${ACCEPTED_VEIR_COMMIT}"
  fi
fi
else
  warn "workspace VeIR repo was not checked; pass --workspace-veir PATH when recording acceptance evidence"
fi

echo
echo "pin verification summary: ${FAIL} fail, ${WARN} warn, mode=${MODE}"
if [[ "$FAIL" -ne 0 ]]; then
  exit 1
fi
exit 0
