# Phase 6 Review Request

Repository: llzk-lean
Created: 2026-06-10

Review the Phase 6 Strategy A divergence burn-down bootstrap and first
implementation target.

Scope:

- Phase 6 is active and starts from the Phase 5 clean-pin exact-polarity corpus.
- Phase 5 findings are closed before Phase 6 implementation work starts.
- The bootstrap does not claim full Strategy A acceptance.
- The first implementation target reclassifies the DCE-only registered
  add/sub/mul constant-fold divergences through the clean VeIR pin
  `a0bb2fc8e6d38ab068247dfc6506ba63f5feb953`.
- The clean-pin canonical corpus remains `21 pass (incl. expected-diverge),
  0 fail` with 7 PASS cases, 13 `EXPECTED-DIVERGE` cases, and
  1 `EXPECTED-LLZK-FAIL` case.
