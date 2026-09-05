---
id: source-zig-http-plaintext-comparison-2026-09-05
title: First local Linux comparison with TechEmpower plaintext leaders
kind: source
status: captured
summary: Exact ReleaseSafe MVP versus pinned Round 23 mrhttp/libreactor under the same Linux CPU budget; repeated throughput, client sensitivity and rejected wrk percentiles.
captured: 2026-09-05
revision: "b8a3afe1bcfd7dd933060e1064cab55c4f7a41c3"
url: https://github.com/technologylab-ai/zig-http/tree/b8a3afe1bcfd7dd933060e1064cab55c4f7a41c3/reports/2026-09-05-comparison
snapshot: sources/snapshots/zig-http-plaintext-comparison-2026-09-05.json.gz
sha256: "56d9061e687daf609865edef14e60c34cbe8c9645b66152f293deb0e30c357db"
---

# Native Linux plaintext comparison

The private pushed commit above contains the full human report, primary/client
sensitivity JSON, contender build manifests and supporting archive. The gzip
snapshot preserves packet.json with uncompressed SHA-256
`90346d48f68bb34db621a9088e6e736998b90cecf207de0b2e042522dc4aae7d`.
The actual measured HTTP implementation remains the unchanged
`6d622009abee5807eb0829e558c3173635e077ea` pinned by [[zig-http-mvp-2026-09-05]].
Source and load-generator inputs were pinned before synthesis in
[[techempower-r23-comparison-inputs]].

2026-09-05, omarx1, Intel Core Ultra 7 258V, x86_64 Omarchy 4.0.2,
kernel 7.1.9-arch1-2, glibc 2.44/GCC 16.2.1 20260810, io_uring_disabled=0,
exact Zig 0.16.0 ReleaseSafe. Server task affinity CPUs 0–2, client 3–7; same
IPv4 loopback host. Three P cores allowed for servers: one I/O owner + two
application workers for Zig; three serving processes plus idle parent for each
contender. Client mask includes one P core/four E cores, with four wrk threads.
Affinities do not reserve exclusive CPUs; normal desktop load and variable
frequency/thermal state remain environmental variation, not controlled constants.

Main sweep: 54 shuffled trials, three repetitions, connections 8/32/128,
pipeline 1/16, one-second warmup plus five-second measurement, seed 20260905.
Every trial separately validated 32 exact plaintext bodies, status, framing,
Content-Length, text/plain, Server and advancing Date. Every measured/warmup
wrk phase returned no connection/read/write/status/timeout errors; 338,159,736
completed timed responses overall and 1,728 preflight bodies. Timed wrk does
not compare every body byte. Header lengths differ by implementation; mrhttp's
preserved lowercase w differs from our/libreactor's canonical uppercase W.

At 128 connections, median responses/s (min–max):

| Server | Pipeline 1 | Pipeline 16 |
| --- | ---: | ---: |
| Zig MVP | 107,752 (100,139–108,522) | 113,342 (112,210–172,531) |
| mrhttp | 334,860 (315,422–376,396) | 3,204,940 (3,121,284–3,412,039) |
| libreactor | 352,742 (335,647–371,252) | 4,035,781 (3,896,107–4,094,436) |

The latter medians are 28.3×/35.6× the MVP under this setup. Three short repeats
and visible variation do not establish tight confidence, universal ratios or
unconstrained capacity. The two-thread client sensitivity sweep passed 18 trials
at 128 connections, with 576 preflight bodies. Pipeline 16 medians became 128,628,
2,679,850 and2,902,494 respectively: client settings and run conditions matter,
while the large ordering gap remains. Do not compare to published 28M/s results.

All observed thread sets remained stable. Every Zig server ended with zero
live connection/operation owners, zero late framework allocations, zero
refusals/timeouts and at most128 admitted slots. Requested framework heap peak
was 20,073,184 bytes; it excludes libc/pthread/kernel/application memory.
Per-process RSS includes shared forked pages and is not unique physical usage.

Some wrk corrected percentiles were zero despite positive means/maxima. The
pinned source's correction/minimum inconsistency is documented in
[[techempower-r23-comparison-inputs]]. Preserve raw values but reject them as
reliable tails. Separately, samples originate from pipeline-batch completion,
not directly observed individual-request latency or open-loop load.

The primary run measured the submitted cached mrhttp route and inline/batched
libreactor callback versus Zig's ordinary worker callback/writer. Resource,
allocation and application-isolation contracts are not equivalent. Source-visible
candidate costs include per-request handoffs, sequential header/body SENDs,
linear operation scans and pipeline compaction; this comparison does not
quantify each cause. Inline mode, gather-send, sharding and profiling require
separate measured changes. No Windows HTTP, Mac contender, HTML comparison,
NIC throughput, long mixed-load capacity or reliable tail-SLO evidence is added.

An initial pilot failed before READY, and an initial client-sensitivity attempt
stopped after 14 successful trials at a forked-listener teardown race. The report
retains both; the successful18-trial rerun waits for listener closure. No
failed/partial attempt is silently relabeled as the main 54-trial result.

Reusable synthesis: [[bounded-http-server-design]],
[[trustworthy-microbenchmarks]].
