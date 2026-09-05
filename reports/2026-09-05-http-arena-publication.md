# HTTP arena/shard publication — 2026-09-05

HTTP main is committed and pushed at **4b3cd5551d80b422ec6ef763627d019e6f1dfb83**. It adopts
the external reference plus bounded startup/ownership fixes. The source-pinned
[[zig-http-arena-adoption-2026-09-05]] preserves all 36 qualified Linux trials,
1,053,649,993 timed responses and 3,840 exact preflights. Original reference
branches, sources and external worktrees remain unchanged and pushed.

The [final native packet](2026-09-05-http-arena-publication/packet.json) and
[logs](2026-09-05-http-arena-publication/native-logs.tar.gz) record complete
Mac/Linux gates from the exact clean pushed HTTP publication above. Server,
parser, writer, transports, tests, build and benchmark harness are unchanged
from measured bbcec8aa; publication adds report/docs/archive exclusions.

| Gate, exact Zig 0.16.0 | Mac M3 Max | Linux omarx1 |
| --- | --- | --- |
| Debug and ReleaseSafe | 14/14 steps, 67/69 tests per mode; 2 Linux-only skips | 14/14 steps, 69/69 tests per mode |
| Comparator | 8/8 | 8/8 |
| Arena/batch/gather/inline/generic wire | 8/29/11/10/26 =84 | 8/29/11/10/26 =84 |
| ReleaseSafe smoke | 30,000 exact bodies | 30,000 exact bodies, 8 auto shards |

Mac: arm64 M3 Max, macOS 26.6.2 build 25G83, Darwin 25.6.0, 16 logical CPUs,
128 GiB. Linux: x86_64 Core Ultra 7 258V, Omarchy 4.0.2, kernel 7.1.9-arch1-2,
glibc 2.44, io_uring_disabled=0. Both reservations were released after owned
children drained. These final correctness gates add no new throughput trial.

The three-core depth16 Zig/libreactor medians are 5.631/6.196M/s (0.909);
one-core depth128 remains 8.653/14.518M/s (0.596). Complete ranges, seeded
ordering, load errors and requested heap tradeoffs are in the immutable packet.
No cross-session speedup, parser-only cause, client limit or wrk tail/SLO is
established. The saved-download extraction failure and safe lock recovery remain
visible separately from passing measurements; no trial was rerun to hide it.

Wiki publication integrates the proposal plus the new source, restores index
navigation, updates reciprocal guidance and keeps earlier sources/log bytes.
Its complete verification, command/retrieval and clean pushed Mac/Linux gates
run according to docs/platform-testing.md. No new Windows workflow is required
for this user-directed HTTP tuning scope; the server has no Windows adapter.
M3-006 stays postponed. Remaining M4 API/reliability/efficiency and HTML/Mac/NIC/
tail work is queued; this adoption does not complete the project roadmap.


Reviewed wiki gates: 87/87 local build steps, 73/82 Mac tests with 9 platform
skips, 28 command tests, zero lint issues (77 sources/51 pages) and 25 retrieval
queries, MRR0.98/hit@3=1.0/recall@5=0.96, policy met. The exact pushed
publication repeats the Mac/Linux runbook gates; no new Windows dispatch.
