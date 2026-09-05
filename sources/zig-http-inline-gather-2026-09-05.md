---
id: source-zig-http-inline-gather-2026-09-05
title: Removing worker handoff and gathering buffered HTTP output
kind: source
status: captured
summary: Separate exact-source Linux comparisons show modest inline gains and larger gather-send gains while preserving borrowed output and native cancellation checks.
captured: 2026-09-05
revision: "ca2eccf262632eda943615b119573c23e0f6e4fc"
url: https://github.com/technologylab-ai/zig-http/tree/ca2eccf262632eda943615b119573c23e0f6e4fc
snapshot: sources/snapshots/zig-http-inline-gather-2026-09-05.json.gz
sha256: "da92232d880ccdbc40f3a5960a61a60d06f76c305227912457a5d750d64ee6d8"
---

# Two separate architecture experiments

The snapshot retains separate inline and gather benchmark/native gate packets.
Both measured exact Zig 0.16.0 ReleaseSafe with assertions, on omarx1 under the
CPU/client/workload constraints in [[zig-http-plaintext-comparison-2026-09-05]].
No code from the separate application is duplicated into wiki guidance.

Inline source commit `a164d42badb05e3d5cb11d3ea3789f06ffcd196d` adds a common
handler invocation path with optional direct I/O-owner execution and zero
application workers. The per-slot phase protocol remains; results and empty
flush continuations run through bounded loop turns, without callback recursion
or a wait for a nonexistent worker. The user explicitly rejected mandatory
worker handoff for cheap nonblocking callbacks. A violating inline callback
still stalls the I/O owner; deadlines do not preempt application code.

A 24-trial sweep used 128 connections, pipeline 1/16, four client threads,
three repetitions, one-second warmup and five-second measured phases. Inline
medians were 124,083 / 133,648 responses/s versus worker medians 108,477 /
117,479: about 14% improvement, far short of explaining the contender gap.
All measured/warmup phases reported zero transport/status errors; 768 exact
preflight responses passed. Mac Debug/ReleaseSafe each passed 45 tests; Mac
and Linux ReleaseSafe passed 26 worker and 10 inline wire/ownership cases.
The source/test packet does not claim Linux Debug ran at this intermediate step.

The gather source above changes the defaults to inline, zero workers and
gather enabled. `--execution workers` explicitly provisions two startup workers
unless configured otherwise. `--gather-send 0` retains scalar sends for controlled
comparison. The demo /stall returns 501 inline, since sleeping violates its
execution contract. No per-request offload or multicore I/O sharding is added.

Inspected `src/{server,main,transport,transport_linux,transport_macos}.zig`.
Headers already occupied a buffer, but the old transport submitted each
framing/payload span separately and awaited its completion. The new path uses
at most five iovecs and stable startup msghdr storage: Linux SENDMSG, Mac
nonblocking sendmsg/kqueue. Payload bytes remain borrowed; aggregate send_chunk
and i32 caps bound each operation. Partial completion advances across spans.
The metadata/input/output lives until target completion, independently of a
cancel acknowledgement. Linux probes SENDMSG before enabling it.

The separate 12-trial pipeline-16 sweep at the same 128-connection CPU budget
measured inline scalar median 124,505 (118,462–125,669), inline gather 344,394
(335,424–348,825), worker scalar 109,178, and libreactor 3,795,163 responses/s.
Gather was 2.77 times the inline scalar rate, while still far below the contender.
All phases had zero reported wrk errors and 384 exact preflight responses passed.
Repeated results preserve desktop/thermal/client variation and the rejected wrk
percentiles; none establishes production capacity or trustworthy request tails.

Mac Debug/ReleaseSafe each passed 49 unit executions. Mac and Linux ReleaseSafe
passed 26 worker, 10 inline and 11 gather integration cases; Mac Debug also
passed 11 gather cases. Both hosts directly witnessed two scalar operations
become one two-vector operation for plaintext in both execution modes. Mac's
slow-reader fixture observed 128 kernel short gather completions, one pending
gather cancellation and one canceled target completion. Linux's own counts are
in its packet, not inferred from Mac. All checked shutdown owners drained.
Submitted byte caps are distinct from actual kernel short completions.

One response still drains before the next on that connection. Pipeline suffix
compaction, linear operation lookup and one I/O owner remain at this checkpoint.
A later batching or indexing change must have separate source and runtime
evidence. This is a custom raw io_uring/kqueue application, not a std.Io backend
contract or Windows runtime evidence.

Synthesis: [[bounded-http-server-design]], [[trustworthy-microbenchmarks]].
