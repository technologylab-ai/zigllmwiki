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
- **Running now:** M1-005/M3-002 Linux (`/root/linux_runtime`), M3-004
  (`/root/windows_mapping`), and LLM maintenance commands
  (`/root/llm_operations`). These are actual concurrent agent assignments.
- **Latest completed content:** M1-001, M1-003, and M1-006 now document and
  prove `std.process.Init`/capability threading, `Select`/`Batch` ownership, and
  the complete `std.Io` synchronization-primitives surface. The six requested
  matklad essays and five
  TigerBeetle documents are joined by structured-concurrency, `io_uring`,
  bounded error-diagnostics, full TigerStyle-coverage, and pinned TigerBeetle
  cross-platform I/O syntheses. `Future`/`Group` ownership, protection, and
  `recancel` have a macOS `Io.Threaded` proof.
- **Queued, not running:** M1-005 Windows cancellation evidence, M2-011,
  M2-012, and M3-005.
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

## M1: `std.Io` field guide (in progress)

| ID | Status | Deliverable / exit condition |
| --- | --- | --- |
| M1-001 | done | `std.process.Init` and explicit capability threading page plus an executable entry-point proof. |
| M1-002 | done | `Future` and `Group` ownership/lifetime page plus terminal-path proof. |
| M1-003 | done | `Select` and `Batch` ownership, fixed capacity, result draining, cancellation traps, and runtime proof. |
| M1-004 | done | `async` versus `concurrent`, including saturated runtime evidence. |
| M1-005 | running | `/root/linux_runtime`: task semantics and a blocked pipe read are proved on macOS; Linux blocked-syscall evidence is running on `omarx1`, while Windows runtime evidence remains queued. |
| M1-006 | done | `Event`, `Queue`, `Mutex`, `RwLock`, `Condition`, `Semaphore`, and futex semantics plus six runtime tests. |
| M1-007 | done | Clock domains, durations, timestamps, one-deadline budgets, timeout conversion, cancelable sleeping, strict-clock guard caveats, and five runtime tests. |
| M1-008 | done | Files, directories, buffered readers/writers, exclusive read limits, flush versus truncation, atomic publication, and the directory-durability seam plus three runtime tests. |
| M1-009 | done | Networking and DNS queue/race ownership, stream/datagram lifecycles, bounded subprocess capture and termination, entropy failure policy, and five macOS runtime tests. |
| M1-010 | done | Host-backed `std.testing.io`, exact `Io.failing` behavior, fixed/failing stream adapters, ordinary and `-fsingle-threaded` execution, and four tests run in both modes. |
| M1-011 | done | `std.Io.Threaded` allocation, limits, thread growth, and eager dispatch seam. |
| M1-012 | done | Separate typed recovery codes from bounded human-facing diagnostics and reporting ownership. |

Exit condition: every public recommendation has a 0.16.x source citation; every
behavioral trap has a runnable proof; Threaded-specific facts are labeled.

## M2: TigerStyle in Zig (in progress)

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
| M2-011 | queued | Close scope/state/lifetime gaps: duplicate aliases, large-value copying, in-place initialization, place-of-check/use, run-to-completion, buffer clearing/padding, paired cleanup, and division intent. |
| M2-012 | queued | Close design/tooling gaps: disciplined revision and exception policy, strict build diagnostics, fault-injection catalog, generated-code inspection, dependency acceptance, and the Python/Zig tooling seam. |

Exit condition: the TigerStyle inventory has no unrepresented rule and an agent
can derive a review checklist for a concrete Zig subsystem without rereading the
source document.

## M3: evented I/O across operating systems (in progress)

Keep interface design separate from backend implementation.

| ID | Status | Deliverable / exit condition |
| --- | --- | --- |
| M3-001 | done | Pinned TigerBeetle `src/io` map distinguishing Linux `io_uring`, Darwin `kqueue` readiness plus synchronous file I/O, and Windows IOCP/overlapped I/O. |
| M3-002 | running | `/root/linux_runtime` on `omarx1`: Linux `io_uring` kernel/version features, registered-resource ownership, cancellation, and runtime evidence. |
| M3-003 | done | Apple-primary `kqueue`, Dispatch I/O, and POSIX AIO lifecycles; exact Zig 0.16 Dispatch/Kqueue mapping and defects; a Zig/C adapter; macOS runtime proof; and bounded comparative evidence. |
| M3-004 | running | `/root/windows_mapping`: Microsoft-primary lifecycle is synthesized; exact Zig 0.16 source mapping and Windows cross-target proof are running, while Windows runtime evidence remains unavailable. |
| M3-005 | queued | Cross-platform backend decision table with guarantees, limits, unsupported cases, and measured evidence. |

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

- Advance the queued Zig 0.16 release-note topics using
  [[zig-0.16-release-inventory]], especially all `std.Io` subtopics.
- Add primary macOS and Windows documentation beside the source-verified
  TigerBeetle I/O comparison; no runtime proof is implied by source inspection.
- Work through the selected matklad clusters in `CURATION.md`; do not promote
  older Zig syntax until it has a 0.16 proof.
- Define a platform test matrix and access to Linux, macOS, and Windows runners.
- Design snippet tangling so Markdown can eventually show verified excerpts
  without duplicating executable code.
