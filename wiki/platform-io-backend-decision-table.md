---
id: platform-io-backend-decision-table
title: Platform I/O backend decision table
kind: map
status: source-verified
zig: "0.16.0"
summary: Choose Zig 0.16 file and network I/O from the required guarantee and evidence level, not from a shared label such as async or evented.
updated: 2026-09-04
sources:
  - "[[zig-0.16.0-release-notes]]"
  - "[[zig-0.16.0-stdlib]]"
  - "[[liburing-interface-and-cancellation]]"
  - "[[liburing-registered-resources]]"
  - "[[linux-io-uring-uapi-history]]"
  - "[[apple-xnu-kqueue-aio]]"
  - "[[apple-libdispatch-io]]"
  - "[[zig-0.16-dispatch-kqueue-source]]"
  - "[[microsoft-windows-iocp]]"
  - "[[microsoft-windows-iocp-api]]"
  - "[[microsoft-windows-nt-fs-control]]"
  - "[[zig-0.16-windows-io-source]]"
  - "[[tigerbeetle-io-source]]"
proofs:
  - proofs/linux_io_uring.zig
  - proofs/macos_dispatch_io.zig
  - proofs/threaded_blocked_read_cancel_linux.zig
  - proofs/threaded_blocked_read_cancel_macos.zig
  - proofs/threaded_blocked_read_cancel_windows.zig
  - proofs/windows_io_mapping.zig
  - proofs/windows_apc_batch.zig
  - proofs/windows_iocp_lifecycle.zig
platforms:
  - linux
  - macos
  - windows
---

# Platform I/O backend decision table

## Remember

Choose a backend separately for socket readiness, regular-file completion, task
execution, and cancellation. “Uses `std.Io`,” “async,” “evented,” and “uses an
OS queue” do not answer those questions.

The safe Zig 0.16 default is `std.process.Init.io`, currently backed by the
feature-complete `std.Io.Threaded`. Choose a custom evented design only when a
measured workload justifies its additional platform-specific ownership,
capacity, shutdown, and test obligations.

## Evidence legend

- **Contract:** public interface or OS-primary documentation; no implementation
  or runtime behavior is inferred.
- **Source:** exact Zig 0.16 or revision-pinned implementation was inspected.
- **Compile:** target code was compiled but not executed on that operating
  system.
- **Runtime:** the named proof ran on the named host; it does not generalize to
  other kernels, filesystems, devices, queue depths, or workloads.

This page is `source-verified`, not cross-platform `runtime-verified`, because
its broad backend comparisons exceed the named lifecycle fixtures. The Windows
IOCP proof now includes bounded pipe/file load; it does not establish production
server capacity or every file/socket/device path.

## Backend matrix

