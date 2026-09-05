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

## [2026-09-04] runtime | Windows mapping and blocked-read cancellation

Added a manual, read-only Windows Actions runner that checksum-verifies the
exact Zig release, records host/toolchain metadata, runs the full verifier and
the Windows proofs explicitly, and retains its evidence packet for 30 days.
The first run executed the exact `std.Io` mapping and synchronous named-pipe
cancellation proofs successfully on x86_64 Windows Server 2025 Datacenter 24H2,
build 26100.33296, with Zig 0.16.0.

That run also exposed repository-wide Windows portability failures rather than
hiding them: checkout CRLF conversion invalidated byte-identical snapshots and
formatting, and the process proof hard-coded `/bin/sh`. The follow-up enforces
LF through `.gitattributes`, selects `cmd.exe` on Windows, and makes the public
Gist revision check independent of repository-token API scope. Custom IOCP,
APC/batch/device race breadth, and load evidence remain M3-004 work.

## [2026-09-04] verification | hosted Linux and Windows gates green

The repaired read-only Linux workflow passed every proof, command test, source
review, retrieval threshold, and checkout-mutation guard in Actions run
33911520101. The Windows workflow then passed 70/70 build steps, 67/74 tests
with 7 intentional platform skips, the native implementation-mapping proof,
and the blocked synchronous pipe-cancellation proof in run 33911991858.

The successful Windows run used x86_64 Windows Server 2025 Datacenter 24H2,
build 26100.33296, and exact Zig 0.16.0. It validates the portable suite and
narrow Threaded evidence on that host; it does not close the custom IOCP,
APC/batch/device breadth, native x86/aarch64, or production-load gates.

## [2026-09-04] ingest | bounded Windows cancellation and IOCP fixtures

Continued from clean `main` at `ddb680360aaa6c274fc36f23030e200ba832410f`,
matching freshly fetched `origin/main`. Exact Zig 0.16.0 baseline verification
passed 70/70 steps and 69/74 tests with 5 macOS platform skips after rerunning
outside sandbox restrictions on library access and loopback networking.

Pinned additional Microsoft SDK and NT filesystem-control contracts before
synthesis. Registered separate APC/batch/NPFS-device and custom IOCP harnesses
with fixed operation storage, explicit cancellation/result ownership,
watchdogs, and bounded workload fixtures. Extended the manual Windows packet
with hardware/filesystem metadata, native proof logs, command/retrieval gates,
and checkout-mutation enforcement. Aligned the Linux SSH wrapper with the
runbook's exact-version, host-metadata, and full-summary requirements.

Source analysis exposed `Threaded.batchCancel`'s unbounded initial alertable
wait before `NtCancelIoFileEx`. The Windows and Select/Batch pages now separate
that implementation progress defect from the interface's terminal ownership
contract. Windows execution of the new harnesses is still pending at this
entry. An early Linux development archive captured proof files during agent
edits and failed formatting/registration lint; it is not runtime evidence for
the new work and will be superseded by clean-commit gates.

## [2026-09-04] runtime | first M3-004 Windows results and fixture corrections

Clean commit `1fa9d1aba72604894c907c5862af3f3f8b0e7783` passed Linux on
`omarx1` with 82/82 steps, 70/77 tests, and 7 skips. Windows
[run 33914988881](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33914988881)
used Zig 0.16.0 on x86_64 Windows Server 2025 Datacenter 24H2 build
26100.33296. The APC harness passed: raw empty-read/quota-write returned
`PENDING`, preloaded-read/small-write returned `SUCCESS`, idle batch cancel
remained unfinished in the 100ms observation then completed after an explicit
`NtAlertThread`, and NPFS direct/batch cancellation and retained success passed.
The separate native batch race observed 3 successes and 29 cancellations;
the full-verifier invocation observed 31 and 1. Neither distribution is required.

Both custom IOCP pipe notification modes passed immediate/pending, cancellation,
bounded load, and shutdown checks, but the regular-file fixture failed its
`File.flags.nonblocking` assertion. Exact source inspection found that
`dirOpenFileWtf16` requests asynchronous NT mode for `follow_symlinks = false`
yet hard-codes false wrapper metadata. Replacing that fixture with an explicit
NT open avoids the inconsistency; this failure did not measure kernel mode.
The complete Windows gate was 80/82 steps, 69/77 tests, 7 skips, 1 failure.
The checkout-status step also failed because empty `git status` output never
created its `Tee-Object` file; explicit packet creation fixes this separate
workflow error. No full Windows success is claimed for this run.

