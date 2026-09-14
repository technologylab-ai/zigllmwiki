---
kind: semantic-lint-report
date: 2026-09-14
zig: "0.16.0"
scope: Two scheduling pages; focused interface and Threaded dispatch source inspection.
verifier: Local runtime gate not run; deterministic lint and retrieval policy passed.
disposition: pass-with-findings
review_run: 34105239480
review_attempt: 1
reviewed_base: a48ddf3ce6d956b4f7e1e0db6a7a31e403c0d27f
---

# Bounded scheduling review

## Scope and result

The pass reviewed two wiki pages, four source records, and three existing proof files.
The substantive source review covers interface scheduling guarantees and Threaded dispatch admission.
Cancellation proofs supplied ownership context; this pass did not revalidate platform cancellation behavior.
Both pages were read completely, but unrelated material claims were outside the focused source audit.
No result here certifies uninspected pages or the complete external writing standard.

The working checkout initially matched the reviewed base and had no changes.
The pass read AGENTS.md, the zig-wiki skill, .zig-version, index.md, ROADMAP.md, CURATION.md, HANDOFF.md, and tools/semantic_lint.md.
The pass also read the technical writing policy and platform testing runbook.
The user's bounded scope overrides publication, remote execution, and full-vault procedure steps.

The review found shared dispatch accounting missing from the implementation explanation.
The edits clarify that accounting and remove duplicated limit descriptions from the scheduling pattern.
No source record, proof, tool, workflow, policy, or Zig version changed.
No runtime status changed, and no M4 guidance was inspected.

## Packet inspection

The caller supplied the authenticated packet at `.zig-cache/review-packet/` for run 34105239480, attempt 1.
The pass read packet files as data and executed no downloaded commands or scripts.
The pass did not independently repeat GitHub authentication or fetch current upstream heads.
Packet identities below preserve the inspected bytes.

| Packet file | Bytes | SHA-256 |
| --- | ---: | --- |
| actual-zig-version.txt | 7 | `aa037454b5e8320521a32b278a3f4aff05fc79009ab5503f5d4a1b9a33b38c47` |
| requested-zig-version.txt | 7 | `aa037454b5e8320521a32b278a3f4aff05fc79009ab5503f5d4a1b9a33b38c47` |
| repository-status.txt | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| source-and-release-review.json | 34924 | `ae1058deba839cf485e6271334eb5e285b033497cd18414409e0bd672e8e872e` |
| zig-build-verify.log | 5748 | `f1d1b0ac4ebc046e00a24d69449e9a5784ea2fbee08410dfe64c4254392c004d` |
| python-tests.log | 4483 | `036f568a15cd1293ccc314abcb50692032c9eccfd051333e63ecf62122e0c665` |
| retrieval-benchmark.json | 36750 | `629eb25c1f14c5ca351a61803a2c7e114f5fdb3418b589b577feb37db86425a6` |
| zig-download.txt | 143 | `fc2dab18fe352afa1951d8eb868e61c08308a1ba1150ed75cf01cbcb76933074` |

The packet reports Zig 0.16.0, 14 upstreams, 28 differing source-record heads, and no release candidates or network errors.
Five local records were skipped; three remote records were unmapped.
Six repository groups differ: Microsoft SDK documentation, TechEmpower, both HTTP repository names, Linux, and Zig.
These are repository-head comparisons, not document diffs or stale-guidance findings.
The mixed HTTP/Zig revision record and shortened historical HTTP revision received no correction from those coarse signals.
M4 source candidates remained outside this pass.

The packet's Linux gate reports 87 successful steps, 74 passing tests, and eight skips.
Its Python log reports 28 passing tests.
Its retrieval result reports 25 cases, MRR 0.98, hit@3 1.0, and recall@5 0.96.
Those results apply to the reviewed base, not the edited tree.
The recorded Linux compiler archive SHA-256 is `70e49664a74374b48b51e6f3fdfbf437f6395d42509050588bd49abe52ba3d00`.
No downloaded compiler or script was executed during this pass.

## Inspected pages, records, and proofs

