# Project handoff — 2026-09-05

This is the durable entry point for a fresh session. ROADMAP.md owns scope and
status; historical log entries and reports retain narrower and failed runs.

## Current M4 MVP

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
performance, M4-005 Windows HTTP and M4-006 API/scheduling/copy/fault experiments
remain queued; M3-006 remains postponed. All implementation/review subagents
finished. No competitor or Windows HTTP runner has been started. Wiki Windows
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
that pinned guidance is stale. The 25-case retrieval regression remains MRR
1.0, hit@3 1.0 and recall@5 0.94 after expanding the M4 draft (previously
0.98 before M4 and 0.96 after its initial notes). The policy still passes; this is not production telemetry.

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
  production load matrix. macOS evidence covers Dispatch/Threaded proofs, not
  a product kqueue reactor or physical durability.
- M3-006 is postponed by user decision. If explicitly resumed, it needs
  deployment hardware/storage/driver/error and durability evidence with
  workload-specific tail-latency criteria. M4 design is open; implementation
  remains queued. Future
  source selection is question-driven. Backend work stays deferred until an
  Obsidian-first ADR trigger is real.

## Publication

Canonical private origin is `technologylab-ai/zigllmwiki`, branch main. Match
hosted run headSha with the intended pushed commit. Publication gates require
a clean tree, complete local verification/retrieval, Linux through
`tools/verify_linux_ssh.sh omarx1`, and the manual Windows matrix on that commit.
Record actual active agents/runners at handoff; queued or timer-waiting work is
not running. Never claim the whole roadmap complete while actionable rows remain.


## M4 publication checkpoint

HTTP project publication c41e0a3919794431b1222a93655945699386b17e was rerun
from clean pushed source on maxross and omarx1: 14/14 steps and 44/44 test
executions in each mode, 26/26 ReleaseSafe integration and 30k exact-body smoke
responses per host. The earlier unchanged implementation packet is pinned by
[[zig-http-mvp-2026-09-05]]. All native HTTP publication runs finished.

The wiki content update has 51 navigable pages and 68 sources. Local full
verification passes 87/87 steps (73 tests, 9 platform skips), all 28 Python tests
pass, and 25 retrieval cases retain MRR 1.0/hit@3 1.0/recall@5 0.94 with policy
met. This wiki's exact-revision Linux and manual Windows publication gates use
[the platform runbook](docs/platform-testing.md); inspect the commit-associated
[Windows run history](https://github.com/technologylab-ai/zigllmwiki/actions/workflows/windows-runtime-verify.yml)
for the hosted receipt. Those Windows checks cover existing wiki proofs only.
