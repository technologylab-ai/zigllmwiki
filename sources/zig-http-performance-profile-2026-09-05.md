---
id: source-zig-http-performance-profile-2026-09-05
title: Linux HTTP depth sweep with recorded performance profile
kind: source
status: captured
summary: Exact Zig 0.16 ReleaseSafe Linux measurements retain profile/EPP endpoints, fixed response limits, pinned contender hashes and the unresolved throughput gap.
captured: 2026-09-05
revision: "c0f87766efa310d517d262781a33ce189c4f9f0d"
url: https://github.com/technologylab-ai/zig-http/tree/c0f87766efa310d517d262781a33ce189c4f9f0d/reports/2026-09-05-power-profile
snapshot: sources/snapshots/zig-http-performance-profile-2026-09-05.json.gz
sha256: "84e336048fe44b83850476454f05cffdc352c77046983b81eb160207048fe5eb"
---

# Pinned input and observation

The private publication commit preserves the report, raw comparison, pinned
preparation, correctness receipts and supporting logs. The snapshot captures
packet.json, uncompressed SHA-256
`8133349aeaaad3365d1c0d084ea61dd5a3c4b08770256cea2b05cd06a446a5cb`.
Measured input is **bda54040bb0b809c82824b87a782e96826f05dff**; the server's Zig
source is unchanged from 5620905193e496af1c4b297a576c4fe7edd6c4a9. The newer
harness captures power state before/after each trial and rejects a configured
expected profile if missing or mismatched. It launches inline execution with
zero workers explicitly. Exact Zig **0.16.0 ReleaseSafe**, assertions enabled.
Earlier observations remain [[zig-http-response-batching-2026-09-05]]; primary
contender/tool contracts remain [[techempower-r23-comparison-inputs]].

Host omarx1: Intel Core Ultra 7 258V, eight logical CPUs, x86_64 Omarchy 4.0.2,
kernel 7.1.9-arch1-2, glibc 2.44/GCC 16.2.1 20260810, io_uring_disabled=0.
Fresh isolated preparation completed all 67 commands with two build jobs;
no Linux build overlapped timed loads. Binary SHA-256 values:

- Zig HTTP: `8352eb4e11a272bdf95438bcf0d4b9214d8c2bf95a9ebb0cda22208f8842d73f`.
- libreactor: `28a29517c5864a16e62a50b05121a7b8bceaea779cdc861712677e4fc2e67624`.
- wrk: `ec4ba590234163a893cb99b2c0874219e9672408d3e52b2851b1f4868ac78658`.

The sweep ran **18:36:38–18:39:38 UTC on 2026-09-05**, IPv4 loopback,
128 connections, server CPU0, four client threads on CPUs 3–7, three shuffled
repetitions, seed 20260905, 1s warmup and 5s measurement. Zig used one owner and
libreactor one serving child plus an idle parent. mrhttp was excluded because
its prepared command retains three workers/CPUs 0–2. Both selected servers use
`Hello, World!`; two complete exact-body/header pipelines were checked before
each timed workload. Timed wrk validates framing/status/errors, not every byte.

| Client depth | Zig median responses/s (min–max) | libreactor median (min–max) |
| --- | ---: | ---: |
| 16 | 1,745,599 (1,649,155–1,842,546) | 4,298,496 (4,295,876–4,323,170) |
| 32 | 1,742,345 (1,629,794–1,769,123) | 7,263,306 (7,260,947–7,389,032) |
| 64 | 1,918,780 (1,889,912–1,936,787) | 10,938,293 (10,832,169–11,027,781) |
| 128 | 1,922,797 (1,915,961–1,926,582) | 13,627,467 (10,302,756–14,755,787) |

All 24 trials/warmups passed: **643,222,112 timed responses**, **2,880 exact
preflights**, zero reported transport/status errors. All Zig final owners,
late allocations, timeouts and refusals were zero. Startup batch/callback limits
remained 16/64, at most 32 spans/2,512 bytes per observed send. Requested framework
heap peaked at 29,618,632 bytes; excluded kernel/libc/pthread/app/allocator costs
remain outside that bound. Whole-session suffix copies were zero at depth16,
247–264MB at32, 840–859MB at64 and1.98–2.02GB at128. These are totals over
different completed work, not isolated copy costs or a profile.

# Power state and limits

Initial and all 48 trial endpoint snapshots report power profile `performance`;
all eight CPU policies report EPP `performance`, governor `powersave`, driver
`intel_pstate`. These are distinct observed controls. Turbo was permitted:
no_turbo=0, min/max performance percentages8/100. CPU0 limits were400,000–4,800,000
kHz; its untimed current-frequency endpoints ranged399,665–4,689,268kHz. No
setting was changed by the harness/agent. Endpoints do not establish mean clocks,
frequency residency or a profile that never changed between observations.

Earlier profile/EPP were not captured. Do not retrospectively assign a balanced
or powersaver profile, or call this a controlled profile A/B. Higher rates for
both binaries coincide with the user's new setting; the cause is not isolated.
CPU affinity does not reserve the desktop, libreactor depth128 still has a broad
range, and approximate outer-interval CPU counts are not cycles/request.
No profiler ran. The pinned wrk corrected-percentile defect still disqualifies
its raw tails. These are experimental loopback observations, not TechEmpower
rankings, production capacity or a portable std.Io/backend guarantee.

Native Linux preflight gates at the exact measured commit passed14/14 steps,
52/52 ReleaseSafe test executions, installed build,22/22 batch wire cases and
5/5 comparator tests. This sweep itself adds no Mac timing or Windows HTTP
runtime evidence. Separate earlier native ownership gates retain their scope.

A cooperative `/tmp/zig-http-measurement.lock` directory was acquired on Linux
at18:37:33UTC during the already-running sweep after the user requested shared
host coordination; the initial trials predate it. Its owner/PID/token metadata
was removed only after no owned comparison/server/client process remained.
The same path is now reserved on each host before future measurements/builds.
This relies on agent cooperation and does not establish a fully quiet host.

Synthesis: [[bounded-http-server-design]], [[trustworthy-microbenchmarks]].
