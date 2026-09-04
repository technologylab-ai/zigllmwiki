# Maintenance log

Append entries with `## [YYYY-MM-DD] operation | subject`. Do not rewrite older
entries; later entries may correct them.

## [2026-09-04] bootstrap | Zig LLM Wiki foundation

Established the Zig 0.16.0 baseline, source records, page schema, Obsidian-first
decision, agent skill, deterministic verification, and seed synthesis pages.
The first runtime proof captures the `std.Io.Threaded` difference between
`async` fallback and `concurrent` failure.

## [2026-09-04] ingest | matklad and TigerBeetle systems corpus

Pinned and synthesized six matklad essays covering startup allocation and
constant work, cancellation vocabulary, `std.Io.Threaded`, error diagnostics,
newtype indexes, and `zig fmt`. Added Zig 0.16 proofs for fixed-pool mechanics,
telescoping diagnostic capture, typed indexes, and formatter-preserved layout.

Pinned TigerBeetle architecture, safety, performance, VOPR, and data-file
documents. Integrated the first four into decision pages, retained data-file
synthesis as an explicit pending item, and added a curation ledger that exposes
source status and the next matklad/TigerBeetle clusters.

## [2026-09-04] ingest | structured lifetimes and io_uring lifecycle

Made M1 and M2 status visible as numbered roadmap tables. Pinned and synthesized
matklad's `io_uring`, UNIX process-lifetime, language-server cancellation, and
async-mutex essays, plus primary liburing interface and cancellation manuals.

Added task-lifetime and Linux `io_uring` decision pages. A Zig 0.16
`std.Io.Threaded` proof now exercises `Future.cancel`, `Group.cancel`,
`recancel`, cancellation protection, and terminal owner synchronization on
aarch64 macOS. Linux and Windows blocked-syscall behavior remains explicitly
active rather than implied complete.

The same pass added a watchdog-bounded macOS proof that cancels an
`std.Io.Threaded` future while its worker is blocked inside a pipe read.

## [2026-09-04] ingest | error control flow and bounded diagnostics

Pinned matklad's error-code, diagnostics-factory, second-error-model, and code
archaeology essays. Close reading reclassified “Always Be Blaming” from the
diagnostics cluster into source archaeology, and the curation ledger records the
correction.

Added a decision page separating typed recovery codes, invariant failures,
human-facing evidence, and reporting ownership. A Zig 0.16 proof implements a
fixed-capacity diagnostic factory with explicit overflow and no allocation.

## [2026-09-04] lint | complete TigerStyle coverage inventory

Inventoried all 71 principles in the pinned TigerStyle document. The coverage
map records 10 covered, 31 partial, and 30 missing items, with an existing page
or named target for every row. M2-001 is complete; the uncovered guidance and
proof work remains visible under the other M2 items.

## [2026-09-04] ingest | TigerBeetle cross-platform I/O implementation

Pinned and inspected TigerBeetle's current `src/io` implementation across
Linux, Darwin, and Windows. Added a source-verified comparison of caller-owned
completion records, serialized dispatch, finite queue behavior, Linux
`io_uring`, Darwin one-shot `kqueue` readiness with synchronous regular-file
operations, and Windows IOCP/overlapped operations.

The synthesis records two negative findings agents must preserve: the custom
interface is not Zig 0.16 `std.Io`, and it exposes no general cancellation
operation. M3 now has numbered status items so the remaining OS-primary and
runtime work is visible rather than folded into prose.

## [2026-09-04] ingest | invariants, review, and benchmark evidence

Pinned and synthesized matklad's invariants, bug-finding, mechanical-habits,
and optimizer-resistance essays. Added focused pages for invariant derivation
and assertion placement, whole-subsystem control-flow/state review, mechanical
repository checks, and correctness-bearing microbenchmarks.

A Zig 0.16 proof derives lower-bound insertion search from a preserved
partition, asserts bounded progress, and exercises the positive and negative
candidate space. The TigerStyle coverage ledger moved from 10 covered, 31
partial, and 30 missing principles to 17 covered, 30 partial, and 24 missing.
M2-003 is now active with its remaining persistence-boundary proof named.

## [2026-09-04] ingest | primary macOS and Windows I/O lifecycles

Pinned current Apple XNU `kqueue` and POSIX AIO manual sources and Microsoft
IOCP, overlapped-I/O, and `CancelIoEx` documentation. Added separate platform
pages distinguishing readiness from file-operation completion, recording stable
control-block and buffer ownership, immediate-success behavior, completion
ordering, cancellation races, and terminal cleanup.

M3-003 and M3-004 are now active with their completed source evidence and
remaining dispatch-I/O, Zig adapter, and platform-runtime work stated
separately.

## [2026-09-04] ingest | portable local-source snapshots

Imported byte-identical snapshots of the `fi` Zig 0.16 migration guide and all
three zig-hermit timeout proof artifacts. The source records preserve their
original repository commits, absolute origin paths, and individual SHA-256
values. Wiki verification now recomputes each declared snapshot hash, making
the evidence portable without treating copied experimental code as an active
wiki proof. C-003 is complete.

## [2026-09-04] ingest | Zig 0.16 release-note scope inventory

Inventoried every named table-of-contents topic in the official Zig 0.16.0
release notes. Each topic now routes to already-integrated guidance, a numbered
roadmap destination, a version/platform watch, or an explicit out-of-scope
decision. This closes C-004 without duplicating the release document or
pretending queued standard-library work is already complete.

## [2026-09-04] lint | graph scoring and first semantic audit

Added deterministic JSON graph health through `zig build graph`. Each wiki page
is scored for index discovery, non-index backlinks, outward conceptual links,
and cited source records; true orphans now fail ordinary verification. Added a
reusable semantic-audit procedure and the first dated review report.

The audit corrected three overstated release-inventory dispositions and added
a natural version-baseline backlink. It found no orphan or weak pages and
retained the remaining Linux, macOS, and Windows runtime gaps as active roadmap
evidence rather than promoting source inspection into runtime verification.
L-004 and M0 are complete; M1/M2 content expansion remains active in parallel.

## [2026-09-04] ingest | process initialization and capability threading

Completed M1-001 from the installed Zig 0.16 `process.zig`, `start.zig`, and the
portable `fi` migration guide. The new page keeps `std.process.Init` at the
executable composition root, records allocator/environment/argument/preopen
ownership, and shows how to pass narrower capabilities into libraries without
hardcoding an I/O implementation.

The registered proof is compiled both as tests and as an executable; ordinary
verification runs a real `main(init: std.process.Init)`, uses the allocating
cross-platform argument iterator, and supplies caller-owned I/O/allocators to a
leaf operation.

## [2026-09-04] ingest | Select and Batch ownership

Completed M1-003 from the installed Zig 0.16 `Io.zig` contract. The new page
separates typed `Select` tasks from low-level fixed-storage `Batch` operations,
including eager versus required concurrency, completion identity, partial
draining, cancellation races, and the Select cancellation-buffer deadlock
precondition.

The proof returns owned memory through two select branches and drains every
result, then drives two file reads through a two-slot batch while accepting
arbitrary completion order and dispatching by result tag/index.
