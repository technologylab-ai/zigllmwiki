---
id: performance-sketches-and-batching
title: Performance sketches, control planes, and batching
kind: pattern
status: source-verified
zig: "0.16.0"
summary: Quantify resource demand before coding, weight costs by frequency, and use bounded control-plane batches to feed regular data-plane work without hiding latency or overload.
updated: 2026-09-05
sources:
  - "[[zig-http-arena-adoption-2026-09-05]]"
  - "[[source-tigerstyle]]"
  - "[[tigerbeetle-performance]]"
  - "[[matklad-do-not-optimize-away]]"
  - "[[zig-http-response-batching-2026-09-05]]"
  - "[[zig-http-operation-cells-2026-09-05]]"
  - "[[zig-http-batch-quantum-2026-09-05]]"
proofs:
  - proofs/performance_sketch.zig
platforms:
  - cross-platform
---

# Performance sketches, control planes, and batching

## Remember

Sketch the workload and interface before optimizing code. For network, disk,
memory, and CPU, write down both bandwidth and latency, multiply each cost by
its frequency, and compare demand with an explicit capacity assumption. The
usual slow-to-fast resource order is only a starting hypothesis: a frequent
memory miss can dominate an infrequent storage operation.

Batching is not “make the batch as large as possible.” A bounded control plane
admits work, owns deadlines and backpressure, and decides when a batch becomes
ready. A data plane receives a dense, already-bounded slice and performs
regular work. Size, time, shutdown, and memory pressure must all be explicit
flush triggers.

## What the sources establish

The pinned TigerStyle source prescribes sketches across the four resources and
their bandwidth/latency dimensions, resource ordering adjusted by access
frequency, a control/data-plane split, batching across the resource hierarchy,
predictable CPU work, and stand-alone hot loops with narrow arguments. It also
says that external event arrival should not dictate internal work cadence;
controlling cadence makes batching and work-per-period bounds possible.

TigerBeetle's performance document is a project-specific example, not a
portable capacity claim. Its OLTP interface accepts batches of up to 8,190
transfers, amortizes replication per batch, and permits smaller batches under
light load for lower latency. Carry the method—interface-level batching and
headroom—into another system only after replacing TigerBeetle's workload,
record layout, durability, and hardware assumptions.

Neither source proves that a chosen batch is faster on a particular Zig or OS
backend. `std.Io.Batch` supplies fixed operation storage and completion
ownership, but it does not choose the application's admission limit, batch
deadline, or latency/throughput tradeoff. See [[select-and-batch]].

## A worksheet an agent can audit

Name every input and attach units. Keep assumptions, calculated demand,
measurements, and service objectives in separate columns.

| Question | Calculation |
| --- | --- |
| How many batch submissions occur? | `ceil(requests_per_second / requests_per_batch)` |
| What network bandwidth is demanded? | `requests_per_second × (request_bytes + response_bytes)` |
| What journal bandwidth is demanded? | `requests_per_second × journal_bytes_per_request` |
| Can serialized durability keep up? | `batches_per_second × durability_latency` must fit inside one second with the chosen headroom. |
| How much fixed queue memory is reserved? | `batches_in_flight × requests_per_batch × bytes_reserved_per_request` |
| What CPU budget remains? | `cpu_hz × allowed_core_fraction / requests_per_second` cycles per request |
| What latency does filling add? | At steady target load, a full batch takes `requests_per_batch / requests_per_second`; a deadline must cap waiting below target load. |

Do not add unlike quantities into one score. Bandwidth utilization, serialized
latency occupancy, CPU cycles, queue bytes, and tail latency remain separate
constraints. The bottleneck is the first constraint to exhaust its budget.

## Worked bounded durable-command server

This example is a falsifiable design sketch, not a machine measurement. It
assumes 20,000 requests/s, at most 1,024 request bytes, 256 response bytes, a
512-byte journal contribution per request, batches of at most 256 requests,
and at most 16 batches in flight. The fixed queue therefore owns at most 4,096
requests and reserves 7,340,032 bytes for request, response, and journal
regions.

For comparison only, assume a 1.25 GB/s network path, 500 MB/s sequential
journal bandwidth, 20 GB/s memory bandwidth, 1 ms serialized durability
latency, and a 3 GHz CPU with 70% assigned to request work. Also assume this
project wants each resource below 10% of its stated capacity in the nominal
case.

| Constraint | Calculated nominal demand | Consequence |
| --- | ---: | --- |
| Network bandwidth | 25.6 MB/s; 2.048% | Below the assumed headroom threshold. |
| Journal bandwidth | 10.24 MB/s; 2.048% | Bandwidth is not the likely storage limit. |
| Memory traffic | 56.32 MB/s; 0.2816% | Based on an explicit 2,816 bytes touched per request; measure the real pass count later. |
| Durability latency | 79 batches/s; 7.9% serialized occupancy | More constraining than journal bandwidth under these assumptions. |
| CPU | 105,000 cycles/request budget | A budget, not evidence of actual cycle cost. |
| Batch fill | 12.8 ms for 256 requests at target rate | The latency objective must allow this or force earlier partial flushes. |

The same assumptions at 100,000 requests/s require 391 durability points/s,
or 39.1% serialized occupancy. That violates the example's 10% headroom
policy even though disk bandwidth still appears comfortable. The design must
then change—larger batches, different durability semantics, safe concurrent
durability, faster storage, a lower target, or an explicit reduction in
headroom. Optimizing the CPU loop cannot repair this interface constraint.

A deadline can also invalidate the full-batch arithmetic. At 20,000
requests/s, a 2 ms deadline yields roughly 40 requests per batch under smooth
load and approximately 500 durability points/s. Recalculate from the deadline
distribution and burst model; do not quote the 256-request result after adding
a latency SLO.

