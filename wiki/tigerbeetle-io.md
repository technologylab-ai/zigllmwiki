---
id: tigerbeetle-io
title: TigerBeetle cross-platform I/O design
kind: pattern
status: source-verified
zig: "n/a"
summary: TigerBeetle maps a caller-owned callback/completion interface onto io_uring, kqueue readiness plus synchronous file I/O, and Windows IOCP/overlapped I/O without pretending the backends are semantically identical.
updated: 2026-09-04
sources:
  - "[[tigerbeetle-io-source]]"
  - "[[tigerbeetle-architecture]]"
  - "[[liburing-interface-and-cancellation]]"
  - "[[apple-xnu-kqueue-aio]]"
  - "[[microsoft-windows-iocp]]"
proofs: []
platforms:
  - linux
  - macos
  - windows
---

# TigerBeetle cross-platform I/O design

## Remember

TigerBeetle's `IO` is an application-specific callback interface, not an
implementation of Zig 0.16 `std.Io`. Its value here is architectural: the same
operation vocabulary is mapped deliberately onto different operating-system
mechanisms, while operation state stays owned by the calling component.

Do not translate “Darwin uses `kqueue`” into “Darwin regular-file I/O is
evented.” In the pinned implementation, socket operations that return
`WouldBlock` are re-armed through one-shot `kqueue` readiness, but `pread`,
`pwrite`, open, close, and sync operations execute synchronously during
callback dispatch.

## Common ownership shape

The caller supplies a `Completion` for every operation and keeps any referenced
buffer or path alive. Each platform-specific completion stores the operation
arguments, callback context, and callback. Intrusive queues link those same
records; the I/O object does not create a heap object per submission.

This yields a useful owner rule:

`component limit → embedded completion slots → submitted operation → callback → slot reuse`

The source does not by itself prove the application's total capacity. The
component that owns the completion slots still needs an explicit concurrency
limit, overload policy, and shutdown protocol.

All three dispatchers serialize ready callbacks. A callback may enqueue more
ready work, and the Darwin and Windows loops deliberately drain such a chain in
the same pass to match the Linux behavior. This simplifies mutation ownership,
but it also means a slow or blocking callback stalls unrelated completions.

## Backend map at the pinned revision

| Concern | Linux | Darwin | Windows |
| --- | --- | --- | --- |
| Kernel mechanism | `io_uring` SQEs/CQEs | `kqueue` one-shot readiness | IO completion port plus overlapped APIs |
| Socket I/O | `accept`, `connect`, `recv`, and `send` SQEs | Try the nonblocking syscall; register `EVFILT_READ` or `EVFILT_WRITE` after `WouldBlock` | `AcceptEx`, `ConnectEx`, `WSARecv`, and `WSASend` |
| Regular-file read/write | `io_uring` read/write SQEs | Synchronous `pread`/`pwrite` in dispatcher callbacks | Overlapped `ReadFile`/`WriteFile` associated with the IOCP |
| Timeouts | Kernel timeout SQEs | Userspace deadline queue plus bounded `kevent` wait | Userspace deadline queue plus bounded IOCP wait |
| Ready batch | Up to 256 CQEs copied per flush | Up to 256 `kevent` events per flush | Up to 64 IOCP entries per wait |
| Submission capacity argument | Sizes the ring; type is `u12` | Accepted but ignored | Accepted but ignored |
| General cancellation API | Not present in the operation union | Not present | Not present; unexpected aborted operations are treated as unreachable |

This is interface similarity, not semantic identity. TigerBeetle's own tests
explicitly skip one timeout-queue behavior on Linux because kernel-managed
timeouts do not behave exactly like the userspace Darwin and Windows queues.

## Linux queue lifecycle and pressure

The Linux backend records queued and in-kernel operation counts separately. It
flushes queued SQEs, copies CQEs into a fixed stack batch, turns `user_data`
back into the caller's completion pointer, and queues callbacks rather than
running them recursively inside CQ processing.

When the submission queue is full, `enqueue` warns, flushes current submissions,
and retries. That policy avoids an overflow allocation and preserves progress,
but submission can now perform a syscall and change latency. Treat it as a
concrete backpressure choice, not as proof that ring exhaustion is harmless.

The implementation requires `IORING_FEAT_EXT_ARG`, documented in the source as
a Linux 5.11-or-newer requirement. It passes the loop wait deadline directly to
`io_uring_enter`; it does not spend an additional timeout SQE for each loop
wait. Application timeouts remain ordinary timeout operations.

## Darwin readiness is not file asynchrony

New non-timeout operations first enter the completed queue. Their wrapper tries
the actual operation on the dispatcher. Only a socket or descriptor operation
that returns `WouldBlock` moves to the pending queue and becomes a one-shot
`kqueue` change. The readiness event causes the syscall to be tried again.

This is a sound reactor pattern for nonblocking sockets. For regular files,
however, the pinned `read` calls `pread`, `write` calls `pwrite`, and optional
durability sync follows synchronously. Therefore:

- a file operation can block the one callback thread;
- `kqueue` is not a portable substitute for `io_uring` file operations;
- an HTTP server can use this reactor for sockets without assuming its file
  serving path is nonblocking;
- truly asynchronous file access needs a separately justified mechanism, such
  as bounded worker execution or a suitable platform API.

## Windows completion ownership

The Windows backend creates an IOCP and associates opened sockets and file
handles with it. It requests that synchronous successes not enqueue redundant
completion packets. Pending socket and file operations embed an `OVERLAPPED`
record that points back to the caller-owned completion, and
`GetQueuedCompletionStatusEx` moves returned entries onto the ready queue.

The source uses overlapped file and network operations, but some other actions
such as sync and close are performed when their callback wrapper runs. Audit
each operation rather than labeling the entire backend “nonblocking.”

## Cancellation boundary

The shared surface at this revision has no cancel function and no cancel tag in
its operation union. Some result mappings acknowledge cancellation errors, but
that is not a public request-and-acknowledgement protocol. Do not copy a buffer
reuse or shutdown rule from this source.

For Linux cancellation lifecycle, use [[io-uring]] and primary liburing
documentation. The parallel Apple and Windows lifecycle rules are in
[[macos-kqueue-and-aio]] and [[windows-iocp-and-overlapped-io]]. For Zig 0.16
task cancellation, use [[cancellation]]. A future portable adapter must specify
how cancellation reaches each backend and when the caller regains ownership of
every completion record and buffer.

## What to transfer

- Put operation state in caller-owned, bounded records.
- Keep backend state transitions explicit and dispatch callbacks serially when
  that matches the application's mutation model.
- Separate queued, kernel-owned, and callback-ready work in capacity accounting.
- Make queue-full behavior an intentional latency and overload policy.
- Preserve platform-specific truth beneath a shared vocabulary.
- Test cross-platform semantic parity and record deliberate exceptions.

Do not copy current TigerBeetle syntax into Zig 0.16 code without a separate
proof. This page is source-verified design guidance; it has no Zig 0.16 runtime
proof or cross-platform behavioral evidence yet.

Related: [[io-uring]], [[evented-io-backends]],
[[macos-kqueue-and-aio]], [[windows-iocp-and-overlapped-io]],
[[static-allocation-and-constant-work]], [[tigerstyle]],
[[task-lifetimes-and-structured-concurrency]].
