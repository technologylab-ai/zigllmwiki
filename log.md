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

## [2026-09-04] ingest | std.Io synchronization primitives

Completed M1-006 with focused guidance for `Event`, `Queue`, `Mutex`, `RwLock`,
`Condition`, `Semaphore`, and futex operations. The page records cancellation
points, uncancelable shutdown risk, event reset preconditions, condition
predicate loops, queue partial-transfer/close behavior, fairness boundaries,
permit balance, and futex spurious wakeups.

Six Zig 0.16 tests exercise event and mutex cancellation, condition handoff,
bounded queue drain after close, shared/exclusive locking, semaphore permit
balance, and an atomic futex predicate loop.

## [2026-09-04] ingest | files, buffering, and atomic publication

Completed M1-008 from the installed Zig 0.16 `Io.File`, `Io.Dir`, reader,
writer, and atomic-file contracts. The new page separates buffered visibility,
file synchronization, atomic namespace publication, and containing-directory
durability instead of treating “saved” as one guarantee.

Three registered tests observe flush behavior, prove that a short positional
overwrite retains its old suffix until `Writer.end` truncates it, synchronize
and atomically replace a temporary file, and exercise the exclusive
`readFileAlloc` limit boundary. The page records the missing portable
directory-sync surface as an explicit seam rather than claiming crash
durability from replacement alone.

## [2026-09-04] ingest | std.Io clocks and absolute deadlines

Completed M1-007 from the installed Zig 0.16 time interface, release notes,
portable migration guide, hermit timeout evidence, and a pinned matklad design
note. The new page distinguishes real, awake, boot, process CPU, and thread CPU
clocks; raw from clock-tagged values; relative timeouts from one captured
absolute deadline; and cancelable sleeping from concurrent progress.

Five registered tests cover duration units and formatting, clock-tagged
arithmetic, timeout conversion, an absolute monotonic deadline, cancellation
of a threaded sleep, and the mechanics of an application-owned strictly
increasing guard. Suspend behavior, wall-clock jumps, and Linux/Windows runtime
coverage remain explicit platform gaps.

## [2026-09-04] ingest | networking, child processes, and entropy

Completed M1-009 from the installed Zig 0.16 networking, process, and entropy
interfaces. Three focused pages cover fixed DNS and connection-result queues,
losing-stream cleanup, stream/datagram ownership, one-deadline network budgets,
bounded dual-pipe process capture, wait/kill terminal paths, and the failure
policy difference between process randomness and fresh external entropy.

Five registered tests validate hostnames and literals, exchange data over a
real loopback TCP connection with explicit task and resource cleanup, exercise
inclusive process-output limits and owned output with an absolute deadline,
and execute both entropy operations without probabilistic assertions.

## [2026-09-04] ingest | testing I/O and single-threaded execution

Completed M1-010 with a guide separating host-backed `std.testing.io`, the
fixed hostile `std.Io.failing` profile, bounded fixed/failing stream adapters,
and whole-compilation `-fsingle-threaded` semantics. Four tests are registered
twice so ordinary verification executes them in both normal and explicitly
single-threaded modules.

The exact 0.16 implementation exposes a documentation mismatch worth retaining:
`Io.failing` returns a zero timestamp, treats sleep as a successful no-op, and
reports `ClockUnavailable` from resolution despite its broader prose saying
unsupported clock operations fail differently. The proof pins implementation
behavior for this release without generalizing it to future versions.

## [2026-09-04] ingest | bounded memory, integer domains, and persistence pairs

Completed M2-003, M2-004, and the bounded-memory/layout slice M2-009. Four
pinned matklad sources now support reserve-before-mutate, finite working state
versus retained output, screen-sized function review, and interior-pointer
lifetime decisions. The integer guide separates domain integers, `usize`
boundaries, native/ABI layout, and stable wire encoding.

Seven tests cover checked narrowing and arithmetic, explicit little-endian
encoding, reserved bits, and independent producer/consumer invariant checks
across malformed, corrupted, and semantically invalid records. Debug and
ReleaseSafe tests passed on macOS; Linux and Windows checks are compile-only
and are not presented as runtime evidence.

## [2026-09-04] ingest | function shape and centralized control flow

Completed M2-005 with applied guidance for the 70-line review bound,
inverse-hourglass shape, parent-owned policy and state mutation, bounded leaf
mechanics, positive nested decision trees, and iterative traversal in place of
input-shaped recursion.

