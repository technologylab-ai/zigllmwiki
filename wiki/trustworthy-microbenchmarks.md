---
id: trustworthy-microbenchmarks
title: Trustworthy microbenchmarks
kind: workflow
status: source-verified
zig: "0.16.0"
summary: A benchmark needs runtime-variable inputs, an externally consumed correctness witness, explicit build mode, and one maintained test/build entry point before its timing means anything.
updated: 2026-09-04
sources:
  - "[[matklad-do-not-optimize-away]]"
  - "[[matklad-mechanical-habits]]"
  - "[[source-tigerstyle]]"
  - "[[tigerbeetle-performance]]"
proofs:
  - proofs/performance_sketch.zig
platforms:
  - cross-platform
---

# Trustworthy microbenchmarks

## Remember

A fast benchmark can be evidence that the compiler removed the work, folded
constant inputs, or that an optimization broke correctness. Timing alone is not
a result.

Every benchmark should expose:

- runtime-overridable input parameters, with named defaults;
- a result or digest that is consumed outside the timed computation;
- the expected witness for known parameters;
- optimization mode, target, Zig revision, machine, and iteration policy;
- the exact code revision and invocation needed to reproduce the run.

Runtime inputs prevent the optimizer from specializing the entire measurement
to compile-time constants. Consuming and reporting a digest prevents dead-code
elimination and makes wrong-answer optimizations visible. An opaque compiler
barrier may still be useful for a narrowly justified experiment, but it is not
a substitute for making the benchmark semantically observable.

## Keep one maintained program

Put the microbenchmark on the normal test/build path. In test mode it should run
a tiny deterministic workload and validate the witness. In benchmark mode it
should use optimized code, long-enough runtime parameters, and visible reporting.
One implementation with explicit mode-dependent parameters avoids a second
program that compiles only when someone remembers it.

Do not make pass/fail depend on wall-clock thresholds in ordinary CI. CI can
check compilation, the small workload, witness stability, and output schema;
dedicated runners can collect performance distributions and compare them under
controlled conditions.

## Evidence checklist

- Is setup excluded from the intended timed region without changing semantics?
- Can a user vary inputs without recompiling?
- Is every timed result consumed into a witness?
- Does the witness detect the likely classes of wrong optimization?
- Are warm-up, sample count, aggregation, and outlier policy recorded?
- Are CPU frequency, contention, allocator state, and I/O cache effects either
  controlled or explicitly part of the workload?
- Does the benchmark measure the proposed bottleneck rather than a cheaper
  surrogate?
- Is architecture-level arithmetic consistent with the measured result?

The harness in [[performance-sketches-and-batching]] now proves these mechanics
with Zig 0.16: runtime parameters, an untimed warm-up, separately reported
samples, a consumed digest, and deterministic CI witnesses. Its local timings
are deliberately not promoted to portable performance evidence.

Related: [[tigerstyle]], [[code-reading-and-mechanical-checks]],
[[static-allocation-and-constant-work]],
[[performance-sketches-and-batching]].
