---
id: build-diagnostics-and-generated-code
title: Build diagnostics and generated-code inspection
kind: pattern
status: source-verified
zig: "0.16.0"
summary: Zig 0.16 has no general strict-warning level for Zig source, so enforce all compile errors, safety-aware build modes, explicit foreign-source warnings, repository lint, and reproducible emitted-code review.
updated: 2026-09-04
sources:
  - "[[source-tigerstyle]]"
  - "[[zig-0.16.0-build-diagnostics]]"
  - "[[zig-0.16.0-language-reference]]"
  - "[[zig-0.16.0-stdlib]]"
proofs:
  - proofs/error_path_catalog.zig
platforms:
  - cross-platform
---

# Build diagnostics and generated-code inspection

## Remember

Do not translate “strictest compiler warnings” into a fictional Zig flag. The
Zig 0.16 frontend does not expose a general `-Wall`/`-Wextra` warning-level
switch for Zig source. Its rejected language conditions are compile errors.

The applied rule is broader: make every available diagnostic and safety layer
deliberate, never discard a failure, compile every maintained target and mode,
and supplement the compiler with project checks for policies it cannot know.

## What Zig 0.16 guarantees and exposes

The exact 0.16 compiler help and build source establish these separate knobs:

| Mechanism | Exact applicability |
| --- | --- |
| `Debug` | Optimizations off and runtime safety on by default. |
| `ReleaseSafe` | Optimizations on and runtime safety on by default. |
| `ReleaseFast`, `ReleaseSmall` | Runtime safety off by default; choosing them is a design decision, not merely a warning setting. |
| Reference traces | Add call-site context to compile errors; they do not enable new warning classes. |
| Error tracing | Adds runtime error-return trace information; it is not compiler strictness. |
| Stack checking/protection, C sanitizer, thread sanitizer, Valgrind integration | Independent build controls with target, mode, and workload limits. |
| C-family source flags | Explicit per-file or file-set flags accepted by `addCSourceFile(s)`; select supported warnings for that frontend and target. |
| `zig fmt --check` and repository lint | Mechanical project policy, separate from language diagnostics. |

For a safety-oriented service, test `Debug` and `ReleaseSafe`; do not let a
Debug-only test suite stand in for the optimized safety-on artifact. If a
release path uses safety-off code or `@setRuntimeSafety(false)`, isolate it,
inspect its generated code, prove its preconditions, and record a bounded
exception under [[design-revision-and-exception-policy]].

For C, C++, Objective-C, assembly, resource files, linkers, and code generators,
“strictest” is tool-specific. Pass an explicit reviewed flag set, normally
including warnings-as-errors for first-party C-family code, and record necessary
third-party suppressions beside the dependency boundary. Do not copy one
frontend's flags to every target and call the result portable.

## Project strictness profile

A reviewable project profile names:

1. exact Zig version and every supported target;
2. `Debug`, `ReleaseSafe`, and any shipped safety-off modes;
3. proof, integration, cross-target, and platform-runtime matrices;
4. explicit foreign-language warning/sanitizer flags;
5. formatting, line/function limits, forbidden APIs, generated-file drift, and
   dependency checks;
6. diagnostic suppression or safety-off exceptions with owners;
7. one command that fails when any required layer fails.

This wiki's command is `zig build verify`. The compiler does not enforce
TigerStyle's 70-line functions, 100 columns, assertion density, resource limits,
or dependency policy; those need review, tests, and deterministic repository
checks.

## Generated-code inspection workflow

Inspect machine-code intent only after correctness tests pass:

1. Select one stand-alone hot function with primitive or narrow domain inputs.
2. Pin Zig version, source revision and hash, target, CPU features, optimization
   mode, and safety mode.
3. Emit assembly with `-femit-asm` or `Compile.getEmittedAsm()`.
4. Locate the intended symbol and inspect calls, branches, loads/stores, bounds
   checks, vectorization, code size, and repeated computations.
5. Relate each observation to the performance sketch; change source only when
   the observation matters at expected frequency.
6. Rerun correctness witnesses and measurements after the change.
7. Preserve a report or focused diff for the exact environment, not a universal
   “optimized” claim.

`tools/inspect_generated_code.py` performs steps two and three for a single
source: it verifies the compiler against `.zig-version`, emits assembly, checks
that the requested symbol is present, and reports source and assembly SHA-256
values as JSON. The [inspection subject](../proofs/error_path_catalog.zig)
exports `bounded_sum_u32` so the workflow has a stable focused symbol.

An assembly hash is a change detector, not an acceptance test. Different
targets, CPU feature sets, compiler builds, optimization modes, or safety modes
may legitimately differ. Cross-target emitted assembly is not runtime evidence.

## What commonly goes wrong

- Inventing a Zig warnings flag and declaring the compiler “strict.”
- Shipping `ReleaseFast` after testing only safety-enabled code without an
  explicit safety-off review.
- Treating reference traces or error traces as additional static checks.
- Silencing third-party warnings globally, including first-party code.
- Snapshot-testing all assembly text and creating permanent noise from harmless
  register allocation changes.
- Reading attractive vector instructions while failing to consume and validate
  the function's result in a benchmark.

## Evidence boundary

[[zig-0.16.0-build-diagnostics]] pins the exact compiler/build interfaces.
[[source-tigerstyle]] supplies the strict-diagnostics and explicit-machine-code
principles. The generated-code workflow is inspection evidence only; executable
behavior remains the responsibility of registered proofs and runtime tests.

Related: [[trustworthy-microbenchmarks]],
[[performance-sketches-and-batching]], [[code-reading-and-mechanical-checks]],
[[lower-dimensional-api-contracts]], [[tigerstyle-coverage]].
