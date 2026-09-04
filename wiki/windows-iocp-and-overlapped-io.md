---
id: windows-iocp-and-overlapped-io
title: Windows IOCP, overlapped I/O, and Zig 0.16 mapping
kind: platform
status: source-verified
zig: "0.16.0"
summary: Windows IOCP adapters require stable OVERLAPPED ownership and terminal cancellation reconciliation, while Zig 0.16 std.Io.Threaded instead mixes worker-blocking and APC-based NtDll paths and has no Windows Evented backend.
updated: 2026-09-04
sources:
  - "[[microsoft-windows-iocp]]"
  - "[[microsoft-windows-iocp-api]]"
  - "[[microsoft-windows-nt-fs-control]]"
  - "[[zig-0.16-windows-io-source]]"
  - "[[tigerbeetle-io-source]]"
proofs:
  - proofs/windows_io_mapping.zig
  - proofs/threaded_blocked_read_cancel_windows.zig
  - proofs/windows_apc_batch.zig
  - proofs/windows_iocp_lifecycle.zig
platforms:
  - windows
---

# Windows IOCP, overlapped I/O, and Zig 0.16 mapping

## Remember

Do not call Zig 0.16 `std.Io.Threaded` an IOCP backend. On Windows it combines
ordinary worker-thread execution, synchronous NT file handles, and alertable
APC completion for selected asynchronous handles. `std.Io.Evented` resolves to
`void` on Windows, and Zig 0.16's `std.os.windows` surface does not declare the
Win32 `OVERLAPPED` or IOCP functions.

A custom IOCP backend is a separate design. Open or create each file or socket
for overlapped operation, associate it with a completion port, and retain a
unique stable `OVERLAPPED` record plus every referenced buffer until one
terminal completion path has been reconciled. Immediate success and a later
completion packet must never reclaim the same operation twice.

## Which Windows design is this?

| Layer | Zig 0.16 mechanism | Completion identity | Production boundary |
| --- | --- | --- | --- |
| `std.Io.Threaded` task dispatch | Allocated futures and a growing worker pool | Future/group task record | This is Zig 0.16's feature-complete default implementation, but `async` may execute eagerly and is not an event loop. |
| Default regular-file I/O | Handles opened `SYNCHRONOUS_NONALERT`; blocking `NtReadFile`/`NtWriteFile` on the executing thread | Call stack plus `IO_STATUS_BLOCK` | A blocked operation consumes its task thread. |
| Selected asynchronous file/device paths | `NtReadFile`, `NtWriteFile`, `NtFsControlFile`, or `NtDeviceIoControlFile` with an APC routine | Stable `IO_STATUS_BLOCK` in the call or `Batch` slot | APC completion is not IOCP completion. Support depends on the handle mode and operation. |
| `std.Io.Threaded` networking | Asynchronous AFD endpoint handles plus `NtDeviceIoControlFile` requests and APC waits | AFD request storage and `IO_STATUS_BLOCK` | This is stdlib implementation detail, not a stable AFD API for applications to copy. |
| Custom/TigerBeetle-style backend | Win32 overlapped file/socket operations associated with IOCP | Caller-owned `OVERLAPPED`, completion key, and buffer | Outside the Zig 0.16 `std.Io.Threaded` implementation; must supply bindings, limits, cancellation, tests, and error mapping. |

The same word “asynchronous” appears in several rows, but the dispatch,
wakeup, resource, and cancellation contracts are different.

Do not attach the APC fixture's handle to an IOCP to combine these designs.
Microsoft's `NtFsControlFile` contract forbids an APC routine on a handle
already associated with an I/O completion object. Its `ApcContext` parameter
has different roles in the callback and port cases. See
[[microsoft-windows-nt-fs-control]].

## Exact Zig 0.16 `std.Io.Threaded` behavior

### Regular files default to synchronous handles

`Io.File.Flags.nonblocking` means `MODE.IO.ASYNCHRONOUS` on Windows. The
ordinary `Dir.openFile` path, with its default `follow_symlinks = true`, opens
the handle with `SYNCHRONOUS_NONALERT` and returns
`File.flags.nonblocking = false`. Streaming and positional reads and writes on
that handle call `NtReadFile` or `NtWriteFile` without an APC routine. If such
an operation runs in an `Io` task, concurrency comes from the Threaded worker,
not from IOCP or kernel completion dispatch.

