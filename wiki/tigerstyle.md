---
id: tigerstyle
title: TigerStyle for Zig systems software
kind: principle
status: draft
zig: "0.16.0"
summary: Apply TigerStyle as linked constraints on safety, performance, and developer experience rather than as isolated slogans.
updated: 2026-09-04
sources:
  - "[[source-tigerstyle]]"
  - "[[matklad-push-ifs-up-fors-down]]"
  - "[[matklad-static-allocation-constant-work]]"
  - "[[tigerbeetle-architecture]]"
  - "[[tigerbeetle-safety]]"
  - "[[tigerbeetle-performance]]"
proofs: []
platforms:
  - cross-platform
---

# TigerStyle for Zig systems software

## Remember

TigerStyle orders its design goals: safety, performance, then developer
experience. Simplicity is the hard-won design that advances those goals
together, not permission to skip analysis. The current page is an orientation;
the complete rule-by-rule inventory and remaining gaps live in
[[tigerstyle-coverage]].

## Safety consequences

- Prefer simple, explicit control flow and avoid recursion so bounded execution
  remains visible.
- Put an explicit upper bound on loops, queues, buffers, messages, connections,
  retries, timeouts, and every other real resource. Assert the exceptional
  intentionally infinite loop.
- Separate programmer errors from operational errors. Assert arguments, return
  values, preconditions, postconditions, and invariants; place paired assertions
  on independent paths. See [[invariants-and-assertions]].
- Test the expected positive space and the forbidden negative space, especially
  where data crosses between them.
- Allocate memory at startup under the strict style. Model capacity before
  implementation and avoid use-after-free and steady-state allocation by
  construction. See [[static-allocation-and-constant-work]].
- Prefer explicitly sized integers for domain values. Treat `usize` as a
  boundary/toolchain type, not an automatic domain model.
- Keep functions small enough to reason about, centralize branching and state
  changes, and push repetitive loops into focused leaves. See
  [[matklad-push-ifs-up-fors-down]].

## Performance consequences

Sketch network, disk, memory, and CPU bandwidth and latency during design.
Optimize in resource order adjusted for frequency, separate control and data
planes, and batch work to amortize costs. Make limits and backpressure part of
the sketch; an unbounded fast path is not a performance design.

Microbenchmarks need runtime-variable inputs and a consumed correctness witness
before timing is credible. See [[trustworthy-microbenchmarks]].

## Integration seams with Zig 0.16

`std.Io` makes ownership, cancellation, nondeterminism, and blocking explicit,
which helps a TigerStyle review. It does not automatically make an
implementation bounded or startup-allocated.

In particular, [[async-vs-concurrent|`std.Io.Threaded.concurrent`]] can allocate
a future and grow its thread pool when called. Strict no-allocation-after-startup
designs therefore need a proven reservation strategy, a bounded/custom backend,
or a deliberately isolated exception. This is an open design seam; do not
declare strict TigerStyle compatibility merely because the application passes
limits in its own code.

## Review lens

For every system component, ask:

- What is the owner, lifetime, bound, and cancellation path?
- Which conditions are programmer invariants and where are both sides asserted?
- What allocates after initialization, including inside the selected I/O backend?
- Where is backpressure applied before a queue or kernel resource is exhausted?
- Which control-plane choices keep the data plane regular and batchable?
- Which OS behavior is measured rather than assumed portable?

TigerBeetle's wider documentation is curated by engineering question in
[[tigerbeetle-engineering-corpus]]; it is not treated as a bag of slogans.
For review, reconstruct both control flow and every mutation of decisive state;
see [[code-reading-and-mechanical-checks]].

Related: [[std-io]], [[cancellation]], [[error-context]], [[newtype-indexes]],
[[deterministic-simulation-testing]], [[evented-io-backends]],
[[invariants-and-assertions]], [[code-reading-and-mechanical-checks]],
[[trustworthy-microbenchmarks]], [[tigerstyle-coverage]],
[[zig-0.16-baseline]].
