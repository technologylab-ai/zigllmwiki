---
id: source-zig-http-operation-cells-2026-09-05
title: Direct Linux HTTP operation cells and paired capacity comparison
kind: source
status: captured
summary: Exact Zig0.16 Linux direct addressing preserves token and cancellation ownership and improves paired throughput with unchanged startup heap.
captured: 2026-09-05
revision: "adf24f380ac56b2ae142e514a1491be1e08d4a20"
url: https://github.com/technologylab-ai/zig-http/tree/adf24f380ac56b2ae142e514a1491be1e08d4a20/reports/2026-09-05-operation-cells
snapshot: sources/snapshots/zig-http-operation-cells-2026-09-05.json.gz
sha256: "ee0b27db7fabf2b4909c06a7b79643c546429dad12b12b84c1d0183389dbacca"
---

# Pinned source and observation

Private HTTP publication adf24f3 preserves native/timed packets, raw logs and
an independent deterministic summarizer. The captured manifest SHA-256 is
acc48cd818f0d23b321a55cce1525707aae6a436fdbff953a1f231ab8747a6b8;
its timed packet is97a53b818b1cbc48baccd4f70e1882df43dd545e2a8962d5a04ccf4d3de8e712.
The snapshot includes both manifest and derived timed summary. Measured candidate
2b971e14f5fd8ed9769b5cdefbea3d86c71d83fc follows baselinec0f8776;
exact Zig0.16.0 ReleaseSafe with assertions, default batch16/global64.

Linux now addresses established data/cancel operations by slot and decodes CQEs
directly. Full kind/token/generation/socket checks remain; first fd binding and
close still scan. Target completion and cancellation acknowledgement both drain
before reuse, including fixed accept identity. Shutdown closes networking
immediately but descriptor close waits for both owners. Mac validates the same
logical identity/reservation contract but retains pooled scans. No new storage,
std.Io guarantee, SEND_ZC or Windows HTTP implementation is introduced.

Mac maxross M3 Max arm64/macOS26.6.2 build25G83 and Linux omarx1 x86_64
Omarchy4.0.2/kernel7.1.9-arch1-2/io_uring_disabled0 each passed58 test executions
in Debug and ReleaseSafe,69 wire cases,8 comparator tests and30,000 smoke bodies.
Retained logs include an initial fixture comptime compiler failure fixed before
these passes. Stale cancellation cannot release a current generation; the new
gather fixture permits normal/canceled completion and is not a forced-pending
witness. Existing16-cell slow-reader cancellation evidence retains its scope.

The Linux timed run19:27:20–19:33:25UTC on2026-09-05 used Core Ultra7 258V,
server CPU0, four wrk threads on CPUs3–7,128 active clients and128/1024 reserved
server slots. Two shuffled A/B/B/A blocks per depth1/16/128 give four samples
per binary/workload;1s warmup and5s measurement. All48 trials/warmups passed,
with301,290,349 timed responses and5,120 exact preflight bodies/headers.
No samples were excluded; the full ranges and both block ratios are captured.

| Reserved slots | Depth | Baseline median/s | Candidate median/s | Ratio |
| --- | --- | ---: | ---: | ---: |
| 128 | 1 | 289,309 | 329,521 | 1.139 |
| 128 | 16 | 1,776,401 | 1,842,778 | 1.037 |
| 128 | 128 | 1,828,908 | 1,913,043 | 1.046 |
| 1024 | 1 | 163,869 | 288,881 | 1.763 |
| 1024 | 16 | 1,365,770 | 1,758,112 | 1.287 |
| 1024 | 128 | 1,599,844 | 1,867,307 | 1.167 |

Both blocks favor the candidate for every workload. The greater improvement
with more reserved slots is consistent with removing hot scans, without a
profile attributing their exact cost. Requested framework peak heap remains
29,618,632/236,924,360 bytes at128/1024 slots in both binaries; this excludes
kernel/libc/pthread/app/allocator costs and is not RSS. All final owners, late
allocations, worker dispatches, refusals and timeouts were zero. Batchmax16,
callbackmax54–64 and largest send32 spans/2,512 bytes stayed bounded.

Every profile/EPP endpoint was performance; governor powersave/driverintel_pstate.
Endpoints do not prove average frequency, residency or a causal profile effect.
Timed wrk counts responses directly but does not compare every body byte; its
corrected histogram disqualifies tails. ABBA reduces linear ordering bias; it
does not prove isolation, unconstrained clients or production capacity. There
were128 active connections even in the1024-slot experiment. No Mac speedup is
claimed. The cooperative Linux lock was held before load through child cleanup;
shared /tmp/zig-http-compare.PIwh35 tools remain for the independent architecture
agent, so no shared-root deletion is claimed.

Prior context: [[zig-http-performance-profile-2026-09-05]],
[[techempower-r23-comparison-inputs]]. Synthesis: [[bounded-http-server-design]],
[[performance-sketches-and-batching]], [[trustworthy-microbenchmarks]].