## [2026-09-04] runtime | M3-004 native evidence complete; Windows command fix

At `959a93ac690abbde9f9ea55cf5f06437fedcec30`,
[run 33915530939](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33915530939)
passed 82/82 Zig steps, 70/77 tests with 7 skips and all four standalone Windows
proofs. The host was x86_64 Windows Server 2025 Datacenter 24H2 build
26100.33296, Zig 0.16.0 Debug, image `win25-vs2026`/`20260824.214.3`,
PowerShell 7.6.5, reported AMD EPYC 7763 with two logical processors and
8,584,425,472 bytes RAM, NTFS and Microsoft Virtual Disk devices.

Both IOCP notification policies reconciled their bounded pipe lifecycles,
including four pending reads at shutdown. Each pipe/file load sample completed
256 cycles of four 64-byte reads with validated checksums. File reads were all
pending; immediate success was observed on prefilled pipes. The exact timings,
status counts, APC/NPFS results, and watchdog limits are preserved in the
Windows page. M3-004 is complete at this bounded scope; M3-006 separately queues
Winsock/file-write/cold-storage/driver/durability and unassisted-shutdown
qualification. Related pages, the decision table, curation, retrieval map, and
handoff reflect those boundaries without broad runtime-status promotion.

The same workflow then exposed a command-layer portability bug: `urlparse`
treated a local Windows drive letter as a remote scheme. Local path detection
now accounts for Windows drives, with a cross-platform regression test while
retaining remote HTTPS validation. All 16 Python command/retrieval tests pass
locally. This historical workflow remains a failure overall; final publication
gates rerun the corrected command layer and unchanged native proofs.

## [2026-09-04] maintenance | two-host execution preference and Windows runner boundary

Recorded the user's host policy in `AGENTS.md`, the platform runbook, retrieval
map, and handoff: both `omarx1` and the M3 Max Mac `maxross` are authoring hosts;
prefer `ssh maxross` from Linux for expensive portable work when available,
and continue feasible work on Linux when travel/connectivity makes the Mac
unavailable. The procedure bounds the availability probe, preserves remote
checkout edits, identifies the input tree and exact compiler, and leaves
unavailable macOS-native evidence pending. The Linux SSH wrapper remains
Linux-specific. This policy update does not assert that reverse SSH was tested.

Clarified that Windows runtime tests use GitHub-hosted Windows VMs; no local
Windows VM or self-hosted Windows runner is configured for this project.
Windows cross-compilation on macOS/Linux is distinct from runtime evidence.
Confirmed the previously completed publication workflow
[run 33916448015](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33916448015)
is successful at `e6eb0b58a0779f50f43a1fea5d07019a44618231` and preserved that
result in the handoff. This documentation change does not extend proof scope
or change the queued M3-006/L-009 roadmap work.

## [2026-09-04] ingest and audit | complete selected storage synthesis and expand Windows qualification

Continued from clean main `000989dcbaaf548a68fefc943c88c4e19a6a6153`, matching
origin after the user's Obsidian-settings change. Exact Zig 0.16.0 baseline
passed 82/82 steps, 69/77 tests with 8 macOS skips. User reserved M4 for a
separate in-depth session.

Pinned five TigerBeetle storage/recovery/operations source slices at
`47aeb2212a255273dda508288412e537d11e4b7c` and synthesized the selected documents
plus named implementation symbols into one linked durable-storage page. It
preserves per-beat versus documented half-bar reservation, fatal capacity
exhaustion, delayed block reuse, recovery authority, and submitted-I/O drain
boundaries. No TigerBeetle engine was built or run.

Pinned the focused Microsoft Winsock/batched-result/flush contracts before
adding a registered four-slot TCP-to-file proof. Exact 0.16.0 cross-compilation
now includes x86/x86_64/aarch64. It covers public socket I/O, partial transfers,
file write/flush/readback, cancellation races, per-operation batched results,
and independent shutdown; native Windows execution is still pending here.
The physical storage and deployment qualification gap is not closed by a VM.

