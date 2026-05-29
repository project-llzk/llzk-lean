# Strategy C — Full replacement of llzk-opt (future, dialect-narrow does not apply)

## Concrete picture

End-to-end replacement. Users run `veir-opt` instead of `llzk-opt`.
Downstream tools (R1CS / SMT / ZKLean / PCL backends) consume
`veir-opt`'s output. The C API and Python bindings expose VEIR symbols.
Veridise's docs change to point at VEIR.

## Trusted base

Lean kernel + Mathlib + every production-path Lean module. Largest TCB
of any option, by far.

## Assurance

Self-contained verified compiler middle-end. Backends remain C++
(unverified) unless those are also reimplemented in Lean.

## Functionality

Everything LLZK does, but in Lean. Independent of LLZK going forward.

## Cost

**LLZK-wide**: 30-60+ engineer-months. The line items:

1. MLIR pass-manager port (~4-6 months).
2. Custom assembly format for every ported dialect (~2-3 weeks).
3. C API rewrite (~3-4 months across all dialects).
4. Python bindings (~2 months).
5. Reimplement R1CS, SMT, ZKLean, PCL backends — or define an
   MLIR-text exchange format the existing C++ backends parse (~3-4
   months each backend, conservatively, without verification).

**Felt-only**: doesn't apply at the dialect level. You can't binary-
replace one dialect — the surrounding tool wants the dialect's C++
headers. The dialect-narrow equivalent of "replacement" is Strategy D
or B applied to that dialect.

## Why this is documented, not pursued

Only makes sense in two strategic scenarios:

1. **Hostile fork**: Veridise stops maintaining LLZK and we keep it
   alive. (No evidence this is on the table.)
2. **Multi-year engineering investment** with the explicit goal of
   making Lean the source of truth for LLZK. (Would need funded
   commitment from project-llzk leadership.)

The maintenance treadmill (Veridise touches `llzk-lib`, our fork goes
stale) is a larger failure mode than the technical scope. Even after
the 30-60 month investment, `veir-opt` only matches a frozen LLZK
release; tracking upstream forward is an ongoing tax.

Strategy A and Strategy E together achieve most of the assurance
benefit at a fraction of the cost. Strategy C is here for
completeness, not to be pursued.
