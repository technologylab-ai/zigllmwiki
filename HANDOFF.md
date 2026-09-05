# Project handoff — 2026-09-05

The arena/shard implementation is now the HTTP main base, committed and pushed
at **4b3cd5551d80b422ec6ef763627d019e6f1dfb83**. The user selected the external agent's version;
this adoption adds reviewed worker-cache, EOF/interim, startup/failure and exact
budget fixes. Measured source bbcec8aa9516efc470238b9edeea4f01b1f4a6d7 is
unchanged by the report publication. [[zig-http-arena-adoption-2026-09-05]] pins
the source, complete raw evidence and independently reproducible summary.

All 36 qualified Linux trials passed: 1,053,649,993 timed responses and 3,840
exact header/body preflights. Three-core Zig/libreactor ratios of medians are
0.957/0.909/0.860 at depths 1/16/128; one-core ratios are 1.106/0.778/0.596.
The one-core deep-pipeline gap remains; its cause needs profiling or controlled
ablation. Do not infer a client bottleneck or parser-only cost from CPU totals.

Final clean pushed HTTP gates passed on both hosts at 4b3cd55:
Mac 67/69 tests per mode (2 Linux-only skips), Linux 69/69, 84 wire cases,
8 comparator tests and 30,000 exact smoke bodies per host. The [publication
receipt](reports/2026-09-05-http-arena-publication.md) preserves both packets,
environments and released reservations. Windows HTTP is absent; its tuning
runs remain deferred and M3-006 remains postponed. No timed runner remains.

The original reference branches `perf/arena-shards` (122e903),
`perf/arena-shards-plus-main` (d5b6d9b) and `wiki/arena-shards-proposal` (cd916aa)
are pushed unchanged. Both external `.claude` worktrees remain intact. Our
integration worktrees are `zig-http-arena-integration` and
`zigllmwiki-arena-integration`; their named branches and main preserve the work.
The proposal source/snapshot and all earlier sources/log bytes are unchanged;
its index deletion was repaired and unsupported causal claims narrowed.

Preserve shared `/tmp/zig-http-compare.PIwh35` and its retained candidate/tools.
Reacquire each host's `/tmp/zig-http-measurement.lock` before future load.
The extraction compatibility failure was recovered from its saved download,
without repeating measurements; original failure/recovery records remain.

The reviewed wiki content passed 87/87 local verification steps (73/82 Mac
tests, 9 platform skips), all 28 command tests and 25-query retrieval policy:
MRR 0.98, hit@3 1.0, recall@5 0.96. Lint reports zero issues across 77 sources
and 51 wiki pages. The clean pushed commit is checked again before completion.

Remaining M4 work is queued: profiled one-core efficiency, dynamic lease
release/optional offload, broader fault/combined-limit qualification, HTML/Mac/
NIC comparisons, trustworthy request tails and Windows HTTP. Adoption completes
this integration, not the entire roadmap. Exact wiki publication gates follow
the Mac/Linux runbook at the pushed revision; this does not extend prior
Windows evidence. The older handoff below is historical, including old defaults
and references to sharding as queued.

Completed HTTP iteration: two performance experiments are integrated and pushed
from the sibling `zig-http-batchq` worktree,
branch `perf/batch-quantum`, consolidated publication62c05de875e9917fc0d7bff36f1c51c83d2a7a60 (measured source dbb6398). Direct operation-cell
source/report is pushed atadf24f380ac56b2ae142e514a1491be1e08d4a20 on
`perf/direct-operation-cells` in `zig-http-opcells`, pinned by
[[zig-http-operation-cells-2026-09-05]]. Do not restart or discard these named
worktrees after interruption; use `git worktree list` and each handoff.

