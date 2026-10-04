---
id: io-threaded
title: std.Io.Threaded implementation guide
kind: concept
status: source-verified
zig: "0.17.0"
summary: Zig 0.17 Threaded shares task capacity, allocates before admission checks, and retains backend-specific cancellation limits.
updated: 2026-10-04
sources:
  - "[[zig-0.17.0-stdlib]]"
  - "[[zig-0.16.0-release-notes]]"
  - "[[zig-0.16.0-stdlib]]"
  - "[[matklad-neat-io-threaded]]"
proofs:
  - proofs/async_vs_concurrent.zig
  - proofs/cancellation.zig
  - proofs/threaded_blocked_read_cancel_macos.zig
platforms:
  - macos
  - linux
  - windows
---

# `std.Io.Threaded` implementation guide

## Remember

Zig 0.17.0 uses `std.Io.Threaded` in the default `main` runtime.
`lib/std/start.zig` constructs that implementation. [[zig-0.17.0-stdlib]]
It provides the `std.Io` interface with
blocking OS operations plus task threads. It is not an event loop disguised by
the word `async`.

Separate portable interface claims in [[std-io]] from the implementation facts
on this page.

## Task dispatch and allocation

The following dispatch details come from the exact multithreaded Zig 0.17.0 source.
[[zig-0.17.0-stdlib]]
Admission means assigning a task to the worker pool.

When CPU discovery succeeds, the default `async_limit` equals the logical CPU count minus one.
If discovery fails, the default is `.nothing`, which permits no async task admission.
`concurrent_limit` defaults to unlimited.
`async` executes the function in the caller when admission, allocation, or thread creation fails.
`concurrent` returns `error.ConcurrencyUnavailable` when the implementation cannot supply the required concurrency.
[[async-vs-concurrent]] explains the interface guarantees and the sleeping-timeout trap.

### Shared dispatch capacity

`Threaded` uses one `busy_count` for `async`, `concurrent`, `Group.async`, and `Group.concurrent`.
Async dispatch compares this shared count with `async_limit`.
Concurrent dispatch compares the same count with `concurrent_limit`.
Successful admission increases the count before queue insertion.
The worker decreases the count after the task returns.

The limits therefore do not reserve separate capacity for the two task kinds.
Async tasks can exhaust the capacity checked by concurrent dispatch, and concurrent tasks can force async fallback.
Each path checks its limit before checking for an idle worker.
Spare pooled threads therefore do not override either limit.
Setting only `async_limit` does not bound concurrent dispatch.
Choose both limits within one application budget, and handle `ConcurrencyUnavailable` after any earlier successful submission.

`setAsyncLimit` changes the limit for later admission checks.
The setter does not cancel existing tasks or remove worker threads.
These conclusions follow from `async`, `concurrent`, `groupAsync`, `groupConcurrent`, `worker`, and `setAsyncLimit` in [[zig-0.17.0-stdlib]].

### Allocation before admission

All four multithreaded dispatch paths attempt task record allocation before checking the limit.
Individual dispatch uses `Future.create`; group dispatch uses `Group.Task.create`.
A zero limit therefore does not remove these allocation attempts.
After limit rejection, async dispatch frees the temporary record before running the task inline.
Concurrent dispatch frees the temporary record before returning `error.ConcurrencyUnavailable`.
The compile-time `builtin.single_threaded` branches bypass these allocation paths. [[zig-0.17.0-stdlib]]

[[static-allocation-and-constant-work]] explains why prewarming threads or bounding allocator storage does not establish allocation-free dispatch.

The allocator passed to `Threaded.init` must be thread-safe. The implementation
uses it for task dispatch and some operation paths. Avoiding task dispatch
alone does not establish that a failing allocator is sufficient; inspect the
operations and their capacity thresholds too.

For [[select-and-batch|Batch]], the exact 0.17.0 poll-based
`batchAwaitConcurrent` path has a 64-entry stack `pollfd` buffer. At the 65th
poll descriptor it uses a slice sized to the batch's entire operation-storage
capacity, allocating it with the Threaded allocator if no slice is retained
from an earlier wait. Allocation failure returns
`error.ConcurrencyUnavailable`. The spill allocation is retained in
`Batch.userdata` until `batchCancel` frees it, even if all completion results
have been drained. Caller-provided operation slots therefore bound admission
without guaranteeing allocation-free waits. This is source evidence from
`poll_buffer_len`, `batchAwaitConcurrent`, and `batchCancel` in
[[zig-0.17.0-stdlib]], not a portable `std.Io` allocation contract or a Windows
implementation rule.

## Zig 0.17 source review

The review inspected `lib/std/Io/Threaded.zig` at the exact release commit.
The dispatch functions retain the shared admission count and allocation order described above.
`batchAwaitConcurrent` retains the 64-descriptor stack buffer and allocator-backed overflow storage.
Windows concurrent batches reject all four network operation tags.
Windows `batchCancel` still waits for an APC or alert before requesting cancellation.
See [[windows-iocp-and-overlapped-io]] for those source limits.
The dated runtime receipts below used Zig 0.16.0.
The 0.17 source review does not renew those receipts. [[zig-0.17.0-stdlib]]

## Cancellation of blocking calls

On supported POSIX pthread targets, the implementation coordinates cancellation
through shared task state and `SIGIO`. A signal can arrive before or after the
target syscall, so it is not sufficient by itself. The canceling side marks the
request and may send repeated signals with backoff while the worker remains
blocked; the interrupted side distinguishes cancellation from unrelated
`EINTR`, acknowledges the request, or retries.

On Windows, the blocked synchronous-I/O path uses
`NtCancelSynchronousIoFile`; alertable waits have a separate wake-up path. This
is an implementation detail, not permission to assume that every arbitrary OS
call made inside a task is cancellable.

The public result remains the portable `error.Canceled` protocol described in
[[cancellation]].

## Design consequences

- Threads make blocking file I/O portable, but one blocked operation can occupy
  a worker and a stack.
- `async` is appropriate only when eager execution is semantically acceptable.
- `concurrent` is appropriate when caller progress is required and the caller
  can handle scheduling failure.
- A strict startup-allocation design cannot assume this backend is compliant:
  scheduling may allocate a task and permanently add a thread to the pool.
- Thread counts, stack sizes, descriptor limits, buffers, and cancellation
  latency belong in the same capacity model.

The historical Zig 0.16 [dispatch proof](../proofs/async_vs_concurrent.zig) covers inline execution and explicit failure with zero limits.
The proof does not test mixed dispatch, idle-worker admission, limit changes, or allocator-call counts.
Those details remain source evidence; this review adds no runtime evidence.
The historical Zig 0.16 [cancellation proof](../proofs/cancellation.zig) covers task
cancellation points and ownership on aarch64 macOS. The
[blocked-read proof](../proofs/threaded_blocked_read_cancel_macos.zig) verifies
actual syscall interruption for a macOS pipe. The corresponding
[Linux](../proofs/threaded_blocked_read_cancel_linux.zig) and
[Windows](../proofs/threaded_blocked_read_cancel_windows.zig) pipe proofs also
ran with Zig 0.16.0; exact environments are retained in
[[cancellation]] and [the platform runbook](../docs/platform-testing.md).
Those fixtures do not establish cancellation for arbitrary devices or calls.

Related: [[async-vs-concurrent]], [[cancellation]],
[[select-and-batch]], [[windows-iocp-and-overlapped-io]],
[[task-lifetimes-and-structured-concurrency]],
[[static-allocation-and-constant-work]], [[evented-io-backends]].
