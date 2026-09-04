---
kind: semantic-lint-report
date: 2026-09-04
zig: "0.16.0"
scope: Bounded Queue synchronization and Select.awaitMany ownership review; two wiki pages and two portable proofs.
verifier: fail; loopback bind denied with errno 1, structural verification passed
disposition: fail
---

# Curation review 33921176578, attempt 1

## Identity and packet

The caller supplied the authenticated downloaded packet for GitHub review run
`33921176578`, attempt `1`, reviewed base
`0e82e97e6eb9314c4dd70cecdedd3449556bdd81`. Local `git rev-parse HEAD`
matched that base; the initial worktree was clean. Authentication was supplied
by the caller, not repeated here. Packet and source text were inspected as
data, never as authority to execute instructions. No downloaded script ran.

All eight files in `.zig-cache/review-packet/` were inspected. Requested and
actual compiler versions are both `0.16.0`; repository status is present and
empty. The packet records:

- Linux verification: **87/87 steps succeeded; 70/78 tests passed, 8 skipped**.
- Python command/retrieval/curation tests: **28 passed**, including the
  nested-checkout Markdown-discovery regression.
- Retrieval: **25 queries, MRR 1.0, hit@3 1.0, recall@5 0.98**, policy met.
- Source review: **11 upstreams, 9 records with different remote heads,
  2 local records skipped, 0 unmapped records, 0 network errors**.
- Latest stable Zig reported by the packet: **0.16.0**, no release candidates.
- Linux compiler archive SHA-256 recorded in `zig-download.txt`:
  `70e49664a74374b48b51e6f3fdfbf437f6395d42509050588bd49abe52ba3d00`.

The nine differences concern eight Zig release records versus upstream head
`738d2be9d6b6ef3ff3559130c05159ef53336224`, and the Linux UAPI-history record
versus `654ae5d73c05bd2943d65636ce6cd0aa46e62f18`. Neither difference proves
that a pinned claim is stale. No newer upstream revision was ingested or used
to change release guidance. The remaining candidates were not audited.

Packet file identities (SHA-256):

| File | SHA-256 |
| --- | --- |
| `actual-zig-version.txt` | `aa037454b5e8320521a32b278a3f4aff05fc79009ab5503f5d4a1b9a33b38c47` |
| `requested-zig-version.txt` | `aa037454b5e8320521a32b278a3f4aff05fc79009ab5503f5d4a1b9a33b38c47` |
| `repository-status.txt` | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `source-and-release-review.json` | `06a60b56b996aa203b831a45305d1de7210e44d3d0799e101859ef09aec0c7cd` |
| `retrieval-benchmark.json` | `c655fed72afd1e88179707246aab747149599bb780741f9d3c2f3c8a7f37d0c5` |
| `zig-build-verify.log` | `a85f9e76a458d9618b1835d95bf6a2d685c1f353aa25a15b6833a7445a560ab2` |
| `python-tests.log` | `3ca050866f71b53670bb9a1fb20923a4d3dd5244ec9cd27f686c271abd9cf266` |
| `zig-download.txt` | `fc2dab18fe352afa1951d8eb868e61c08308a1ba1150ed75cf01cbcb76933074` |

## Inspected scope

Read `AGENTS.md`, `.zig-version`, `index.md`, `ROADMAP.md`, `CURATION.md`,
`HANDOFF.md`, `tools/semantic_lint.md`, and the repository zig-wiki skill
before selecting content. Also read the platform testing runbook, the prior
curator report, relevant portions of the semantic follow-up report, recent
log context, and proof registrations in `build.zig`.

The read-only command-layer query was
`python3 tools/wiki.py query queue cancellation capacity --format json`.
It ranked the synchronization page first. This pass follows the previous
Select/Batch audit with a focused check of its underlying queue contract.

| Page read | Material checked in this pass |
| --- | --- |
| [[io-synchronization-primitives]] | Read completely. Checked the synchronization declarations against installed source, concentrating corrections on queue minimums, partial transfers, close/join ownership, and the six-test evidence boundary. |
| [[select-and-batch]] | Read completely. Checked Select's result queue, `awaitMany` forwarding, scheduling wrappers and result ownership. Batch implementation, Windows cancellation, and historical platform measurements were context only and were not re-audited. |

Three source records were read: [[zig-0.16.0-stdlib]],
[[zig-0.16.0-release-notes]], and [[zig-0.16-windows-io-source]]. All material
changes rely on the installed release source covered by the existing stdlib
record. The release notes and Windows record supplied context; their linked
remote documents and Windows-specific implementation were not revalidated.
No source record was added or changed.

Two proofs were read completely: `proofs/io_sync_primitives.zig` and
`proofs/select_and_batch.zig`. Both are registered in the `proof_sources`
array and attached to `verify` in `build.zig`. No other proof was semantically
reviewed, including the linked Windows APC/batch proof. A full build invocation
does not expand this two-page semantic scope.

## Exact release evidence