| Choice | File I/O | Network I/O | Guarantees, limits, and unsupported cases | Ownership, cancellation, and resource model | Exact evidence |
| --- | --- | --- | --- | --- | --- |
| `std.Io` interface | Defines file, network, task, batch, deadline, and cancellation vocabulary. | Same capability is passed to networking APIs. | Makes no event-loop, thread, progress, allocation, or platform-mechanism guarantee. `async` may complete eagerly; `concurrent` requires independent progress or fails. | Owners must await or cancel tasks, drain raced results, and retain borrowed resources until acknowledgement. Implementations choose the machinery. | **Contract/source:** Zig 0.16 public interface. See [[std-io]], [[async-vs-concurrent]], and [[select-and-batch]]. |
| Zig 0.16 `std.Io.Threaded` | Portable blocking file operations executed by the caller or task workers; Windows has narrower APC-based paths for asynchronous handles. | Feature-complete shipped network surface, with platform-specific blocking/APC internals. | Production default, but one blocked operation can occupy a worker. `async` can fall back inline; `concurrent` can return `error.ConcurrencyUnavailable`. It is not a readiness loop. | Futures and worker stacks may allocate; the pool can grow. Bound thread count, stack memory, open handles, buffers, and tasks. Task cancellation is request plus join/acknowledgement. | **Source:** exact release and implementation. **Runtime:** blocked pipe-read cancellation on arm64 macOS 26.6.2, x86_64 Linux 7.1.9, and x86_64 Windows Server 2025 build 26100.33296. See [[io-threaded]]. |
| Linux low-level `std.os.linux.IoUring` or a custom `io_uring` adapter | True submission/completion operations for supported file/device combinations; fixed files and buffers are optional measured optimizations. | Supports socket opcodes when the running kernel and operation probe do. | Linux only. Probe setup features and required opcodes; do not rely on kernel version alone. SQ, CQ, registered tables, locked memory, and operation slots are finite. Device/filesystem support and security policy can still reject work. | Stable `user_data` identity and buffers survive to the target CQE. A cancel request has its own CQE and does not reclaim the target. Preallocate bounded records; drain CQ pressure; generation-tag reused slots. | **Runtime:** Zig 0.16 proof on x86_64 Omarchy 4.0.2, Linux 7.1.9, covering finite SQ capacity/probing, registered file+buffer lifetime, and target/cancel CQEs. No load or older-kernel matrix. See [[io-uring]]. |
| Zig 0.16 high-level `std.Io.Uring` | Experimental implementation with incomplete error handling and task-stack work. | Networking vtable operations are unavailable even though the low-level wrapper has socket SQEs. | Proof of concept, not feature parity with Threaded and not a production HTTP-server choice. Its source-derived effective kernel floor is stricter than the base `io_uring` ABI. | Experimental fiber/task allocation and cancellation paths require their own audit; low-level ring proofs do not validate this backend. | **Source only:** Zig 0.16 release and implementation. No backend runtime proof here. See [[evented-io-backends]] and [[io-uring]]. |
| macOS nonblocking `kqueue` reactor | Regular files are not turned into asynchronous data operations. `EVFILT_VNODE` is metadata notification; TigerBeetle performs regular-file `pread`/`pwrite` synchronously. | Strong candidate for socket readiness: attempt nonblocking operation, register one-shot readiness after `WouldBlock`, then retry. | Readiness is not byte transfer. Events may coalesce; one-shot watches require re-arm; a slow callback can stall a serialized dispatcher. Zig 0.16 `std.Io.Kqueue` is an unfinished proof of concept and is not selected as Apple `Io.Evented`. | Preallocate watch/operation records and retain identity through re-arm. Closing a descriptor removes its watches but does not acknowledge a separate AIO request. Cancellation/shutdown is application policy. | **Contract/source:** Apple XNU and pinned TigerBeetle; exact Zig 0.16 Kqueue source. No product reactor runtime/load proof in this vault. See [[macos-kqueue-and-aio]]. |
| Apple Dispatch I/O for macOS files | Random-access channels accept explicit offsets and may run operations concurrently; stream operations have channel-position ordering. Handlers may deliver partial data before terminal `done`. | This page does not recommend Dispatch I/O as the socket reactor; use nonblocking readiness/Dispatch sources or Threaded until proved. | The Zig 0.16 stdlib does not expose `dispatch_io_*`; the proof uses a C Blocks shim. One hot-cache result is not a storage-backend ranking. | Dispatch retains channels and write data; read data must be retained or copied before handler return. `DISPATCH_IO_STOP` is best effort; retain buffers until terminal callback. Bound channels, operations, queued bytes, and callbacks. | **Runtime:** one random-access read via a Zig/C shim on arm64 macOS 26.6.2 plus a narrow hot-cache comparison. No cancellation, write, cold-I/O, durability, queue-depth, or load proof. See [[macos-kqueue-and-aio]]. |
| Zig 0.16 `std.Io.Dispatch` on macOS | Positional file operations and `fsync` call synchronous syscalls inside fibers; streaming descriptors use Dispatch readiness after `WouldBlock`. | Network vtable operations are unavailable. | Experimental, not feature parity with Threaded. Each allocated fiber reserves at least 60 MiB, and `deinit` does not compile under Zig 0.16.0. Not a production server backend as shipped. | Allocated stackful fibers and Dispatch queues are implementation resources; synchronous file work can still occupy execution. Current teardown limitation prevents a clean lifecycle claim. | **Source/runtime:** exact Zig source; type mapping, initialization, async fiber, and positional read ran on arm64 macOS 26.6.2. No networking path exists. See [[macos-kqueue-and-aio]]. |
| Zig 0.16 Windows `std.Io.Threaded` APC/NtDll paths | Default files use synchronous NT handles; selected asynchronous handles use APC completion. The no-follow open path has inconsistent `nonblocking` metadata. | Asynchronous AFD endpoints use `NtDeviceIoControlFile`; shutdown has a synchronous exception. | Not IOCP. `Io.Evented` is `void`; AFD details are private. Concurrent `Batch.net_receive` is unavailable. Pending `batchCancel` waits for an APC/alert before issuing cancellation, so unassisted shutdown can stall. | Direct paths retain stack status blocks/buffers; batches retain fixed slots. Cancellation must reconcile terminal state; the proof uses an explicit NT alert for the initial-wait defect. | **Runtime:** x86_64 Windows Server 2025 build 26100.33296, Zig 0.16.0: synchronous cancellation, raw APC immediate/pending paths, 32 batch races, and NPFS `NtFsControlFile` transaction cancellation. No arbitrary-driver/AFD cancellation proof. x86/arm64 compile only. See [[windows-iocp-and-overlapped-io]]. |
| Custom Windows IOCP/overlapped adapter | Overlapped `ReadFile`/`WriteFile` with per-operation offsets. The proof exercises reads; file writes/durability remain outside its runtime scope. | Overlapped Winsock is supported by the OS/source design but untested by this custom fixture. | Port concurrency does not bound handles, requests, backlog, or memory. Immediate success normally queues a packet unless skip-on-success is enabled. Zig 0.16 stdlib supplies no IOCP bindings. | Stable `OVERLAPPED`/buffer ownership until terminal dispatch; four-slot admission includes undrained completions. Stop admission, cancel, drain data and distinct control packets, then close. Cancellation does not promise byte rollback. | **Runtime:** same Windows build, both pipe notification policies, cancel races and shutdown from four pending reads, plus 256 four-read cycles on pipes and a hot 256-byte NTFS file. File load was pending-only. No production ranking, cold storage, Winsock, or arbitrary-device result. See [[windows-iocp-and-overlapped-io]] and [[tigerbeetle-io]]. |

