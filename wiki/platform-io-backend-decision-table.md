---
id: platform-io-backend-decision-table
title: Platform I/O backend decision table
kind: map
status: source-verified
zig: "0.17.0"
summary: Choose Zig 0.17 I/O from exact source limits; dated 0.16 runtime receipts remain historical.
updated: 2026-10-04
sources:
  - "[[zig-0.17.0-stdlib]]"
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
  - "[[microsoft-windows-winsock-batched-file-io]]"
  - "[[microsoft-windows-acceptex-provider]]"
  - "[[bounded-http-windows-iocp-2026-09-06]]"
  - "[[bounded-http-windows-shards-2026-09-06]]"
  - "[[microsoft-windows-winsock-cleanup]]"
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
  - proofs/windows_iocp_tcp_file.zig
  - proofs/dispatch_017_io_compile_error.zig
  - proofs/uring_017_io_compile_error.zig
  - proofs/kqueue_017_io_compile_error.zig
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

Zig 0.17 supplies `std.process.Init.io` through `std.Io.Threaded`.
The source constructs that implementation in `lib/std/start.zig`. [[zig-0.17.0-stdlib]] Choose a custom evented design only when a
measured workload justifies its additional platform-specific ownership,
capacity, shutdown, and test obligations.

## Evidence legend

- **Contract:** public interface or OS-primary documentation; no implementation
  or runtime behavior is inferred.
- **Source:** exact Zig 0.17 or revision-pinned implementation was inspected.
- **Compile:** target code was compiled but not executed on that operating
  system.
- **Runtime:** the named proof ran on the named host; it does not generalize to
  other kernels, filesystems, devices, queue depths, or workloads.

The 0.17 review inspected the exact `Io`, Threaded, Uring, Kqueue, Dispatch, allocator, and Windows source.
Those files match the immutable release commit. [[zig-0.17.0-stdlib]]
The current comparison is source evidence.
The runtime cells below preserve dated 0.16 receipts.
Each maintained proof needs a named native 0.17 gate before those runtime claims resume.
The Windows load fixtures do not establish production capacity or every device path.

## Backend matrix

