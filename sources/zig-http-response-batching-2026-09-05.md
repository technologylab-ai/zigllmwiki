---
id: source-zig-http-response-batching-2026-09-05
title: Bounded response cells, gather batches and deeper HTTP pipelines
kind: source
status: captured
summary: Exact Zig 0.16 Linux/macOS ownership evidence and separate batch-limit, one-core, deeper-pipeline and code-control measurements preserve gains and unresolved variation.
captured: 2026-09-05
revision: "e07766e4f1a3bf1cd5dc772e8da48f63d085e5ad"
url: https://github.com/technologylab-ai/zig-http/tree/e07766e4f1a3bf1cd5dc772e8da48f63d085e5ad/reports/2026-09-05-batch
snapshot: sources/snapshots/zig-http-response-batching-2026-09-05.json.gz
sha256: "c6ed44ae42d5435b551c324b971788699002bda0c24b84104eb56587ae2fcba7"
---

# Pinned implementation and native packet

The private publication commit above retains the report, every JSON receipt and
supporting raw logs. The snapshot preserves packet.json, uncompressed SHA-256
`866ea47f424eb0a0a0aeb78fb9224eb232a78ff60405162282a4d2cde47efc86`.
Primary contender/wrk evidence is [[techempower-r23-comparison-inputs]]; earlier
worker, inline and gather checkpoints remain separately pinned rather than
being relabeled as batching results.

Inspected the exact application server, parser, writer, main, both transports,
batch wire tests and comparator at these immutable checkpoints:

- `b7ac35558dea3e418e7dab5e41b1d3bb9054ca73`: bounded response batching.
- `5620905193e496af1c4b297a576c4fe7edd6c4a9`: multi-cell cancellation counter/test.
- `3f1963f21a8d5c84b08efed94c90e1cbb9434330`: client depth 32/64/128 harness and
  wire tests; Zig server source is unchanged from 5620905.

Exact Zig 0.16.0, Linux raw io_uring SENDMSG or macOS nonblocking sendmsg/kqueue.
Default inline callbacks use zero workers; explicit worker mode remains.
Startup response-cell count is 1–16, default 16 inline, effective 1 with workers.
Each cell retains separate output/header/chunk storage. One callback owns the
request/writer metadata at a time; finished snapshots remain immutable while
that metadata advances to the next already-buffered request. Receive bytes are
not moved while a frozen response borrows them. No route-specific response cache
bypasses the ordinary callback/writer.

At most 80 payload/framing spans enter stable iovecs/msghdr storage. Aggregate
send_chunk/i32 bounds and cross-span partial completion remain enforced. Drain
on cell/global callback exhaustion, lack of ready input, flush or close; do not
wait for a batch to fill. Flush drains preceding finished responses and the
active snapshot before resuming that request/state with an empty writer. Compact
remaining input once after the batch drains. A global 64-callback turn budget,
per-connection batch limit and rotating scan start bound dispatch work. Oldest
unsent deadlines remain, but application callbacks cannot be preempted.

Parser rejection and Connection: close responses preserve preceding wire order.
Application `.close`, invalid output or deadline abort may discard earlier
finished-but-unsent cells. Whole-batch drain records completed counts and cycle
maxima; a sent prefix of a subsequently canceled batch may be omitted. These
are not individual request completion timestamps. Startup heap arithmetic covers
exact requested framework allocations and separate requested stacks; kernel,
libc/pthread, allocator overhead, assets and arbitrary application memory remain
outside it. Ordinary kernel socket copies remain; no SEND_ZC or NIC claim.

# Runtime witnesses

Mac: M3 Max arm64, macOS 26.6.2 build 25G83. Linux: omarx1, x86_64 Omarchy
4.0.2, kernel 7.1.9-arch1-2, Intel Core Ultra 7 258V, glibc 2.44/GCC 16.2.1
20260810, io_uring_disabled=0. Both use exact Zig 0.16.0. At 5620905 both hosts
passed 52 Debug and 52 ReleaseSafe unit executions, 26 generic, 10 inline,
11 gather and 16 batch wire cases, plus 30,000 ReleaseSafe smoke bodies.
At 3f1963f all 22 batch cases passed on both hosts, adding distinct generated and
borrowed-body pipelines at depths 32/64/128 with connection reuse and unchanged
batch/callback limits. Earlier b7ac355 receipts retain their 15-case scope.