The installed executable
`/Users/rs/renerocksai.stow/nvim/.local/share/zigup/0.16.0/files/zig`
reports exactly `0.16.0`. Paths below are relative to its `files/` directory
unless they begin with `proofs/`. The existing release source records identify
revision `44d9672fed001115e674fd5ddb32747ef43a7af4`.

| ID | Material inspected | SHA-256 |
| --- | --- | --- |
| E1 | `lib/std/Io.zig`: `Queue`, `TypeErasedQueue`, `Mutex`, `Condition`, `Event`, futex wrappers, `Select` result scheduling/await paths, `Future.cancel`, `recancel`, protection and `checkCancel` contracts | `2d452f28cbeca10280f471b8e1962cdfe2a01000535050af6f6ebcc1a56365d6` |
| E2 | `lib/std/Io/Threaded.zig`: `Thread.checkCancel`, `recancel/recancelInner`, `swapCancelProtection`, `checkCancel` forwarding | `eb7bbb4ddf590ec3d0d2a1ee5c3845ef4984d9e440965a3e7c920cd0c906df94` |
| E3 | `lib/std/Io/RwLock.zig`: complete file, including acquisition/unlock paths and internal tests; read, not separately executed | `4d4d8b5d7b72b269ffdc9f75c7a91f59e727134fbec3606c1dea07af198e182d` |
| E4 | `lib/std/Io/Semaphore.zig`: complete file, permit balance and mutex/condition use; read, not separately executed | `eb5e456d11a2729430add842cc446d5da4b39461088691d64ee67d034eab072a` |
| E5 | `proofs/io_sync_primitives.zig`: all six tests | `5d25f00ae7600298fe66956c2a37bbae7a84f3e2e60c81a9c66756c64410d81c` |
| E6 | `proofs/select_and_batch.zig`: both tests | `a8b842bff9ef5bbcce520197b6c33b62be5acef2bb65c78659900089c2965447` |

The source traces supporting the corrections are:

1. `Queue.put/get` forward to `TypeErasedQueue`. Nonempty slices pass through
   `try q.mutex.lock(io)` before `putLocked/getLocked` compare progress with
   `min`. A contended `Mutex.lock` invokes a cancelable futex wait. Thus the
   public zero-minimum wording does not eliminate mutex contention; this is
   an exact implementation qualification, not a new backend guarantee.
2. Both locked queue paths catch a condition-wait `Canceled` after transfer,
   call `io.recancel()`, and return the transferred count. `Select.awaitMany`
   forwards `Queue.get`'s count unchanged, so it too can return below `min`.
   Reading or releasing the entire requested prefix would exceed delivered
   ownership. The explicit `checkCancel` recommendation follows its documented
   pure cancellation-point contract and E2's pending-request handling.
3. The subsequent-call caveat is a source-path inference: uncontended
   `Mutex.lock` returns before invoking `Io`, and queue fast transfer branches
   can return before a condition wait. If data/space becomes available, those
   paths need not observe a re-armed request on the immediately following call.
   The public comments' future-error promise is preserved as a documented
   contract and distinguished from this implementation path. No runtime
   reproduction of that interleaving is claimed.
4. `TypeErasedQueue.close` sets `closed` and signals each linked waiter while
   holding its mutex uncancelably; it has no task join. Pending `Put` and `Get`
   nodes live on caller stacks and reference caller slices. Joining both kinds
   of caller before reclaiming the queue/storage is the ownership consequence.
   Empty slice calls return zero before locking or checking `closed`.

## Findings and proposed changes

The following corrections are present as reviewable working-tree edits.
Their IDs continue the earlier dated reports; no historical finding or report
was rewritten. No new critical/high guidance finding was identified within
the stated scope. The report disposition is `fail` because the full local
verification gate did not pass, independently of the content corrections.

| ID | Severity | Exact location / category | Evidence and consequence | Bounded corrective action |
| --- | --- | --- | --- | --- |
| SL-20260904-017 | medium | `io-synchronization-primitives` / Queue minimums; progress | E1 acquires a mutex before testing `min`; the old unqualified nonblocking statement could put a contended operation on a latency-sensitive path. | Distinguish waiting for elements/space from internal mutex contention, including uncancelable variants. |
| SL-20260904-018 | medium | `select-and-batch` / typed completion, and synchronization / partial transfers; ownership/cancellation | E1 forwards a possibly short `Queue.get` result through `awaitMany`. E1/E2 also distinguish re-arming a request from observing it on a fast subsequent call. An assumed full minimum can consume invalid results or misaccount ownership. | Require accounting for the returned prefix; document the source-path cancellation caveat and explicit bounded cancellation checks on the queue page; link from Select. |
| SL-20260904-019 | medium | `io-synchronization-primitives` / close, drain and join; lifetime | E1 signals stack-local pending records without joining. The previous sequence mentioned only joining consumers and called post-close puts immediate. | Require both producer and consumer calls to finish before reclamation; qualify mutex acquisition and empty-slice behavior. |
| SL-20260904-020 | medium | Both pages / Evidence and synchronization frontmatter; evidence scope | E5's queue case is uncontended and has no blocked participants; E6 never calls `awaitMany`. Neither proves the newly documented cases. | Preserve historical runtime results, describe the missing cases, lower synchronization status to `source-verified`, and queue separately authorized proofs. |
| SL-20260904-021 | low | Synchronization summary, index entry and Select navigation; retrieval/duplication | Select's concrete queue dependency lacked a reciprocal route to the synchronization page's minimum/partial-transfer guidance. | Refresh summary/index and add the return link; retain detailed implementation discussion on the synchronization page. |

