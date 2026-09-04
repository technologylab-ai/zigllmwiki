# Roadmap

This is the persistent plan for the Zig LLM Wiki. Status values are `done`,
`active`, `next`, `later`, and `blocked`. Update this file in the same change
that completes or materially changes an item.

## North star

A coding agent designing Zig systems software can consult this repository and
produce Zig 0.16.x code that:

- compiles under the pinned compiler;
- models `std.Io`, scheduling, cancellation, and limits correctly;
- makes platform-specific I/O choices without pretending they are portable;
- applies TigerStyle as concrete engineering constraints;
- can trace important recommendations to primary sources and runnable proofs.

## Progress snapshot — 2026-09-04

- **Active milestone:** M0 is not complete; C-003, C-004, and L-004 remain.
- **M1/M2 content expansion is active in parallel:** M1-005 and M2-009 are
  explicitly `active` in the milestone tables below. Selected M1/M2 work is
  running before M0 exits because it directly constrains the seed pages.
- **Latest completed content:** the six requested matklad essays and five
  TigerBeetle documents are joined by structured-concurrency, `io_uring`,
  bounded error-diagnostics, full TigerStyle-coverage, and pinned TigerBeetle
  cross-platform I/O syntheses. `Future`/`Group` ownership, protection, and
  `recancel` have a macOS `Io.Threaded` proof.
- **Current next slice:** complete M1-005 with Linux and Windows
  blocked-syscall evidence, finish the macOS dispatch-I/O and Windows Zig-source
  maps, and close the next TigerStyle gaps at integer boundaries.
- **Backend:** intentionally deferred; the Obsidian-first ADR remains in force.

Source status is tracked as `discovered → selected → captured → synthesized →
proved` in [CURATION.md](CURATION.md). “Captured” never implies that guidance
has been written, and conceptual material does not require a code proof.

## Current milestone — M0: trustworthy foundation (active)

| ID | Lane | Status | Deliverable / exit condition |
| --- | --- | --- | --- |
| C-001 | content | done | Zig 0.16.0 baseline and source hierarchy recorded. |
| C-002 | content | done | Seed pages for `std.Io`, async vs concurrent, backend readiness, and TigerStyle. |
| C-003 | content | next | Import portable snapshots of the local migration guide and hermit proofs while retaining their hashes and origins. |
| C-004 | content | next | Turn the full Zig 0.16 release notes into a scoped topic inventory; do not duplicate the release notes. |
| C-005 | content | done | Pin and synthesize the six requested matklad posts on allocation, cancellation, `Io.Threaded`, diagnostics, typed indexes, and formatting. |
| C-006 | content | done | Curate the first TigerBeetle engineering-doc slice and publish a transfer-oriented corpus map. |
| C-007 | content | done | Add a source ledger that exposes discovered, selected, captured, synthesized, and proved states. |
| L-001 | LLM | done | Repository agent contract defines query, ingest, lint, and upgrade operations. |
| L-002 | LLM | done | Discoverable repo-local `zig-wiki` skill exposes those operations to Codex. |
| L-003 | LLM | done | Mechanical verification checks compiler version, page schema, links, proof paths, and executable proofs. |
| L-004 | LLM | next | Add orphan/backlink quality scoring and a semantic lint prompt/report format. |
| L-005 | LLM | done | Record revision-pinned source archaeology and distinguish history, rationale, inference, and current guarantees. |
| B-001 | backend | done | Obsidian-first ADR; no application backend in M0. |

M0 exits when C-003, C-004, and L-004 are done and the first unsupervised lint
pass produces a reviewable report without weakening verification rules.

## M1: `std.Io` field guide (active)

| ID | Status | Deliverable / exit condition |
| --- | --- | --- |
| M1-001 | next | `std.process.Init` and explicit capability threading page. |
| M1-002 | done | `Future` and `Group` ownership/lifetime page plus terminal-path proof. |
| M1-003 | next | `Select` and `Batch` ownership, result, and cleanup page. |
| M1-004 | done | `async` versus `concurrent`, including saturated runtime evidence. |
| M1-005 | active | Cancellation acknowledgement, `recancel`, protection, cleanup, and blocked-syscall platform matrix. Task semantics and a blocked pipe read are proved on macOS; Linux/Windows syscall interruption remains. |
| M1-006 | next | `Event`, `Queue`, `Mutex`, `RwLock`, `Condition`, `Semaphore`, and `Futex`. |
| M1-007 | next | Clocks, durations, timestamps, deadlines, timeouts, and sleeping. |
| M1-008 | next | Files, directories, buffered readers/writers, flush, and atomic persistence. |
| M1-009 | next | Networking, DNS racing, sockets, processes, and entropy. |
| M1-010 | next | `-fsingle-threaded`, `std.testing.io`, and failing/test implementations. |
| M1-011 | done | `std.Io.Threaded` allocation, limits, thread growth, and eager dispatch seam. |
| M1-012 | done | Separate typed recovery codes from bounded human-facing diagnostics and reporting ownership. |

Exit condition: every public recommendation has a 0.16.x source citation; every
behavioral trap has a runnable proof; Threaded-specific facts are labeled.

## M2: TigerStyle in Zig (active)

