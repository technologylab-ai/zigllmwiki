---
id: windows-iocp-and-overlapped-io
title: Windows IOCP and overlapped I/O lifecycle
kind: platform
status: source-verified
zig: "n/a"
summary: IOCP unifies completions for overlapped file and socket operations, while each OVERLAPPED record and buffer stays owned until one terminal completion path reconciles success, failure, or cancellation.
updated: 2026-09-04
sources:
  - "[[microsoft-windows-iocp]]"
  - "[[tigerbeetle-io-source]]"
proofs: []
platforms:
  - windows
---

# Windows IOCP and overlapped I/O lifecycle

## Remember

Open a file or device for asynchronous operation with
`FILE_FLAG_OVERLAPPED`, associate the handle with an I/O completion port, and
give each in-flight operation its own stable `OVERLAPPED` record and buffer.
Neither may be modified, freed, or reused until that operation's terminal path
has been consumed.

An asynchronous call can complete immediately. With an IOCP-associated handle,
immediate success can still produce a completion packet unless notification
modes suppress it. Choose one reclamation owner so immediate success plus a
later packet cannot double-complete or double-free the operation.

## Completion-port model

An IOCP combines completions from many associated handles into one queue. The
completion key can identify the handle-level owner, while the returned
`OVERLAPPED` address identifies the particular operation.

Packets enter the port queue in FIFO order but may be dequeued in a different
order. Never derive request ordering from dequeue order. The `NumberOfConcurrentThreads`
setting limits runnable threads associated with the port; it is not a limit on
open handles, in-flight operations, queued packets, or application memory. Each
needs its own capacity model.

`PostQueuedCompletionStatus` can place application-defined packets on the same
queue, which is useful for explicit wakeup or control-plane messages. Give
synthetic packets identities that cannot be confused with kernel I/O results.

Supported IOCP operations include file reads/writes and Windows socket
operations, but support depends on using the operation's overlapped form and an
associated handle. Asynchronous file handles do not maintain one shared file
pointer; every operation supplies its own offset in `OVERLAPPED`.

## Cancellation is request plus terminal reconciliation

`CancelIoEx` marks matching outstanding work for cancellation and returns
without waiting. It can target one `OVERLAPPED` or all work for a handle. A
successful call means the request was issued, not that the operation is
terminal; `ERROR_NOT_FOUND` means no matching outstanding request was found,
not that a previously issued operation is safe to forget.

The target can still complete normally, complete as canceled with
`ERROR_OPERATION_ABORTED`, or fail for another reason. Keep its `OVERLAPPED`
and buffer alive until that outcome is observed. With a completion-port handle,
a still-pending asynchronous operation produces a completion packet when
cancellation resolves, while a synchronously canceled operation has a documented
exception where no packet is queued. The adapter must know which path owns
terminal reconciliation.

This is the Windows form of [[cancellation|request and acknowledgement]]:

`cancel requested → target races → terminal status observed → resources reusable`

## TigerBeetle mapping

The pinned TigerBeetle Windows backend:

- creates one IOCP and registers socket/file handles;
- embeds `OVERLAPPED` inside its caller-owned completion operation;
- uses `AcceptEx`, `ConnectEx`, `WSARecv`, `WSASend`, `ReadFile`, and
  `WriteFile` for pending work;
- drains up to 64 entries with `GetQueuedCompletionStatusEx`;
- requests `FILE_SKIP_COMPLETION_PORT_ON_SUCCESS`, then handles synchronous
  success directly;
- serializes application callbacks on its dispatcher;
- does not expose a general cancel operation at this revision.

That mapping validates the ownership shape, not a portable cancellation API or
Zig 0.16 `std.Io` backend. Some actions in the wrapper still run synchronously;
audit each operation rather than calling the whole surface nonblocking.

## Adapter checklist

- Is the handle opened for the intended synchronous or overlapped mode?
- Does every operation have a unique stable record, buffer, offset, and owner?
- Can immediate success and queued completion reach exactly one terminal path?
- Are dequeue order and operation order kept independent?
- Are in-flight count, completion backlog, handle count, and runnable callback
  concurrency bounded separately?
- Does cancellation retain resources until success, canceled, or other failure
  is observed?
- Can shutdown drain or explicitly account for every submitted operation?

No Windows runtime proof exists in this repository yet. M3-004 remains active
for Zig 0.16 source mapping, error translation, and behavioral tests on a
Windows runner.

Related: [[tigerbeetle-io]], [[evented-io-backends]], [[cancellation]],
[[invariants-and-assertions]].
