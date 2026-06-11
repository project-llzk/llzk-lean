# Phase 3 Findings

Repository: llzk-lean
Reviewed: 2026-06-06

## P3-L1: Freshness gate accepted README-only Phase 3 evidence

- Severity: medium
- Evidence: `scripts/harness/check-doc-freshness.sh` required only
  `reviews/PHASE-03/evidence/README.md`, while the Phase 3 done criteria require
  fresh adversarial evidence.
- Status: fixed
- Disposition: `check-doc-freshness.sh` now requires nonempty Phase 3 evidence
  outputs for doc freshness, LLZK source truth, pin verification, strict doctor,
  skill validation, lake build, and adversarial review.

## P3-L2: Evidence README omitted declared closeout gates

- Severity: low
- Evidence: `reviews/PHASE-03/evidence/README.md` did not list strict doctor or
  skill-validation evidence even though those gates are part of the Phase 3
  acceptance path.
- Status: fixed
- Disposition: the README now lists every required bootstrap evidence file, and
  each file has been captured under `reviews/PHASE-03/evidence/`.

## P3-L3: Freshness checks allowed weak evidence and ledger false positives

- Severity: medium
- Evidence: the freshness gate required accepted operation mnemonics to appear,
  but did not require exactly 18 operation rows, did not reject duplicate rows,
  did not enforce that unsupported or incomplete Strategy A/E rows still ended
  as gaps, and treated arbitrary nonempty evidence files as sufficient.
- Status: fixed
- Disposition: `check-doc-freshness.sh` now requires exactly one row for each
  accepted Felt mnemonic, exactly 18 operation rows, explicit Strategy A/E
  coverage gaps for `sub`, `mul`, and `neg`, explicit missing consumed-VeIR
  semantic model plus `Gap` status for the 13 unmodeled operations, and expected
  success markers in the captured Phase 3 evidence files.
