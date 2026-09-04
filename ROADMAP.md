# Roadmap

This is the persistent plan for the Zig LLM Wiki. Status values are `done`,
`running`, `queued`, `deferred`, and `blocked`. `running` means an agent is
executing that item now; it never means merely “important” or “partially
complete.” Update this file when ownership, completion, or scope changes.

## North star

A coding agent designing Zig systems software can consult this repository and
produce Zig 0.16.x code that:

- compiles under the pinned compiler;
- models `std.Io`, scheduling, cancellation, and limits correctly;
- makes platform-specific I/O choices without pretending they are portable;
- applies TigerStyle as concrete engineering constraints;
- can trace important recommendations to primary sources and runnable proofs.

## Progress snapshot — 2026-09-04

- **Foundation milestone:** M0 is complete. Portable local evidence, the full
  Zig 0.16 release-note scope inventory, deterministic graph scoring, and the
  first semantic lint report are all in place.
- **Running now:** none at handoff. M3-004's proof and source-review assignments
  are complete. Queued qualification work below has no assigned agent.
- **Latest completed content:** M1-001, M1-003, and M1-006 now document and
  prove `std.process.Init`/capability threading, `Select`/`Batch` ownership, and
  the complete `std.Io` synchronization-primitives surface. The six requested
  matklad essays and five
  TigerBeetle documents are joined by structured-concurrency, `io_uring`,
  bounded error-diagnostics, full TigerStyle-coverage, and pinned TigerBeetle
  cross-platform I/O syntheses. `Future`/`Group` ownership, protection, and
  `recancel` have a macOS `Io.Threaded` proof.
- **Latest platform evidence:** M3-004 adds Windows APC/batch/NPFS cancellation,
  both custom IOCP notification policies, cancellation/shutdown ownership, and
  bounded pipe/hot-NTFS read measurements. Zig 0.16.0 native Windows verification
  passed 82/82 steps, 70/77 tests, 7 skips; x86/aarch64 remain compile-only.
  The initial-wait batch defect and no-follow open metadata mismatch are
  preserved, not hidden by successful fixtures. Linux `omarx1` also passed
  82/82 steps, 70 tests and 7 skips.
- **Queued, not running:** M3-006 deployment qualification and L-009
  review-packet-to-PR automation.
- **Backend:** intentionally deferred; the Obsidian-first ADR remains in force.

Source status is tracked as `discovered → selected → captured → synthesized →
proved` in [CURATION.md](CURATION.md). “Captured” never implies that guidance
has been written, and conceptual material does not require a code proof.

## M0: trustworthy foundation (done)

| ID | Lane | Status | Deliverable / exit condition |
| --- | --- | --- | --- |
| C-001 | content | done | Zig 0.16.0 baseline and source hierarchy recorded. |
| C-002 | content | done | Seed pages for `std.Io`, async vs concurrent, backend readiness, and TigerStyle. |
| C-003 | content | done | Byte-identical portable snapshots of the local migration guide and hermit proofs retain repository commits, origins, and SHA-256 values checked by `zig build verify`. |
| C-004 | content | done | Every named Zig 0.16 release-note topic is routed to integrated guidance, a numbered queue item, upgrade/platform watch, or explicit out-of-scope decision. |
| C-005 | content | done | Pin and synthesize the six requested matklad posts on allocation, cancellation, `Io.Threaded`, diagnostics, typed indexes, and formatting. |
| C-006 | content | done | Curate the first TigerBeetle engineering-doc slice and publish a transfer-oriented corpus map. |
| C-007 | content | done | Add a source ledger that exposes discovered, selected, captured, synthesized, and proved states. |
| L-001 | LLM | done | Repository agent contract defines query, ingest, lint, and upgrade operations. |
| L-002 | LLM | done | Discoverable repo-local `zig-wiki` skill exposes those operations to Codex. |
| L-003 | LLM | done | Mechanical verification checks compiler version, page schema, links, proof paths, and executable proofs. |
| L-004 | LLM | done | `zig build graph` scores discovery, conceptual backlinks, outward navigation, and source evidence; true orphans fail verification; the reusable semantic audit produced its first dated report. |
| L-005 | LLM | done | Record revision-pinned source archaeology and distinguish history, rationale, inference, and current guarantees. |
| B-001 | backend | done | Obsidian-first ADR; no application backend in M0. |

