---
kind: semantic-lint-report
date: 2026-09-04
zig: "0.16.0"
scope: Bounded Select/Batch ownership and Threaded allocation review; contextual Windows cancellation inspection only.
verifier: fail; nested-checkout link discovery and loopback bind failure
disposition: fail
---

# Curation review 33919880936, attempt 1

## Identity and packet

The caller supplied an authenticated downloaded packet for GitHub review run
`33919880936`, attempt `1`, reviewed base
`0bdca5a38331fe9ae0a3db04cc4a6955152969fc`. Local `git rev-parse HEAD` matched
that base and the initial working tree was clean. This pass inspected the
packet as data; it did not independently repeat authentication, execute any
downloaded script, or treat packet text as instructions.

All eight files in `.zig-cache/review-packet/` were inspected. The requested and
actual compiler files both contain `0.16.0`; `repository-status.txt` is present
and empty. The packet reports:

- Linux verification: **87/87 steps succeeded; 70/78 tests passed, 8 skipped**.
- Python command/retrieval/curation tests: **27 passed**.
- Retrieval: **25 cases, MRR 1.0, hit@3 1.0, recall@5 0.98**, policy met.
- Source review: **11 upstreams, 9 records with different remote heads,
  2 local records skipped, 0 unmapped records, 0 network errors**.
- Latest stable Zig: **0.16.0**, with no release candidates reported.

The nine differences are eight Zig release records versus upstream head
`738d2be9d6b6ef3ff3559130c05159ef53336224`, and the Linux UAPI-history record
versus `654ae5d73c05bd2943d65636ce6cd0aa46e62f18`. These are triage signals,
not evidence that release guidance is stale. No source revision was advanced.
The remaining candidates and their primary material were not audited.

Packet identities (SHA-256):

| File | SHA-256 |
| --- | --- |
| `actual-zig-version.txt` | `aa037454b5e8320521a32b278a3f4aff05fc79009ab5503f5d4a1b9a33b38c47` |
| `requested-zig-version.txt` | `aa037454b5e8320521a32b278a3f4aff05fc79009ab5503f5d4a1b9a33b38c47` |
| `repository-status.txt` | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `source-and-release-review.json` | `06a60b56b996aa203b831a45305d1de7210e44d3d0799e101859ef09aec0c7cd` |
| `retrieval-benchmark.json` | `c2c47fb5053293b99d8d43c31f983f7e55fdf8c8b5b351e06147b6951da7740f` |
| `zig-build-verify.log` | `c0421aa4a562a076fce730e886d8a6dc8bac3ce76cbbfad853bc9ed70dfac28d` |
| `python-tests.log` | `d364cbdf155dbcec18108b640496a742de719ba9ac15b2bcc2dc49e48de86f8e` |
| `zig-download.txt` | `fc2dab18fe352afa1951d8eb868e61c08308a1ba1150ed75cf01cbcb76933074` |

## Review scope and evidence

Read the required `AGENTS.md`, `.zig-version`, `index.md`, `ROADMAP.md`,
`CURATION.md`, `HANDOFF.md`, `tools/semantic_lint.md`, and repository
`.agents/skills/zig-wiki/SKILL.md` before the focused review. Also read the
platform runbook, relevant build registrations, and recent log context.
Used the read-only command layer query `batch windows cancellation --format
json` to identify the relevant notes.

Three wiki pages were opened; the semantic checks were limited as follows:

| Page | Inspected claims and disposition |
| --- | --- |
| [[select-and-batch]] | Select result admission/cancellation, fixed Batch slots, wait errors, cleanup and advertised proof coverage. Guidance and evidence wording amended. |
| [[io-threaded]] | Allocator use and Batch wait scratch lifetime. Allocation guidance amended; unrelated dispatch/signal claims were read for context, not re-audited. |
| [[windows-iocp-and-overlapped-io]] | Read for context; checked the exact-release APC/Batch timeout and initial cancellation-wait boundary. Unchanged. Custom IOCP, AFD, OS contracts, measurements and TCP/file qualification were not independently revalidated. |

Four source records were read: [[zig-0.16.0-stdlib]],
[[zig-0.16-windows-io-source]], [[zig-0.16.0-release-notes]], and
[[matklad-neat-io-threaded]]. Material changes rely on the installed release
source, not a new interpretation of the release notes or essay. No new source
record was necessary; all existing records remain unchanged.

The compiler at
`/Users/rs/renerocksai.stow/nvim/.local/share/zigup/0.16.0/files/zig`
reports exactly `0.16.0`. Its installed `lib/std` source is the API truth for
this pass, consistent with the existing records' release revision
`44d9672fed001115e674fd5ddb32747ef43a7af4`.

