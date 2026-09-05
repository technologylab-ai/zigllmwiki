---
id: macos-kqueue-and-aio
title: macOS kqueue, Dispatch, and asynchronous file I/O
kind: platform
status: source-verified
zig: "0.16.0"
summary: On macOS, separate kqueue readiness, Apple Dispatch I/O completion, POSIX AIO, and Zig 0.16's unfinished Dispatch backend before choosing a bounded file or network design.
updated: 2026-09-05
sources:
  - "[[zig-http-arena-adoption-2026-09-05]]"
  - "[[apple-xnu-kqueue-aio]]"
  - "[[zig-http-arena-shards-2026-09-05]]"
  - "[[apple-libdispatch-io]]"
  - "[[zig-0.16-dispatch-kqueue-source]]"
  - "[[zig-0.16.0-release-notes]]"
  - "[[tigerbeetle-io-source]]"
proofs:
  - proofs/macos_dispatch_io.zig
  - proofs/macos_dispatch_io_shim.c
platforms:
  - macos
---

# macOS `kqueue`, Dispatch, and asynchronous file I/O

## Remember

`kqueue` reports events and conditions. Apple Dispatch I/O schedules read and
write operations on retained channels and delivers partial and terminal
callbacks. POSIX AIO has yet another request/completion lifecycle. A bounded
worker queue can isolate synchronous calls. These are different designs; none
is a drop-in macOS spelling of Linux `io_uring`.

For Zig 0.16 specifically, `std.Io.Evented` resolves to `std.Io.Dispatch` on
Apple targets, not `std.Io.Kqueue`. The name does not mean that its regular-file
path uses Apple's Dispatch I/O channel API: it calls `preadv`, `pwritev`, and
`fsync` directly. The release notes identify evented implementations as
experimental while the default `main` capability remains `std.Io.Threaded`.

## `kqueue` contract

- An event is identified by its filter tuple; registering the same identity
  modifies the watch instead of adding another independent watch.
- Multiple triggers may be aggregated into one returned `kevent`. One returned
  record is not necessarily one underlying occurrence.
- Changes are applied before pending events are returned, and `kevent` can
  submit and retrieve arrays in one call.
- `udata` passes application identity through the kernel unchanged.
- A zero timeout polls; a null timeout waits without a deadline. Production
  loops need an intentional bounded-wait policy.
- `EV_ONESHOT` deletes the watch after its first returned occurrence; re-arming
  is an application state transition.
- Closing a descriptor removes watches that reference it. That says nothing
  about completion of a separate AIO request.

For sockets, `EVFILT_READ` reports queued data and can report EOF while unread
data remains. Process buffered data and terminal state independently. For
vnodes, the read filter reports whether the file pointer is before end-of-file,
while the write filter is not supported for vnodes. `EVFILT_VNODE` reports
metadata events such as write, extend, rename, and delete; it does not complete
your requested data write.

The same facility also has process, signal, timer, Mach-port, and filesystem
filters. Select filters by the condition they actually promise, not by the fact
that all results arrive as `kevent` records.

## Apple Dispatch I/O lifecycle

Dispatch I/O supports stream and random-access channels:

- stream reads and writes of the same type are ordered at the channel's file
  position; read and write directions may overlap;
- random-access operations use explicit offsets and may run concurrently;
- a handler may receive multiple partial results, but handler invocations for
  one operation are non-reentrant; only `done` identifies the terminal call;
- low-water, high-water, and interval settings influence callback cadence.

Treat a channel and each operation as explicit ownership state:

`created/retained → operation scheduled → partial handler calls → terminal done → channel closed → cleanup → released`

For a channel created from an existing descriptor, Dispatch takes control and
may alter flags such as `O_NONBLOCK`. Do not mutate or operate directly on that
descriptor while Dispatch owns it, except from a channel barrier for documented
operations such as `fsync` or `lseek`. A path-backed channel opens lazily when
the first operation is ready.

Read data is a `dispatch_data_t` whose automatic lifetime ends when its handler
returns; retain, concatenate, or copy it before then. A write retains its input
dispatch-data object until the operation completes, but whether the underlying
bytes were copied or borrowed was decided when that object was created.

