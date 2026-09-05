# Source curation ledger

This file makes content work visible before and after synthesis. Update it in
the same change that selects, captures, synthesizes, rejects, or supersedes a
source.

## Status vocabulary

| Status | Meaning |
| --- | --- |
| discovered | A relevant source is known; no commitment has been made. |
| selected | It answers a named wiki question and is queued for close reading. |
| captured | An immutable revision has a record under `sources/`. |
| synthesized | Its useful claims and caveats are integrated into linked wiki pages. |
| proved | A runnable Zig claim is exercised by `zig build verify`; conceptual sources may legitimately stop at synthesized. |
| rejected | It was reviewed and excluded, with the reason recorded. |

The current matklad snapshot is commit
`ff6734c93ac8b41677dee016af6bb67c39420101`. The current TigerBeetle snapshot is
commit `47aeb2212a255273dda508288412e537d11e4b7c`. A later revision gets new source
records; it does not silently rewrite captured evidence.

The local `fi` migration guide and zig-hermit timeout experiments also have
byte-identical portable snapshots. Their source records retain the original
repository commits and absolute origin paths, while verification recomputes the
snapshot SHA-256 values on every `zig build verify` run.

The official Zig 0.16 release notes are fully inventoried by named section in
[[zig-0.16-release-inventory]]. The inventory routes topics by decision and
roadmap destination; it does not copy the release notes or claim that queued
topics have already been synthesized.

## matklad — synthesized now

