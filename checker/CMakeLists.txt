# Standalone build for the certificate checker. The real integration
# target is `llzk-lib/lib/Pass/` (after the LLZKVerifyRewritesPass PR
# lands); this CMakeLists is for review, unit testing, and the
# eventual standalone `llzk-lean-check` driver (W4B).

cmake_minimum_required(VERSION 3.20)
project(llzk_lean_cert_checker CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# MLIR headers are required for the eventual real implementation of
# pattern matching against mlir::Operation (W4B). The cert loader +
# JSON parser don't need them, so the standalone build (no MLIR)
# compiles and exercises the loader's full surface. The pattern
# matcher remains fail-closed without MLIR; with MLIR available, the
# real implementation runs (gated by LLZK_HAVE_MLIR).
find_package(MLIR CONFIG QUIET)
if(MLIR_FOUND)
  message(STATUS "MLIR found at ${MLIR_DIR}; pattern matcher will be live")
  include_directories(SYSTEM ${MLIR_INCLUDE_DIRS})
else()
  message(STATUS "MLIR not found; pattern matcher remains fail-closed (W4B).")
  message(STATUS "Cert loader / JSON parser tests run regardless.")
endif()

# --- core library ----------------------------------------------------------
#
# JsonParser is split into its own translation unit because:
#   1. It's a candidate for a future shared library if the cert
#      format gains other consumers (e.g., a Python binding).
#   2. The test driver exercises both the parser and the schema
#      loader; keeping them as separate components makes the tests'
#      coverage easier to attribute.

add_library(llzk_lean_cert_checker STATIC
  src/JsonParser.cpp
  src/OperandPath.cpp
  src/CertChecker.cpp
)
target_include_directories(llzk_lean_cert_checker PUBLIC src)
if(MLIR_FOUND)
  target_compile_definitions(llzk_lean_cert_checker PUBLIC LLZK_HAVE_MLIR=1)
endif()

# --- pass skeleton (W4B target host) ---------------------------------------

add_library(llzk_lean_verify_rewrites_pass OBJECT
  src/VerifyRewritesPass.cpp
)
target_link_libraries(llzk_lean_verify_rewrites_pass PUBLIC llzk_lean_cert_checker)

# --- standalone driver -----------------------------------------------------
#
# `llzk-lean-check --cert <path>` loads a cert file and prints a
# summary. With --mlir <path> + a build that includes MLIR, runs the
# checker against an MLIR input (today: plumbing only, since W4B's
# matcher body lands incrementally).

add_executable(llzk-lean-check bin/llzk_lean_check.cpp)
target_link_libraries(llzk-lean-check PRIVATE llzk_lean_cert_checker)

# --- tests -----------------------------------------------------------------
#
# The loader smoke test runs without MLIR (the cert loader doesn't
# touch mlir::Operation). It needs the path to the committed cert
# snapshot at runtime; CMake passes it via the test command.

enable_testing()

add_executable(test_loader tests/test_loader.cpp)
target_link_libraries(test_loader PRIVATE llzk_lean_cert_checker)

# Locate the committed cert snapshot relative to this CMakeLists.txt.
set(LLZK_LEAN_CERT_SNAPSHOT
    "${CMAKE_CURRENT_SOURCE_DIR}/../certs/felt-combine.cert.json"
    CACHE FILEPATH "Path to the committed cert snapshot for tests")

add_test(NAME loader_smoke_tests
         COMMAND test_loader "${LLZK_LEAN_CERT_SNAPSHOT}")

# Driver smoke test: load the committed snapshot, print summary,
# verify exit code 0. Adds independent coverage of the bin/
# executable on top of the library-level tests above.
add_test(NAME driver_cert_summary
         COMMAND llzk-lean-check --cert "${LLZK_LEAN_CERT_SNAPSHOT}")