All48 direct-cell Linux paired trials and24 batch/callback matrix trials passed.
Both native platforms passed the larger batch code atdbb6398:59 tests in each
build mode,77 wire cases,8 comparator tests and30,000 smoke bodies. Both timed
runners and implementation/platform agents finished and released their locks.
The evidence agent finished both deterministic packet checks. Final HTTP
publication gates passed on Mac/Linux at clean62c05de; the durable receipt is
[here](reports/2026-09-05-http-bounded-tuning-publication.md). Wiki publication181f4f3b1ae827c9997d4fc1841e67c4f318b61c passed the exact
clean-commit gates:87 steps on both hosts, Mac73/82 tests with9 skips,
Linux74/82 with8 skips,28 command tests and25-query retrieval MRR1.0/hit@3=1.0/
recall@5=0.96. Both reservations were released; no runner remains active for
these experiments. This follow-up only refreshes roadmap counts and this
completion receipt; repeat the runbook gates at its pushed commit. The batch evidence is pinned by
[[zig-http-batch-quantum-2026-09-05]]. Remaining roadmap work is queued, not assigned to a runner.
The independent external `.claude/worktrees/perf-architecture` remains untouched.

Preserve `/tmp/zig-http-compare.PIwh35`: its pinned wrk/libreactor tools are also
borrowed by the external architecture agent. Do not delete this shared root
merely because our experiments finished. Future host load must reacquire the
host-local `/tmp/zig-http-measurement.lock` through child cleanup. Windows tuning
gates remain deferred by the user's Mac/Linux focus; M3-006 remains postponed.

Earlier paragraphs below retain their historical checkpoint scope; the new
source records and final publication receipt supersede their active-work status.

This is the durable entry point for a fresh session. ROADMAP.md owns scope and
status; historical log entries and reports retain narrower and failed runs.

Shared host coordination: the user reports another agent taking Mac measurements.
Use `/tmp/zig-http-measurement.lock` on each host as documented in the runbook;
acquire atomically before load/build/runtime work and release only after all
owned children finish. Keep the Mac free while its measurement owner is active.

Current user steering: focus the HTTP performance loop on macOS and Linux;
further Windows measurements/publication gates are deferred while tuning this
Linux/macOS-only server. Windows run33983581660 passed at1afb4e4 before this
decision; no Windows runner remains active and no new dispatch is planned.
The user then selected omarx1's performance power profile. The completed
24-trial depth16/32/64/128 sweep at bda5404 measured Zig medians
1.746/1.742/1.919/1.923M/s and libreactor4.298/7.263/10.938/13.627M/s.
All 643,222,112 timed responses and2,880 exact preflights passed. Startup
batch/callback limits remain16/64; all final owners/late allocations were zero.
All profile/EPP endpoints were performance, governor powersave, driver
intel_pstate; untimed current-frequency observations are not average clocks.
Prior profile/EPP were not captured, so no causal profile speedup is established.
[[zig-http-performance-profile-2026-09-05]] pins the packet at HTTP publication
c0f87766efa310d517d262781a33ce189c4f9f0d. The preparation agent and timed
runner finished, all owned comparison processes/containers drained, and the
validated temporary preparation root was removed. Initial trials predated the
new cooperative lock. The remaining architecture experiments are queued.
The [new publication receipt](reports/2026-09-05-http-power-profile-publication.md)
records the clean c0f8776 Mac/Linux gates:52 unit executions in each mode,
69 wire cases,5 comparator tests and30,000 ReleaseSafe smoke bodies per host.
The other agent's separate HTTP worktree is preserved; all statements about this
team's completed work exclude that external agent's ongoing activity.

The new wiki content passed the full local verifier (87 steps;73/82 tests and
9 platform skips),28 command tests and25-query retrieval MRR1.0/hit@3=1.0/
recall@5=0.96 before publication. Existing source records and prior log bytes
are unchanged. Final clean-commit verification follows the Mac/Linux cadence.
The HTTP main checkout also contains another agent's untracked worktree under
.claude/worktrees; preserve it. Publication gates used an isolated clean checkout.

## Preceding batching publication and execution experiment