Closing with `DISPATCH_IO_STOP` requests best-effort interruption. Partial
results may still arrive. An interrupted operation reports `ECANCELED` in its
terminal handler; a stop request does not promise every operation is interrupted. Thus,
as with [[cancellation]], close/stop is a request and the terminal callback is
the buffer-ownership acknowledgement.

## POSIX AIO lifecycle

For a successfully enqueued `aio_read`, the AIO control block and referenced
buffer must remain valid and unmodified until completion. Submission can fail
with `EAGAIN` because of system resource limits; this is a real admission and
backpressure case. `EVFILT_AIO` can carry its completion notification through a
`kqueue`, but that does not turn other readiness filters into completion APIs.

A useful lifecycle is:

`free → initialized/zeroed → enqueued → in progress → terminal → aio_return once → free`

`aio_error` distinguishes in-progress from terminal success/failure.
`aio_return` obtains final status and releases system resources; the Apple
manual requires it exactly once after completion and warns that omitting it
leaks resources.

`aio_cancel` can report all done, canceled, or not canceled. Canceled work gets
normal asynchronous notification and a terminal `ECANCELED` result, but raw
disk requests are documented as non-cancellable. As with `std.Io` and
`io_uring`, the cancellation request does not transfer buffer ownership back;
terminal completion does.

## Exact Zig 0.16 mapping

The release source establishes these boundaries:

| Zig surface | What the 0.16.0 source does | Do not infer |
| --- | --- | --- |
| `std.Io.Evented` on Apple targets | Aliases `std.Io.Dispatch` when fibers are supported. | That `std.Io.Kqueue` is the selected macOS backend. |
| `std.Io.Dispatch` task execution | Allocates stackful fibers and schedules them on a concurrent GCD queue. | That every operation is a kernel-completion operation or allocation-free. |
| Streaming descriptor read/write | Tries `readv`/`writev`; after `WouldBlock`, waits with Dispatch read/write sources and retries. | That readiness itself transferred bytes. |
| Positional file read/write and sync | Calls `preadv`, `pwritev`, and `fsync` directly in the running fiber. | That naming the backend `Dispatch` makes regular-file calls use `dispatch_io_*`. |
| Networking | The `Dispatch` vtable installs unavailable stubs in this release. | Feature parity with `Threaded`, or suitability as an HTTP-server backend. |
| `std.Io.Kqueue` | Directly importable proof-of-concept with many panicking `TODO` paths; selected for four BSD targets, not Apple targets. | A supported general-purpose macOS wrapper. |

The concrete `std.c.dispatch` bindings used by Zig 0.16 expose queues, sources,
semaphores, and data objects but not `dispatch_io_*`. Calling Dispatch I/O from
Zig therefore currently needs an additional C/Objective-C Blocks boundary or
new standard-library bindings.

Two additional release-source seams are too large to ignore:

- each allocated `std.Io.Dispatch` fiber reserves a 60 MiB minimum stack;
- `std.Io.Dispatch.deinit()` does not compile under the same Zig 0.16.0
  compiler because its fixed-size slice expression is passed to
  `Allocator.free` as a pointer-to-array.

The proof runs the backend in an isolated process and lets process exit reclaim
its initialization resources. That is proof of a current limitation, not an
endorsed teardown pattern.

## Runnable Zig wrapper and macOS evidence

The [Zig proof](../proofs/macos_dispatch_io.zig) and its
[Blocks shim](../proofs/macos_dispatch_io_shim.c) provide a deliberately narrow
adapter around `dispatch_io_create_with_path` and `dispatch_io_read`. It keeps a
caller-owned buffer borrowed until the terminal handler, copies every delivered
dispatch-data region, joins with a Dispatch semaphore, and surfaces the final
errno as failure. It is not a `std.Io` implementation and has no cancellation,
admission queue, write path, or detailed error translation.

On 2026-09-04, Zig 0.16.0 compiled the shim with Blocks enabled and both tests
passed on arm64 macOS 26.6.2 (build 25G83):

- an actual Dispatch I/O random-access channel read the expected regular-file
  bytes through the Zig adapter;