## Control plane and data plane

Use this ownership split for a bounded server:

1. The control plane checks connection, byte, queue, and in-flight-operation
   limits before accepting a request. It rejects or defers excess work at the
   admission boundary.
2. It places accepted work in caller-owned fixed storage and records one
   absolute batch deadline. External callbacks only make work eligible; they
   do not recursively run the service pipeline.
3. It flushes on size, deadline, shutdown, or a documented pressure signal.
   Submission and completion identities remain owned until terminal cleanup.
4. The data-plane function receives dense slices and narrow values. It has no
   allocator, broad server pointer, I/O capability, or per-item callback. Its
   loop remains regular enough to inspect and measure.
5. The control plane validates the result, performs I/O, releases the batch
   slot on completion, and applies backpressure before rearming admission.

The split does not mean “assert only cold code.” Validate the batch envelope
on entry, keep cheap local invariants in the hot loop, and validate the result
on the independent return path. Measure an assertion policy before weakening
it; safety remains TigerStyle's first goal.

## Common failures

- Ranking resources only by single-operation latency and ignoring frequency.
- Estimating bandwidth while omitting serialized latency, queue depth, or tail
  behavior.
- Waiting indefinitely to fill a batch, which converts throughput into
  unbounded latency.
- Calling a queue bounded while its byte capacity, kernel slots, or completion
  backlog remains unbounded.
- Running the full data path recursively from each external callback, which
  gives arrival timing control over internal work cadence.
- Moving parsing or validation out of the measured region even though it is
  part of the proposed fast path.
- Reporting a wall-clock number without a runtime-variable workload,
  correctness witness, build mode, revision, and machine metadata.

## Executable sketch and harness

The [Zig 0.16 proof](../proofs/performance_sketch.zig) models a finite
256-request batch buffer. Its control plane owns admission and flushes; its
data plane accepts two dense slices, allocates nothing, and returns a consumed
digest. Tests prove that batch sizes 1 and 128 produce the same witness while
reducing control-plane flushes from 1,000 to 8, check every number in the
worked sketch, and reject the 100,000-request/s case under the stated headroom
policy.

The same source is a benchmark-style executable with runtime parameters. A
reproducible invocation is `zig run -O ReleaseSafe
proofs/performance_sketch.zig -- --request-count 1000000 --batch-size 256
--sample-count 5`. It performs an untimed warm-up, times only the control/data
workload, consumes and prints the digest, and prints every sample separately.
It deliberately has no pass/fail timing threshold.

This harness can compare revisions on a controlled runner; its output is not a
portable throughput claim. Record CPU, power mode, OS, target, Zig revision,
repository revision, affinity/contention policy, and the complete invocation
before treating a distribution as evidence. See [[trustworthy-microbenchmarks]].

## Applied HTTP experiment

[[bounded-http-server-design]] separates buffering bytes from amortizing I/O:
the original header already occupied memory, yet separate header/body sends
created avoidable completion dependencies. Gather-send joined those spans;
bounded response cells then joined multiple ordinary callback results without
reusing live output. Lack of ready input and flush force a partial batch, so
light traffic does not wait for a batch to fill. Cancellation retains all cells
until target ownership ends. [[zig-http-response-batching-2026-09-05]]

The Linux batch1/16 comparison improved pipelined throughput, but larger client
pipelines did not improve the fixed-16 server proportionally. Distinguish client
queue depth, server storage and dispatch budgets. More queued input increased
compaction; measuring that copy count does not establish its share of elapsed
time. The direct-operation-cell experiment subsequently isolated Linux hot lookup:
with128 active clients, gains grew when reserved capacity rose from128 to1024,
while requested heap stayed identical between binaries. Full slot/generation/fd
and independent target/cancel checks remained. Both ABBA blocks favored the
candidate at each tested workload, but no profile attributes an exact share of
runtime to scans. Cold bind/close scans and whole-slot scheduling remain.
[[zig-http-operation-cells-2026-09-05]]

Separate configured storage from active load when testing bounded systems:
reservation size itself can affect a hot scan even when fewer clients are busy.
Addressing fixed cells can make established operations independent of that scan
without weakening identity checks. This is a custom Linux adapter example;
using io_uring alone does not establish cheap surrounding control work.

The subsequent same-binary response-cell16/64 × global-callback64/256 matrix
shows why those are separate controls: Q alone changes no storage, while B64
reserves almost twice B16's requested framework heap on this implementation.
The compiled maximum also enlarges static metadata even at B16. Depth128
throughput improves, but full ranges, sample order and finite cold-service/
cancellation witnesses constrain the result; defaults remain16/64. Do not
choose a larger bound without charging its startup storage or mistake a
callback-count budget for preemption. [[zig-http-batch-quantum-2026-09-05]]

Related: [[tigerstyle]], [[static-allocation-and-constant-work]],
[[io-uring]], [[evented-io-backends]], [[trustworthy-microbenchmarks]], and
[[tigerstyle-coverage]].


The adopted HTTP arena/shard implementation changes that allocation model:
[[zig-http-arena-adoption-2026-09-05]] records one64KiB arena per connection,
128response descriptors and up to256-byte borrowed-span copies to merge small
responses into a contiguous send. Every shard reserves full connection storage,
while admission is process-wide: measured requested heap29,635,986bytes with
one shard versus88,907,590bytes with three, plus two requested1MiB owner stacks.
Coordinator arrays are included; kernel/libc/app/actual stack overhead is not.
Configured callbacks are bounded per shard, and multiple handlers can access
shared application state concurrently. Use [[bounded-http-server-design]] for
that ownership boundary; the earlier16/64-cell defaults are historical.
