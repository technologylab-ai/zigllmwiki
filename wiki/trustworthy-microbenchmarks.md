---
id: trustworthy-microbenchmarks
title: Trustworthy microbenchmarks
kind: pattern
status: source-verified
zig: "0.16.0"
summary: A benchmark needs runtime-variable inputs, an externally consumed correctness witness, explicit build mode, and one maintained test/build entry point before its timing means anything.
updated: 2026-09-05
sources:
  - "[[matklad-do-not-optimize-away]]"
  - "[[matklad-mechanical-habits]]"
  - "[[source-tigerstyle]]"
  - "[[tigerbeetle-performance]]"
  - "[[techempower-r23-comparison-inputs]]"
  - "[[zig-http-plaintext-comparison-2026-09-05]]"
  - "[[zig-http-response-batching-2026-09-05]]"
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

## HTTP comparison lesson

[[bounded-http-server-design]] now has a repeated native Linux comparison of
pinned plaintext leaders and the unchanged ReleaseSafe MVP. Preserve callback,
resource-policy, toolchain, client-CPU and wire differences alongside rates;
shared hardware alone does not equate contracts. Its two/four-client-thread
sweeps expose sensitivity; they do not establish unconstrained capacity.
[[zig-http-plaintext-comparison-2026-09-05]]

wrk 4.2.0 counts completed responses directly, but timestamps pipeline-batch
completion and corrects the histogram. The pinned correction can add samples
below an unchanged minimum, yielding impossible zero percentiles. A load tool's
plausible throughput does not validate its latency distribution. Retain raw
values, identify the source defect, and withhold tail claims until independently
qualified. [[techempower-r23-comparison-inputs]]

The HTTP batch experiments separate client pipeline depth, server batch cap
and actual parallelism. Deeper pipelines (32/64/128) keep the server cap at 16;
exact preflight depth and distinct-body wire tests prevent a throughput counter
from hiding ordering or buffer reuse mistakes. A repeated control varied even
with an unchanged binary. Preserve that uncertainty and compare revisions in
the same controlled sweep; sequential groups can still confound time and code.
[[zig-http-response-batching-2026-09-05]]

Related: [[tigerstyle]], [[code-reading-and-mechanical-checks]],
[[static-allocation-and-constant-work]],
[[performance-sketches-and-batching]],
[[build-diagnostics-and-generated-code]].