Task cancellation of a worker blocked in this synchronous region uses
`NtCancelSynchronousIoFile` against the worker thread. `NOT_FOUND` is treated
as a race that may mean the syscall has not started, so the canceling side can
signal again; `SUCCESS` confirms that the interrupt request reached the OS.
That source path is not runtime proof that every Windows device and driver
interrupts with acceptable latency.

### APC-based operations retain their stack or slot

For a file whose `nonblocking` flag is true, direct read, write, and device
control paths provide an APC routine and a stack `IO_STATUS_BLOCK`. Both
`STATUS_PENDING` and immediate `STATUS_SUCCESS` enter an alertable wait for the
APC routine. If task cancellation arrives, the code calls
`NtCancelIoFileEx` for that exact status block and continues waiting until the
APC has run before returning `error.Canceled`. This is the required ownership
shape: cancellation requests interruption; it does not expire the control
block or buffer lifetime.

The Windows `Batch` path stores a handle and `IO_STATUS_BLOCK` inside the
caller-provided fixed `Operation.Storage` slot. Its APC moves the slot from
pending to either completed or unused. `Batch.cancel` requests
`NtCancelIoFileEx` for every pending status block and alertably waits until the
pending list is empty. Canceled operations disappear, while operations that
won the race remain available through `Batch.next`, matching the public batch
contract in [[select-and-batch]].

`Batch.awaitConcurrent` is narrower than “all operations concurrently”:

- a streaming file read/write or device control on a synchronous handle
  returns `error.ConcurrencyUnavailable` instead of blocking;
- Windows `net_receive` has an explicit source TODO to integrate overlapped or
  equivalent I/O and returns `error.ConcurrencyUnavailable` in this mode;
- `awaitAsync` may perform the corresponding blocking path because its
  interface contract permits eager/non-concurrent progress.

These are backend-specific limits, not contradictions in the portable
`std.Io.Batch` interface.

### Pending batch cancellation has a progress defect

In the exact 0.16.0 `Threaded.batchCancel` implementation, a nonempty pending
list first calls `waitForApcOrAlert()` with no deadline, **before** issuing any
`NtCancelIoFileEx` requests. It then requests cancellation and waits again
until the pending list empties. With no queued APC or alert and no operation
able to finish, that first wait can prevent cancellation from ever reaching
the kernel. This follows directly from [[zig-0.16-windows-io-source]]; do not
mistake the public terminal-ownership contract for a backend progress proof.

An ordinary `defer batch.cancel(io)` still describes who owns cleanup, but it
does not impose a shutdown deadline on this Windows path. A bounded adapter
needs a separately owned wake/escape mechanism and a watchdog for its tested
environment. That mechanism is an implementation-specific integration seam,
not an additional requirement of the portable `Batch` interface.

### Networking goes through NT AFD, not IOCP

The Threaded backend opens `\\Device\\Afd\\Endpoint` with
`MODE.IO.ASYNCHRONOUS`. Connect, accept, stream, and datagram operations are
implemented as AFD control requests through `NtDeviceIoControlFile`, using APC
completion where the operation permits it. Network shutdown is a visible
exception: the source states that shutdown does not support APCs and performs
that AFD request through the synchronous path.

This implementation is useful evidence about what the shipped backend does.
It is not an endorsed public AFD programming surface and must not be confused
with the Winsock `AcceptEx`/`ConnectEx`/`WSARecv`/`WSASend` IOCP design used by
the pinned TigerBeetle backend.

## Zig error translation

Zig 0.16 translates expected NTSTATUS values at each operation boundary rather
than leaking a universal Windows error code:

- file reads map end-of-file/broken-pipe, invalid-handle, directory, lock, and
  access statuses to the corresponding typed Zig errors;
- file writes map resource, broken-pipe, invalid-handle, lock, access, and
  disk-full statuses to typed errors;
- AFD operations have operation-specific maps for resource exhaustion,
  address conflicts, connection state, oversized messages, port
  unreachability, and related network failures;