A 32-distinct-generated-response fixture reduced gather sends 32→2 and suffix
copy bytes 25,251→816. The eight-connection fairness witness completed 3,585
responses; it is not a starvation or real-time guarantee. Partial-send caps,
empty flush resumptions and malformed/Expect/close order are exercised.

The original large-body cancellation fixture could drain its preceding cells
before the body completed. A separate depth-16 pipeline of small requests for a
startup-loaded 65,535-byte asset explicitly observes 16 frozen cells at pending
gather cancellation. Mac observed 80 short completions and a canceled target;
Linux observed two short completions and a normally completed target race.
Both drained every target/cancel owner, recovered healthy service and ended
with zero late allocations. Socket buffers were requested at 4096/1024 bytes,
the server deadline was one second, and client/process watchdogs were finite.
The first 65,536-byte asset fixture failed StreamTooLong: this exact file-reader
limit is exclusive. The final size and documentation preserve that boundary.

# Separate Linux measurements

All timings use ReleaseSafe with assertions, IPv4 loopback, 128 connections,
four wrk threads on CPUs 3–7, three repetitions, seed 20260905, one-second
warmup plus five-second measurement. Builds did not overlap Linux timed loads.
Every phase reported zero wrk transport/status errors. Exact preflights checked
bodies/framing/Server/advancing Date; timed wrk did not compare every body byte.

At b7ac355, a 24-trial sweep with server CPUs 0–2 measured pipeline-16 median
233,768 responses/s for batch 1 versus 1,220,510 for batch 16 (5.22×); pipeline-1
medians were 198,087 and 195,144. mrhttp/libreactor pipeline-16 medians were
3,593,634 / 4,630,824. Their three serving processes differ from Zig's single
owner. A separate 12-trial CPU0-only sweep measured Zig 1,833,059 versus
libreactor 2,617,684 at depth 16, with one serving thread/process each. Preserve
ranges and observed CPU use; do not divide aggregate rates by assumed cores.

At 3f1963f the 24-trial CPU0-only depth sweep measured median responses/s:

| Client depth | Zig, server batch 16 | libreactor |
| --- | ---: | ---: |
| 16 | 1,160,475 | 2,695,065 |
| 32 | 1,159,432 | 4,371,778 |
| 64 | 1,063,927 | 5,939,668 |
| 128 | 1,189,968 | 7,412,593 |

All 388,038,368 timed responses and 2,880 exact preflights passed. The configured
batch cap stayed 16; whole-session compaction rose from zero at depth 16 to
roughly 1.05–1.31 GB at 128. More copying is observed, not a profile quantifying
its share of the plateau. All Zig final owners and late-allocation counts were
zero, with no timeouts/refusals and no configured batch/callback limit exceeded.

A six-trial old/current control investigated the lower repeated depth-16 result.
The same current binary ranged from 1,016,938 to 1,806,564; original batching
ranged from 964,131 to 1,156,666. Shuffling happened to group current trials
before original trials, leaving time and binary confounded. Neither a code
regression nor a specific thermal/frequency/cache cause is established. Desktop
load, affinity rather than isolation, and client/host variation remain limits.
Do not cherry-pick the earlier 1.83M as current capacity. Broken wrk corrected
percentiles remain rejected; all rates are experimental, not request-tail SLOs
or official TechEmpower results. Deeper depths are a different workload from 16.

Source review identifies full operation searches, whole-slot scans, six clock
reads per ordinary request and generic header formatting. These are code costs,
not profiled bottlenecks. Token-addressed reserved operation cells, independent
batch-size tuning/input layout and bounded I/O sharding remain separate next
experiments. No Windows HTTP or new std.Io contract is established.

Synthesis: [[bounded-http-server-design]], [[trustworthy-microbenchmarks]],
[[performance-sketches-and-batching]].