| Choice | File I/O | Network I/O | Guarantees, limits, and unsupported cases | Ownership, cancellation, and resource model | Exact evidence |
| --- | --- | --- | --- | --- | --- |
| `std.Io` interface | Defines file, network, task, batch, deadline, and cancellation vocabulary. | The caller passes the same capability to networking APIs. | No portable event-loop, allocation, or platform-mechanism guarantee. `async` permits inline completion; `concurrent` requires progress or fails. | Owners await or cancel tasks and drain raced results before releasing borrowed resources. | **Contract/source:** exact Zig 0.17 interface. See [[std-io]], [[async-vs-concurrent]], and [[select-and-batch]]. |
| Zig 0.17 `std.Io.Threaded` | Blocking file operations run on the caller or task workers. Selected Windows handles use APC completion. | Platform-specific blocking/APC internals implement the network surface. | Default implementation. A blocked operation occupies its executing thread. `async` can run inline; `concurrent` can fail. | Dispatch allocates task records before admission. Workers may grow the pool. Both task kinds share the busy count. | **Source:** exact 0.17 implementation. **Historical runtime, 0.16:** blocked pipe cancellation on macOS 26.6.2, Linux 7.1.9, and Windows build 26100.33296. See [[io-threaded]]. |
| Linux low-level `std.os.linux.IoUring` or a custom `io_uring` adapter | True submission/completion operations for supported file/device combinations; fixed files and buffers are optional measured optimizations. | Supports socket opcodes when the running kernel and operation probe do. | Linux only. Probe setup features and required opcodes; do not rely on kernel version alone. SQ, CQ, registered tables, locked memory, and operation slots are finite. Device/filesystem support and security policy can still reject work. | Stable `user_data` identity and buffers survive to the target CQE. A cancel request has its own CQE and does not reclaim the target. Preallocate bounded records; drain CQ pressure; generation-tag reused slots. | **Historical runtime, 0.16:** proof on x86_64 Omarchy 4.0.2, Linux 7.1.9, covering finite SQ capacity/probing, registered file+buffer lifetime, and target/cancel CQEs. No load or older-kernel matrix. See [[io-uring]]. |
| Zig 0.17 high-level `std.Io.Uring` | Experimental ring-backed implementation. `io()` initializes a removed vtable field. | IP bind and message receive have implementations. Send/read return errors; write and network batching panic. Listen/accept/connect remain unavailable. | The shipped I/O interface is source-incompatible. Setup requires cooperative task running and single-issuer mode. | Allocated fibers reserve at least 60 MiB. Ring cancellation and borrowed resources need independent qualification. | **Source/compile:** exact 0.17 implementation and the registered interface-failure witness. Low-level proofs do not qualify this backend. See [[evented-io-backends]] and [[io-uring]]. |
| macOS nonblocking `kqueue` reactor | Regular files are not turned into asynchronous data operations. `EVFILT_VNODE` is metadata notification; TigerBeetle performs regular-file `pread`/`pwrite` synchronously. | Strong candidate for socket readiness: attempt nonblocking operation, register one-shot readiness after `WouldBlock`, then retry. | Readiness is not byte transfer. Events may coalesce; one-shot watches require re-arm; a slow callback can stall a serialized dispatcher. Zig 0.17 `std.Io.Kqueue` is an unfinished proof of concept and is not selected as Apple `Io.Evented`. | Preallocate watch/operation records and retain identity through re-arm. Closing a descriptor removes its watches but does not acknowledge a separate AIO request. Cancellation/shutdown is application policy. | **Contract/source:** Apple XNU and pinned TigerBeetle; exact Zig 0.17 Kqueue source and registered interface-failure witness. No product reactor runtime/load proof in this vault. See [[macos-kqueue-and-aio]]. |
| Apple Dispatch I/O for macOS files | Random-access channels accept explicit offsets and may run operations concurrently; stream operations have channel-position ordering. Handlers may deliver partial data before terminal `done`. | This page does not recommend Dispatch I/O as the socket reactor; use nonblocking readiness/Dispatch sources or Threaded until proved. | The Zig 0.17 stdlib does not expose `dispatch_io_*`; the proof uses a C Blocks shim. One hot-cache result is not a storage-backend ranking. | Dispatch retains channels and write data; read data must be retained or copied before handler return. `DISPATCH_IO_STOP` is best effort; retain buffers until terminal callback. Bound channels, operations, queued bytes, and callbacks. | **Historical runtime, 0.16:** one random-access read via a Zig/C shim on arm64 macOS 26.6.2 plus a narrow hot-cache comparison. No cancellation, write, cold-I/O, durability, queue-depth, or load proof. See [[macos-kqueue-and-aio]]. |
| Zig 0.17 `std.Io.Dispatch` on macOS | Source positional operations and sync call synchronous syscalls inside fibers. Streaming descriptors retry after Dispatch readiness. | Creation stubs remain unavailable. Receive, send, read, write, and network batch paths panic. | `io()` assigns removed `processReplacePath`; the exact compiler rejects the I/O interface. Each allocated fiber reserves at least 60 MiB. | The old deinit allocator restriction is fixed. Initialization also calls the blocked interface constructor. Public signatures do not qualify runtime teardown. | **Source/compile:** exact 0.17 source and interface rejection. **Historical runtime, 0.16:** macOS type/init/fiber/read fixture; Safe failure remains dated. See [[macos-kqueue-and-aio]]. |
| Zig 0.17 Windows `std.Io.Threaded` APC/NtDll paths | Default and no-follow file opens use synchronous NT handles. Selected asynchronous handles use APC completion. | Asynchronous AFD endpoints use NT device-control requests. Shutdown takes a synchronous path. | Not IOCP. Windows `Io.Evented` is `void`. Concurrent network batches reject all four tags. Batch cancellation still waits before requesting cancellation. | Direct calls retain stack status blocks; batches retain slots until terminal APC handling. No-follow metadata now matches the handle mode. | **Source:** exact 0.17 implementation. **Historical runtime, 0.16:** x64, WOW64, and ARM64 cancellation/APC/batch/NPFS fixtures. The batch fixture uses an explicit alert. See [[windows-iocp-and-overlapped-io]]. |
| Custom Windows IOCP/overlapped adapter | Overlapped `ReadFile`/`WriteFile` with per-operation offsets. The original proof exercises reads; the TCP-to-file fixture adds writes and flush/readback, without power-loss evidence. | A separate bounded loopback Winsock TCP-to-file fixture ran on x64, WOW64 and ARM64; it is not a production socket workload. | Port concurrency does not bound handles, requests, backlog, or memory. Immediate success normally queues a packet unless skip-on-success is enabled. Zig 0.17 stdlib supplies no IOCP bindings. | Stable `OVERLAPPED`/buffer ownership until terminal dispatch; four-slot admission includes undrained completions. Stop admission, cancel, drain data and distinct control packets, then close. Cancellation does not promise byte rollback. | **Historical runtime, 0.16:** same Windows build, both pipe notification policies, cancel races and shutdown from four pending reads, plus 256 four-read cycles on pipes and a hot 256-byte NTFS file. File load was pending-only. The later TCP-to-file fixture adds batched results and public Winsock. No production ranking, cold-storage, power-loss or arbitrary-device result. See [[windows-iocp-and-overlapped-io]] and [[tigerbeetle-io]]. |

