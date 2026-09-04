# Project handoff — 2026-09-04

This is the durable entry point for a fresh session. ROADMAP.md owns scope and
status; historical log entries and reports retain narrower and failed runs.

## Scope and completed work

The user requested completion of actionable wiki work, reserving M4 for a
separate in-depth session. M0, M1, M2, and M3-001 through M3-005 are complete.
The wiki covers the targeted public `std.Io` surface, all 71 pinned TigerStyle
principles, the selected matklad corpus, and platform backend selection.
Selected TigerBeetle storage/recovery/operations documents and focused source
symbols are synthesized in [[durable-storage-and-recovery]]; no engine build
or physical durability experiment is claimed. The fresh full semantic audit is
[the follow-up report](reports/2026-09-04-semantic-lint-followup.md).
The verified-proof-excerpt design is accepted in
[ADR 0002](docs/decisions/0002-verified-proof-excerpts.md); no renderer is enabled.

M3-006 has an implemented four-slot TCP-to-file IOCP fixture with partial
transfer handling, batched per-operation results, file write/flush/readback,
cancellation races and public-API stop/cancel/drain. Native x64 passed; ARM64
and WOW64 runtime gates are the next active validation work. Hosted VMs cannot
supply physical power-loss evidence or a named deployment's driver/storage/SLO
qualification. Preserve these limits rather than declaring all of M3 complete.

L-009's consumer and scheduler are implemented. The first live curator trial
correctly retained an unpushed proposal when the caller verifier exposed an
absolute-path cache-filter bug in the linter. The fix and regression are now
implemented; a new packet and successful draft-PR trial remain required.

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
1.0, hit@3 1.0 and recall@5 0.98; this is not production telemetry.

## Hosts and automation

Use `ssh omarx1` for Linux runtime gates. When working on Linux, prefer
`ssh maxross` for expensive portable work and macOS evidence. If the Mac is
offline during travel, continue feasible work on omarx1 with appropriate
parallelism. Preserve authoring checkouts and identify exact input revisions.
The runbook owns commands and host metadata requirements.

Windows runtime tests use **GitHub-hosted VMs**, not a local Windows VM. The
manual workflow now defines native x64 and ARM64 jobs, and x86 executables
under WOW64 on the x64 host. Until those new jobs complete, x86/ARM64 remain
compile-only evidence. WOW64 is not a native 32-bit Windows OS.

The weekly/manual GitHub review stays read-only. The separate local consumer
uses `gh` for GitHub packets/branches/draft PRs and the authenticated Codex CLI
for semantic curation. It uses an isolated clone, bounded Markdown edits,
immutable-source/append-only-log checks, independent exact-Zig/Python/retrieval
gates, and no automatic merge. See [agent curation](docs/agent-curation.md).

On omarx1 the user-systemd timer is installed and enabled for Mondays at
05:17 UTC, with `Persistent=true`; the preexisting user manager has Linger=yes.
Units are under `~/.config/systemd/user/zig-wiki-curation.*`; their dedicated
runner clone is `~/.local/state/zigllmwiki-curator/runner`. The timer is waiting,
not a continuously running agent. Service routing validation is still pending.
The wrapper prefers an available clean/current maxross checkout, otherwise
runs locally; once an agent starts remotely it never launches a second fallback
agent on failure. No current successful review packet produces an idle result.

## Verification checkpoints

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

Exact Windows metrics, observed paths and watchdogs are retained in
[[windows-iocp-and-overlapped-io]]. The TCP/file sample observed immediate file
writes, all file reads pending, and successful file cancellation races; it did
not observe a canceled file completion or a short OS receive. Flush/readback on
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
- M3-006 needs deployment hardware/storage/driver/error and durability evidence
  with workload-specific tail-latency criteria. M4 remains reserved. Future
  source selection is question-driven. Backend work stays deferred until an
  Obsidian-first ADR trigger is real.

## Publication

Canonical private origin is `technologylab-ai/zigllmwiki`, branch main. Match
hosted run headSha with the intended pushed commit. Publication gates require
a clean tree, complete local verification/retrieval, Linux through
`tools/verify_linux_ssh.sh omarx1`, and the manual Windows matrix on that commit.
Record actual active agents/runners at handoff; queued or timer-waiting work is
not running. Never claim the whole roadmap complete while actionable rows remain.