Three tests exercise a centralized batch transition, the complete admission
decision space, and a fixed-stack traversal whose separate visit and capacity
limits reject cycles and excessive width. Mechanical size checks remain a
guardrail; whole-component semantic review still owns the claim that policy
and state are truly centralized.

## [2026-09-04] ingest | TigerStyle seams with Zig and OS resources

Completed M2-008 with a seam map that labels strict core, isolated exception,
and nonconforming dependency boundaries. It connects explicit-width domains to
`usize`, visible allocators to actual allocation lifetime, fixed application
state to `Io.Threaded` growth, portable `std.Io` calls to backend behavior, and
atomic publication to platform-specific durability.

The guide requires system-wide admission to include descriptors, kernel
queues/buffers, worker stacks, DNS/process state, completion capacity, and
drain rate. Existing proofs support individual boundaries; the page explicitly
does not promote them into a claim that the whole standard-library runtime is
startup-reserved or that OS behavior is uniform.

## [2026-09-04] ingest | bounded retries and defer ownership patterns

Completed M2-010 by pinning and synthesizing matklad's two retry-loop essays
and defer-pattern note. The new guide defines a total attempt limit, one
absolute deadline, transient/terminal classification, preservation of the last
cause, no final sleep, side-effect ambiguity, and cancellation-aware cleanup.

Four tests prove retry success/exhaustion counts, exact delay placement,
terminal-error preservation, expired-deadline behavior, and rejected attempt
limits. The defer patterns are constrained by explicit ownership transfer,
reverse cleanup order, and one reporting boundary rather than copied as
context-free idioms.

## [2026-09-04] ingest | performance sketches and bounded batching

Completed M2-006 with a resource/frequency worksheet, a quantified durable
command-server sketch, explicit control/data-plane ownership, finite queues,
and size/deadline/shutdown flush triggers. The worked arithmetic shows a case
where durability-call frequency breaks the headroom policy while raw disk
bandwidth still appears comfortable.

The registered Zig proof checks the capacity arithmetic and separates bounded
control-plane admission from a dense allocation-free data-plane loop. Its
runtime-parameterized executable performs warm-up, reports individual samples,
and consumes a correctness digest without imposing a nonportable timing
threshold; ordinary verification runs a small deterministic harness invocation.

## [2026-09-04] ingest | naming, comments, API shape, and formatting policy

Completed M2-007 from the pinned TigerStyle and Zig 0.16 style guides. The new
page makes their naming conflicts explicit, documents unit/qualifier and
allocator-lifetime names, options structs, positional unique dependencies,
callback ordering, top-down files, and reasoning-bearing comments.

The formatter proof now exercises the API-shape fixture, and deterministic
lint separately enforces TigerStyle's 100-character maximum across maintained
Zig files. Captured source snapshots, generated caches, and foreign-language
shims are deliberately outside that local Zig policy.

## [2026-09-04] ingest | macOS kqueue, Dispatch I/O, and Zig mapping

Completed M3-003 with pinned Apple Dispatch I/O headers and exact Zig 0.16
Dispatch/Kqueue source. The synthesis distinguishes readiness, Dispatch
channel completion, POSIX AIO, and bounded workers; it records that Apple
`Io.Evented` aliases Dispatch, whose regular-file path uses direct syscalls,
whose networking is unavailable, whose fibers reserve 60 MiB, and whose
`deinit` does not compile in this release.

A registered Zig/C Blocks adapter performs an actual Dispatch I/O read, while
a second test initializes Zig's Dispatch backend and completes an asynchronous
positional read. A seven-run hot-cache comparison is retained with strict
limitations: it measures this wrapper shape, not production backend quality.

## [2026-09-04] ingest | state lifetime, buffer hygiene, and division intent

Completed M2-011 with focused rules for one authoritative mutable state,
smallest scopes, near-use calculation and validation, const borrowing above
TigerStyle's 16-byte review threshold, and viral in-place initialization for
address-sensitive values. The guidance treats the threshold as project policy,
not a Zig ABI guarantee, and requires ownership or revalidation across every
suspension gap.

The companion buffer/arithmetic guidance prevents stale-tail disclosure,
rejects native struct memory as a wire format, separates ordinary zeroing from
secure erasure, and names exact, floor, and ceiling division semantics. Three
Zig 0.16 tests exercise large-value borrowing, nested final-address identity,
complete fixed-buffer initialization and reuse clearing, remainder rejection,
signed floor/ceiling behavior, and division by zero.

## [2026-09-04] ingest | Linux io_uring and blocked-call cancellation