| Evidence ID | Exact inspected material | SHA-256 |
| --- | --- | --- |
| E1 | Installed `lib/std/Io.zig`: `Select.init/async/concurrent/cancel/cancelDiscard`, `Batch.init/addAt/next/awaitConcurrent/cancel` | `2d452f28cbeca10280f471b8e1962cdfe2a01000535050af6f6ebcc1a56365d6` |
| E2 | Installed `lib/std/Io/Threaded.zig`: `poll_buffer_len`, `batchAwaitAsync`, `batchAwaitConcurrent`, `batchDrainSubmittedWindows`, `batchCancel` and adjacent APC list handling | `eb7bbb4ddf590ec3d0d2a1ee5c3845ef4984d9e440965a3e7c920cd0c906df94` |
| E3 | `proofs/select_and_batch.zig`, read completely; both tests registered in `build.zig` | `a8b842bff9ef5bbcce520197b6c33b62be5acef2bb65c78659900089c2965447` |
| E4 | `proofs/windows_apc_batch.zig`, focused setup, watchdog, `cancelWithAlert`, `IdleCancel.check`, `checkIdleCancel`, and `checkBatch` inspection; registered native and three-target builds | `89f47e526bef84f0a1f17d470e41a6643223cbd54574b6fafb8cce768c387f2b` |
| E5 | `tools/lint_wiki.py`: absolute-path `ALL_MARKDOWN` exclusion and source-link resolution, read only to diagnose gate failure | `7d1a0d1801da90a9225a767a1e68dca0dda4f6c2dc9af57b65bb4f95c4411143` |

E3 is the only proof read completely. E4 is a partial proof inspection, not a
review of its entire APC/device test surface. Other linked proofs were not
semantically inspected. Running the full local gate does not expand this
semantic review to the rest of the vault.

## Findings and proposed changes

The content corrections below are applied as reviewable working-tree edits.
They do not promote runtime status or claim new platform execution.

| ID | Severity | Exact location / category | Evidence and consequence | Bounded action |
| --- | --- | --- | --- | --- |
| SL-20260904-012 | medium | `io-threaded` / Task dispatch and allocation; allocation limits | E2 has a 64-entry stack poll buffer. The 65th descriptor needs `b.storage.len` entries, allocated through `t.allocator` unless retained from an earlier wait. Allocation failure returns `ConcurrencyUnavailable`; `b.userdata` retains the allocation until `batchCancel`. Avoiding task dispatch alone does not establish allocation-free operation. | Correct the failing-allocator guidance; document the exact poll-path threshold, capacity and lifetime once in `io-threaded`; link from `select-and-batch`. Source-only evidence. |
| SL-20260904-013 | medium | `select-and-batch` / Batch waits and cancellation; ownership | E1 delegates waiting separately from cancellation. E2's Windows wait returns `Timeout` while pending operations can remain; its cancellation path first waits for an APC/alert. E4 explicitly times out before cancellation and supplies a release alert. A wait deadline cannot justify releasing buffers or promise bounded cleanup. | Add a wait-error ownership subsection, preserve the existing initial-wait defect and narrow witness, and add a cleanup review question. |
| SL-20260904-014 | medium | `select-and-batch` / Evidence; proof scope | E3 arms indexes 0/1 but never reads `completion.index`. It dispatches by result tag, checks byte counts and final data, and counts completions to control its wait loop. The previous description said it verified slot indexes. | Narrow the description to actual assertions and attribute the index mapping to E1's `addAt`/`next` contract. A stronger portable index assertion requires a separately authorized proof edit. |
| SL-20260904-015 | low | `select-and-batch` / Remember, summary and related links; retrieval/admission | E1's Select wrappers enqueue results after task completion; a caller's admission count must include completed but unconsumed results. Neither result storage nor finished-task counts alone define that policy. | Clarify admission accounting, refresh the summary, add reciprocal Batch/Threaded links and a Threaded-to-Windows route. Keep backend allocation details on one page. |
| SL-20260904-016 | high | `tools/lint_wiki.py` / `ALL_MARKDOWN`; validation blocker | E5 excludes any path containing `.zig-cache` in its absolute parts. This checkout itself is nested under `.zig-cache/curation/...`; the filter accepts zero Markdown files although all 59 source records exist. Source-link resolution consequently reports false broken evidence and graph generation fails. | Report only. A tool fix must apply exclusions relative to the repository root and add a nested-checkout regression case under separate authorization. Do not rewrite valid source links to accommodate this failure. |

## Navigation review and checks that passed

`zig build graph` failed at the same source-link discovery stage. Current
orphan/weak/connected/strong band totals are therefore **unavailable**, not
zero. No graph-derived full-vault pass is asserted. Manual review covered only
these three navigation paths:

