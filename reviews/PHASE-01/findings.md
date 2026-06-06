# Phase 1 Findings

Repository: llzk-lean

## P1-L1 - Dirty dependency state could masquerade as proof state

Severity: Critical

At bootstrap, `.lake/packages/VeIR` was at
`09d5f00f0d2b4a8710afbe53dfdd7cf468578a04` with modified
`Combine.lean`, modified `Proofs.lean`, and untracked `RewriteLemmas.lean`.
That meant proof-relevant state existed only in a local dependency checkout.

Evidence:

- `evidence/dependency-status-before.txt`
- `evidence/dependency-dirty-diff.txt`
- `evidence/verify-pins-before.txt`

Disposition: fixed in `reviews/PHASE-01/disposition.md`.

## P1-L2 - Lake metadata and dependency checkout needed a single accepted rev

Severity: High

`lakefile.toml` and `lake-manifest.json` previously pinned
`09d5f00f0d2b4a8710afbe53dfdd7cf468578a04`. Phase 1 requires both files and
`.lake/packages/VeIR` HEAD to identify the accepted VeIR commit
`d52917ca4a57c4094b1aa61dd413aca4e1c2a56e`.

Evidence:

- `evidence/lake-pin-diff.txt`
- `evidence/dependency-ref-after.txt`
- `evidence/verify-pins-after.txt`

Disposition: fixed in `reviews/PHASE-01/disposition.md`.

## P1-L3 - Accepted remote URL was documented but not enforced

Severity: High

The Phase 1 pin mode records `https://github.com/project-llzk/veir.git` as the
accepted source, but the first implementation only checked the commit rev. A
Lakefile and manifest pair using another URL could pass strict verification if
the dependency checkout was locally at the accepted commit.

Evidence:

- `evidence/adversarial-url-spoof-after.txt`

Disposition: fixed in `reviews/PHASE-01/disposition.md`.

## P1-L4 - Manifest inputRev was not checked

Severity: Medium

The first implementation checked `lake-manifest.json` `rev` but not
`inputRev`. A stale `inputRev` could make the manifest internally inconsistent
while strict verification still passed.

Evidence:

- `evidence/adversarial-inputrev-after.txt`

Disposition: fixed in `reviews/PHASE-01/disposition.md`.

## P1-L5 - Catalog coverage warning was stale under the accepted VeIR pin

Severity: Medium

The accepted VeIR pin exposed shared rewrite helper tails in `Veir.FeltPass`,
and `LlzkLean.CertValidate` counted them as rewrite patterns. The build
therefore reported 18 pattern defs and 16 uncovered while still saying
"expected 13 today".

Evidence:

- `evidence/lake-build.txt`

Disposition: fixed in `reviews/PHASE-01/disposition.md`.

## P1-L6 - Phase file status lagged the active harness state

Severity: Low

`docs/phases/PHASE-01-pins-and-repro.md` still said `Status: bootstrap` after
the harness docs marked Phase 1 active.

Disposition: fixed in `reviews/PHASE-01/disposition.md`.

## Open Findings

No open Critical or High findings remain for Phase 1 pin reproducibility.