A fresh semantic audit reviewed 50 navigable pages, 59 records, 31 Zig proofs
and the C shim, with seven corrected findings and no remaining high/critical
finding. Fixed Threaded prewarming/allocation wording, Group.await propagation,
RwLock fast-path wording, Dispatch STOP error qualification, stale platform/DST
claims, and invalid page kinds. Kind validation now enforces the agent contract.
The follow-up report preserves the historical audit and exact review scope.
The proof-excerpt design is documented without enabling wiki Zig fences.

Implemented a local review-packet consumer with isolated agent edits and
separate gh publication, bounded Markdown changes, immutable-source and
append-only-log checks, exact-revision gates, and retained failure artifacts.
Publication-boundary review and end-to-end runtime validation are in progress;
no timer or autonomous PR is claimed at this entry.

## [2026-09-04] runtime and maintenance | x64 TCP/file evidence and isolated-curator failure

At `0bdca5a38331fe9ae0a3db04cc4a6955152969fc`, the Mac passed 87/87 Zig steps,
69/78 tests with 9 skips; Linux omarx1 passed 87/87, 70/78 with 8 skips.
[Read-only run 33919880936](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33919880936)
and [Windows run 33919878353](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33919878353)
passed, including 27 Python tests and the 25-case retrieval policy. Windows
passed 87/87, 71/78 with 7 skips and all five standalone native proofs.
The Windows page retains the exact x64 image, virtual disk, all TCP/file counts
and timings, and unobserved regular-file canceled results/short receives.

The first live Codex consumer read that packet and proposed a bounded semantic
correction. Its independent caller gate rejected publication: the linter
excluded every source candidate when the checkout itself lived beneath an
outer `.zig-cache` directory. Cache filtering now uses paths relative to the
checkout root; a nested-checkout regression covers this. The trial's sandbox
also denied a loopback bind; trusted caller gates remain outside that sandbox.
The proposal and failed result remain in the local state directory; no PR was
published by that trial. Reviewed content findings are handled separately.

Installed the omarx1 user-systemd timer, enabled for Monday 05:17 UTC; the
preexisting manager has Linger=yes. The timer is waiting, and service routing
and successful PR publication remain to be tested. Added the Mac's actual
`/Users/rs/bin` Zig path to the bounded host probe. Expanded the Windows workflow
to native ARM64 and x64 plus x86 process execution under WOW64, with compiler
and test PE architecture checks; these new runtime gates are pending.

## [2026-09-04] maintenance | bounded queue and Select review 33921176578

Inspected the caller-authenticated packet for run `33921176578`, attempt `1`,
at matching clean base `0e82e97e6eb9314c4dd70cecdedd3449556bdd81`.
The packet reports 87/87 Linux steps, 70/78 tests with 8 skips, 28 Python tests,
and passing retrieval policy. Its nine upstream-head differences did not
establish stale guidance or justify changing any source revision.

Reviewed two wiki pages, three source records, and two portable proofs.
Installed Zig 0.16.0 source qualifies queue zero-minimum calls as still subject
to mutex contention, permits short `Select.awaitMany` delivery on cancellation,
and requires joining both producers and consumers after queue closure before
reclaiming storage. Documented the re-armed-cancellation/fast-path caveat and
added a reciprocal Select-to-synchronization link. The synchronization page is
now source-verified while preserving its six historical runtime tests; new
contention/partial-transfer/shutdown proofs require separate authority and are
queued in the roadmap. No proof, source record, tool, workflow or version changed.

[The bounded report](reports/curation-review-33921176578-1.md) records exact
source hashes, findings, inspected scope, and limitations. Local macOS arm64
26.6.2 build 25G83, Zig 0.16.0 verification passed structural checks but failed
the loopback bind with errno 1: 85/87 steps, 68/78 tests passed, 9 skips,
1 failure. This also occurred on the clean base and is consistent with the
sandbox network restriction. Graph and retrieval policy passed; the caller's
independent gates and publication remain pending. No new Linux/Windows runtime
evidence, full-vault semantic pass, or successful curator publication is claimed.

## [2026-09-04] maintenance | installed curator opens its first reviewed PR

