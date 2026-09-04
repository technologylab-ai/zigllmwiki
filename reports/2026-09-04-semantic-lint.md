---
kind: semantic-lint-report
date: 2026-09-04
zig: "0.16.0"
scope: all current wiki pages, source records, proofs, and roadmap boundaries
verifier: pass
disposition: pass-with-findings
---

# Semantic lint report — 2026-09-04

## Summary

This first unsupervised pass followed [the semantic lint
procedure](../tools/semantic_lint.md). It reviewed all 28 navigable Markdown
pages (the index plus 27 wiki pages), 34 source records, eleven registered Zig
proof files, and the claims most likely to mislead an agent: `std.Io` versus
`std.Io.Threaded`, `async` versus `concurrent`, cancellation ownership, and
Linux/macOS/Windows I/O boundaries.

`zig build verify --summary all` passed with the exact Zig 0.16.0 compiler:
27/27 build steps and 17/17 tests. The graph report contains 27 pages excluding
the index and 190 directed wiki edges: 26 strong, one connected, zero weak, and
zero orphan pages.

No critical or high finding remains. Two overstatements/maintenance defects
were corrected in this pass. The report is `pass-with-findings` so those
corrections and the deliberately unproved platform work remain visible.

## Findings

| ID | Status | Severity | Page / heading | Category | Evidence and consequence | Bounded corrective action |
| --- | --- | --- | --- | --- | --- | --- |
| SL-20260904-001 | resolved | medium | [[zig-0.16-release-inventory]] / target, language, and standard-library tables | evidence scope | Three entries were labeled integrated although the linked pages did not teach the exact release change. This could make an agent skip needed source work. | Reclassified OS minimums and the local-address rule as watches, and `Thread.Pool` removal as queued M1-006 work distinct from `std.Io.Threaded`'s internal pool. |
| SL-20260904-002 | resolved | low | [[zig-0.16-release-inventory]] / graph routing | retrieval | The new inventory initially had only its index backlink. A map this important should also be reachable from the version baseline. | Added a natural backlink from [[zig-0.16-baseline]] rather than synthetic unrelated links. |
| SL-20260904-003 | accepted | note | [[steering-zig-fmt]] / whole page | graph quality | Score 75: indexed, one conceptual backlink, two outward links, and one source record. It is a narrow leaf and the current links reach its governing TigerStyle and version pages. | Keep as connected; do not manufacture unrelated backlinks merely to raise a count. |
| SL-20260904-004 | open roadmap evidence | note | [[cancellation]], [[io-uring]], [[macos-kqueue-and-aio]], [[windows-iocp-and-overlapped-io]] | platform evidence | The pages clearly label Linux/Windows cancellation and the evented platform adapters as source-verified rather than locally runtime-verified. An agent still cannot treat them as measured backend recommendations. | Complete M1-005 and M3-002 through M3-005 on named runners; retain current qualifications until then. |

## Graph review

There are no orphan or weak pages. The only connected page is reviewed here as
required by the report format.

| Page | Score / band | Semantic review |
| --- | --- | --- |
| [[steering-zig-fmt]] | 75 / connected | Adequate narrow leaf: discoverable from the index and TigerStyle coverage; routes back to TigerStyle and the Zig baseline; cites the pinned matklad source and a format-checked fixture. |

The new [[zig-0.16-release-inventory]] initially had no non-index conceptual
backlink. Adding the natural link from [[zig-0.16-baseline]] raised it to strong
without adding a synthetic graph-only edge.

## Explicit checks that passed

- Current Zig claims name 0.16.0; executable snippets live under `proofs/` and
  are registered in `build.zig` rather than copied into wiki fences.
- [[std-io]] states an interface/capability contract; [[io-threaded]] isolates
  blocking-call, allocation, pool-growth, and platform-cancellation details of
  the concrete default implementation.
- [[async-vs-concurrent]] preserves the eager-execution trap and requires
  explicit handling of `error.ConcurrencyUnavailable` where independent
  progress is required.
- Cancellation request, acknowledgement, terminal result, and buffer/operation
  reuse are separate across Zig futures/groups, `io_uring`, POSIX AIO, and
  Windows overlapped I/O.
- macOS socket readiness is not generalized to asynchronous regular-file I/O;
  TigerBeetle implementation evidence is not mislabeled as a Zig `std.Io`
  backend or a portable cancellation API.
- Source-inspected and runtime-proved statements remain distinct, and all
  known missing runner evidence is reflected in active roadmap items.
- TigerStyle's full pinned principle inventory remains explicit about covered,
  partial, and missing work; “inventory complete” is not represented as
  “guidance complete.”
- The local migration and zig-hermit sources have byte-identical, hash-checked
  portable snapshots.
- [[process-init-and-capabilities]] keeps process startup ownership separate
  from narrower library dependencies, and its real initializer entry point is
  executed by verification.
- [[select-and-batch]] distinguishes task results from low-level operation
  storage and proves owned-result draining plus index-based batch completion.

## Roadmap effect

This pass completes L-004 and therefore closes M0. It does not close any open
content evidence merely because that evidence was audited. M1-005, M2-003,
M2-009, and M3-002 through M3-004 remain active with their stated boundaries.
M1-001 (`std.process.Init`) and M1-003 (`Select`/`Batch`) were completed and
included in the final pass. The next primary content slice is M1-006, the
`std.Io` synchronization primitives.