- the low-level Windows `device_io_control` result is the raw
  `IO_STATUS_BLOCK`, so its consumer owns interpretation of operation-specific
  status and information fields;
- unrecognized NTSTATUS values go through `windows.unexpectedStatus` and
  become `error.Unexpected` (with optional unexpected-error tracing).

`STATUS_CANCELLED` is intentionally not a normal file-result mapping in these
paths. Task cancellation becomes the portable `error.Canceled` protocol before
result translation, and a successfully canceled batch operation is absent from
the completion iteration. Do not invent a second error translation at a layer
that no longer owns cancellation.

## IOCP adapter contract

An IOCP combines completions from many associated handles into one queue. The
completion key can identify a handle-level owner, while the returned
`OVERLAPPED` address identifies the particular operation. Packets enter the
port queue in FIFO order but may be dequeued in a different order, so request
ordering must not depend on dequeue order.

`NumberOfConcurrentThreads` limits how many threads associated with the port
may run at once. It does not limit open handles, in-flight operations, queued
packets, buffers, or application callbacks; bound each separately.
`PostQueuedCompletionStatus` may share the queue with kernel completions for
control-plane wakeups, but synthetic packets need identities that cannot be
confused with I/O results.

For overlapped files, each operation carries its own offset; do not rely on a
shared file pointer. An overlapped call can report immediate success. With an
IOCP-associated handle, that success normally still produces a completion
packet. If the adapter explicitly enables
`FILE_SKIP_COMPLETION_PORT_ON_SUCCESS`, synchronous success instead belongs to
the direct call path and no packet is queued for that case. Select exactly one
reclamation owner for either policy.

## Cancellation is request plus terminal reconciliation

Win32 `CancelIoEx` and NT `NtCancelIoFileEx` are related layers with different
return conventions; do not mix `GetLastError` rules with NTSTATUS handling.
For an IOCP adapter, `CancelIoEx` can target one `OVERLAPPED` or all operations
on a handle and returns without waiting for the target to become terminal.

A successful cancellation request is not a completion. The target may still
finish normally, finish canceled with `ERROR_OPERATION_ABORTED`, or fail for
another reason. `ERROR_NOT_FOUND` only says that no matching request was found
at that instant. In every case, retain the `OVERLAPPED`, buffer, handle
association, and owner generation until the adapter observes and reconciles
the terminal outcome.

Use this state machine:

`submitted → cancel requested (optional) → terminal outcome observed → callback/result drained → slot reusable`

This is the Windows instance of [[cancellation|request and acknowledgement]].
Closing a handle or freeing an operation record is not an acknowledgement.

`GetQueuedCompletionStatus` returning false is not always a wait failure. If
it returns a non-null `OVERLAPPED`, it dequeued a terminal failed I/O packet;
reconcile that operation using `GetLastError`. If the pointer is null, no
packet was dequeued and the byte/key outputs are indeterminate. A synthetic
successful packet with a null pointer can instead be an application control
message, provided its identity and handling are explicit.
[[microsoft-windows-iocp-api]] supplies the exact API contracts.

## Bounded proof design

The two new harnesses implement deliberately narrow fixtures, not a complete
`std.Io` backend. Their records remain at final addresses while the kernel can
borrow them; cleanup drains terminal outcomes before closing handles. The
named-pipe buffer reservation is a requested kernel quota, not an application
memory cap or a guarantee about every driver's buffering.

| Harness | Application limits and ownership | Shutdown/failure boundary |
| --- | --- | --- |
| [APC/batch/device](../proofs/windows_apc_batch.zig) | NPFS pipes; one or two fixed operation slots; a 4096-byte requested pipe quota; 1-byte and 8192-byte transfers; one permitted Threaded concurrent task plus bounded helper threads. Raw NT calls record actual immediate/pending statuses. | Direct task cancellation joins; batch cleanup explicitly alerts the issuing thread to release the 0.16.0 initial-wait defect, then drains retained successes. The device fixture is message-pipe `FSCTL_PIPE_TRANSCEIVE` through `NtFsControlFile`. |
| [Custom IOCP](../proofs/windows_iocp_lifecycle.zig) | Four stable slots and 64-byte buffers, port concurrency one, four pipe pairs or four handles to one 256-byte regular file. Admission counts submitted operations until terminal dispatch, including queued completions. Both default and skip-on-success modes have separate runs. | Stop admission, post one uniquely identified control packet, cancel outstanding operations, keep draining after the control packet, reconcile every data result, then close handles and port. Capacity exhaustion and closed admission fail explicitly. |