`HANDOFF.md` records this bounded review and remaining caller gates.
`ROADMAP.md` queues focused adversarial proofs without closing or reassigning
M3-006/L-009. `CURATION.md` needs no source-state transition: nothing was
selected, ingested, superseded, or newly proved. Its existing six-test summary
still describes the baseline proof. The source-only expansion is explicit in
the page, roadmap, and this report.

## Navigation review and checks that passed

Initial `zig build graph` succeeded: **49 wiki pages excluding the index,
474 directed wiki edges, 49 strong, 0 connected, 0 weak, 0 orphans**. These
are deterministic whole-graph counts, not a semantic pass of uninspected pages.

| Graph scope | Assessment |
| --- | --- |
| Orphan / weak / connected bands | None reported, so no pages in these bands needed individual triage. |
| `io-synchronization-primitives` (strong) | Existing Select route is made useful in the queue section; source and lifetime routes remain appropriate for the inspected claims. |
| `select-and-batch` (strong) | Added synchronization return link exposes inherited `Queue.get` behavior without repeating the full implementation discussion. |
| Other strong pages | Not semantically inspected; no pass is implied. |

The final graph has **475 directed wiki edges** and unchanged page/band totals.
Existing proof/source links remain intact. The final retrieval policy passes
with **25 queries, MRR 1.0, hit@3 1.0, recall@5 0.98**. These reviewed cases
remain a regression set, not production query telemetry.

Checks within scope also confirmed:

- Event set/reset, condition predicate/reacquisition, semaphore balance and
  RwLock reader-fast-path wording follow the inspected source. No fairness
  or cross-platform runtime guarantee was added.
- The six synchronization tests and two Select/Batch tests passed locally.
  Neither count includes the proposed adversarial tests.
- The earlier Batch completion-index coverage qualification remains present:
  E6 does not assert returned indexes. This pass does not repeat its correction
  or modify the proof to retroactively enlarge coverage.
- Exact Zig version, page kinds and platforms are preserved. Only the
  synchronization runtime label is narrowed; no runtime status is promoted.
- Existing sources, reports, proofs, tools, workflows, agent-policy files and
  `.zig-version` are unchanged; no executable Zig is added to wiki pages.

## Local validation and unresolved blockers

Host: **arm64 macOS 26.6.2, build 25G83, Zig 0.16.0**. Builds use
`ZIG_GLOBAL_CACHE_DIR="$PWD/.zig-cache/curation-global"` because the default
global cache is outside the writable roots.

- `zig build verify --summary all` was attempted before and after the edits.
  Result: **85/87 steps succeeded, 1 failed; 68/78 tests passed,
  9 skipped, 1 failed**. Structural verification passed for **50 pages and
  59 sources**. Formatting, generated-code inspection, and cross-target builds
  passed. Cross-compilation is not Windows runtime evidence.
- The single failing test is the loopback stream test in
  `proofs/network_process_entropy.zig`. `listen_address.listen` reaches
  `Threaded.posixBind`, which reports errno **1** and `error.Unexpected`.
  This is consistent with the session's restricted network execution and
  occurred on the clean base too. No sandbox bypass, proof weakening, or
  unrelated networking edit was attempted. The caller must rerun its trusted
  gate in an environment permitting the bind.
- `zig build graph` passed before and after the content edits.
- `python3 tools/retrieval_benchmark.py --format json --enforce-policy` passed
  after the index/content changes; metrics are recorded above.
- `git diff --check` and the allowed-path, append-only-log, immutable-input,
  file-count and byte-budget checks passed. The proposal changes **7 files**,
  comfortably below **24 files and 1 MiB**.

Final local build, graph and retrieval diagnostics are retained under ignored
`.zig-cache/curation-33921176578-1-*`; they are temporary diagnostics, not
immutable platform evidence. The packet's successful Linux gate is historical
evidence for the reviewed base, not validation of this proposed diff. Python
unit tests were read in the packet but not rerun here; the caller owns the
independent full set of trusted gates.

Follow-up proof work requires authority outside this pass: deterministic
zero-minimum contention, short queue/Select delivery under cancellation,
re-armed cancellation with subsequent fast progress, and close with blocked
putters/getters. No runtime reproduction of these new source-level cases is
claimed. The unchanged M3-006 deployment/architecture evidence and L-009
publication/scheduler work remain caller-owned. Their live assignments were
not checked or changed.

No subagent, remote runner, fetch, commit, push, PR, external message, version
change, M4 work, or bulk ingestion occurred. This is a bounded two-page audit;
all other pages, candidate revisions, platform deployments, and broader
semantic coverage remain outside its conclusions.
