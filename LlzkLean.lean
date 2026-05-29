-- llzk-lean library entry point.
--
-- This file just re-exports the namespaces that LLZK-Lean ships. The
-- actual content lives in submodules under `LlzkLean/`. The library is
-- intentionally small: most of the verified content (the 15 Felt
-- rewrites, the `ZMod p` semantic model, the parser/printer) lives in
-- the imported `Veir` library, not here.

import LlzkLean.Cert
-- Importing CertValidate causes `lake build` to run compile-time
-- assertions that each cert's `theoremName` resolves in VEIR. A
-- dangling theorem-name reference fails the build loudly here
-- rather than silently shipping a stale cert.
import LlzkLean.CertValidate
