---
id: source-zig-http-batch-quantum-2026-09-05
title: Bounded HTTP batch and global callback quantum experiment
kind: source
status: captured
summary: Exact Zig 0.16 Linux/macOS ownership gates and a same-binary Linux16/64-cell ×64/256-callback matrix expose throughput, memory and time-order limits.
captured: 2026-09-05
revision: "62c05de875e9917fc0d7bff36f1c51c83d2a7a60"
url: https://github.com/technologylab-ai/zig-http/tree/62c05de875e9917fc0d7bff36f1c51c83d2a7a60/reports/2026-09-05-batch-quantum
snapshot: sources/snapshots/zig-http-batch-quantum-2026-09-05.json.gz
sha256: "c4ff93a585a0b6fe1b8ce4c546fab369615b2ea326be0a4bd646e423477a80ee"
---

# Pinned implementation and experiment

HTTP publication62c05de consolidates the earlier direct-operation-cell work and
batch/callback candidate **dbb639859e4c8503310933a2e53f0aaf45e2fca0**. Runtime
source is unchanged by the publication doc merge. The captured manifest SHA-256
is0bf505cbd8a287bce0a4b1c6cce3cadc2758a6b5a8c84d0262cc00de6649211c;
its timed packet isdac26d215074eb7064e00cb84667448a5ac48b0ce799f50883a3eeebb76cb1b3.
The snapshot includes both packets and exact native vector header evidence.
Raw logs, native packet and deterministic summarizer remain in the pinned
publication. Exact Zig **0.16.0 ReleaseSafe with assertions**; separate Debug
gates. Prior lookup experiment: [[zig-http-operation-cells-2026-09-05]].

Startup response cells accept1–64 (B, default16), global inline callbacks per
turn accept1–256 (Q, default64). Worker mode still uses one response cell.
No parser/framing, scan-start, flush, compaction, callback or ownership algorithm
is replaced. Config and READY/STATS expose Q. Raising static gather capacity
80→320 adds3840 bytes to each64-bit Slot and Gather and to temporary
SendSelection storage. There are connections Slots and2*(connections+1) Gathers
when gathering. Config.heapBytes accounts for actual struct sizes; exact-byte
startup-budget tests pass. Q alone changes no allocation. B16→64 adds
connections*48*(output_bytes+sizeof(ResponseCell)) within this binary.

Mac maxross M3 Max arm64/macOS26.6.2 build25G83 and Linux omarx1 x86_64
Omarchy4.0.2/kernel7.1.9-arch1-2/io_uring_disabled0 each passed59 test executions
in Debug and ReleaseSafe,77 wire cases (30 batch/11 gather/10 inline/26 generic),
8 comparator tests and30,000 exact ReleaseSafe smoke responses at clean dbb6398.
Generated-output and borrowed-input fixtures each submitted320 native send spans
from64 distinct nonempty chunked-finish cells. A23-byte cap then forced partial
progress through ordered flush and close barriers. A65,535-byte asset/small
socket-window fixture retained64 cells during deadline cancellation. Linux
observed a normal target-terminal race, not a canceled CQE; separate target and
cancel ownership drained on both OSes. Seven backpressured depth128 pipelines
and a cold eighth connection exercised Q256 under a finite2s watchdog. These
are bounded witnesses, not starvation proofs, arbitrary application preemption
or production request-tail guarantees.

Header packet: Apple SDK26.5 limits.h SHA-256
4e09d7a2307887fe787c65e31d63747720c4d462b7ba3bf8f45e401d74f0b246
lists IOV_MAX1024 and _XOPEN_IOV_MAX16. Exact installed Zig0.16 std.c lists16
for macOS; Linux syscall/UAPI constants list1024. Full paths/file hashes/line
excerpts are preserved. The320-span observation is specific to the custom
Linux io_uring SENDMSG and Mac sendmsg/kqueue adapters; it is not a portable
std.c/std.Io guarantee or SEND_ZC/NIC-zero-copy evidence. Windows is absent.

# Same-binary Linux matrix

The Linux binary SHA-256 is
be0d15486773cd986dcc31a44d85fa44feb559751f911f9ef1f4769a6b2716a0;
wrk isc8000cec3cb25e87292c983828ecfcfd4108ce39d2bb01b9cd313f17dcf290af.
Core Ultra7 258V, server CPU0, four client threads on CPUs3–7,128 configured
and active connections, three shuffled repetitions per B/Q/depth, seed20260905,
1s warmup/5s timing. All24 trials/warmups passed, with254,542,464 timed responses
and3,456 exact-body/header preflights. Timed wrk does not compare every body byte.

| B/Q | Depth16 median/s (range) | Depth128 median/s (range) | Requested framework heap |
| --- | ---: | ---: | ---: |
| 16/64 | 1,700,614 (1,676,603–1,953,552) | 1,950,970 (1,942,795–1,967,415) | 31,100,880 bytes |
| 16/256 | 2,048,490 (2,043,918–2,060,565) | 2,024,634 (2,015,306–2,028,032) | 31,100,880 bytes |
| 64/64 | 1,730,203 (1,632,596–1,915,378) | 2,577,426 (2,575,268–2,608,414) | 59,805,648 bytes |
| 64/256 | 2,053,499 (2,029,529–2,084,071) | 2,779,508 (2,513,178–2,788,822) | 59,805,648 bytes |

B16 is1,482,248 requested bytes larger than the old operation-cell binary's
29,618,632-byte heap; this matrix is not an old/new same-footprint comparison.
Q changes no requested heap. Kernel/libc/pthread/app/allocator overhead and
actual stack mappings remain outside the framework metric. All final owners,
late allocations, workers, refusals and timeouts were zero. B/Q maxima stayed
within configured limits. Throughput runs observed up to128 spans; the separate
native fixtures supply the320-span witness.

All profile/EPP endpoints were performance; governor powersave/driverintel_pstate.
They do not prove average frequency, isolation or a causal profile effect.
Only three samples/configuration were taken. Depth16 Q64 samples occurred late
(B16 indices14/19/22; B64 indices18/21/23), while B16/Q256 occurred4/5/9;
shuffling did not balance time drift. Preserve full ranges/sample order and
withhold clean causal attribution of that Q improvement. wrk corrected tails
remain excluded. Defaults16/64 are unchanged; output representation/sharding,
long combined-limit runs, Mac/HTML/NIC comparisons and qualified tails remain.
The cooperative Linux lock covered load through cleanup and was released.
Shared /tmp/zig-http-compare.PIwh35 tools remain for the independent agent.

Synthesis: [[bounded-http-server-design]], [[performance-sketches-and-batching]],
[[trustworthy-microbenchmarks]].