The newer [TCP-to-file proof](../proofs/windows_iocp_tcp_file.zig) extends the
custom IOCP design with public Winsock, batched dequeue, per-operation result
checks, file writes, flush/readback, and independent cancel/drain shutdown.
It ran on x86_64 Windows Server 2025 with exact Zig 0.16.0, including
immediate file-write completions and cancel-before-drain shutdown. File cancel
races all returned success; canceled file results, physical durability and
additional architecture runs are not established by that observation. Its five-second cycle diagnostic and sixty-second process watchdog
are fixture limits, not production latency or power-loss guarantees.
See [[windows-iocp-and-overlapped-io]] for the exact qualification boundary.

A custom Winsock adapter must distinguish application handle limits from provider resources.
`WSASocketW` allocates provider resources during admission.
Default `closesocket` cleanup can retain those resources after handle release.
A fixed application table therefore supplies no complete kernel-memory bound. [[microsoft-windows-acceptex-provider]]

## Recommendation by project stage

### Portable-first Zig 0.17 service

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

This path uses the default Zig 0.17 implementation. It does not
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

Do not select Zig 0.17's high-level `Io.Uring`, `Io.Kqueue`, or `Io.Dispatch`
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

The historical Zig 0.16 Windows matrix ran all five Windows proofs under WOW64 and as
ARM64 executables. The ARM64 qualification uses exact Zig 0.16.0 x64 compiler
emulation to produce and execute ARM64 baseline targets; native ARM compiler
crashes are a distinct recorded toolchain limit. See
[[windows-iocp-and-overlapped-io]] for the failed diagnostic workflow's successful
runtime phases, exact images and unobserved storage paths. Architecture breadth
does not discharge deployment durability, device/error or production-SLO gates.

Design application: [[bounded-http-server-design]] implements experimental Linux io_uring, macOS kqueue, and Windows IOCP HTTP backends.
The Windows adapter defaults to one shard and supports explicit inline configurations from one through 64 shards.
One accepting owner transfers socket metadata through fixed queues to independent IOCP owners.
Shared admission includes queued, transferred, and adopted connections.
The dated 2026-09-06 Zig 0.16 fixtures cover one through four owners, 89 wire cases, and 30,000 exact smoke responses.
[[bounded-http-windows-shards-2026-09-06]] retains source identities, fixture skips, and qualification limits.
Final Winsock cleanup follows every owner's terminal reconciliation. [[microsoft-windows-winsock-cleanup]]
The HTTP implementation does not implement the complete `std.Io` interface.
Its API proposals and production qualification remain open.