## Recommendation by project stage

### Portable-first Zig 0.16 service

Use `std.process.Init.io` and pass the `std.Io` capability through component
boundaries. Keep the shipped Threaded backend unless measurements show that its
worker, stack, cancellation-latency, or throughput costs violate an explicit
requirement.

Even on Threaded, design the server as bounded systems software:

- distinguish `async` eager fallback from `concurrent` required progress;
- cap connections, tasks, per-connection buffers, queued responses, open
  files, DNS work, and worker stacks;
- stop admission before cancellation, then await/drain every owner;
- use one absolute deadline across a multi-step operation;
- isolate regular-file work so a slow device does not silently consume all
  workers;
- measure tail latency and saturation on each deployment OS.

This path maximizes Zig 0.16 API coverage and current evidence. It does not
promise no steady-state allocation; `std.Io.Threaded` task dispatch can
allocate futures and grow its thread pool.

### TigerStyle evented server

Use an application-owned, bounded operation vocabulary rather than pretending
the OS mechanisms are interchangeable. Give every component a fixed number of
operation slots and buffers, encode slot generation in completion identity,
and define these states explicitly:

`free → prepared → submitted/waiting → terminal queued → callback drained → free`

Then choose the platform substrate:

| Platform | Network recommendation | Regular-file recommendation | Gate before production |
| --- | --- | --- | --- |
| Linux | Custom low-level `io_uring` path when batching and measured queue depth justify it; otherwise bounded Threaded. | `io_uring` for proven file/device combinations; registered resources only after measurement. | Feature/opcode probes, finite SQ/CQ/operation pools, target-CQE cancellation reconciliation, filesystem/device matrix, and load/tail-latency tests. |
| macOS | Product-owned nonblocking `kqueue` or Dispatch-source reactor; bounded Threaded is the portable starting point. | Apple Dispatch I/O, POSIX AIO where its constraints fit, memory mapping for a proven access pattern, or a bounded worker lane. Never call `kqueue` regular-file completion. | Bounded admission and callback work, terminal partial-result ownership, cancellation and durability tests, cold/warm representative I/O, writes, and queue-depth measurements. |
| Windows | Custom IOCP adapter when Windows-specific scale justifies it; otherwise shipped Threaded. | The same IOCP can carry overlapped file completions, but synchronous metadata/durability operations need separate treatment. | Stable `OVERLAPPED` pool, explicit immediate-success policy, independent in-flight/backlog/handle limits, `CancelIoEx` race tests, shutdown drain, typed error mapping, and Windows runtime/load evidence. |

Do not select Zig 0.16's high-level `Io.Uring`, `Io.Kqueue`, or `Io.Dispatch`
for this production design merely because the types exist. They are useful
research artifacts with material missing operations or lifecycle problems.
A custom platform loop also does not automatically implement the entire
`std.Io` vtable; keep that integration boundary explicit.

## TigerStyle acceptance checklist

- Every queue, ring, worker set, handle table, operation pool, buffer pool, and
  completion batch has a derived maximum and overload response.
- Startup reserves stable operation state; steady-state submission does not
  escape to an unbounded allocation path.
- Each immediate, pending, failed, timed-out, canceled, and shutdown path ends
  at exactly one terminal owner.
- Control wakeups cannot be mistaken for data completions, and slow callbacks
  cannot create unbounded completion backlog.
- Unsupported operations fail explicitly or route to a named bounded fallback;
  they never inherit guarantees from another OS.
- Measurements record OS/kernel, hardware, filesystem/device, queue depth,
  workload, build mode, correctness witness, and tail latency.

Related: [[std-io]], [[io-threaded]], [[evented-io-backends]], [[io-uring]],
[[macos-kqueue-and-aio]], [[windows-iocp-and-overlapped-io]],
[[tigerbeetle-io]], [[cancellation]], [[static-allocation-and-constant-work]],
and [[tigerstyle]].
