# llzk-lean documentation index

Strategy docs for the LLZK ↔ VEIR cooperation surface. Each strategy
covers: concrete architecture, trusted base it adds, what it provides
as **assurance** vs. **functionality**, effort estimate at Felt-only
and (where applicable) LLZK-wide scope, and dependence on Veridise /
LLZK maintainers.

## Initial (this scaffold's deliverables)

- [Strategy A — Verified-output oracle](strategy-a-oracle.md). The
  differential harness. Observational; non-disruptive to upstream.
- [Strategy E — Proof-certificate generator](strategy-e-certificates.md).
  Per-rewrite cert emission from Lean + structural validation in C++.
  Requires upstream PR.

## Documented future options

- [Strategy F — Folders-only replacement](future-f-folders-only.md).
  The narrowest possible C++ replacement: just the `Ops.cpp:141-333`
  fold switch-cases. Cheapest meaningful integration.
- [Strategy B — Lean → C++ extraction](future-b-extraction.md). Like
  Coq's extraction-to-OCaml, applied to the Lean → C++ direction.
- [Strategy D — Lean MLIR dialect plugin via FFI](future-d-ffi-plugin.md).
  LLZK loads a Lean `.so` as the dialect implementation.
- [Strategy C — Full replacement of `llzk-opt`](future-c-drop-in.md).
  `veir-opt` replaces `llzk-opt`. Multi-year scope; documented here
  for completeness rather than as an active plan.

## Picking among them

The trade-off space is laid out in the [top-level README](../README.md)'s
strategy table. Two questions drive the choice:

1. **What does "replace" mean to your stakeholders?** Strategy A
   provides behavioral evidence; E provides runtime certificates;
   F/B/D replace progressively more C++; C replaces the binary.
2. **What's the relationship with Veridise / LLZK maintainers?**
   Strategy A needs no cooperation. E/F/B/D need cooperation in
   increasing degrees. C only makes sense as a hostile fork or a
   funded multi-year program.