The preceding standalone batching publication is
`e07766e4f1a3bf1cd5dc772e8da48f63d085e5ad`, pinned with its evidence by
[[zig-http-response-batching-2026-09-05]]. Defaults: inline/zero application
workers, gathered output, 16 startup response cells per connection, global
64-callback turn budget, flush barriers and compaction after batch drain.
The batch API still calls the ordinary handler for every request; no cached
plaintext route or kernel zero-copy send is claimed. Read the sibling README,
HANDOFF and ownership contract before changing retained input/output lifetimes.

Completed measurements: 24 batch1/16 trials, 12 one-core trials, 24 deeper-client
pipeline trials and 6 old/current controls. The same-binary batch comparison
improved pipeline16 from 234k to 1.22M responses/s. The first one-core run reached
1.83M versus libreactor2.62M; the later depth16/32/64/128 sweep plateaued at
1.06–1.19M while libreactor reached7.41M at128. Both are preserved. An unchanged
current binary varied1.02–1.81M in the control; code/host/frequency attribution
remains unresolved. All66 measured trials/warmups passed, with4,224 exact
preflight responses. Do not report a chosen best run as production capacity or
use broken wrk corrected percentiles for request-tail claims.

Exact Zig0.16.0 on Mac/Linux passed52 unit executions in both Debug and
ReleaseSafe,26 generic +10 inline +11 gather cases and the expanded22 batch
cases. Both passed30,000 ReleaseSafe smoke bodies. A new multi-cell cancellation
witness retained16 frozen cells and drained all target/cancel owners on both OSes;
Mac observed a canceled target, Linux a normal terminal race. Deep distinct-body
pipelines32/64/128 preserved order/reuse without enlarging the server batch cap.
Earlier checkpoints below retain their original narrower test counts.

The [max-reasoning review](reports/2026-09-05-http-performance-review.md) finished.
Next M4 work is queued: token-addressed Linux operation cells, a batch16/64 ×
callback64/256 matrix, output representation and I/O sharding, then leases/offload and
fault/combined-limit qualification. Mac/HTML contender comparisons and trustworthy
tail measurements remain M4-004. Windows HTTP remains M4-005; M3-006 remains
postponed by user decision. All implementation/review agents and timed runners finished.
The [HTTP publication receipt](reports/2026-09-05-http-performance-publication.md)
records the completed clean e07766e native gates and benchmark cleanup.
Wiki publication gates use the final clean pushed documentation revision; match their
headSha to that revision using the runbook, not an older receipt.


The initial Linux plaintext comparison is preserved by
[[zig-http-plaintext-comparison-2026-09-05]] at standalone checkpoint
`b8a3afe1bcfd7dd933060e1064cab55c4f7a41c3`. Unchanged worker MVP: at 128
connections/pipeline16, median 113k responses/s versus mrhttp 3.20M and
libreactor 4.04M. All 54 primary + 18 client-sensitivity trials passed;
throughput is experimental, and broken wrk corrected percentiles were rejected.
This is not a production capacity/SLO or official TechEmpower result.

The user rejected mandatory worker handoff and sequential header/body sends.
The separate inline checkpoint `a164d42badb05e3d5cb11d3ea3789f06ffcd196d`
measured a roughly 14% pipeline gain. Gather checkpoint
`ca2eccf262632eda943615b119573c23e0f6e4fc` made inline/zero-workers/gather the
default and measured 344k/s versus 125k scalar-inline in the same sweep.
[[zig-http-inline-gather-2026-09-05]] preserves both checkpoints independently.
Inline application callbacks must be bounded/nonblocking; the server cannot
preempt a violation. Workers remain an explicit mode. Per-request offload and
I/O sharding are not implemented. The demo /stall returns 501 inline.

The generalized pinned contender preparation completed all 67 commands from
a fresh isolated Linux directory at b8a3afe; no installed system packages or
user checkout was changed. Preserve its source/artifact/compiler/image differences.


## Original M4 MVP checkpoint

