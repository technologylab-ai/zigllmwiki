# Roadmap

This is the persistent plan for the Zig LLM Wiki. Status values are `done`,
`running`, `queued`, `postponed`, `deferred`, and `blocked`. `running` means an agent is
executing that item now; it never means merely “important” or “partially
complete.” `postponed` means deliberately set aside by the user until explicitly
resumed. Update this file when ownership, completion, or scope changes.

## North star

A coding agent designing Zig systems software can consult this repository and
produce Zig 0.16.0 code that:

- compiles under the pinned compiler;
- models `std.Io`, scheduling, cancellation, and limits correctly;
- makes platform-specific I/O choices without pretending they are portable;
- applies TigerStyle as concrete engineering constraints;
- can trace important recommendations to primary sources and runnable proofs.

## Progress snapshot — 2026-09-05

- **Foundation milestone:** M0 is complete. Portable local evidence, the full
  Zig 0.16 release-note scope inventory, deterministic graph scoring, and the
  first semantic lint report are all in place.
- **Completed in this session:** selected TigerBeetle storage/recovery/ops
  synthesis, a fresh full semantic audit, verified-excerpt design, and L-009's
  installed curator. Its first reviewed draft PR was separately merged.
- **Platform evidence:** all available M3-006 fixtures passed on x64, x86
  WOW64 and ARM64. The ARM64 runtime path explicitly uses emulated x64 Zig to
  produce ARM64 executables; native ARM compiler failures remain documented.
- **Verification:** 87/87 steps on each host; Mac 73/82 tests with 9 skips,
  Linux 74/82 with 8, Windows x64 and ARM64 75/82 with 7. Four new Queue/Select
  tests and Batch index assertions passed across the four runtime environments.
  28 Python tests and the 25-query retrieval policy passed. See
  [the publication receipt](reports/2026-09-04-publication-verification.md).
- **Postponed:** the user set aside M3-006 on 2026-09-05. No dedicated Windows
  deployment hardware is available and further qualification is not a current
  priority; existing GitHub-hosted runtime evidence remains valid within its limits.
  The curator service is inactive, with its weekly timer enabled and waiting.