The installed omarx1 service selected maxross and consumed successful packet
33921176578 at `0e82e97e6eb9314c4dd70cecdedd3449556bdd81`. The bounded agent
found Queue/Select contention, partial-delivery and join-ownership corrections.
Its sandbox denied loopback binding; the independent caller subsequently
passed all 87 Zig steps, 69/78 tests with 9 skips, 28 Python tests and the
25-query retrieval policy. The caller published
[PR #1](https://github.com/technologylab-ai/zigllmwiki/pull/1), and the owning
interactive agent separately reviewed and merged it as e3fccc362e8b4504b3660916e4bde277fe104667.
The consumer never merged automatically.

Service routing to the Mac, an unavailable-Mac idle fallback, and a repeat
service invocation falling back to Linux and finding the existing PR all
passed. No duplicate agent or PR was started. The service exited successfully;
the enabled Monday 05:17 UTC timer is waiting. L-009 is complete at this bounded
operational scope; new queue proof gaps are being implemented separately.
[The operational receipt](reports/2026-09-04-curation-operations.md) preserves
exact phases and the first failed trial without retroactive success claims.

## [2026-09-04] proof | exercise curator-found queue and Select ownership cases

Added four tests to the existing registered synchronization and Select/Batch
proofs: zero-minimum mutex contention, partial put/get cancellation followed by
fast progress and explicit checkCancel, close with blocked producers/consumers
and separate join, and a short owned awaitMany prefix with an untouched sentinel.
The Batch fixture now actually asserts bounded unique completion indexes.
Exact implementation-state witnesses avoid inferring submission from sleeps;
finite attempt counts and native watchdog threads retain ownership on failures.

On arm64 macOS 26.6.2 build 25G83, exact Zig 0.16.0 passed 87/87 steps,
73/82 tests with 9 skips (nine synchronization and three Select/Batch tests).
Linux/Windows publication gates remain pending for these new cases. Historical
curator reports and six/two-test results are unchanged. Guidance, retrieval,
curation and roadmap now distinguish implemented proofs from platform evidence.

## [2026-09-04] runtime | WOW64 and ARM64 execution with explicit compiler boundaries

At 0e82e97, [run 33921176754](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33921176754)
passed its x64 job and all five x86 executables under WOW64. Its ARM64 job
failed overall while three standalone native compiler/test commands passed.
Diagnostic branch commit `96215657c1e682334f40b7b0d77cc0a6688da4ca` in
[run 33921810785](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33921810785)
separated compilation and execution: all five default native ARM compiler
attempts failed with -1073741819 before launching a test; seven of eight focused
variants also failed. No general native-compiler remedy or root cause is claimed.

The same diagnostic job used the checksum-verified exact 0.16.0 x64 compiler
under Windows ARM emulation, compiled ARM64 baseline PEs, verified their machine
headers and executed all five successfully on Windows 11 ARM64. The full ARM64
target gate passed 87/87 steps, 71/78 tests with 7 skips, explicit ARM64 assembly,
28 Python tests and retrieval/clean checks. These successful phases do not turn
the original diagnostic workflow's overall failure into success.

The Windows page preserves Cobalt 100 / Windows 11 Enterprise 25H2 build 26200.9168,
image win11-arm64/20260830.155.1, 8,579,493,888 bytes RAM, NTFS C: and virtual-device
identities, measured TCP/file counts and timings. ARM64 observed all 64 file
writes pending while x64/WOW64 observed immediate writes; none of the file
cancellation races produced a canceled file result. The final workflow uses an
explicit x64-compiler/ARM64-runtime qualification path with optional fatal
native-compiler diagnostics. Physical deployment evidence remains unavailable.

## [2026-09-05] verification and handoff | all available gates pass; deployment evidence blocked

Clean pushed a92ec380adaad914a304021d1502a77e93dd549c passed 87/87 build steps
on maxross, omarx1 and both hosted Windows targets. Mac passed 73/82 tests with
9 skips; Linux 74/82 with 8; Windows x64 and ARM64 each 75/82 with 7. All 28 Python
tests and the 25-query retrieval policy passed. The
[Windows matrix 33922946389](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33922946389)
and [read-only review 33922946096](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33922946096)
concluded success on that exact commit, including the new Queue/Select proofs,
five standalone binaries per Windows job and all five WOW64 binaries. No proof
or compiler was weakened to hide the separate native ARM compiler failures.

The [publication receipt](reports/2026-09-04-publication-verification.md)
preserves proof hashes and exact environments, including the new Intel Xeon
6973P-C/NVMe x64 runner rather than silently reusing older AMD host metadata.
Updated current evidence counts, reciprocal retrieval, curation, roadmap and
handoff. L-009, selected storage synthesis, semantic/curator fixes and excerpt
design are complete; all subagents and the curator finished, timer waiting.
M3-006's available fixture work is complete but its broad deployment exit is
blocked by unavailable physical power-loss/controlled cold-storage and named
deployment driver/error/SLO evidence. M4 remains reserved. This documentation
publication is followed by the required exact-final-commit local/Linux/Windows
gates; it does not predict their outcome or rewrite earlier failure records.

## [2026-09-05] roadmap scope | postpone M3-006 by user decision

The user postponed Windows deployment qualification because dedicated Windows
deployment hardware is unavailable and further qualification is not a current
priority. Updated ROADMAP.md, HANDOFF.md, CURATION.md and the index to keep it
out of active curation until explicitly resumed with a concrete deployment need
and suitable test access. Existing GitHub-hosted Windows runtime results and
all physical durability, driver/workload and unobserved-path limits remain
intact. This is a scope decision, not completion or a new platform claim.
M4 remains reserved for its own session.

Local exact Zig 0.16.0 verification passed 87/87 steps, 73/82 tests with
9 platform skips. The 25-query retrieval policy passed (MRR 1.0, hit@3 1.0,
recall@5 0.98). This documentation-only scope update adds no runtime evidence.

## [2026-09-05] M4 design | bounded HTTP framework and response writer ideas

The user opened the reserved M4 design discussion and requested a Linux-first
HTTP/1.1 framework with macOS/Windows support, TigerStyle startup limits, borrowed
request access and an asynchronous response writer supporting incremental writes
and flush. Pinned HTTP RFCs, Linux network copy-avoidance docs and TechEmpower
HTTP test requirements before writing [[bounded-http-server-design]]. Inspected
exact Zig 0.16 Reader and HTTP Server ownership comments.

The draft distinguishes framework copies from kernel copies, finite request
policy from finite streaming memory, application upload parts from HTTP chunks,
and writer submission from safe buffer reuse. It records explicit backpressure,
partial sends, deferred handlers, lifetime and shutdown questions. Refreshed
reciprocal links, index, curation, roadmap and handoff. M4-001 records an initial
draft; remaining design/implementation/measurement items are queued. M3-006 stays
postponed. No new executable API, server benchmark, subagent or remote run was
created for this design discussion.

Follow-up requirements make evented progress and extensive TigerStyle assertions
explicit. The draft bounds work per loop turn, rejects blocking on an event-loop
worker, distinguishes callback budgets from preemption, and derives assertions
for pool conservation, generations, parsing, partial writes and shutdown.
Adversarial request validation remains ordinary error handling.

Local exact Zig 0.16.0 verification passed: 87/87 steps, 73/82 tests and
9 platform skips, with 51 navigable pages and 62 source records. All 25
retrieval cases passed policy: MRR 1.0, hit@3 1.0 and recall@5 0.96, down from
0.98 after adding the draft. Historical measurements remain unchanged.

## [2026-09-05] M4 execution design | startup workers, lazy headers and finite admission

Collected the user's follow-ups into the existing HTTP draft: compare leading
TechEmpower implementations on our hardware; demonstrate a constant response
and small index.html; decouple arbitrary callbacks; create threads at startup;
interpret optional headers lazily; and refuse new requests when bounded
backpressure reaches capacity/deadline limits.

Pinned the actual plaintext driver at 57d92fbec6f8fd7431bc77326dd0484e60c96e20
(13-byte Hello, World! body, pipeline depth 16) and Microsoft TerminateThread
source before synthesis. Inspected exact Zig 0.16 Thread spawn/join contracts
and existing ownership/DST guidance. The draft proposes fixed I/O/application
workers, bounded handle/response/terminal credits, and retained memory when
timed-out callbacks still run. Generation IDs do not invalidate pointers.
Lazy interpretation preserves full framing/Host/length validation. Preloaded
HTML is explicitly memory-resident serving, not per-request storage evidence.

Refreshed reciprocal links, retrieval index, curation, roadmap and handoff.
M4 execution choices remain proposed and its final design/implementation gates
remain queued; M3-006 remains postponed. No subagent, remote runner, server or
competitor benchmark was started for this discussion.

Pinned RFC 9110 section 15.6.4 separately for overload refusal. Benchmark
notes retain production assertions/safety checks and distinguish callback
isolation from the optional trusted/static path.

Local exact Zig 0.16.0 verification passed 87/87 steps, 73/82 tests with
9 platform skips (51 pages, 65 sources). The 25-query retrieval policy passed
with MRR 1.0, hit@3 1.0 and recall@5 0.96. No new runtime evidence is claimed.

## [2026-09-05] M4 reliability contract | provision and test the configured maximum

The user clarified that limits are commitments: support the full configured
load reliably and refuse work beyond it. Added joint worst-case capacity
derivation, the distinction between open connections and simultaneous active
requests, and exact-limit/over-limit/recovery acceptance criteria. Resource
safety, progress/failure behavior and workload-specific performance guarantees
are separate obligations. Bounded refusal work and latency-compatible queues
are part of the budget. Updated roadmap and handoff; no implementation or
performance guarantee is claimed by these design notes.

The user further clarified responsibility: the framework guarantees its own
resource/admission bounds, while application developers own workload/performance
targets. Added bounded measurement tools for pool/queue usage, handler time,
event-loop lag, output stalls, rejection causes and response latency. The
reference server will demonstrate a recorded normal-web profile; its numeric
limits and performance remain to be measured.

Verification of the expanded resource/measurement draft passed exact Zig
0.16.0: 87/87 steps, 73/82 tests with 9 skips. The 25-query retrieval policy
passed with MRR 1.0, hit@3 1.0 and recall@5 0.94 (previous draft 0.96).
Updated current roadmap/handoff metrics without rewriting historical results.


## 2026-09-05 — Working M4 HTTP MVP and Linux ReleaseSafe linker lesson

Implemented the first standalone private zig-http MVP after user authorization,
using independent parser, transport, integration and lifecycle/doc review agents.
Pinned source 6d622009abee5807eb0829e558c3173635e077ea and the native packet in
[[zig-http-mvp-2026-09-05]] before extending the existing design synthesis. Exact
Zig 0.16.0 on Mac M3 Max/macOS 26.6.2 build 25G83 and omarx1/Omarchy 4.0.2/kernel
7.1.9-arch1-2/io_uring_disabled=0 passed 44 test executions per mode and 26 wire
integration cases each. Source/binary/asset hashes and all fixture bounds are
preserved. The 26 include combined exact body/connection limits and recovery.
A strengthened slow-reader witness excludes the first Linux fixture's completed
response followed by idle timeout. Both ReleaseSafe smoke runs validated 30k
bodies; pipeline compaction copied 7,563,688 bytes each. No capacity claim.

At the user's suggestion, retried the Linux CRT relocation failure in default
ReleaseSafe. An independent same-source probe confirmed Debug fails before
execution, default ReleaseSafe passes 6/6 transport tests, and Debug LLVM/LLD
passes 6/6. Pinned CRT/compiler/command evidence and added the first-workaround
lesson to build diagnostics; all timing remains ReleaseSafe. No compiler or CRT
was patched. RFC 3986 URI scheme/path rules are separately pinned.

Updated reciprocal links, index, curation, platform runbook, roadmap and durable
handoff. M4-001/002/003 are done for the initial Linux/macOS experiment;
comparisons, Windows HTTP and API/reliability follow-ups remain queued under
M4-004/005/006. M3-006 remains postponed. All assigned agents and the isolated
linker probe finished; no queued item is represented as active. Existing Windows
wiki publication checks remain distinct from future Windows HTTP evidence.


## 2026-09-05 — M4 retrieval publication receipt

The final MVP title/summary changes yielded 25-case MRR 0.98, hit@3 1.0 and
recall@5 0.96 (preceding design draft: MRR 1.0, recall 0.94). Policy remains met;
no ranking weights or reviewed cases were changed. Updated current roadmap and
handoff metrics to the measured result. Full local gate 87/87, 73 passed/9 skips,
28 Python tests and deterministic lint (51 pages/68 sources, zero issues) passed.

## 2026-09-05 — pinned Linux plaintext contender comparison

Pinned TechEmpower R23 result bytes and exact mrhttp/libreactor/wrk primary
inputs before synthesis. The unchanged Zig 0.16.0 ReleaseSafe MVP completed
54 shuffled five-second Linux trials and 18 two-client-thread sensitivity
trials; all load/warmup error counters zero and 2,304 exact preflight bodies.
At 128 connections/pipeline16, four-client-thread medians were 113,342 /
3,204,940 / 4,035,781 responses/s. Preserved compiler, container, affinity,
wire/body, callback/resource-policy and desktop/thermal differences; no capacity
or official-ranking claim. Rejected impossible wrk corrected percentiles after
pinning the correction/minimum source defect. Baseline standalone checkpoint
b8a3afe1bcfd7dd933060e1064cab55c4f7a41c3 contains all receipts/failed pilots.
The user then rejected mandatory worker handoff; a separately pinned inline
experiment follows rather than silently optimizing or rewriting this baseline.


## 2026-09-05 — performance architecture and deeper-pipeline evidence

Preserved separate immutable inline, gather and bounded-response-batch checkpoints
in the standalone HTTP project. Inline removes mandatory worker dispatch; gather
submits buffered header/body together; startup response cells retain multiple
ordinary callback results through terminal sends. Flush drains preceding cells
before resume, compaction waits for all borrows, and a global64-callback budget
plus rotating scan bounds dispatch. Assertions, exact0.16.0 and ReleaseSafe
measurement remain. No kernel zero-copy, arbitrary callback preemption or Windows
HTTP claim is added.

Pinned the published e07766e4f1a3bf1cd5dc772e8da48f63d085e5ad packet before
synthesis. The batch1/16 sweep measured234k→1.22M/s; a separate one-core run
measured1.83M versus libreactor2.62M. The user's deeper-depth follow-up tested
32/64/128 with the server cap still16: correctness passed, but Zig plateaued
near1.06–1.19M while libreactor reached7.41M at128. Same-binary control samples
varied1.02–1.81M, leaving code/host attribution unresolved. All24+12+24+6
trials/warmups passed and4,224 exact preflight bodies were checked. Raw ranges,
CPU budgets, compaction, resource peaks and rejected wrk percentiles are retained.

Both native hosts passed52 tests per Debug/ReleaseSafe mode,26 generic +10 inline
+11 gather +22 batch cases and30,000 ReleaseSafe smoke bodies. A separate witness
held16 frozen response cells at pending cancellation; Mac observed a canceled
target and Linux a normal-completion race, with every owner drained. The exclusive
65,535-byte asset limit and initial larger-fixture failure remain documented.
Updated existing HTTP, batching and microbenchmark pages, reciprocal links,
index, curation, runbook, roadmap and durable handoff. Remaining M4 comparison,
operation-lookup/batch tuning/sharding, dynamic API and qualification work is
explicit; M3-006 stays postponed. All timed runners and implementation agents
finished; the user's max-reasoning performance review runs independently.


## 2026-09-05 — independent performance review completed

The user-authorized max-reasoning subagent finished its read-only review without
starting builds or loads. Recorded a source/counter-based experiment order:
explicit token-addressed operation cells, then batch16/64 × callback64/256 with
fairness/ownership gates, followed by output representation and sharding. Copy
counts cannot explain the zero-compaction depth16 plateau; CQE lookup stops at
its match rather than always scanning the entire array. The review preserves
unmeasured attribution and current opaque-token API constraints. All agents and
timed runners are finished; remaining M4 items are queued. Final local retrieval
scores are MRR1.0/hit@3=1.0/recall@5=0.96 over25 cases, with policy met.


## 2026-09-05 — performance integration publication gates

Clean wiki7a5dd5455858a7f84117e04beeed5181c83693a2 passed87/87 steps on all four
runtime environments, with Mac73/82, Linux74/82 and Windows x64/ARM64 each75/82;
remaining tests are deliberate platform skips. All28 command tests and25-query
retrieval policy passed. Windows run33983000614 also passed all five explicit
proofs per architecture and five x86/WOW64 executions. Preserved exact host,
compiler/archive/source/executable hashes and runtime logs in the durable
publication JSON: x64 Server2025 build26100.33296/AMD EPYC7763 and ARM64 Windows11
build26200.9168/Cobalt100, with emulated x64 compiler producing native ARM64
baseline tests. This does not enable native ARM-compiler diagnostics or qualify
Windows HTTP/physical deployment. The receipt-only commit is rechecked at its
own pushed revision. Standalone HTTP e07766e had already passed its final clean
Mac/Linux gates. All worktrees were clean at gate input; owned benchmark state
was removed after preserving logs.
