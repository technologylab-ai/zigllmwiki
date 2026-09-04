---
id: cancellation
title: Cancellation, shutdown, and crash recovery
kind: concept
status: source-verified
zig: "0.16.0"
summary: Cancellation of in-flight work is a request-and-acknowledgement protocol whose resource lifetime must not be confused with error unwinding, graceful shutdown, or crash recovery.
updated: 2026-09-04
sources:
  - "[[zig-0.16.0-stdlib]]"
  - "[[matklad-cancelation-terminology]]"
  - "[[matklad-neat-io-threaded]]"
  - "[[matklad-zig-error-context]]"
  - "[[matklad-zig-language-server-cancellation]]"
  - "[[liburing-interface-and-cancellation]]"
  - "[[apple-xnu-kqueue-aio]]"
  - "[[microsoft-windows-iocp]]"
  - "[[microsoft-windows-iocp-api]]"
  - "[[zig-0.16-windows-io-source]]"
proofs:
  - proofs/cancellation.zig
  - proofs/threaded_blocked_read_cancel_macos.zig
  - proofs/threaded_blocked_read_cancel_linux.zig
  - proofs/threaded_blocked_read_cancel_windows.zig
  - proofs/windows_apc_batch.zig
  - proofs/windows_iocp_lifecycle.zig
platforms:
  - cross-platform
---

# Cancellation, shutdown, and crash recovery

## Remember

For concurrent work, cancellation is not “drop the handle and forget the task.”
It is a protocol: request cancellation, keep every borrowed resource alive, wait
for the task or kernel operation to acknowledge completion, then release it.

Use distinct words for distinct layers:

| Mechanism | Finished when initiated? | Primary job |
| --- | --- | --- |
| Error unwinding | Synchronous control flow. | Leave scopes and run cleanup. |
| In-flight cancellation | Not until acknowledgement/join. | Stop concurrent work without invalidating its resources. |
| Graceful shutdown | Application policy. | Stop admission and drain or bound existing work. |
| Crash recovery | No cleanup is assumed. | Recover durable state after arbitrary termination or power loss. |

Matklad calls the first two “synchronous cancelation” and “asynchronous
cancelation.” The important part is the semantic distinction, not the spelling.

## Zig 0.16 `std.Io` contract

`Future.cancel` is equivalent to awaiting while also placing a cancellation
request. A task observes `error.Canceled` at a cancellation point: an `Io`
operation whose error set contains it. The request normally signals only the
next cancellation point. Ignoring that result is usually a bug because later
points are not automatically signaled again.

Use `io.recancel()` only after observing `error.Canceled` when a layer must
finish a partial result or cleanup and then re-arm propagation. Use
`swapCancelProtection(.blocked)` narrowly around a region that must not observe
cancellation; restore the prior state with `defer`. Long CPU-bound work with no
other cancellation point can cooperate through `io.checkCancel()`.

`Group.await` propagates a request to members and waits for the group to finish.
`Group.cancel` requests cancellation immediately and also completes the group's
resource lifecycle. A group task returning `error.Canceled` is a propagation
boundary rather than an application failure.

## `Io.Threaded` blocked-syscall interruption

The portable contract is cancellation request and acknowledgement; the means
of interrupting a blocking syscall belongs to the concrete implementation. On
Linux and other supported POSIX targets, Zig 0.16 `Io.Threaded` installs a
do-nothing `SIGIO` handler without restart semantics. A canceler marks the
worker as blocked-and-canceling, sends `SIGIO` to that specific thread, and
retries with exponential backoff if the signal races syscall entry. When the
syscall returns `EINTR`, the wrapper checks and acknowledges cancellation.

This has a process-wide integration seam: `Io.Threaded.init` replaces the
existing `SIGIO` and `SIGPIPE` actions where those signals are available, saves
them, and `deinit` restores them after joining its workers. Applications with
their own signal policy must account for that implementation behavior rather
than assuming cancellation is isolated inside a worker pool.

## Ownership rule

The owner of a future, group, buffer, or operation record must have exactly one
terminal path: successful await, failed await, or acknowledged cancellation.
The memory cannot be recycled merely because cancellation was requested. This
is especially visible with `io_uring`, where the kernel may still hold a buffer
until a completion establishes that the operation is over.

