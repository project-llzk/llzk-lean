# Strategy F — Folders-only replacement (future)

## Concrete picture

Replace `llzk-lib/lib/Dialect/Felt/IR/Ops.cpp:141-333` — the ~190 LoC
of switch-cases implementing all 18 Felt op folders — with code
*derived from* VEIR's verified Lean folds. Everything else in the
LLZK Felt dialect (TableGen declarations, type/attribute parsing,
Field registry, op verifiers) stays as upstream C++.

The replacement is produced either by Strategy B (Lean → C++
extraction) applied narrowly, or by Strategy E with the validation
scope narrowed to fold transformations (a per-fold cert validates that
LLZK's fold matches the Lean fold).

## Why call it out

This is the cheapest meaningful integration. The folders are exactly
what we've verified in Lean, and they're a self-contained ~190 LoC
unit in `Ops.cpp`. The TableGen-generated boilerplate (op classes,
verifier-shape skeleton, custom assembly format) doesn't carry
algorithmic content that would benefit from formal verification.

If Veridise asks "what's the smallest concrete artifact that
demonstrates the LLZK + Lean cooperation?", this is the answer.

## What it provides

- **Assurance**: every LLZK Felt fold is sound by a paired Lean
  theorem. Trusted base shrinks to whichever of Strategy B or E
  underpins the integration.
- **Functionality**: zero user-visible change. The folders behave
  exactly as before, just generated from verified Lean.

## Effort

**1-2 engineer-months**, contingent on:

- VEIR shipping a Field registry (so the Lean folds apply modular
  reduction; today they fold over `Int` without reduction).
- Strategy B's Lean → C++ extractor or Strategy E's certificate format
  being mature enough to cover the 18 fold transformations.

## Why not start here

Folders-only requires Veridise to take a PR replacing real code in
`llzk-lib/lib/Dialect/Felt/IR/Ops.cpp`. That's a stronger ask than
Strategy A (no PR) or Strategy E (PR a new flag). Start with A and E;
land F once those have demonstrated value.
