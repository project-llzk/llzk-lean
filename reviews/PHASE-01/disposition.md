# Phase 1 Disposition

Repository: llzk-lean

## P1-L1

Disposition: fixed

The dirty dependency diff and untracked file were preserved under
`reviews/PHASE-01/evidence/` before cleanup. `.lake/packages/VeIR` was then
reset to the accepted commit
`d52917ca4a57c4094b1aa61dd413aca4e1c2a56e`; post-transition evidence records a
clean checkout.

## P1-L2

Disposition: fixed

`lakefile.toml`, `lake-manifest.json`, and `.lake/packages/VeIR` now agree on
`d52917ca4a57c4094b1aa61dd413aca4e1c2a56e`. `scripts/harness/verify-pins.sh`
is the strict gate for this invariant.

## P1-L3

Disposition: fixed

`scripts/harness/verify-pins.sh` now verifies the VeIR `git` URL in
`lakefile.toml` and the VeIR `url` field in `lake-manifest.json` against
`https://github.com/project-llzk/veir.git`. The URL spoof adversarial probe is
recorded in `evidence/adversarial-url-spoof-after.txt` and exits non-zero as
expected.

## P1-L4

Disposition: fixed

`scripts/harness/verify-pins.sh` now verifies `lake-manifest.json` `inputRev`
against the accepted commit. The stale-`inputRev` adversarial probe is recorded
in `evidence/adversarial-inputrev-after.txt` and exits non-zero as expected.

## P1-L5

Disposition: fixed

`LlzkLean.CertValidate` now excludes shared rewrite tail helpers from the
catalog coverage scan, so the informational uncovered count matches the current
stub expectation under the accepted VeIR pin.

## P1-L6

Disposition: fixed

`docs/phases/PHASE-01-pins-and-repro.md` now records `Status: active`.

## Closure Rule

Phase 1 is closed only if the final evidence includes:

- `scripts/harness/verify-pins.sh --workspace-veir ../veir`
- `scripts/harness/doctor.sh --workspace-veir ../veir`
- `lake build`
- adversarial URL and `inputRev` spoof probes
- `scripts/harness/check-doc-freshness.sh`
- `scripts/harness/validate-skills.sh`