The IOCP proof uses one-packet `GetQueuedCompletionStatus` dequeue and bounded
submission batches. It does not exercise `GetQueuedCompletionStatusEx` or
Winsock. Aborted results do not imply byte rollback: race fixtures close their
pipe only after the writer and target are terminal, then create a fresh pair.
The regular-file fixture uses the exact 0.16.0
`openFile(.follow_symlinks = false)` implementation to obtain an asynchronous
handle and checks its flag; that is an implementation fixture, not a portable
API promise that symlink policy selects a scheduling mechanism.

Watchdogs bound the test's willingness to wait: the APC harness has a 20-second
process watchdog; IOCP has a 3-second drain deadline and a separate 30-second
process watchdog. These are scheduler-dependent diagnostic bounds, not hard
real-time guarantees. Failure terminates the isolated test process instead of
unwinding live operation storage. Even `TerminateProcess` depends on pending
I/O completing or canceling, so the hosted workflow's outer job timeout
remains necessary; no watchdog proves arbitrary-driver cancellation progress.
See [[microsoft-windows-iocp-api]].

## TigerBeetle comparison

At the pinned revision, TigerBeetle's custom Windows backend creates one IOCP,
associates socket and file handles, embeds `OVERLAPPED` in caller-owned
completion records, and uses `AcceptEx`, `ConnectEx`, `WSARecv`, `WSASend`,
`ReadFile`, and `WriteFile`. It drains batches with
`GetQueuedCompletionStatusEx`, requests
`FILE_SKIP_COMPLETION_PORT_ON_SUCCESS`, and completes synchronous successes on
the direct path. Application callbacks are serialized by the dispatcher.

The source has no public general cancel operation at that revision, and some
actions still execute synchronously. It validates a bounded ownership shape;
it is not a Zig 0.16 `std.Io` backend or evidence that every wrapper operation
is nonblocking.

## Evidence and missing runtime work

The [mapping proof](../proofs/windows_io_mapping.zig) checks the exact Zig
0.16 Windows type surface, confirms that `Io.Evented` is unavailable, confirms
the relevant NtDll declarations and absence of stdlib IOCP bindings, and
constructs a fixed-slot Windows `Io.Batch` operation. It was compiled as PE
test executables for `x86-windows`, `x86_64-windows`, and `aarch64-windows`
with Zig 0.16.0 on 2026-09-04. It also ran natively on x86_64 Windows Server
2025 Datacenter 24H2, build 26100.33296. Cross-compilation remains compile
evidence for the other two architectures.

The
[blocked-read cancellation harness](../proofs/threaded_blocked_read_cancel_windows.zig)
constructs the same synchronous NT named-pipe shape used by Threaded process
pipes, starts a read on an owned concurrent task, and expects cancellation to
interrupt it before a watchdog write. It ran successfully on that same Windows
Server 2025 host and still compiles for all three Windows architectures. The
exact host metadata and both native logs are retained by
[Actions run 33911991858](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33911991858).

Windows-specific work still needs to exercise, with watchdogs and exact OS
version recorded:

- immediate and pending APC completion paths, including buffer lifetime;
- `Batch.cancel` racing success and cancellation on asynchronous handles;
- each expected NTSTATUS-to-Zig error path that matters to the application;
- custom IOCP immediate-success policy both with and without skip-on-success;
- `CancelIoEx` races, shutdown draining, completion backlog bounds, and handle
  closure only after every terminal packet is reconciled.

This page remains `source-verified`, not broadly `runtime-verified`: one host
proves the narrow mapping and synchronous cancellation harness, not the APC,
device, custom-IOCP, or load matrix. The shipped Threaded backend is the
production default; the custom IOCP design is a platform-backend research
target.

Related: [[std-io]], [[io-threaded]], [[select-and-batch]],
[[tigerbeetle-io]], [[evented-io-backends]], [[cancellation]],
[[invariants-and-assertions]], [[static-allocation-and-constant-work]].