| Material | Inspection scope |
| --- | --- |
| [async-vs-concurrent](../wiki/async-vs-concurrent.md) | Complete page; interface distinction, backend link, dispatch duplication, and proof limits. |
| [io-threaded](../wiki/io-threaded.md) | Complete page; exact source review focused on initialization, allocation failure, dispatch limits, and worker accounting. |
| [Standard-library record](../sources/zig-0.16.0-stdlib.md) | Existing authority for installed release source; revision `44d9672fed001115e674fd5ddb32747ef43a7af4`. |
| [Release-notes record](../sources/zig-0.16.0-release-notes.md) | Context only; no release-note claim changed or remote release page fetched. |
| [Timeout experiment record](../sources/hermit-io-timeout-proof.md) | Existing historical scope; Pi measurements and snapshot claims were not independently re-audited. |
| [matklad Threaded record](../sources/matklad-neat-io-threaded.md) | Context only; the installed release supplies the changed implementation claims. |
| [Dispatch proof](../proofs/async_vs_concurrent.zig) | Both tests: zero async capacity executes inline; zero concurrent capacity fails without executing the function. |
| [Cancellation proof](../proofs/cancellation.zig) | Read for task cleanup context; two Future/Group ownership tests. |
| [macOS pipe proof](../proofs/threaded_blocked_read_cancel_macos.zig) | Read for scope boundaries; no fresh syscall or timing claim. |
| [Build registration](../build.zig) | Confirmed all three proofs feed `verify`; inspected the graph command and native/platform registration structure. |

The source records retain their original bytes.
No new source record was necessary because the existing exact-release record already supports the correction.

## Exact primary evidence

`zig version` returned `0.16.0`, matching `.zig-version`.
`zig env` resolved the installed distribution to `/Users/rs/renerocksai.stow/nvim/.local/share/zigup/0.16.0/files`.
The reported default target was `aarch64-macos.26.6.2...26.6.2-none`.
That compiler target is not a new runtime environment receipt.

| Installed file or registered input | SHA-256 |
| --- | --- |
| zig | `e6cd688d25664983833aae272f501d4bceeae304875b8f1741209d15fd13a4ec` |
| lib/std/Io.zig | `2d452f28cbeca10280f471b8e1962cdfe2a01000535050af6f6ebcc1a56365d6` |
| lib/std/Io/Threaded.zig | `eb7bbb4ddf590ec3d0d2a1ee5c3845ef4984d9e440965a3e7c920cd0c906df94` |
| proofs/async_vs_concurrent.zig | `b6367caae835641225913650187d1a65ff57c5eef4c7be7b27ff2a3103955e12` |
| proofs/cancellation.zig | `98422bdbb16391665bc8714f23d17767d9cf56df2915e6254548102d3c846789` |
| proofs/threaded_blocked_read_cancel_macos.zig | `1241f629032033c8818f7d7348cc88bfdc2fadaa5fa33c16177158b36362723a` |
| build.zig | `ff3a293989452b10f32e48a06cad8811bccf40ecb90fa07bfc405cf42bba2f93` |

Exact source locations in those hashed files:

- `Io.zig`, `async`, `ConcurrentError`, and `concurrent`, lines 2314–2391: inline permission and the stronger I/O progress guarantee.
- `Io/Threaded.zig`, `busy_count`, lines 43–46: one shared count of unavailable workers.
- `InitOptions` and `init`, lines 1573–1642: defaults, failed CPU detection, and single-threaded initialization.
- `async`, lines 2074–2128: future allocation, shared-count limit check, inline fallback, then idle-thread inspection or thread creation.
- `concurrent`, lines 2130–2178: future allocation, the same count, explicit failure, then idle-thread inspection or thread creation.
- `groupAsync` and `groupConcurrent`, lines 2180–2290: equivalent shared-count checks for group dispatch.
- `worker`, lines 1787–1804: completion decrements the shared count before the worker resumes dispatch or waits.

The source checks limits before checking idle threads.
Therefore, an enlarged pool does not bypass a dispatch limit.
Concurrent work can consume capacity used by async admission.
These conclusions follow from source control flow; no mixed-dispatch runtime experiment was performed.

## Findings and proposed changes

The following changes are applied to the working diff for caller review.