- **Current scope:** the first M4 HTTP MVP is implemented in the private
  [zig-http project](https://github.com/technologylab-ai/zig-http). Linux io_uring
  and macOS kqueue pass native ownership/wire gates with exact Zig 0.16.0.
  Inline/gather/batching and Linux contender/deeper-pipeline experiments are
  implemented and pinned; remaining Windows HTTP, API/reliability and broader
  comparison work is queued. M3-006 stays postponed; the roadmap is not entirely complete.
- **Current measurement cadence:** user-directed Mac/Linux focus while HTTP
  performance is still being tuned. Repeated Windows measurements/publication
  gates for HTTP-only changes are deferred; existing receipts remain valid
  within their original scope. See the platform runbook.
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
| M1-006 | done | `Event`, `Queue`, `Mutex`, `RwLock`, `Condition`, `Semaphore`, and futex semantics plus nine runtime tests, including contended queue cancellation, partial transfer and close/join ownership. |
| M1-007 | done | Clock domains, durations, timestamps, one-deadline budgets, timeout conversion, cancelable sleeping, strict-clock guard caveats, and five runtime tests. |
| M1-008 | done | Files, directories, buffered readers/writers, exclusive read limits, flush versus truncation, atomic publication, and the directory-durability seam plus three runtime tests. |
| M1-009 | done | Networking and DNS queue/race ownership, stream/datagram lifecycles, bounded subprocess capture and termination, entropy failure policy, and five macOS runtime tests. |
| M1-010 | done | Host-backed `std.testing.io`, exact `Io.failing` behavior, fixed/failing stream adapters, ordinary and `-fsingle-threaded` execution, and four tests run in both modes. |
| M1-011 | done | `std.Io.Threaded` allocation, limits, thread growth, and eager dispatch seam. |
| M1-012 | done | Separate typed recovery codes from bounded human-facing diagnostics and reporting ownership. |

Exit condition: every public recommendation has a 0.16.0 source citation; every
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

## M3: evented I/O across operating systems (deployment qualification postponed)

Keep interface design separate from backend implementation.

| ID | Status | Deliverable / exit condition |
| --- | --- | --- |
| M3-001 | done | Pinned TigerBeetle `src/io` map distinguishing Linux `io_uring`, Darwin `kqueue` readiness plus synchronous file I/O, and Windows IOCP/overlapped I/O. |
| M3-002 | done | Linux kernel/feature floors, finite queues, registered-file/buffer ownership, target/cancel CQE reconciliation, exact Zig-layer readiness, and three Zig 0.16 runtime tests on `omarx1`. |
| M3-003 | done | Apple-primary `kqueue`, Dispatch I/O, and POSIX AIO lifecycles; exact Zig 0.16 Dispatch/Kqueue mapping and defects; a Zig/C adapter; macOS runtime proof; and bounded comparative evidence. |
| M3-004 | done | Pinned Microsoft/0.16 source, raw immediate/pending APC, fixed batch races and NPFS device-control cancellation, custom IOCP immediate/pending/cancel/shutdown ownership, finite limits/watchdogs, and bounded pipe/hot-file read metrics ran on Windows Server 2025. Initial-wait and wrapper-mode defects are explicit; broader qualification is M3-006. |
| M3-005 | done | Cross-platform decision table selects portable Threaded or platform-specific file/network backends with guarantees, limits, unsupported cases, ownership, resource models, and exact evidence gates. |
| M3-006 | postponed | Postponed by the user on 2026-09-05; resume only on explicit request with a concrete Windows deployment need and suitable test access. Available work complete: Winsock/batched TCP-to-file IOCP, file writes/flush/readback, cancel races, public stop/cancel/drain and x64/WOW64/ARM64 runtime gates. Remaining exit requires unavailable physical power-loss/controlled cold-storage evidence and a named deployment filesystem/device/driver/error/SLO matrix; immediate file-read and canceled file terminal results remain unobserved. Native ARM compiler failure is separate from the passing explicit ARM64 runtime path. |

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

## M4: synthesis project — TigerStyle evented HTTP server (MVP available)

The user authorized the initial implementation on 2026-09-05 after the design
session. [[bounded-http-server-design]] separates the implemented contract from
broader proposals. Runnable code is in the dedicated private zig-http project;
[[zig-http-mvp-2026-09-05]] pins its source and native evidence. It has fixed
startup slots and optional workers, bounded complete-body parsing and lazy headers, a borrowed
response path, explicit flush/resume/finish, finite refusal/deadlines and
cancellation drain. The original checkpoint passed 44 Debug and 44 ReleaseSafe test
executions plus 26 integration cases; current inline/gather/batch evidence below
passes 52 per mode and 26 generic + 10 inline + 11 gather + 22 batch cases. Finite smoke validated 30k exact responses
per host; these are client-bound experiments, not capacity or TechEmpower rank.

For the accepted first-iteration scope, M4-003 now owns the working Linux/macOS
slice; the remaining Windows HTTP adapter is explicitly split into M4-005.
M3-006 physical Windows deployment qualification remains postponed. The MVP's
pending/resume API is deliberately replaceable, with dynamic release and broader
reliability work retained under M4-006. All implementation subagents finished;
queued items have no assigned running agent. Current performance/ownership evidence
is pinned by [[zig-http-response-batching-2026-09-05]]; its measurements do not
claim production capacity or trustworthy tail latency.

| ID | Status | Deliverable / exit condition |
| --- | --- | --- |
| M4-001 | done | Capture the initial requirements, pinned HTTP/copy-avoidance/benchmark evidence, candidate reader/writer ownership model and unresolved design choices. This is an initial draft, not an accepted final architecture. |
| M4-002 | done | Establish the first experimental contract: fixed workers and per-slot mailboxes, complete bounded requests, lazy optional headers, explicit flush/resume/finish, requested-byte heap cap and plain loopback HTTP boundary. Implement parser/ownership/failure cases; future API revision remains M4-006. |
| M4-003 | done | Working standalone Linux io_uring/macOS kqueue HTTP/1.1 MVP with plaintext, preloaded HTML, echo, chunked flush/resume, native gates, watchdogs and retained-borrow shutdown. Source/evidence pinned; not production qualification. Windows portability is tracked explicitly in M4-005. |
| M4-004 | queued | Completed the recorded-performance-profile Linux depth sweep: 24 trials passed, Zig 1.74–1.92M/s versus libreactor 4.30–13.63M/s at depths16–128. Prior profile/EPP remain unknown; no controlled profile speedup is established. Completed pinned Linux baseline/client-sensitivity, inline/gather, batch1/16, one-core, deeper-pipeline32/64/128 and old/current control sweeps. Preserve gains, the fixed-batch plateau and unresolved host/code variation. Remaining: preloaded HTML comparisons, macOS contenders, dedicated-host/NIC saturation and qualified request tails. |
| M4-005 | queued | Implement Windows HTTP IOCP adapter and hosted native runtime gates; current server intentionally rejects Windows compilation. Separate from postponed M3-006 deployment qualification. |
| M4-006 | queued | Implemented/measured inline default, gather and bounded response cells with flush barriers, deferred compaction and multi-cell cancellation/deep-pipeline gates. Independent max-reasoning review is complete: next isolate token-addressed Linux operation cells, then batch16/64 × callback64/256, output representation and sharding. Offload, dynamic release and fault/combined-limit qualification remain. |

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
| L-009 | done | Installed weekly omarx1 consumer prefers maxross with Linux fallback, validates a current read-only packet, runs bounded semantic curation and independent gates, and opens a draft PR. Real PR #1, idle and idempotent fallback passed; root reviewed/merged separately. See the operational receipt. |
| L-010 | done | Read-only `review` reports coarse upstream-head differences and newer stable Zig releases while preserving source records and requiring an explicit upgrade workflow. |
| L-011 | done | A versioned 25-query benchmark scores the deterministic index/lexical layer; MRR 1.0, hit@3 1.0, and recall@5 0.96 after the performance/batching update meet policy; the preceding MVP had MRR 0.98, and the earlier design draft recall 0.94. |

The benchmark is a curated regression set, not production telemetry. Revisit
hybrid search when thresholds fail or real agent queries demonstrate misses.

## Research queue

- Implemented the Queue/Select follow-ups from
  [bounded review 33921176578](reports/curation-review-33921176578-1.md):
  zero-minimum contention, partial-transfer cancellation and re-armed fast
  progress, close/join with blocked callers, owned awaitMany prefixes, and
  actual Batch index assertions. Completed with clean exact-commit Mac, Linux,
  Windows x64 and ARM64 gates; historical reports retain their earlier gaps.
- Monitor a future Zig release through the explicit upgrade workflow; the 0.16
  inventory has no stale queued rows.
- M3-006 is postponed by user decision. If explicitly resumed, extend the
  completed Windows NPFS/IOCP fixtures against its named workload, device,
  error-path, and shutdown requirements.
- Completed the selected TigerBeetle storage/recovery/operations slice on
  2026-09-04 in [[durable-storage-and-recovery]], including focused implementation
  evidence. Future source selection remains question-driven; old Zig syntax
  must not enter guidance without an exact 0.16 proof.
- Future deployment qualification can extend the three-platform matrix with
  workload-specific filesystem/device, cold-storage and durability evidence;
  Windows deployment work remains postponed. ARM64/WOW64 fixtures have named
  runtime results with distinct compiler and process architectures.
- Verified-excerpt design is complete in
  [ADR 0002](docs/decisions/0002-verified-proof-excerpts.md): proof files remain
  canonical, future exports require provenance/drift gates, and wiki Zig fences
  remain forbidden. No renderer or tangler is enabled by that design.