For `io_uring`, cancellation itself is an operation. Its completion and the
target operation's completion can arrive in either order; only reconciling the
target completion closes the resource lifetime. See [[io-uring]].

Apple POSIX AIO and Windows overlapped I/O preserve the same ownership rule
through different APIs. `aio_cancel` can report all done, canceled, or not
canceled; final status still requires `aio_error`/`aio_return`. `CancelIoEx`
does not wait, and the target may still succeed, be canceled, or fail for
another reason; its `OVERLAPPED` and buffer remain live until that outcome is
observed. See [[macos-kqueue-and-aio]] and
[[windows-iocp-and-overlapped-io]].

Keep asynchronous cancellation low in the stack. If only the device/grid layer
has outstanding operations, cancel and join that layer, then reset upper state
machines synchronously. Making every intermediate API asynchronous multiplies
states and cleanup paths without adding a guarantee.

## Reporting rule

`error.Canceled` is expected control flow in many I/O paths. Low-level
`errdefer` logging will fire before an outer owner gets the chance to handle it,
creating false error diagnostics. Accumulate context separately and decide at
the ownership boundary whether the final result is reportable; see
[[error-context]].

## Review questions

- What event requests cancellation, and which task acknowledges it?
- Which buffers and operation records remain borrowed until acknowledgement?
- Where is cancellation propagation intentionally stopped or re-armed?
- Can a blocked syscall be interrupted by the concrete I/O implementation?
- Does shutdown stop new admissions before draining, canceling, or timing out?
- Can durable state recover if cleanup never runs?

Related: [[io-threaded]], [[async-vs-concurrent]],
[[static-allocation-and-constant-work]], [[deterministic-simulation-testing]],
[[io-uring]], [[macos-kqueue-and-aio]],
[[windows-iocp-and-overlapped-io]].
Also see [[task-lifetimes-and-structured-concurrency]].
For result-buffer sizing and terminal draining in task/operation aggregators,
see [[select-and-batch]].
For cancelable versus uncancelable waits and lock reacquisition, see
[[io-synchronization-primitives]].

## Runtime evidence

The [cancellation proof](../proofs/cancellation.zig) ran on aarch64 macOS with
Zig 0.16.0 on 2026-09-04. It verifies `Future.cancel`, `Group.cancel`,
`recancel`, protection, and owner-visible completion using `std.Io.Threaded`.
The [blocked-read proof](../proofs/threaded_blocked_read_cancel_macos.zig)
verifies that cancellation interrupts a worker blocked in a macOS pipe read; a
watchdog turns failure to interrupt into a finite test failure. The
[Linux blocked-read proof](../proofs/threaded_blocked_read_cancel_linux.zig)
ran on x86_64 Omarchy 4.0.2 with Linux `7.1.9-arch1-2` and Zig 0.16.0 on
2026-09-04; it verifies that the `SIGIO` path interrupts and joins the blocked
pipe read before the watchdog releases it. The
[Windows blocked-read harness](../proofs/threaded_blocked_read_cancel_windows.zig)
constructs a synchronous NT named pipe through the exact Threaded
implementation and compiles for x86, x86_64, and aarch64 Windows. It ran with
Zig 0.16.0 on x86_64 Windows Server 2025 Datacenter 24H2, build 26100.33296, on
2026-09-04 and proved that `NtCancelSynchronousIoFile` interrupts and joins the
blocked pipe read before the watchdog releases it. The exact environment and
logs are retained by [Actions run 33911991858](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33911991858).

The later Windows [APC/batch proof](../proofs/windows_apc_batch.zig) and
[custom IOCP proof](../proofs/windows_iocp_lifecycle.zig) passed on that Windows
build in [run 33915530939](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33915530939).
They add NPFS task/batch/device-control cancellation, result-race draining,
both IOCP notification policies, and shutdown from four pending reads. The
batch proof requires an explicit NT alert to release Zig 0.16.0's initial
pre-cancellation wait; it does not prove unassisted progress. See
[[windows-iocp-and-overlapped-io]] for exact limits, host metadata, and the
distinction between observed task entry and kernel submission.
