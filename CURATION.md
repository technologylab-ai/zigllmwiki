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

## matklad — selected next

| Cluster | Sources | Intended decision page |
| --- | --- | --- |
| Bounded memory and layout | [Reserve First](https://matklad.github.io/2025/08/16/reserve-first.html), [Size Matters](https://matklad.github.io/2025/11/28/size-matters.html), [Static Allocation for Compilers](https://matklad.github.io/2025/12/23/static-allocation-compilers.html), [Memory Safety's Hardest Problem](https://matklad.github.io/2026/07/20/memory-safety-hardest-problem.html) | Extend [[static-allocation-and-constant-work]] and [[newtype-indexes]] |
| Time, retries, and cleanup | [Strictly Monotonic Time](https://matklad.github.io/2026/01/23/strictly-monotonic-time.html), [Retry Loop](https://matklad.github.io/2023/12/21/retry-loop.html), [Retry Loop, Retry](https://matklad.github.io/2025/08/23/retry-loop-retry.html), [Defer Patterns](https://matklad.github.io/2024/03/21/defer-patterns.html) | `std.Io` clocks, deadlines, retries, cleanup, and cancellation |

Other Zig/comptime/syntax posts remain discovered. They move to selected only
when a concrete systems-programming question needs them.

## Platform I/O — current slice

| Source | Status | Wiki effect |
| --- | --- | --- |
| liburing `io_uring.7` and cancellation manuals | synthesized | Linux lifecycle, ordering, retained resources, and cancellation races in [[io-uring]] |
| Apple XNU `kqueue.2` and POSIX AIO manuals | synthesized | Readiness versus asynchronous file completion, ownership, cancellation, and cleanup in [[macos-kqueue-and-aio]] |
| Microsoft IOCP, overlapped I/O, and `CancelIoEx` documentation | synthesized | Completion ownership, immediate-success handling, ordering, capacity, and cancellation in [[windows-iocp-and-overlapped-io]] |

## TigerBeetle — current slice

| Source/path | Status | Wiki effect |
| --- | --- | --- |
| `docs/TIGER_STYLE.md` | captured + partially synthesized | [[tigerstyle]]; full rule inventory remains M2 work |
| `docs/ARCHITECTURE.md` | synthesized | [[tigerbeetle-engineering-corpus]], allocation and DST pages |
| `docs/concepts/safety.md` | synthesized | fault-model and DST guidance |
| `docs/concepts/performance.md` | synthesized | interface, batching, headroom, and capacity guidance |
| `docs/internals/vopr.md` | synthesized | [[deterministic-simulation-testing]] |
| `docs/internals/data_file.md` | captured | selected for storage correctness; synthesis waits for implementation and OS evidence |
| `docs/internals/lsm.md` | selected | bounded compaction and manifest invariants |
| `docs/internals/sync.md` | selected | recovery and cancellation boundaries |
| `docs/internals/vsr.md` | selected | protocol state machines, quorums, and repair |
| `docs/operating/{hardware,monitoring,recovering}.md` | selected | operational assumptions and failure handling |
| `src/io{,.zig}/**` | synthesized | [[tigerbeetle-io]] maps caller-owned completions, dispatch, queue pressure, Linux `io_uring`, Darwin `kqueue`, and Windows IOCP while recording the missing cancellation surface. |
| `src/{vsr,lsm}/**` | selected | implementation evidence for ownership, limits, storage, state machines, and recovery |

## Active curation

| Roadmap item | Status | Current boundary / next artifact |
| --- | --- | --- |
| M1-005 cancellation | active | `Future`, `Group`, `recancel`, protection, and a blocked pipe read are proved on macOS; add blocked-syscall evidence on Linux and Windows. |
| M2-009 source curation | active | Structured-concurrency, error/diagnostics, and invariant/review clusters are synthesized; bounded-memory/layout and time/retry clusters remain selected. |
| M3 evented I/O | active research | Primary Linux/Apple/Microsoft lifecycles and TigerBeetle's three backends are synthesized; dispatch I/O, Zig adapters, kernel-version detail, and platform runtime proofs remain. |

M1-001 is complete: [[process-init-and-capabilities]] synthesizes the official
Zig 0.16 initializer/startup source and the local migration guide, with a real
entry-point proof executed by `zig build verify`.

M1-003 is complete from the installed Zig 0.16 `Io.zig` contract:
[[select-and-batch]] distinguishes typed task results from fixed low-level
operation slots and proves result draining plus arbitrary completion order.

M1-006 is complete from `Io.zig`, `Io/RwLock.zig`, and `Io/Semaphore.zig`:
[[io-synchronization-primitives]] covers the entire public synchronization
surface with six tests for cancellation, predicate, capacity, close/drain,
permit, shared-lock, and futex behavior.

## Immediate curation order

1. Complete cancellation with Linux and Windows blocked-syscall evidence; the
   task-level and macOS blocked-read proofs are done.
2. Finish dispatch I/O and Zig 0.16 source mapping beside the primary platform
   lifecycles; then design the runtime matrix.
3. Ingest the bounded-memory/layout source cluster and close the integer-width,
   index/count/size, and arithmetic-intent gaps.
4. Ingest time/retry/defer sources alongside the `std.Io` clocks and timeout
   inventory.
5. Continue selected TigerBeetle storage, recovery, and operational sources by
   a named system-design question rather than bulk summary.
