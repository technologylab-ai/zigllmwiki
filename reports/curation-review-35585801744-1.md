---
kind: semantic-lint-report
date: 2026-09-28
zig: "0.16.0"
scope: Bounded Threaded dispatch review; two guidance pages, four source records, one proof, and two adjacent navigation checks.
verifier: "Not run: sandbox denied the required shared-host process inspection. Structural lint and retrieval checks are recorded below."
disposition: pass-with-findings
---

# Curation review 35585801744, attempt 1

## Identity and packet

The caller supplied the authenticated packet for [review run 35585801744](https://github.com/technologylab-ai/zigllmwiki/actions/runs/35585801744), attempt `1`.
The reviewed base is `a48ddf3ce6d956b4f7e1e0db6a7a31e403c0d27f`.
Local `HEAD` matched that base, and the initial worktree was clean.
The caller supplied authentication; this pass did not repeat authentication.
Packet and source text served only as evidence.
No downloaded script ran.

The eight files under `.zig-cache/review-packet/` were inspected as text or parsed JSON.
Requested and actual Zig versions both read `0.16.0`.
The repository-status file exists and contains zero bytes.
The packet records these results for the reviewed base:

- Linux verification: 87/87 steps; 74/82 tests passed, with eight skips.
- Python tests: 28 passed.
- Retrieval: 25 queries; MRR 0.98, hit@3 1.0, recall@5 0.96; policy passed.
- Source review: 14 upstreams; 58 records with different remote heads; zero network errors.
- Five local records were skipped; three remote records were unmapped.
- The release review reported no candidate beyond Zig 0.16.0.

These historical results do not verify the proposed diff.
Different upstream heads did not establish stale guidance.
The packet compared Zig's pinned release with head `738d2be9d6b6ef3ff3559130c05159ef53336224`.
The matklad comparison used head `e6f330a601b8c7336f12b81057ea967f8902904a`.
Those signals motivated inspection of existing Threaded guidance against the installed release.
This pass did not ingest either head or inspect their new commits.
Other candidate groups remain outside this bounded review, including all M4 material.

| Packet file | SHA-256 |
| --- | --- |
| `actual-zig-version.txt` | `aa037454b5e8320521a32b278a3f4aff05fc79009ab5503f5d4a1b9a33b38c47` |
| `requested-zig-version.txt` | `aa037454b5e8320521a32b278a3f4aff05fc79009ab5503f5d4a1b9a33b38c47` |
| `repository-status.txt` | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `zig-download.txt` | `fc2dab18fe352afa1951d8eb868e61c08308a1ba1150ed75cf01cbcb76933074` |
| `zig-build-verify.log` | `7f13e5608116dd438a6f8e6790f2b1eafea4a6c6e2c6476c84f237955cef20ad` |
| `python-tests.log` | `060ca474dbef826280a5db7cda114ccf9ab7ca520ee8cf70c4fcf7f2ed39971e` |
| `retrieval-benchmark.json` | `629eb25c1f14c5ca351a61803a2c7e114f5fdb3418b589b577feb37db86425a6` |
| `source-and-release-review.json` | `b10d484427260b10f28fae706c3e13937241dbf9164027410dcab68b5d05407d` |

## Inspected scope

The pass read all requested entry documents and the repository `zig-wiki` skill before packet inspection.
The pass also read the writing policy and platform runbook.
The read-only query was `python3 tools/wiki.py query async concurrent cancellation Threaded --format json`.
That query ranked `async-vs-concurrent` and `io-threaded` first and second.

| Page | Inspection boundary |
| --- | --- |
| [[io-threaded]] | Read the full page. Rechecked dispatch, limits, allocation order, and the dispatch proof's scope. Cancellation and Batch sections were not re-audited. |
| [[async-vs-concurrent]] | Read the full page and dispatch proof. Checked interface progress wording, implementation routing, and duplicated limit descriptions. |
| [[static-allocation-and-constant-work]] | Read for adjacent guidance. Checked only its Threaded allocation seam against installed source; other principles and M4 text were outside scope. |
| [[std-io]] | Read for navigation context. Checked the interface/implementation distinction; no broader semantic pass or edits. |

The page totals are two focused reviews and two adjacent context reads.
The evidence totals are four source records, two installed source files, one proof, and its build registration.
No conclusion applies to uninspected pages, claims, proofs, or upstream changes.

### Source records

| Record read | Pinned revision and use |
| --- | --- |
| [[zig-0.16.0-stdlib]] | Zig 0.16.0, `44d9672fed001115e674fd5ddb32747ef43a7af4`. Authority for every changed implementation claim. |
| [[zig-0.16.0-release-notes]] | Same Zig release revision. Existing release context; this pass did not fetch the release notes again. |
| [[matklad-neat-io-threaded]] | `ff6734c93ac8b41677dee016af6bb67c39420101`. Existing reading guide; new claims rely on installed Zig source. |
| [[hermit-io-timeout-proof]] | `b7d7f421d64780fa4471146cc5de7f198d9cb453`. Historical timeout evidence; measurements and snapshots were not re-audited. |

All four records retain their original bytes.
No new record was needed for facts already covered by the exact-release standard-library record.

### Exact primary evidence

The compiler resolves to `/Users/rs/renerocksai.stow/nvim/.local/share/zigup/0.16.0/files/zig`.
Both `.zig-version` and `zig version` report `0.16.0`.
The installed standard-library root is that distribution's `lib/std/` directory.

| ID | Inspected material | SHA-256 |
| --- | --- | --- |
| E1 | `lib/std/Io.zig`: `async`, `concurrent`, and `ConcurrentError`; interface progress and failure contracts. | `2d452f28cbeca10280f471b8e1962cdfe2a01000535050af6f6ebcc1a56365d6` |
| E2 | `lib/std/Io/Threaded.zig`: `InitOptions`, `init`, `setAsyncLimit`, `worker`, four dispatch functions, and task/future creation and destruction. | `eb7bbb4ddf590ec3d0d2a1ee5c3845ef4984d9e440965a3e7c920cd0c906df94` |
| E3 | [Dispatch proof](../proofs/async_vs_concurrent.zig): both zero-limit tests, read completely. | `b6367caae835641225913650187d1a65ff57c5eef4c7be7b27ff2a3103955e12` |
| E4 | [Build registration](../build.zig): the proof belongs to `proof_sources`; `verify` depends on its test run. | `ff3a293989452b10f32e48a06cad8811bccf40ecb90fa07bfc405cf42bba2f93` |

The source trace establishes these facts:

1. E1 permits immediate execution through `async`.
   E1 gives `concurrent` a stronger caller-progress guarantee during I/O waits and an explicit scheduling error.
2. E2 uses the same `t.busy_count` in all four dispatch functions.
   Async paths compare against `async_limit`; concurrent paths compare against `concurrent_limit`.
   Admission increments the count before queue insertion; `worker` decrements it after `runnable.startFn` returns.
3. E2 checks the selected limit before testing `pool_size - busy_count` for an available worker.
   Therefore idle threads do not override an exhausted dispatch limit.
   Mixed task kinds share admission capacity; neither limit reserves a separate pool.
4. E2 calls `Future.create` or `Group.Task.create` before acquiring the dispatch mutex and checking the limit.
   Both creation functions call `gpa.alignedAlloc`.
   Rejection destroys an allocated record before inline execution or the concurrent error return.
   The compile-time single-threaded branches return before allocation.
5. E2's `setAsyncLimit` only assigns the limit while holding the mutex.
   The setter neither cancels admitted tasks nor removes worker threads.
   E2 also records CPU-discovery failure and defaults `async_limit` to `.nothing` in that case.
6. E3 checks the two zero-limit outcomes.
   The packet records successful execution at the reviewed base.
   E3 does not count allocator calls or exercise mixed dispatch, spare workers, or limit changes.
   This pass adds no runtime reproduction of those cases.

## Findings and proposed changes

The following corrections are present as reviewable working-tree edits.
No critical or high finding emerged within the stated scope.
The content disposition is `pass-with-findings`; the full local verification gate remains unrun.

| ID | Severity | Location and category | Evidence and consequence | Corrective action |
| --- | --- | --- | --- | --- |
| SL-20260928-001 | medium | `io-threaded` / Task dispatch and allocation; resource limits | E2 uses shared accounting and checks limits before idle workers. The previous explanation could suggest separate budgets or admission whenever a worker is idle. | Explain the shared counter, both limit checks, idle-worker consequence, CPU-discovery fallback, and setter boundary. Keep these details source-verified. |
| SL-20260928-002 | medium | `io-threaded` / Allocation before admission; allocation and evidence | E2 allocates before limit rejection. E3 proves zero-limit outcomes without allocator instrumentation. A zero limit does not eliminate allocation attempts. | State allocation order, cleanup, and the single-threaded exception. Link to the existing strict-allocation guidance and state the proof gaps. |
| SL-20260928-003 | low | `async-vs-concurrent` / Remember and implementation section; retrieval and duplication | The `std.Io.Threaded` alias targeted `std-io`. Both guides repeated implementation defaults without the shared-counter explanation. | Target `io-threaded`, retain the progress distinction, and centralize detailed limits. Update the Threaded summary and index description. |

`HANDOFF.md` records this bounded pass and caller-owned validation.
`ROADMAP.md` records the unassigned proof follow-up without changing milestone status.
`CURATION.md` remains unchanged because no source moved through its curation states.
The existing runtime status and platform list on `async-vs-concurrent` remain unchanged.
The Threaded page remains `source-verified` and explicitly limits the dispatch proof's coverage.

## Graph and successful checks

The trusted graph command was `python3 tools/lint_wiki.py --graph-report`.
This command is the operation registered by `zig build graph`.
The initial graph reported 50 wiki pages, excluding the index, and 507 directed wiki edges.
All 50 pages were in the strong band; orphan, weak, and connected bands were empty.
These counts describe structure, not a semantic audit of all pages.

| Graph scope | Semantic navigation assessment |
| --- | --- |
| Orphan, weak, and connected bands | Empty; no page in these bands required individual triage. |
| `io-threaded`, strong | The progress guide and allocation guide explain concrete consequences. Existing reciprocal links already connect both destinations. |
| `async-vs-concurrent`, strong | The corrected alias now leads directly to the implementation details. Existing cancellation and selection links remain relevant. |
| Adjacent context pages | Their existing Threaded links supply the needed return paths; no new links were necessary. |
| Remaining pages | No semantic navigation conclusion. |

The read-only structural lint command is `python3 tools/wiki.py lint --deterministic-only --format json`.
Initial structural lint passed with zero issues across 51 pages and 84 source records.
Final structural lint also passed with zero issues across the same pages and source records.
The final graph retains 507 directed edges and the same page and band totals.

`git diff --check` passed.
The allowed-path and size checks passed for seven changed files.
Patch content plus the new report remains below 32 KiB.
The resulting contents of all changed files remain below 200 KiB.
Both measures stay within the 1 MiB limit.
The log retains the reviewed base's complete byte prefix.
No old source record, report, proof, tool, workflow, agent policy, or compiler-version file changed.

The retrieval policy passed after the index change:
`python3 tools/retrieval_benchmark.py --format json --enforce-policy`.
Results matched the packet: 25 queries, MRR 0.98, hit@3 1.0, and recall@5 0.96.
Those cases remain a regression set, not production retrieval evidence.
Ignored diagnostics remain under `.zig-cache/curation-review-35585801744-1/`.
Those diagnostics contain structural, retrieval, and scope checks; they supply no new platform runtime evidence.

## Verification blocker and remaining work

The local host reports arm64 macOS 26.6.2, build `25G83`.
The [platform runbook](../docs/platform-testing.md#cooperative-host-measurement-lock) requires process inspection before shared-host runtime suites or heavy builds.
`ps -axo pid,ppid,etime,comm` failed with `operation not permitted: ps`.
Direct execution also raised `PermissionError: [Errno 1] Operation not permitted: '/bin/ps'`.
The measurement lock was absent, but lock absence does not exclude workloads that ignore the lock protocol.
This pass could not establish the required preflight condition.

Therefore `zig build verify --summary all` was not started.
No measurement reservation or runtime workload was created.
The pass used the lightweight Python graph operation without invoking the Zig build wrapper.
No sandbox bypass or remote runner was attempted.
The caller must run the full trusted local gate after checking the diff.
The packet's successful Linux run remains evidence for the reviewed base only.

Mixed-dispatch, idle-worker, limit-change, and allocator-count proofs require permission to edit proofs and relevant native execution.
Those proposed tests remain unassigned and unexecuted.
This pass does not change M3-006, perform M4 work, or assert complete roadmap coverage.
Python unit tests were inspected in the packet but not rerun; the caller owns independent trusted gates.

The pass adds no source record, Zig snippet, runtime promotion, compiler change, or executable edit.
Old source records and reports remain unchanged; the log receives only an appended entry.
No subagent, remote runner, fetch, commit, push, PR, or external message was used.
