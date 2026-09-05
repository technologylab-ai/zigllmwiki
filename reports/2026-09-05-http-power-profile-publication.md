# HTTP performance-profile publication — 2026-09-05

The new immutable source [[zig-http-performance-profile-2026-09-05]] captures
the completed Linux comparison at HTTP source bda5404, published in
**c0f87766efa310d517d262781a33ce189c4f9f0d**. All 24 trials/warmups passed,
with 643,222,112 timed responses and 2,880 exact preflights. Earlier profile/EPP
were unknown; this is a new recorded environment, not a controlled profile A/B.
The source and HTTP report retain the substantial fixed-batch gap and full ranges.

[The durable native receipt](2026-09-05-http-power-profile-publication.json)
records final HTTP publication gates at that exact pushed commit. A clean
isolated Mac checkout excluded the other agent's worktree; Linux received that
clean checkout through the maintained SSH wrapper. Exact Zig 0.16.0 on each:

| Gate | Mac maxross | Linux omarx1 |
| --- | --- | --- |
| Debug verification | 14/14 steps, 52/52 tests | 14/14 steps, 52/52 tests |
| ReleaseSafe verification | 14/14 steps, 52/52 tests | 14/14 steps, 52/52 tests |
| ReleaseSafe installed build | passed | passed |
| Comparator | 5/5 | 5/5 |
| Batch/gather/inline/generic wire | 22/11/10/26 passed | 22/11/10/26 passed |
| ReleaseSafe smoke | 30,000 exact bodies | 30,000 exact bodies |

Mac: M3 Max arm64, macOS26.6.2 build25G83. Linux: x86_64 Omarchy4.0.2,
kernel7.1.9-arch1-2, io_uring_disabled=0. These correctness gates do not supply
a new Mac contender benchmark. Existing Windows wiki
[run33983581660](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33983581660)
passed at1afb4e461c54e4d0d1c3fa3c28d4a05d71d997e6 before the user's scope change;
no new Windows run was dispatched. Windows HTTP remains unimplemented.

The user requested host coordination because another agent also measures on
the Mac. The host-local `/tmp/zig-http-measurement.lock` directory now reserves
benchmarks, heavy builds and runtime suites on each host; acquire atomically,
record owner.json, hold through child cleanup and release only your own lock.
The initial Linux trials predated adoption of this protocol. Both HTTP
publication reservations were released after successful checks; future wiki
gates reacquire. See `docs/platform-testing.md` for complete recovery rules.

The validated Linux preparation root `/tmp/zig-http-compare.1FQK18` was removed
after results/logs were preserved and zero owned processes/containers confirmed.
The other agent's `.claude/worktrees/perf-architecture` tree is preserved and
is not included in publication input. Implementation/review claims about our
agent team do not imply that this separate agent has finished.

Remaining work is explicit in ROADMAP.md: operation addressing, batch/dispatch
quantum experiments, output construction/sharding, API and reliability
qualification, and HTML/Mac/NIC/request-tail comparisons. Windows tuning gates
are deferred by user decision; M3-006 remains postponed. The roadmap is not
complete.

Pre-publication wiki checks on the reviewed tree passed: exact Zig0.16.0,
87/87 build steps,73/82 Mac tests with9 platform skips,28 command tests,
and25-query retrieval MRR1.0/hit@3=1.0/recall@5=0.96. Deterministic lint reported
zero issues. Final publication checks rerun on the clean pushed revision;
Windows dispatch stays deferred under the current user instruction.