M0 exited on 2026-09-04 after the first unsupervised semantic pass produced a
reviewable report and deterministic graph scoring without weakening the
existing verification rules.

## M1: `std.Io` field guide (done)

| ID | Status | Deliverable / exit condition |
| --- | --- | --- |
| M1-001 | done | `std.process.Init` and explicit capability threading page plus an executable entry-point proof. |
| M1-002 | done | `Future` and `Group` ownership/lifetime page plus terminal-path proof. |
| M1-003 | done | `Select` and `Batch` ownership, fixed capacity, result draining, cancellation traps, and runtime proof. |
| M1-004 | done | `async` versus `concurrent`, including saturated runtime evidence. |
| M1-005 | done | Task semantics and blocked pipe-read cancellation are runtime-proved on macOS, Linux, and Windows; exact Windows APC/IOCP cancellation breadth remains the platform-specific M3-004 gate. |
| M1-006 | done | `Event`, `Queue`, `Mutex`, `RwLock`, `Condition`, `Semaphore`, and futex semantics plus six runtime tests. |
| M1-007 | done | Clock domains, durations, timestamps, one-deadline budgets, timeout conversion, cancelable sleeping, strict-clock guard caveats, and five runtime tests. |
| M1-008 | done | Files, directories, buffered readers/writers, exclusive read limits, flush versus truncation, atomic publication, and the directory-durability seam plus three runtime tests. |
| M1-009 | done | Networking and DNS queue/race ownership, stream/datagram lifecycles, bounded subprocess capture and termination, entropy failure policy, and five macOS runtime tests. |
| M1-010 | done | Host-backed `std.testing.io`, exact `Io.failing` behavior, fixed/failing stream adapters, ordinary and `-fsingle-threaded` execution, and four tests run in both modes. |
| M1-011 | done | `std.Io.Threaded` allocation, limits, thread growth, and eager dispatch seam. |
| M1-012 | done | Separate typed recovery codes from bounded human-facing diagnostics and reporting ownership. |

Exit condition: every public recommendation has a 0.16.x source citation; every
behavioral trap has a runnable proof; Threaded-specific facts are labeled.

M1 exited on 2026-09-04 after the Windows Server 2025 run completed the
three-platform blocked-read cancellation matrix. This does not promote custom
IOCP behavior or arbitrary Windows devices into runtime-verified claims.

## M2: TigerStyle in Zig (done)

| ID | Status | Deliverable / exit condition |
| --- | --- | --- |
| M2-001 | done | Every principle in the pinned TigerStyle source is mapped in `tigerstyle-coverage.md` to current guidance, a proof target, or an explicit pending artifact. |
| M2-002 | done | Applied startup-allocation, overload, constant-work, and `Io.Threaded` seam page. |
| M2-003 | done | Invariant guidance plus an independent producer/consumer persistence assertion pair with malformed, corrupt, reserved, and semantically invalid cases. |
| M2-004 | done | Explicit integer domains, checked narrowing/arithmetic, `usize` seams, layout assertions, serialization boundaries, reserved fields, and stale-handle risks. |
| M2-005 | done | Function-size and inverse-hourglass guidance, centralized policy/state mutation, explicit decision trees, bounded iterative traversal, applied counterexamples, and three runtime tests. |
| M2-006 | done | Resource/frequency sketches, bounded control/data planes, batching/deadline tradeoffs, a quantified durable-server worksheet, and a reproducible Zig harness. |
| M2-007 | done | TigerStyle/Zig naming seams, comments, API/file/callback shape, explicit options, canonical formatting, and a deterministic 100-character Zig lint. |
| M2-008 | done | Strict-core/exception labels and seams for `usize`, allocator-using standard-library APIs, concurrency runtimes, atomic persistence, and finite platform resources. |
| M2-009 | done | Ingested the selected bounded-memory/layout cluster into reservation, working-set/output, explicit-layout, and stable-handle decisions. |
| M2-010 | done | Ingested both retry-loop essays and the defer-pattern essay into bounded total-attempt/deadline, side-effect ambiguity, cancellation, and cleanup guidance with four runtime tests. |
| M2-011 | done | One-authority state, smallest scope, const borrowing over 16 bytes, viral in-place initialization, check/use gaps across suspension, complete buffer initialization/reuse clearing, explicit encoding, and exact/floor/ceiling division have focused guidance and three Zig 0.16 tests. |
| M2-012 | done | Disciplined design revision, zero-safety-debt/exception policy, strict Zig diagnostics, exhaustive fault catalogs, generated-code inspection, lower-dimensional APIs, dependency admission, and the deliberate Python/Zig seam close all remaining TigerStyle inventory rows. |

