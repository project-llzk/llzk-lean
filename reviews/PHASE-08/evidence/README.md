# Phase 8 Evidence

Repository: llzk-lean
Updated: 2026-06-10

This directory records Phase 8 implementation evidence. Phase 8 starts from the
Phase 7 clean-pin corpus baseline and consumes the VeIR field-precondition pin
that reclassifies `unspecified_add_fold.llzk` as a positive no-fold case.

Expected evidence:

- `check-doc-freshness.txt`
- `verify-llzk-source.txt`
- `verify-pins.txt`
- `doctor-workspace.txt`
- `validate-skills.txt`
- `lake-build.txt`
- `cert-smoke.txt`
- `differential-clean-pin-canonicalize.txt`
- `adversarial-review.txt`

The differential evidence must record the exact `env -u VEIR_DIFF -u VEIR_OPT`
clean-pin command and the `CLEAN-VEIR-OPT` marker emitted after refreshing the
pinned dependency executable.