| ID | Status | Deliverable / exit condition |
| --- | --- | --- |
| M2-001 | done | Every principle in the pinned TigerStyle source is mapped in `tigerstyle-coverage.md` to current guidance, a proof target, or an explicit pending artifact. |
| M2-002 | done | Applied startup-allocation, overload, constant-work, and `Io.Threaded` seam page. |
| M2-003 | active | Invariant derivation, assertion placement, bounded progress, positive/negative-space testing, and DST are synthesized; a persistence-boundary assertion-pair proof remains. |
| M2-004 | next | Explicit integer widths, typed indexes, layout assertions, and serialization boundaries. Typed indexes are proved; the broader integer-width guide remains. |
| M2-005 | next | Function shape and centralized control flow. Orientation exists; applied counterexamples remain. |
| M2-006 | next | Batching, control/data planes, and performance sketches. Benchmark correctness guidance is source-verified; the quantified sketch and reproducible Zig harness remain. |
| M2-007 | next | Naming, comments, and canonical formatting. `zig fmt` steering is proved; full TigerStyle coverage remains. |
| M2-008 | next | Document seams with `usize`, standard-library allocation, concurrency runtimes, and platform APIs. |
| M2-009 | active | Curate matklad and TigerBeetle engineering sources by concrete design decision; track state in `CURATION.md`. |

Exit condition: the TigerStyle inventory has no unrepresented rule and an agent
can derive a review checklist for a concrete Zig subsystem without rereading the
source document.

## M3: evented I/O across operating systems (active)

Keep interface design separate from backend implementation.

| ID | Status | Deliverable / exit condition |
| --- | --- | --- |
| M3-001 | done | Pinned TigerBeetle `src/io` map distinguishing Linux `io_uring`, Darwin `kqueue` readiness plus synchronous file I/O, and Windows IOCP/overlapped I/O. |
| M3-002 | active | Linux `io_uring` kernel-version/feature matrix, registered-resource ownership, cancellation, and runnable Linux evidence. Interface and TigerBeetle queue lifecycle are source-verified. |
| M3-003 | active | Apple-primary `kqueue` and POSIX AIO lifecycles are synthesized; dispatch I/O, a Zig 0.16 wrapper, comparative performance, and macOS runtime evidence remain. |
| M3-004 | active | Microsoft-primary IOCP, overlapped ownership, immediate completion, and `CancelIoEx` races are synthesized; Zig 0.16 source mapping, error translation, and Windows runtime evidence remain. |
| M3-005 | next | Cross-platform backend decision table with guarantees, limits, unsupported cases, and measured evidence. |

| Platform | Research and proof targets |
| --- | --- |
| Linux | `io_uring` submission/completion ownership, registered resources, cancellation, backpressure, fixed limits, kernel-version behavior, and TigerBeetle patterns. |
| macOS/BSD | `kqueue` readiness semantics, regular-file limitations, sockets, timers, process events, GCD/dispatch I/O, and viable file-I/O strategies. |
| Windows | IOCP, overlapped file/socket I/O, completion ownership, cancellation, and the Zig 0.16 NtDll/networking direction. |

For each platform: use OS primary documentation, inspect current Zig and
TigerBeetle source, write minimal compile proofs, then run behavioral proofs on
the named OS. Never generalize a networking result to regular files.

Exit condition: a decision table can select a backend for file and network I/O
with explicit guarantees, limits, unsupported cases, and measured evidence.

## M4: synthesis project — TigerStyle evented HTTP server

Use the wiki to design, implement, and critique a bounded HTTP server:

- no steady-state allocation;
- explicit connection/request/body/queue/time limits;
- assertion pairs at trust and persistence boundaries;
- structured task ownership and cancellation;
- separate control and data planes with batching where justified;
- Linux `io_uring` path plus explicit macOS and Windows strategies;
- deterministic tests, fault injection, and back-of-the-envelope resource
  sketches before optimization.

The example belongs in a dedicated project; this wiki stores the reusable
patterns, proofs, decisions, and postmortems.

## Backend lane

Stay Obsidian-first while one local vault satisfies human browsing. Reconsider a
web application only when at least one trigger is real:

- readers need browser access without an Obsidian checkout;
- multi-user review, authentication, or publishing is required;
- search quality is measurably inadequate at vault scale;
- the graph needs typed claim/source/proof edges Obsidian cannot express;
- an agent API needs behavior beyond filesystem search and the index.

The first backend should be a read-only generated site/index over Markdown, not
a second content store. A mutable service and database come only after that.

## LLM maintenance lane

After M0:

1. Add deterministic `ingest`, `query`, `lint`, and `upgrade` command wrappers.
2. Produce machine-readable lint output for broken evidence and stale versions.
3. Add a scheduled agent job that opens reviewable changes; never silently
   rewrites verified knowledge.
4. Track source revisions and Zig releases, but require an explicit upgrade run
   before changing the active version.
5. Evaluate hybrid search only after index-plus-`rg` retrieval is benchmarked on
   real queries and shown insufficient.

## Research queue

- Complete Zig 0.16 release-note coverage, especially all `std.Io` subtopics.
- Add primary macOS and Windows documentation beside the source-verified
  TigerBeetle I/O comparison; no runtime proof is implied by source inspection.
- Work through the selected matklad clusters in `CURATION.md`; do not promote
  older Zig syntax until it has a 0.16 proof.
- Define a platform test matrix and access to Linux, macOS, and Windows runners.
- Design snippet tangling so Markdown can eventually show verified excerpts
  without duplicating executable code.