Exit condition: the TigerStyle inventory has no unrepresented rule and an agent
can derive a review checklist for a concrete Zig subsystem without rereading the
source document.

M2 exited on 2026-09-04 with all 71 principles in the pinned TigerStyle
revision mapped to focused guidance and all local Zig claims registered for
Zig 0.16 verification. This is guidance coverage, not automatic conformance by
projects that consult it.

## M3: evented I/O across operating systems (in progress)

Keep interface design separate from backend implementation.

| ID | Status | Deliverable / exit condition |
| --- | --- | --- |
| M3-001 | done | Pinned TigerBeetle `src/io` map distinguishing Linux `io_uring`, Darwin `kqueue` readiness plus synchronous file I/O, and Windows IOCP/overlapped I/O. |
| M3-002 | done | Linux kernel/feature floors, finite queues, registered-file/buffer ownership, target/cancel CQE reconciliation, exact Zig-layer readiness, and three Zig 0.16 runtime tests on `omarx1`. |
| M3-003 | done | Apple-primary `kqueue`, Dispatch I/O, and POSIX AIO lifecycles; exact Zig 0.16 Dispatch/Kqueue mapping and defects; a Zig/C adapter; macOS runtime proof; and bounded comparative evidence. |
| M3-004 | done | Pinned Microsoft/0.16 source, raw immediate/pending APC, fixed batch races and NPFS device-control cancellation, custom IOCP immediate/pending/cancel/shutdown ownership, finite limits/watchdogs, and bounded pipe/hot-file read metrics ran on Windows Server 2025. Initial-wait and wrapper-mode defects are explicit; broader qualification is M3-006. |
| M3-005 | done | Cross-platform decision table selects portable Threaded or platform-specific file/network backends with guarantees, limits, unsupported cases, ownership, resource models, and exact evidence gates. |
| M3-006 | queued | Qualify a named Windows deployment workload: Winsock and batched dequeue, overlapped file writes, regular-file immediate-success/cancellation, cold storage/durability, required driver/error paths, and a supported solution to unassisted batch shutdown. Record load/tail-latency criteria and native architecture/device matrix before extending runtime claims. |

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

| ID | Status | Deliverable / exit condition |
| --- | --- | --- |
| L-006 | done | Deterministic read-only `query`/`lint` and plan-only `ingest`/`upgrade` commands expose versioned JSON and never silently mutate knowledge. |
| L-007 | done | Machine lint classifies broken evidence, stale versions, schema, links, graph health, and style with stable codes. |
| L-008 | done | Weekly/manual GitHub workflow installs the exact checksum-verified Zig baseline, verifies proofs, checks sources/releases and retrieval, proves the checkout stayed unchanged, and uploads a 30-day review packet. |
| L-009 | queued | Connect a separately authorized coding agent that consumes the review packet and opens a reviewable PR; the read-only workflow intentionally lacks write/PR authority. |
| L-010 | done | Read-only `review` reports coarse upstream-head differences and newer stable Zig releases while preserving source records and requiring an explicit upgrade workflow. |
| L-011 | done | A versioned 25-query benchmark scores the deterministic index/lexical layer; MRR 1.0, hit@3 1.0, and recall@5 0.98 do not justify hybrid search yet. |

The benchmark is a curated regression set, not production telemetry. Revisit
hybrid search when thresholds fail or real agent queries demonstrate misses.

## Research queue

- Monitor a future Zig release through the explicit upgrade workflow; the 0.16
  inventory has no stale queued rows.
- Extend the completed Windows NPFS/IOCP fixtures only against M3-006's named
  workload, device, error-path, and shutdown requirements.
- Select new matklad or TigerBeetle sources only for a named system-design
  question; never promote old Zig syntax without a 0.16 proof.
- Extend the three-platform matrix with workload-specific filesystem/device,
  cold-storage, durability, and native architecture runners.
- Design snippet tangling so Markdown can eventually show verified excerpts
  without duplicating executable code.
