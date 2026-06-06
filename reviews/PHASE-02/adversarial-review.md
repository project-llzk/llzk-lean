# Phase 2 Preflight Adversarial Review

Repository: llzk-lean
Reviewed: 2026-06-06

## Checks Run

- Phase 1 pin verification passed against `../veir`.
- Strict Phase 1 doctor passed.
- `lake build` succeeded against the clean accepted VeIR pin.
- `../llzk-lib` refs were inspected with `git rev-parse HEAD origin/main`.
- `../llzk-lib` local `main` resolves to
  `30b0fa1eb77de154ff60c13fa88ef286d8b01c65`.
- Fetched `../llzk-lib origin/main` resolves to
  `db922857bc5a88a9107627ef6b36a8b5e57bc5c2`.
- Fetched `origin/main` Felt source was inspected through `git show`.

## Result

The llzk-lean pin state is reproducible, but Phase 2 must establish a fresh
LLZK Felt source ledger at `db922857bc5a88a9107627ef6b36a8b5e57bc5c2` before
certificate, checker, or Strategy A/E source claims can be trusted.

## Fresh Review After Phase 2 Edits

Reviewed: 2026-06-06

### Findings

- The first source gate checked the accepted LLZK source and the checker comment
  block, but it did not verify the Strategy A source claim, the Lean certificate
  catalog, or the committed JSON snapshot that carry the Phase 2
  `constant_fold_add` assumptions.
- llzk-lean could not claim it consumed the Phase 2 VeIR registry update while
  Lake still pinned the Phase 1 VeIR commit.

### Disposition

- Fixed the source gate by checking the Strategy A field-list claim, checker
  registry comments, source ledger field list, Lean `constant_fold_add`
  side-conditions, and committed JSON side-conditions.
- Fixed pin propagation by selecting
  `d4cc1bf2d31beeca17eb2e8c9c7181d04af013a3`, updating Lake metadata, and
  refreshing `.lake/packages/VeIR` to a clean checkout of that commit.