- compile-time type identity established `std.Io.Evented == std.Io.Dispatch`,
  then `Dispatch.init`, an asynchronous fiber, and a positional file read ran
  to completion.

The proof also contains an opt-in hot-cache benchmark. Seven consecutive
ReleaseFast samples each read 1 MiB 64 times from the same file with persistent
handles and reusable buffers. Median total times were:

| Path | Median | Observed range |
| --- | ---: | ---: |
| `std.Io.Threaded` positional read | 1,440,084 ns | 1,427,250–1,541,000 ns |
| `std.Io.Dispatch` positional read | 1,439,625 ns | 1,420,958–1,520,458 ns |
| Apple Dispatch I/O plus synchronous proof join | 3,789,916 ns | 3,708,875–3,809,125 ns |

This result shows wrapper/callback overhead for hot cached sequential reads; it
does not rank storage backends. Page-cache throughput dominates the two direct
syscall paths, while the proof serializes and joins every Dispatch I/O request.
Before a product decision, measure bounded concurrent queue depths, cold and
warm files, representative sizes, tail latency, cancellation, writes, and
durability on the deployment hardware.

## Design choices for a macOS server

| Work | Candidate | Current evidence boundary |
| --- | --- | --- |
| TCP accept/read/write | A product-owned nonblocking `kqueue`/Dispatch-source reactor, or `std.Io.Threaded` while bounded | `std.Io.Dispatch` networking is unavailable in 0.16. A production reactor and load proof still belong to the application. |
| Regular-file read/write | Dispatch I/O, POSIX AIO, memory mapping for a proven access pattern, or a bounded worker backend | Dispatch I/O and POSIX AIO lifecycles are sourced; the proof establishes integration and one hot-cache baseline, not production superiority. |
| File metadata change | `EVFILT_VNODE` | Notification only; it is not data-operation completion. |
| Timers/process events | `EVFILT_TIMER` / `EVFILT_PROC`, Dispatch sources, or explicit deadlines | Match the facility's guarantee to the loop; do not treat all event records as I/O completion. |

The preliminary HTTP reference ([[zig-http-arena-shards-2026-09-05]]) reports
two loopback observations on the user's M3 Max. With several TCP listeners
bound through `SO_REUSEPORT`, its per-shard counters assigned every connection
to the last-bound listener. That fixture motivated a one-shard macOS default;
it does not establish a universal XNU guarantee across OS versions, socket
options, addresses or connection patterns. An acceptor handing descriptors to
bounded owners is a candidate if a deployment needs different distribution,
not a requirement proved by this single fixture.

The same report records 6–16% lower throughput with early receive submission
in its custom `kqueue` adapter. An unsuccessful nonblocking read followed by
readiness registration is a possible additional path, not evidence of exactly
two extra syscalls for every pipeline or a result for Apple Dispatch I/O or
`std.Io`. The captured design/report lacks a qualified shuffled comparison and
an integrated publication receipt. Preserve this preliminary observation and
its scope when consulting [[bounded-http-server-design]]; neither observation
changes the regular-file proof or its evidence level above.

TigerBeetle currently chooses `kqueue` for readiness and synchronous
regular-file operations in its callback dispatcher. That is a concrete product
choice, not proof that synchronous storage work is suitable for every server.
The source does not state that choice's full rationale, so do not invent one.

The M3-003 research artifacts now include Dispatch I/O primary evidence, an
executable Zig 0.16 adapter, macOS runtime evidence, and a reproducible first
comparison. The remaining work is product-specific rather than a missing
platform fact: a production wrapper must choose finite operation limits,
cancellation ownership, error taxonomy, durability behavior, and workload
measurements before it can be selected for a server.

Related: [[tigerbeetle-io]], [[evented-io-backends]], [[cancellation]],
[[static-allocation-and-constant-work]], [[trustworthy-microbenchmarks]], and
[[invariants-and-assertions]]. HTTP application: [[bounded-http-server-design]].


The subsequent adopted HTTP source and repeated Linux comparison have their
own immutable pin, [[zig-http-arena-adoption-2026-09-05]], with Mac/Linux native
completion/startup witnesses. This does not repeat or strengthen the earlier
prearm or Mac listener-distribution experiment; their preliminary scope remains.
