# Phase 2 Preflight Findings

Repository: llzk-lean
Reviewed: 2026-06-06

## P2-L1 - Local llzk-lib checkout is stale relative to fetched origin/main

Severity: Critical

`../llzk-lib` local `main` is at
`30b0fa1eb77de154ff60c13fa88ef286d8b01c65`, while fetched `origin/main` is at
`db922857bc5a88a9107627ef6b36a8b5e57bc5c2`. Phase 2 must use an explicitly
selected source ref, not stale local files.

Disposition: fixed by `docs/harness/LLZK_SOURCE.md` and
`scripts/harness/verify-llzk-source.sh`, which read the accepted ref through
`git show` and warn when the worktree is stale.

## P2-L2 - Current LLZK source adds grumpkin and corrects bn128/bn254

Severity: Critical

Fetched `llzk-lib origin/main:lib/Util/Field.cpp` maps `bn128` and `bn254` to
the BN scalar field, adds `grumpkin` as a distinct built-in field, and keeps
`koalabear`. Any llzk-lean certificate or checker claim that omits this source
fact is stale.

Disposition: fixed by updating certificate/checker source claims and the
source gate.

## P2-L3 - Checker registry comments are not source-ledger backed

Severity: High

`checker/src/CertChecker.cpp` still carries TODO comments about a hardcoded
field registry. Phase 2 must make those comments and any future registry checks
match the accepted LLZK source ledger.

Disposition: fixed by updating `checker/src/CertChecker.cpp` comments and
checking the accepted built-ins in `scripts/harness/verify-llzk-source.sh`.

## P2-L4 - Phase 1 work is not committed in this workspace

Severity: Medium

Both `veir` and `llzk-lean` contain uncommitted Phase 1 implementation changes.
Phase 2 execution should either commit those changes first or explicitly carry
the dirty state as non-release local work.

Disposition: fixed by selecting VeIR commit
`d4cc1bf2d31beeca17eb2e8c9c7181d04af013a3`, updating Lake metadata, and
refreshing `.lake/packages/VeIR` to a clean checkout of that commit.

## P2-L5 - Accepted LLZK source remote is stale and ungated

Severity: High

`docs/harness/LLZK_SOURCE.md` recorded
`git@github.com:Veridise/llzk-lib.git`, but the checked and fetched source
repository uses `git@github.com:project-llzk/llzk-lib.git`. The source gate
checked only the commit and `origin/main`, so it could not catch a remote
provenance mismatch.

Disposition: fixed by recording
`git@github.com:project-llzk/llzk-lib.git` in the source ledger and requiring
that exact `origin` URL in `scripts/harness/verify-llzk-source.sh` and doc
freshness evidence.

## P2-L6 - Consumed VeIR field registry was not directly source-checked

Severity: Medium

The pin gate proved `.lake/packages/VeIR` was clean and at the accepted commit,
but the llzk-lean source gate did not directly check the consumed dependency's
`Veir/Passes/Felt/InterpModel.lean` field registry mirror against the accepted
LLZK source.

Disposition: fixed by making `scripts/harness/verify-llzk-source.sh` check the
pinned dependency HEAD and its exact `feltPrime` field-to-prime branches.

## P2-L7 - Source ledger files were listed but not all gated

Severity: Medium

The source ledger listed `OpInterfaces.td`, Felt lit tests, and unit tests, but
the source gate only checked a subset of paths and parsed only ops/types/field
registry facts deeply. That made the ledger broader than the mechanical gate.

Disposition: fixed by checking every ledgered source path at the accepted
commit and adding representative checks for Felt attrs, op interfaces, folder
source, lit tests, and unit tests.
