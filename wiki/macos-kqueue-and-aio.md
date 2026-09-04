---
id: macos-kqueue-and-aio
title: macOS kqueue readiness and asynchronous file I/O
kind: platform
status: source-verified
zig: "n/a"
summary: kqueue batches descriptor conditions and readiness; POSIX AIO is a separate asynchronous file-operation lifecycle, so neither should be treated as a drop-in io_uring clone.
updated: 2026-09-04
sources:
  - "[[apple-xnu-kqueue-aio]]"
  - "[[tigerbeetle-io-source]]"
proofs: []
platforms:
  - macos
---

# macOS `kqueue` readiness and asynchronous file I/O

## Remember

`kqueue` reports that an event happened or a condition holds. For nonblocking
sockets, that supports the reactor pattern: wait for read/write readiness, try
the operation, and re-arm when it would block. It does not turn an ordinary
`pread` or `pwrite` into an asynchronous regular-file operation.

Apple's current XNU manual documents POSIX AIO as a separate interface. An
`aio_read` request can be enqueued and complete later; `EVFILT_AIO` can carry
notification for such a request. Keep “readiness notification” and “operation
completion” as different concepts even when one `kqueue` receives both.

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

## POSIX AIO lifecycle

For a successfully enqueued `aio_read`, the AIO control block and referenced
buffer must remain valid and unmodified until completion. Submission can fail
with `EAGAIN` because of system resource limits; this is a real admission and
backpressure case.

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

## Design choices for a macOS server

| Work | Candidate | Current evidence boundary |
| --- | --- | --- |
| TCP accept/read/write | Nonblocking sockets plus `kqueue` | Primary readiness semantics are source-verified; a Zig 0.16 wrapper and load proof remain. |
| Regular-file read/write | POSIX AIO, dispatch I/O, or a bounded worker backend | POSIX AIO lifecycle is source-verified; comparative performance, filesystem behavior, and dispatch I/O remain unproved here. |
| File metadata change | `EVFILT_VNODE` | Notification only; it is not data-operation completion. |
| Timers/process events | `EVFILT_TIMER` / `EVFILT_PROC` or explicit loop deadlines | Semantics are documented; clock and cancellation composition still need a Zig proof. |

TigerBeetle currently chooses `kqueue` for readiness and synchronous
regular-file operations in its callback dispatcher. That is a concrete product
choice, not proof that synchronous storage work is suitable for every server.
The source does not state that choice's full rationale, so do not invent one.

No Zig 0.16 platform wrapper or runtime comparison is proved by this page.
M3-003 remains active until dispatch I/O is sourced and candidate designs are
measured on macOS.

Related: [[tigerbeetle-io]], [[evented-io-backends]], [[cancellation]],
[[invariants-and-assertions]].
