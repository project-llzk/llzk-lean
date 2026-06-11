# Phase 5 Findings

Repository: llzk-lean
Reviewed: 2026-06-10

## F5-LLZK-01: Differential wrapper returned success when every input skipped

Severity: high
Status: resolved

`differential/run-differential.sh` counted `llzk-diff.sh` exit 77 as `SKIP`,
but still returned exit 0 when no input failed. A missing `lake` or other
required tool could therefore produce `0 pass`, `0 fail`, and nonzero `skip`
while still looking like a successful wrapper invocation.

Resolution: the wrapper now exits non-zero whenever any input is skipped
because required tools are unavailable. SKIP remains visible in the summary,
but cannot be used as Phase 5 acceptance evidence.

## F5-LLZK-02: Clean-pinned differential driver could hang in `lake exec`

Severity: high
Status: resolved

The first clean-pin candidate, `3e936409c85a27b6d9695f5431d6ccb8a6d842fd`,
contained `--canonicalize` support but invoked `veir-opt` only through
`lake exec`. In the llzk-lean dependency checkout, the first canonical corpus
input did not finish within a 240-second bounded run, while the already-built
`.lake/packages/VeIR/.lake/build/bin/veir-opt` completed the same lowered input
immediately.

Resolution: VeIR commit `220cd215579b435c3c22ce86b34a3f4ce2ca276e` updates
`scripts/llzk-diff.sh` to prefer an existing `.lake/build/bin/veir-opt` and
fall back to `lake exec` only when the binary is absent. llzk-lean now pins
that commit, and the clean-pin canonical corpus evidence runs through the
default dependency driver without `VEIR_DIFF`.

## F5-LLZK-03: Phase 5 status docs still described corpus expansion as future seed work

Severity: medium
Status: resolved

After the clean-pin corpus was expanded to 21 inputs, `docs/harness/CURRENT.md`
still said corpus expansion beyond the seed set was the next Strategy A task,
and `differential/README.md` still described the corpus as a reviewed seed with
a "Current seed bar." Those claims contradicted the Phase 5 corpus evidence and
could mislead the next phase handoff even while freshness passed.

Resolution: `docs/harness/CURRENT.md`, `docs/harness/GATES.md`, and
`differential/README.md` now describe the clean-pin expanded corpus and the
15-pattern rewrite matrix without claiming full Strategy A acceptance.
`scripts/harness/check-doc-freshness.sh` now rejects the stale seed/future-work
phrases and requires the differential README to record the expanded corpus
status.

## F5-LLZK-04: Corpus docs omitted expected tool-failure polarity

Severity: low
Status: resolved

`differential/corpus/README.md` documented PASS/DIVERGE inversion under
`expected-divergence/`, but the wrapper and current corpus also support
`EXPECTED-LLZK-FAIL` and `EXPECTED-VEIR-FAIL`. Future parser/verifier-gap inputs
could therefore be documented as ordinary divergence even when one tool failed
before comparable output existed.

Resolution: the corpus README now documents expected LLZK/VEIR failure polarity,
and doc freshness requires both expected-failure labels to remain documented.

## F5-LLZK-05: Source evidence omitted stderr warning detail

Severity: low
Status: resolved

`reviews/PHASE-05/evidence/verify-llzk-source.txt` reported
`LLZK source verification summary: 0 fail, 1 warn`, but the warning text itself
was emitted on stderr and was not captured in the evidence file. The known stale
`../llzk-lib` worktree warning was documented elsewhere, but the evidence file
was not exact command output.

Resolution: Phase 5 source evidence is refreshed with stderr captured so the
warning detail appears alongside the pass/fail summary.

## F5-LLZK-06: Expected-divergence polarity accepted wrong failure modes

Severity: high
Status: resolved

`differential/run-differential.sh` treated every file under
`expected-divergence/` as allowed to pass on `DIVERGE`, `VEIR-FAIL`, or
`LLZK-FAIL`. That was too broad for canonical output-divergence tests: a
regression where `llzk-opt` or `veir-opt` stopped producing comparable output
would still count as accepted evidence instead of failing the corpus run.

Resolution: the wrapper now requires each expected-divergence file to declare
its exact accepted label in a header comment: `EXPECTED-DIVERGE`,
`EXPECTED-LLZK-FAIL`, or `EXPECTED-VEIR-FAIL`. The corpus docs and Strategy A
README document the stricter polarity, and `polarity-guard.txt` records a
forced wrong-mode failure returning nonzero.
