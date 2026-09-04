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