| ID | Severity | Page / heading | Category | Evidence and consequence | Bounded corrective action |
| --- | --- | --- | --- | --- | --- |
| SL-20260914-001 | medium | io-threaded / Task dispatch and allocation | Resource limits | All four dispatch functions inspect one count before idle-thread selection. Separate-pool assumptions can misstate available capacity. | Resolved: describe shared admission, failure behavior, CPU-detection fallback, and source-only mixed-dispatch evidence. |
| SL-20260914-002 | low | async-vs-concurrent / Remember; What std.Io.Threaded does | Retrieval and duplication | The backend-labelled link targeted std-io; limit details duplicated io-threaded and omitted shared accounting. | Resolved: target io-threaded and delegate detailed capacity guidance to that page. |
| SL-20260914-003 | note | io-threaded / dispatch proof boundary | Evidence | Existing dispatch tests only use zero limits in separate instances. They do not exercise shared pressure or idle surplus threads. | Preserve source verification; record a separately authorized proof extension in ROADMAP.md. |

The io-threaded summary now identifies shared dispatch capacity.
CURATION.md and HANDOFF.md record this bounded review and the pending runtime gate.
ROADMAP.md records the proof opportunity without changing milestone statuses.
log.md receives one appended entry.
index.md retains its existing retrieval descriptions because they remain appropriate.

## Graph and semantic checks

The trusted graph implementation reported 50 strong pages and 507 directed wiki edges.
It reported zero connected-band pages, weak pages, or orphans.
Those whole-repository counts are mechanical observations, not semantic approval.

| In-scope page | Score / band | Link review |
| --- | --- | --- |
| async-vs-concurrent | 100 / strong | Corrected backend link now reaches the capacity explanation; reciprocal navigation already exists. |
| io-threaded | 100 / strong | Added contextual return link connects resource sizing to the scheduling guarantee. |

No orphan, weak, or connected-band page required a graph triage row.
Other strong pages were not semantically audited.

The focused review preserved these boundaries:

- The interface permits inline async execution; Threaded implements the specific allocation and worker rules.
- Concurrent dispatch failure remains explicit; no event loop or parallel CPU progress guarantee was added.
- Existing timer-race guidance still requires suitable scheduling for both branches.
- Existing runtime status and platform lists remain unchanged.
- The new mixed-dispatch explanation explicitly identifies its source evidence and missing runtime fixture.
- Historical measurements and immutable evidence retain their original limits.

## Checks and unresolved blockers

`python3 tools/wiki.py query async concurrent cancellation --format json` selected the focused page set.
`python3 tools/wiki.py lint --deterministic-only --format json` passed after guidance edits, with zero issues.
That command checked 51 pages including the index and 84 source records.
Its result explicitly reports `verification.ran=false`.
`python3 tools/lint_wiki.py --graph-report` supplied the graph counts above.
This invokes the trusted graph implementation registered by `zig build graph`, without compiling its build runner.

`python3 tools/retrieval_benchmark.py --enforce-policy --format json` passed all 25 cases.
Results remain MRR 0.98, hit@3 1.0, and recall@5 0.96.
The regression result does not establish general retrieval quality.

`zig build verify` was not launched.
The sandbox rejected `ps -axo pid,ppid,comm` with `operation not permitted: ps`.
The host reservation directory was absent, but absence cannot exclude workloads that ignore the reservation protocol.
The runbook requires checking existing workloads before reserving the host and starting a runtime suite.
The pass therefore acquired no reservation and started no build or runtime suite.
The caller must perform the required host checks, acquire its reservation, and run the full trusted gate.
The pass did not run `zig build graph` through Zig; the direct graph command above supplied structural evidence only.
Python unit tests and native remote gates were not rerun; the caller owns independent publication checks.

Final deterministic lint passed after the report, ledger, handoff, roadmap, and log edits.
`git diff --check` passed.
A scope check confirmed seven permitted changed paths and preserved the complete original log prefix.
The same check confirmed unchanged page status and Zig fields.
Both total changed-file size and diff size remain below the 1 MiB limit.

A mixed-dispatch proof needs permission to edit proofs and possibly their registration.
Useful cases include concurrent work exhausting async capacity and limit enforcement despite existing idle threads.
The current bounded pass cannot supply those runtime claims.
M3-006 remains postponed, and this pass leaves M4 work outside scope.
No subagents, remote runners, commits, pushes, pull requests, or external messages were used.