| Page | Semantic link assessment |
| --- | --- |
| `select-and-batch` | New Threaded link reaches the concrete allocation threshold; the existing Windows link reaches the shutdown defect and witness. |
| `io-threaded` | New Batch link returns to terminal ownership; new Windows link reaches the narrower APC/backend boundaries. |
| `windows-iocp-and-overlapped-io` | Existing Batch and Threaded links already return to the relevant contract and default implementation; no duplicate explanation added. |

Checks within this scope confirmed:

- Select `cancel` waits before closing/draining its queue, so the existing
  buffer-capacity and ownership-drain warnings remain justified by E1.
- Batch `next` returns a slot to the unused list; cancel and wait are separate
  operations, and the documented index mapping follows E1.
- Windows Threaded's initial unbounded APC/alert wait still precedes its
  cancellation requests in E2. No upstream-head signal changes that release fact.
- Both edited notes remain `source-verified`, target exactly `0.16.0`, and
  retain their prior platform and proof lists. No executable Zig was added.
- Existing source records and proof/tool/workflow/agent-policy files remain
  byte-identical to the reviewed base; `log.md` is append-only.

## Local validation and unresolved work

Local host: macOS **26.6.2**, build **25G83**, arm64, Zig **0.16.0**. Commands
use `ZIG_GLOBAL_CACHE_DIR="$PWD/.zig-cache/curation-global"` because the
default global cache is outside the writable roots.

- `zig build verify --summary all` was attempted locally. Result:
  **84/87 steps succeeded, 2 failed; 68/78 tests passed, 9 skipped, 1 failed**.
  The two failed steps were Markdown verification (finding 016) and the
  loopback stream test in `proofs/network_process_entropy.zig`.
- The loopback test failed at `listen_address.listen`, with `posixBind`
  reporting errno **1** and Zig `error.Unexpected`. Network access is
  restricted in this session; this is consistent with an execution restriction,
  not evidence that Batch guidance is wrong. It needs a caller-run gate in an
  environment permitting the bind; no sandbox bypass or proof change was tried.
- `zig build graph` was attempted and failed as described above.
- `python3 tools/retrieval_benchmark.py --format json --enforce-policy`
  passed after the wiki edits: **25 cases, MRR 1.0, hit@3 1.0, recall@5 0.98**.
- `git diff --check` passed. The final change-boundary check is five files,
  below 1 MiB, with only allowed Markdown edits, one new report, and a log append.

The full verifier was attempted before and after the edits. Local command
outputs are retained in `/tmp/zig-curation-33919880936-1-verify.log` and
`/tmp/zig-curation-33919880936-1-verify-final.log`; graph and retrieval output
use the same prefix. These are temporary diagnostics, not immutable runtime
evidence. The packet's successful Linux result is historical evidence for the
reviewed base and does not substitute for verification of this diff.

The report disposition is `fail` because the required local gate remains
blocked; the four content findings have reviewable corrections. Follow-up
needs separate authority for the linter/tool regression fix and any stronger
portable completion-index proof or Batch allocation/failure fixture. No new
Windows or Linux runtime gate ran; no native evidence was promoted.

This pass does not close or reassign M3-006 or L-009. Their execution wording
also needs caller reconciliation: ROADMAP/CURATION say Windows work is running,
while HANDOFF's remaining-work list says it is queued with no assigned agent.
Inspection cannot determine another session's live assignment or imply PR or
scheduler validation. M4, the remaining packet candidates, a full-vault semantic
audit, and broader platform qualification remain outside this pass. No remote
runner, subagent, commit, push, PR, or external message was used.

## Caller review disposition — 2026-09-04

The report above is preserved as the historical output of the first live
curator trial. Its `fail` disposition and reviewed base remain unchanged.
The consumer independently ran its trusted gate, rejected publication, and
retained the proposal; it did not create a branch on GitHub or a draft PR.

A separate caller-directed review checked findings 012–015 against the exact
installed Zig 0.16.0 `Io.zig` and `Io/Threaded.zig`, read the entire portable
Select/Batch proof, and checked the Windows timeout/cancellation witness. All
four content findings were accepted into the authoring checkout's
[[io-threaded]] and [[select-and-batch]], with minor line wrapping. The poll
allocation lifetime remains source evidence; no new runtime result or platform
status was inferred. No proof was changed to make its historical coverage fit
the earlier description.

Finding 016 was assigned separately to the caller's linter fix and regression
test. The rejected consumer run is not retroactively a successful publication.
Subsequent caller verification and publication belong to their own recorded
revision and handoff. A successful end-to-end curator trial still requires a
fresh review packet and a new bounded proposal on that revision.