| Source | Status | Wiki effect |
| --- | --- | --- |
| [Static Allocation, Constant Work](https://matklad.github.io/2026/09/02/static-allocation-constant-work.html) | synthesized + mechanics proved | [[static-allocation-and-constant-work]] and the fixed-pool proof |
| [Cancelation Terminology](https://matklad.github.io/2026/08/31/cancelation-terminology.html) | synthesized | [[cancellation]] |
| [Zig's Io.Threaded is Neat](https://matklad.github.io/2026/08/06/neat-io-threaded.html) | synthesized + dispatch proof linked | [[io-threaded]], [[async-vs-concurrent]], [[cancellation]] |
| [Minimal Viable Zig Error Contexts](https://matklad.github.io/2026/05/03/zig-error-context.html) | synthesized + context mechanics proved | [[error-context]] |
| [Newtype Index Pattern in Zig](https://matklad.github.io/2025/12/23/zig-newtype-index-pattern.html) | synthesized + 0.16 port proved | [[newtype-indexes]] |
| [Steering Zig Fmt](https://matklad.github.io/2026/05/08/steering-zig-fmt.html) | synthesized + 0.16 format check | [[steering-zig-fmt]] |
| [Push Ifs Up And Fors Down](https://matklad.github.io/2023/11/15/push-ifs-up-and-fors-down.html) | synthesized | [[tigerstyle]] function and control-flow guidance |
| [What is io_uring?](https://matklad.github.io/2024/09/23/what-is-io-uring.html) | synthesized with primary Linux evidence | [[io-uring]] |
| [UNIX Structured Concurrency](https://matklad.github.io/2023/10/11/unix-structured-concurrency.html) | synthesized | [[task-lifetimes-and-structured-concurrency]] process boundary |
| [Zig Language Server and Cancellation](https://matklad.github.io/2023/05/06/zig-language-server-and-cancellation.html) | synthesized | State generations and cancel-before-mutate in [[task-lifetimes-and-structured-concurrency]] |
| [On Async Mutexes](https://matklad.github.io/2025/11/04/on-async-mutexes.html) | synthesized | Serialized actor/state-machine callbacks versus task-oriented concurrency |
| [Error Codes for Control Flow](https://matklad.github.io/2025/11/06/error-codes-for-control-flow.html) | synthesized + bounded sink proved | [[error-handling-and-diagnostics]] |
| [Diagnostics Factory](https://matklad.github.io/2026/02/16/diagnostics-factory.html) | synthesized + bounded sink proved | Producer-oriented diagnostic constructors and replaceable presentation |
| [The Second Great Error Model Convergence](https://matklad.github.io/2025/12/29/second-error-model-convergence.html) | synthesized | Narrow versus erased error sets and the separate invariant-failure path |
| [Always Be Blaming](https://matklad.github.io/2026/05/18/always-be-blaming.html) | reclassified + synthesized | [[source-archaeology]], not error diagnostics |
| [What is an Invariant?](https://matklad.github.io/2023/10/06/what-is-an-invariant.html) | synthesized + algorithm proof | [[invariants-and-assertions]] |
| [Look Out For Bugs](https://matklad.github.io/2025/09/04/look-for-bugs.html) | synthesized | Whole-subsystem control-flow and state review in [[code-reading-and-mechanical-checks]] |
| [Mechanical Habits](https://matklad.github.io/2025/12/06/mechanical-habits.html) | synthesized | Repository invariants and maintained benchmark entry points |
| [Do Not Optimize Away](https://matklad.github.io/2025/12/09/do-not-optimize-away.html) | synthesized | Runtime inputs and correctness witnesses in [[trustworthy-microbenchmarks]] |
| [Considering Strictly Monotonic Time](https://matklad.github.io/2026/01/23/strictly-monotonic-time.html) | synthesized + guard mechanics proved | [[io-time-clocks-and-deadlines]] |
| [Reserve First](https://matklad.github.io/2025/08/16/reserve-first.html) | synthesized | Reserve-before-mutate in [[static-allocation-and-constant-work]] |
| [Size Matters](https://matklad.github.io/2025/11/28/size-matters.html) | synthesized | Human and architectural size limits in [[tigerstyle-coverage]]; applied function work is M2-005 |
| [Static Allocation for Compilers](https://matklad.github.io/2025/12/23/static-allocation-compilers.html) | synthesized | Bounded working state versus retained output in [[static-allocation-and-constant-work]] and index/layout pages |
| [Memory Safety's Hardest Problem](https://matklad.github.io/2026/07/20/memory-safety-hardest-problem.html) | synthesized | Interior-pointer lifetime and validated-handle guidance in [[newtype-indexes]] and [[integer-widths-and-boundaries]] |
| [Retry Loop](https://matklad.github.io/2023/12/21/retry-loop.html) | synthesized + mechanics proved | Explicit outcomes, visible attempt bound, terminal cause, and no final sleep in [[bounded-retries-and-cleanup]] |
| [Retry Loop Retry](https://matklad.github.io/2025/08/23/retry-loop-retry.html) | synthesized + mechanics proved | Guaranteed first attempt expressed as a validated total `attempt_limit` |
| [Zig defer Patterns](https://matklad.github.io/2024/03/21/defer-patterns.html) | synthesized | Postconditions, infallible commit, grouped lifetime, and reporting constraints in [[bounded-retries-and-cleanup]] |

## matklad — selected next

| Cluster | Sources | Intended decision page |
| --- | --- | --- |
No source cluster is currently selected without synthesis. New discoveries move
here only after they answer a named systems-programming question.

Other Zig/comptime/syntax posts remain discovered. They move to selected only
when a concrete systems-programming question needs them.

## Platform I/O — current slice

| Source | Status | Wiki effect |
| --- | --- | --- |
| liburing `io_uring.7`, registration, and cancellation manuals | synthesized + runtime mechanics proved | Linux lifecycle, ordering, registered-resource ownership, finite queues, and cancellation races in [[io-uring]] |
| Apple XNU `kqueue.2` and POSIX AIO manuals | synthesized | Readiness versus asynchronous file completion, ownership, cancellation, and cleanup in [[macos-kqueue-and-aio]] |
| Apple libdispatch I/O headers | synthesized + adapter proved | Dispatch channel/data/callback lifecycles and the Zig/C macOS proof in [[macos-kqueue-and-aio]] |
| Zig 0.16 Dispatch/Kqueue source | synthesized + selected macOS paths proved | Exact Evented alias, synchronous regular-file calls, unavailable networking, 60 MiB fibers, and broken deinit in [[macos-kqueue-and-aio]] |
| Microsoft IOCP, overlapped I/O, and `CancelIoEx` documentation | synthesized | Completion ownership, immediate-success handling, ordering, capacity, and cancellation in [[windows-iocp-and-overlapped-io]] |
| Microsoft SDK API contracts at `5f2625b6782d3e9c0df08756583c527a0a2872ca` | synthesized + bounded runtime mechanics proved | Both IOCP notification policies, terminal ownership, fixed admission, cancel/shutdown, and pipe/hot-file read metrics; quotas/watchdogs remain explicitly limited. |
| Microsoft `NtFsControlFile` at `7515063cea4c9e98db6a92986c5b4ddb0463fd16` | synthesized + NPFS mechanics proved | APC/port-context ownership and message-pipe transaction direct/batch cancellation; arbitrary devices are unproved and the nonexistent `Asynchronous` parameter is excluded. |
| Zig 0.16 Windows `std.Io` source | synthesized + selected Windows runtime and three-target compile proofs | Exact mapping, APC/batch/NPFS evidence, initial-wait progress defect, and no-follow open metadata mismatch in [[windows-iocp-and-overlapped-io]]; AFD and arbitrary-driver behavior remain source-only. |

The Microsoft SDK slice at `5f2625b6782d3e9c0df08756583c527a0a2872ca` also
now covers public Winsock, batched dequeue and flush/result APIs in
[[microsoft-windows-winsock-batched-file-io]]. The bounded TCP-to-file proof is
registered and ran on x64 Windows in run 33919878353. WOW64 and ARM64
fixtures and full target gates subsequently passed in run 33922946389; physical
deployment qualification was postponed by the user on 2026-09-05; its external
evidence gaps remain recorded.

## TigerBeetle — current slice

| Source/path | Status | Wiki effect |
| --- | --- | --- |
| `docs/TIGER_STYLE.md` | synthesized + mechanics proved | [[tigerstyle-coverage]] maps all 71 principles to focused guidance and registered Zig 0.16 evidence where code is involved. |
| `docs/ARCHITECTURE.md` | synthesized | [[tigerbeetle-engineering-corpus]], allocation and DST pages |
| `docs/concepts/safety.md` | synthesized | fault-model and DST guidance |
| `docs/concepts/performance.md` | synthesized | interface, batching, headroom, and capacity guidance |
| `docs/internals/vopr.md` | synthesized | [[deterministic-simulation-testing]] |
| `docs/internals/data_file.md` | synthesized | [[durable-storage-and-recovery]] separates layout, checkpoint authority and OS durability assumptions. |
| `docs/internals/lsm.md` | synthesized | Bounded compaction and manifest ownership; exact per-beat reservation differs from the document's half-bar description. |
| `docs/internals/sync.md` | synthesized | Authoritative checkpoint selection, I/O drain, lazy-repair markers and sync ratchets. |
| `docs/internals/vsr.md` | synthesized | Distinct replication/view-change quorums and recovery promises. |
| `docs/operating/{hardware,monitoring,recovering}.md` | synthesized | Fault domains, capacity/latency signals and lost-replica recovery assumptions. |
| `src/io{,.zig}/**` | synthesized | [[tigerbeetle-io]] maps caller-owned completions, dispatch, queue pressure, Linux `io_uring`, Darwin `kqueue`, and Windows IOCP while recording the missing cancellation surface. |
| `src/{vsr,lsm}/**` | synthesized, focused symbols | [[tigerbeetle-storage-source]] names inspected reservations, pools, root selection, delayed reuse and sync-cancellation symbols; not a full implementation audit. |

## Current curation execution

`running` below means an agent is executing the item now. `queued` means no
agent is currently working on it.

| Roadmap item | Execution | Current boundary / next artifact |
| --- | --- | --- |
| M1-005 cancellation | done | `Future`, `Group`, `recancel`, and protection are proved, and blocked pipe reads are runtime-proved on macOS, Linux, and Windows. |
| M2-009 bounded-memory/layout curation | done | Reservation, finite working state, retained output, representation lifetime, and stable-handle consequences are synthesized. |
| M2-010 retry/defer curation | done | Both retry-loop essays and the defer-pattern essay are synthesized into one-deadline retry and terminal cleanup guidance. |
| M3-003 macOS evented I/O | done | Primary `kqueue`/AIO/Dispatch lifecycles, exact Zig mappings and defects, an actual Dispatch I/O adapter, macOS runtime evidence, and a bounded comparison are recorded. |
| M3-002 Linux evented I/O | done | Kernel/feature floors, registered resources, cancellation races, and real Zig 0.16 `omarx1` evidence are integrated. |
| M3-004 Windows evented I/O | done | APC/batch/NPFS plus custom IOCP pipe/file lifecycle and bounded load ran on Windows Server 2025; exact observations, defects, watchdogs and limits are preserved. All subagents finished. |
| M3-005 backend decision table | done | File/network choices, guarantees, limits, unsupported paths, ownership, resource models, and evidence gates are synthesized across all three platforms. |
| M3-006 Windows deployment qualification | postponed | User decision on 2026-09-05; resume only on explicit request with a concrete deployment need and suitable test access. All available x64/TCP-file, WOW64 and ARM64 runtime fixtures and publication gates passed. Physical power-loss/controlled cold storage and named deployment driver/error/SLO evidence are unavailable. Native ARM compiler failure is separate from passing ARM64 runtime evidence. No assigned agent remains active. |

M1-001 is complete: [[process-init-and-capabilities]] synthesizes the official
Zig 0.16 initializer/startup source and the local migration guide, with a real
entry-point proof executed by `zig build verify`.

M1-003 is complete from the installed Zig 0.16 `Io.zig` contract:
[[select-and-batch]] distinguishes typed task results from fixed low-level
operation slots and proves result draining plus arbitrary completion order.

M1-006 is complete from `Io.zig`, `Io/RwLock.zig`, and `Io/Semaphore.zig`:
[[io-synchronization-primitives]] covers the entire public synchronization
surface with six original tests for cancellation, predicate, capacity, close/drain,
permit, shared-lock, and futex behavior. Three additional queue tests now pass
on macOS, Linux, Windows x64 and Windows ARM64 for contention, partial
cancellation and close/join ownership. The selected source revision is unchanged.

M1-007 is complete from the installed time interface and the pinned monotonic
time design note: [[io-time-clocks-and-deadlines]] distinguishes all five clock
domains, relative and absolute budgets, sleep semantics, and the optional
strict-clock application guard with five runtime tests.

M1-010 is complete: [[testing-io-and-single-threaded-builds]] distinguishes
host-backed tests, the exact fixed `Io.failing` profile, stream adapters, and
whole-build single-threaded semantics. Its four tests run in both normal and
`-fsingle-threaded` modules.

M2-003, M2-004, and M2-009 are complete. The persistence proof independently
checks a state invariant before encoding and after validation/decoding;
[[integer-widths-and-boundaries]] covers domain widths, arithmetic, native
layout, wire encoding, and stale representation handles; and all four selected
bounded-memory/layout essays have decision-level synthesis.

## M4 design sources and first implementation

| Source | Status | Wiki effect |
| --- | --- | --- |
| RFC 9110 / 9112 / 6585 published sections | captured + draft synthesis | [[bounded-http-server-design]] separates HTTP framing from configured request limits and incremental response writing. |
| Linux network zero-copy docs at `8cd9520d35a6c38db6567e97dd93b1f11f185dc6` | captured + draft synthesis | Framework borrowing versus kernel copy avoidance, send reuse notification and hardware-dependent receive path; no NIC experiment. |
| TechEmpower wiki at `3be9618978e68b1a953f0c1a9cb642440c064fd8` | captured + draft synthesis | Plaintext/pipelining and JSON workload requirements; no leaderboard or performance claim. |

Additional pinned slices: [[techempower-plaintext-validator]] establishes the
actual plaintext body/driver configuration, and [[microsoft-thread-termination]]
records one concrete unsafe thread-termination boundary. Together with [[http-overload-refusal]] for 503/refused connections, these are
captured and synthesized into the draft, without new runtime claims. Exact Zig 0.16 Thread
startup/join and existing deterministic-simulation evidence inform the proposal.

The new [[rfc3986-uri-syntax]] source pins URI scheme/authority/path rules.
[[zig-http-mvp-2026-09-05]] pins the standalone implementation and source-hashed
Linux/macOS unit, wire/ownership and ReleaseSafe smoke packet. Its facts are
integrated into the existing HTTP design page; no application code is duplicated
into wiki proofs. [[zig-0.16-linux-crt-linker-workaround]] preserves the user's
ReleaseSafe workaround, reproduced with an independent exact-source native probe
and integrated into build diagnostics.

M4-001/002/003 are done for the first experiment. M4-004 comparisons, M4-005
Windows HTTP and M4-006 further API/reliability work are queued. All assigned
subagents finished. M3-006 remains postponed; no Windows HTTP runtime is claimed.

## Immediate curation order

1. M3-006 is postponed by user decision; do not select further Windows
   deployment qualification unless explicitly resumed. The initial
   APC/batch/NPFS and IOCP lifecycle/load slice is done.
2. Keep the cross-platform backend table synchronized with runtime evidence and
   explicitly tested OS/kernel/filesystem/device combinations.
3. The selected TigerBeetle storage/recovery/operations slice is synthesized
   in [[durable-storage-and-recovery]]. New sources require a new named design
   question; source synthesis does not prove an engine or storage deployment.