Completed M3-002 on `omarx1` with Zig 0.16.0, x86_64 Linux
`7.1.9-arch1-2`, and enabled `io_uring`. Three low-level ring tests prove
finite submission capacity plus opcode probing, registered file/buffer
ownership after the original descriptor closes, and separate target/cancel CQE
reconciliation. A fourth test proves that `Io.Threaded` cancellation interrupts
and joins a worker blocked in a Linux pipe read.

The guide now distinguishes the low-level `std.os.linux.IoUring` wrapper from
the incomplete high-level `std.Io.Uring` backend and retains explicit gaps for
older kernels, filesystems/devices, multishot operations, resource tags,
performance, and product-load behavior. `tools/verify_linux_ssh.sh` preserves a
repeatable full-suite runner using the temporary workspace on `omarx1`.

## [2026-09-04] ingest | exact Zig Windows I/O mapping

Expanded M3-004 with the exact Zig 0.16 Windows source and a compile-only proof
for x86, x86_64, and aarch64 Windows. The synthesis corrects a critical
assumption: `std.Io.Threaded` is not IOCP. It combines synchronous worker I/O
with selected APC-based NtDll/AFD paths, while Windows `Io.Evented` is `void`.
IOCP remains a custom backend design with stable `OVERLAPPED` and terminal
cancellation ownership. Windows runtime and load evidence remain queued.

## [2026-09-04] ingest | cross-platform I/O backend decision table

Completed M3-005 with an agent-facing decision matrix for the `std.Io`
contract, shipped Threaded implementation, low- and high-level Linux uring,
macOS kqueue/Dispatch choices, Windows APC/NtDll behavior, and custom IOCP.
Every row separates file from network behavior and records limits, unsupported
operations, cancellation ownership, allocation/resources, and exact evidence.

## [2026-09-04] maintenance | deterministic agent command layer

Added read-only `query` and `lint` commands plus plan-only `ingest` and
`upgrade` commands. Versioned JSON exposes page scope/evidence and stable lint
codes; local-source ingest validates SHA-256, and upgrade planning never changes
`.zig-version`. Seven focused Python tests protect the non-mutation and schema
contracts.

## [2026-09-04] ingest | TigerStyle design and tooling closure

Completed M2-012 and the rule-by-rule TigerStyle pass: all 71 principles in the
pinned revision now map to focused guidance, with zero partial or missing rows.
The new pages define replaceable design sketches, zero-safety-debt and bounded
exception policy, dependency admission, the deliberate Python/Zig tooling seam,
exact Zig 0.16 diagnostic and safety controls, lower-dimensional APIs, and an
ownership-aware error-path/fault-injection catalog.

Two Zig tests traverse every injected pipeline error and validate cleanup plus
forbidden publication. The generated-code tool verifies the exact compiler,
emits ReleaseSafe assembly for a focused exported leaf, locates its symbol, and
reports source and assembly hashes; an assembly hash remains change evidence,
not a portable performance threshold.

## [2026-09-04] ingest | Zig 0.16 API migration traps and queue closure

Audited every release-inventory row that still pointed at a completed M1, M2,
or M3 deliverable. The new migration map captures current language and
representation changes, arena/container ownership, memory-map synchronization,
selective walking, optional access time, explicit process/path policy,
reader/writer allocation APIs, build diagnostics and temporary files, and
Smith/crash-corpus behavior.

All named Zig 0.16 release-note topics now resolve to integrated guidance, a
specific watch decision, or explicit out-of-scope reasoning; none remain in a
stale queued state. Windows AFD/NtDll topics are linked to the source-verified
platform mapping, while actual Windows behavioral and load evidence remains a
separate queued roadmap gate. Bundled Linux/macOS/MinGW headers are kept as
toolchain watches rather than misreported as runtime support floors.

## [2026-09-04] maintenance | scheduled review and retrieval policy

Added a weekly/manual GitHub Actions workflow that installs the exact
checksum-verified Zig baseline, runs every registered proof and command test,
checks pinned-source heads and Zig releases, evaluates retrieval, proves the
checkout stayed unchanged, and uploads a 30-day review packet. Its repository
permission is deliberately read-only: a separately authorized coding agent is
still required to inspect a packet and propose a content-changing pull request.

Established a reviewed 25-query regression set for the deterministic index and
lexical query layer. The first local run produced MRR 1.0, hit@3 1.0, and
recall@5 0.98, so hybrid retrieval is not justified by current evidence. The
benchmark is not production telemetry; its dated report records adversarial,
multilingual, scale, latency, and independent-labeling gaps.
