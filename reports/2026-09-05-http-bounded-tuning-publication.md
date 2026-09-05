# HTTP bounded tuning publication — 2026-09-05

Both completed experiments are consolidated and pushed to the private HTTP main
at **62c05de875e9917fc0d7bff36f1c51c83d2a7a60**. Source and complete measurements
are pinned by [[zig-http-operation-cells-2026-09-05]] and
[[zig-http-batch-quantum-2026-09-05]]. All48 paired lookup trials and24 same-binary
batch/callback trials passed:555,832,813 timed responses and8,576 exact preflight
bodies/headers. Preserve the full ranges, allocation costs and time-order limits;
no corrected wrk tails, production capacity or Windows HTTP evidence is claimed.

[Final HTTP native packet](2026-09-05-http-bounded-tuning-publication/packet.json)
and [logs](2026-09-05-http-bounded-tuning-publication/native-logs.tar.gz) preserve
gates against that exact clean pushed commit, with no src/tests/tools/build diff
from measured dbb6398. Both hosts used exact Zig0.16.0:

| Gate | Mac maxross | Linux omarx1 |
| --- | --- | --- |
| Debug | 14/14 steps,59/59 tests | 14/14 steps,59/59 tests |
| ReleaseSafe | 14/14 steps,59/59 tests | 14/14 steps,59/59 tests |
| Comparator | 8/8 | 8/8 |
| Batch/gather/inline/generic wire | 30/11/10/26 passed | 30/11/10/26 passed |
| ReleaseSafe smoke | 30,000 exact responses | 30,000 exact responses |

Mac: M3 Max arm64, macOS26.6.2 build25G83. Linux: Core Ultra7 258V,
x86_64 Omarchy4.0.2, kernel7.1.9-arch1-2, io_uring_disabled0. Linux publication
waited while the external architecture agent actually ran its comparison;
no competing test/build began. Both final reservations were released after
owned child cleanup. These correctness gates add no new throughput trial.

The reviewed wiki tree passed87/87 steps,73/82 Mac tests with9 platform skips,
28 command tests and25-query retrieval MRR1.0/hit@3=1.0/recall@5=0.96. Structural
lint reported zero issues. Exact pushed publication verification repeats after
this receipt is committed, following docs/platform-testing.md's Mac/Linux cadence.
Existing source records and prior log bytes remain unchanged.

The named worktrees zig-http-opcells and zig-http-batchq remain discoverable
with git worktree list; their branches are pushed and the integrated work is on
main. The separate external .claude/worktrees/perf-architecture remains untouched.
Shared /tmp/zig-http-compare.PIwh35 tools remain available to that agent; no
shared-root deletion is claimed. No implementation/evidence agent or timed
runner remains active for these two experiments. Publication gates are distinct
from queued M4 work.

M4 still has output/layout/sharding, offload/dynamic leases, fault/combined-limit
qualification and Mac/HTML/NIC/qualified-tail comparisons to do. Windows HTTP is
queued; M3-006 remains postponed. The user deferred repeated Windows tuning
gates, so no new workflow was dispatched. Existing
[Windows run33983581660](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33983581660)
retains its earlier1afb4e4 wiki-proof scope and is not HTTP evidence.
