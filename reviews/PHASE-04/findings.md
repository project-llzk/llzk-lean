# Phase 4 Findings

Repository: llzk-lean
Reviewed: 2026-06-09

## F4-LLZK-01: Canonical mode failed unclearly with the clean pinned VeIR script

Severity: low
Status: resolved

`differential/run-differential.sh --canonicalize ...` forwards
`--canonicalize` to the selected VeIR `scripts/llzk-diff.sh`. Before the VeIR
dependency pin is bumped, the default clean pinned script does not support that
flag. The wrapper previously discovered this only after invoking the selected
script per input, producing a generic `unknown flag: --canonicalize` failure.

Resolution: the wrapper now checks the selected diff script before expanding the
corpus and exits with an explicit instruction to use
`VEIR_DIFF=../veir/scripts/llzk-diff.sh` for Phase 4 workspace evidence or bump
the clean VeIR pin.

## F4-LLZK-02: Mode-skip-only runs returned success with zero executed inputs

Severity: low
Status: resolved

A parse/print invocation over only `expected-divergence/canonical/` inputs
returned exit 0 with `0 pass`, `0 fail`, and all inputs marked `MODE-SKIP`.
That is correct classification for each file, but it is a false green for the
invocation because no input executed in the selected mode.

Resolution: the wrapper now exits non-zero when every selected input is
mode-skipped, and the README files document that mode-skip-only runs are not
evidence.