The user authorized implementation after the design discussion. A working
experimental framework is now in the private
[zig-http project](https://github.com/technologylab-ai/zig-http), local sibling
`../zig-http`. Its published documentation checkpoint is
`c41e0a3919794431b1222a93655945699386b17e`; the unchanged implementation is pinned
at `6d622009abee5807eb0829e558c3173635e077ea` by
[[zig-http-mvp-2026-09-05]]. Read that project's README, AGENTS, HANDOFF and
ownership docs before coding. Do not restart it or copy runnable Zig into wiki text.

Exact Zig 0.16.0; Linux raw io_uring and macOS nonblocking kqueue; one I/O owner
and fixed startup application workers with per-slot atomic mailboxes. Complete
bounded requests expose lazy headers and borrowed body spans. Returning
writer.flush() writes the entire committed snapshot asynchronously and resumes
with an empty writer. finish() ends framing. Borrow only request-owned or
immutable server-lifetime bytes: dynamic finish/cancel release is still queued.
Timeout cannot reclaim an active worker's borrow; shutdown drains or exits the
whole process at its deadline. Pipeline suffix compaction is a measured copy.

The pinned clean source passed 44 test executions in each of Debug/ReleaseSafe
and 26 integration cases on both maxross and omarx1. Each host's ReleaseSafe
smoke validated 30k bodies; no capacity or TechEmpower ranking is claimed.
The actual response-stall test limits SO_SNDBUF and requires incomplete output,
preventing an idle-timeout false positive observed in the first Linux fixture.
The packet preserves environments, configurations, binary/source hashes and
all receipts. Framework heap bounds exclude libc/pthread/kernel/application
storage; arbitrary callback isolation and whole-process RSS bounds are unproved.

The user's Linux linker lesson is now in
[[build-diagnostics-and-generated-code]]: on omarx1 with GCC 16/glibc 2.44,
default Debug fails on crt1.o:.sframe R_X86_64_PC64, while default ReleaseSafe
runs the same six transport tests without overrides. Debug also passes with
-fllvm -flld. Prefer ReleaseSafe for performance measurements; retain Debug as
a correctness gate. Exact compiler and CRT/source hashes are pinned in
[[zig-0.16-linux-crt-linker-workaround]]. Do not upgrade Zig as a workaround.

M4-001/002/003 are complete for the initial experiment. M4-004 comparative
performance and M4-006 architecture have subsequent results above. Their remaining
experiments and M4-005 Windows HTTP remain queued; M3-006 remains postponed. All implementation/review subagents
finished. Linux competitor runs now have separate pinned receipts. No Windows HTTP runner exists. Wiki Windows
publication gates continue to verify existing wiki proofs, not this HTTP server.
Use gh run view HEAD-associated runs to inspect hosted publication status;
queued is never equivalent to executed or passed.

## Prior completed wiki work

The user requested completion of actionable wiki work, initially reserving M4 for a
separate in-depth session, now opened above. M0, M1, M2, and M3-001 through M3-005 are complete.
The wiki covers the targeted public `std.Io` surface, all 71 pinned TigerStyle
principles, the selected matklad corpus, and platform backend selection.
Selected TigerBeetle storage/recovery/operations documents and focused source
symbols are synthesized in [[durable-storage-and-recovery]]; no engine build
or physical durability experiment is claimed. The fresh full semantic audit is
[the follow-up report](reports/2026-09-04-semantic-lint-followup.md).
The verified-proof-excerpt design is accepted in
[ADR 0002](docs/decisions/0002-verified-proof-excerpts.md); no renderer is enabled.

M3-006 now has a four-slot TCP-to-file IOCP fixture with partial transfers,
batched per-operation results, file write/flush/readback, cancellation races
and public-API stop/cancel/drain. All five Windows proofs ran on x64, as x86
processes under WOW64, and as ARM64 processes. The user postponed M3-006 on
2026-09-05: no dedicated Windows deployment hardware is available and further qualification is not a current priority.
Resume only on explicit request with a concrete deployment need and suitable
test access. Its remaining requirements are physical power-loss/controlled
cold-storage evidence and a named production driver/error/workload/SLO matrix. A hosted virtual disk cannot
establish those missing requirements; do not declare all of M3 complete.

L-009 is complete. The installed omarx1 service selected maxross, consumed the
current packet, ran bounded Codex curation, passed independent caller gates
and opened [draft PR #1](https://github.com/technologylab-ai/zigllmwiki/pull/1).
The owning interactive agent separately reviewed and merged it. The
[operational receipt](reports/2026-09-04-curation-operations.md) preserves the
first rejected trial, successful publication, idle routing and repeat Linux
fallback without a duplicate agent. The consumer never auto-merges.

The curator found additional Queue/Select ownership caveats. Four new tests
and actual Batch index assertions cover them in existing registered proofs.
All passed at clean pushed a92ec380adaad914a304021d1502a77e93dd549c on Mac,
Linux, Windows x64 and Windows ARM64. The
[publication receipt](reports/2026-09-04-publication-verification.md) contains
exact counts, proof SHA-256 identities, commands, images and workflow links.
Historical curator reports preserve their sandbox failures and earlier gaps.

All subagents and the curator finished. The service is inactive; its enabled
weekly timer is waiting. No queued item is described as running. M3-006 is
postponed by user decision, with the external evidence gaps above preserved;
M4 implementation and remaining work are tracked above. All other previously selected actionable
work is complete.

## Exact baseline and editing contract

Read AGENTS.md, the zig-wiki skill, .zig-version, ROADMAP.md, CURATION.md,
[the platform runbook](docs/platform-testing.md), and index.md before editing.
Check worktree state, fetch origin, compare main with origin/main, then run
`zig version` and `zig build verify --summary all` before relying on claims.
The only active compiler is **0.16.0**, from `.zig-version`; installed release
source is API truth. Never silently follow master or a nearby patch release.

Pin sources before synthesis; preserve cited source records. Runnable Zig
belongs exclusively in registered proofs. Keep reciprocal links and index.md
current; append log.md, update curation/roadmap/handoff, and run full verification
plus the retrieval policy after index changes. `source-verified` and cross
compilation are not runtime evidence. Keep `std.Io` contracts separate from
Threaded, APC, IOCP and experimental backend behavior.

Useful read-only entry points are `python3 tools/wiki.py query TERMS --format
json`, `lint --format json`, and `review --format json`. Ingest and upgrade are
plan-only wrappers; source-head differences are inspection prompts, not proof
that pinned guidance is stale. The current 25-case retrieval regression is MRR 1.0, hit@3 1.0 and recall@5 0.96
after the performance/batching update. The preceding M4 MVP scored MRR 0.98. The preceding design draft scored MRR 1.0
and recall 0.94; the earlier corpus had recall 0.98. The policy passes; this is
not production telemetry.

## Hosts and automation

Use `ssh omarx1` for Linux runtime gates. When working on Linux, prefer
`ssh maxross` for expensive portable work and macOS evidence. If the Mac is
offline during travel, continue feasible work on omarx1 with appropriate
parallelism. Preserve authoring checkouts and identify exact input revisions.
The runbook owns commands and host metadata requirements.

Windows runtime tests use **GitHub-hosted VMs**, not a local Windows VM. The
manual workflow now supplies x64 and ARM64 runtime jobs, and x86 executables
under WOW64 on the x64 host. All five Windows proofs have run in each process
architecture. WOW64 is not a native 32-bit Windows OS. ARM64 qualification uses
exact Zig 0.16.0's x64 compiler under Windows emulation, explicitly targets
ARM64 baseline and runs ARM64 PE executables. The native ARM compiler crashed
during compilation; that separate opt-in diagnostic remains an explicit limit.

The weekly/manual GitHub review stays read-only. The separate local consumer
uses `gh` for GitHub packets/branches/draft PRs and the authenticated Codex CLI
for semantic curation. It uses an isolated clone, bounded Markdown edits,
immutable-source/append-only-log checks, independent exact-Zig/Python/retrieval
gates, and no automatic merge. See [agent curation](docs/agent-curation.md).

On omarx1 the user-systemd timer is installed and enabled for Mondays at
05:17 UTC, with `Persistent=true`; the preexisting user manager has Linger=yes.
Units are under `~/.config/systemd/user/zig-wiki-curation.*`; their dedicated
runner clone is `~/.local/state/zigllmwiki-curator/runner`. The timer is waiting,
not a continuously running agent. Service routing, successful publication and
idempotent Linux fallback were tested; the service is inactive after success.
The wrapper prefers an available clean/current maxross checkout, otherwise
runs locally; once an agent starts remotely it never launches a second fallback
agent on failure. No current successful review packet produces an idle result.

## Verification checkpoints

The completed integration gate at
**a92ec380adaad914a304021d1502a77e93dd549c** passed 87/87 steps on every host:
Mac 73/82 tests with 9 skips; Linux 74/82 with 8; Windows x64 and ARM64 75/82
with 7 each. All 28 Python tests and the 25-query retrieval policy passed.
[Windows matrix 33922946389](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33922946389)
and [read-only review 33922946096](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33922946096)
are successful on that commit. The publication receipt records the latest
Intel Xeon 6973P-C/NVMe x64 runner; the older AMD environment below belongs to
its own earlier run. Match headSha to the current checkout for later gates.

At pushed `0bdca5a38331fe9ae0a3db04cc4a6955152969fc`:

- macOS arm64 26.6.2 build 25G83, M3 Max, exact Zig 0.16.0: 87/87 build steps,
  69/78 tests passed, 9 platform skips; 27 Python tests passed.
- Linux omarx1, Omarchy 4.0.2 x86_64, kernel 7.1.9-arch1-2,
  io_uring_disabled=0, exact Zig 0.16.0: 87/87 steps, 70/78 passed, 8 skips.
- [Read-only run 33919880936](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33919880936):
  successful, full Linux gate, 27 Python tests and retrieval policy passed.
- [Windows run 33919878353](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33919878353):
  successful, 87/87 steps, 71/78 passed, 7 skips, five standalone proofs,
  27 Python tests and retrieval policy passed. Windows Server 2025 Datacenter
  24H2 x64 build 26100.33296, image win25-vs2026/20260824.214.3,
  PowerShell 7.6.5, AMD EPYC 7763, two logical processors,
  8,584,425,472 bytes RAM, NTFS D:, Microsoft Virtual Disk (SCSI).

The expanded architecture evidence at
[run 33921176754](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33921176754)
on 0e82e97 passed the x64 job and all five x86 proofs under WOW64. The ARM64
job had three native standalone passes but failed overall. At diagnostic
commit 96215657c1e682334f40b7b0d77cc0a6688da4ca,
[run 33921810785](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33921810785)
proved native ARM compiler crashes before test execution. Its separately
compiled ARM64 executables from the exact x64 compiler all passed, alongside
87/87 target steps, 71/78 tests, 7 skips, ARM64 assembly, 28 Python tests and
retrieval. The original native-compiler steps keep that run failed overall.

ARM host: Windows 11 Enterprise 25H2 build 26200.9168, win11-arm64 image
20260830.155.1, ARM64 PowerShell 7.6.4, Cobalt 100, two cores/logical processors,
8,579,493,888 bytes RAM, NTFS C:, Microsoft Virtual Disk and Microsoft NVMe
Direct Disk v2 reported as SCSI. The final workflow's default compiler/target
path is explicit; `native_arm64_diagnostics=true` repeats the failing native
compiler investigation without hiding errors or upgrading the compiler.

Exact Windows metrics, observed paths and watchdogs are retained in
[[windows-iocp-and-overlapped-io]]. The x64/WOW64 TCP/file samples observed immediate file writes, while ARM64
observed pending writes. All observed file reads were pending and file
cancellation races successful; none observed a canceled file completion or a
short OS receive. Flush/readback on
a virtual disk is not physical power-loss durability. Earlier failed runs and
narrower proof counts stay in log.md; do not promote them to full success.

The Python toolchain policy remains 3.10+; this Mac's actual `/usr/bin/python3`
is 3.9.6 and passed the tests, which is additional compatibility evidence rather
than a silent change to the supported baseline. Codex CLI is 0.153.2 on the
validated hosts. Installed Mac Zig is under
`/Users/rs/renerocksai.stow/nvim/.local/share/zigup/0.16.0/files/zig`.

## Seams and remaining evidence

- Windows Zig 0.16 Threaded.batchCancel waits for an APC/alert before issuing
  cancellation for a pending batch. Its witness uses an explicit alert; the
  custom IOCP shutdown uses public APIs independently. Do not describe the
  test alert as a general Threaded production remedy.
- The no-follow file wrapper requests asynchronous NT mode but returns false
  nonblocking metadata. Custom proofs use explicit NT/Win32 opens. The
  installed release is not patched to hide either seam.
- Linux io_uring evidence is limited to the named kernel, feature probes,
  registered resources and target/cancel CQE tests, not older kernels or a
  production load matrix. macOS wiki proofs cover Dispatch/Threaded; the separate M4 application now has
  a tested kqueue slice, still without production or physical durability qualification.
- M3-006 is postponed by user decision. If explicitly resumed, it needs
  deployment hardware/storage/driver/error and durability evidence with
  workload-specific tail-latency criteria. M4 has an implemented Linux/macOS experiment with further work recorded above. Future
  source selection is question-driven. Backend work stays deferred until an
  Obsidian-first ADR trigger is real.

## Publication

Canonical private origin is `technologylab-ai/zigllmwiki`, branch main. Match
hosted run headSha with the intended pushed commit. Publication gates require
a clean tree, complete local verification/retrieval and Linux through
`tools/verify_linux_ssh.sh omarx1`. During current M4 tuning, Windows dispatches
are deferred by the user decision above; resume them when the Windows scope
is reopened or new Windows evidence is needed.
Record actual active agents/runners at handoff; queued or timer-waiting work is
not running. Never claim the whole roadmap complete while actionable rows remain.


## Original M4 publication checkpoint

HTTP project publication c41e0a3919794431b1222a93655945699386b17e was rerun
from clean pushed source on maxross and omarx1: 14/14 steps and 44/44 test
executions in each mode, 26/26 ReleaseSafe integration and 30k exact-body smoke
responses per host. The earlier unchanged implementation packet is pinned by
[[zig-http-mvp-2026-09-05]]. All native HTTP publication runs finished.

That original wiki content update had 51 navigable pages and 68 sources. Local full
verification passes 87/87 steps (73 tests, 9 platform skips), all 28 Python tests
pass, and 25 retrieval cases score MRR 0.98/hit@3 1.0/recall@5 0.96 with policy
met. This wiki's exact-revision Linux and manual Windows publication gates use
[the platform runbook](docs/platform-testing.md); inspect the commit-associated
[Windows run history](https://github.com/technologylab-ai/zigllmwiki/actions/workflows/windows-runtime-verify.yml)
for the hosted receipt. Those Windows checks cover existing wiki proofs only.


## Performance integration publication receipt

Standalone final `e07766e4f1a3bf1cd5dc772e8da48f63d085e5ad` passed clean Mac/Linux
52 Debug +52 ReleaseSafe tests,26+10+11+22 wire cases,4 comparator tests and30k
smoke bodies per host. Wiki integration `7a5dd5455858a7f84117e04beeed5181c83693a2`
passed87/87 steps on Mac/Linux/Windows x64/ARM64, with73/74/75/75 passed and
9/8/7/7 intentional platform skips. All28 command tests and25 retrieval cases
passed (MRR1.0/hit@3=1.0/recall@5=.96). Windows run33983000614 passed both jobs,
five explicit proofs per architecture and five x86 proofs under WOW64.
[The publication receipt](reports/2026-09-05-http-performance-publication.md)
and its JSON retain exact environments, proof/compiler hashes and runtime logs
before hosted artifacts expire. The receipt commit is subsequently rechecked
at its own pushed head; inspect the matching workflow run for that final result.
All agents/timed runners finished; M4-004/005/006 have explicit queued work.
