---
id: io-threaded
title: std.Io.Threaded implementation guide
kind: concept
status: source-verified
zig: "0.16.0"
summary: Zig 0.16's default I/O implementation combines blocking OS calls, pooled task threads, explicit dispatch limits, and cooperative cancellation of blocked calls.
updated: 2026-09-04
sources:
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

In Zig 0.16.0, `std.Io.Threaded` is the feature-complete, tested implementation
used by the default `main` runtime. It provides the `std.Io` interface with
blocking OS operations plus task threads. It is not an event loop disguised by
the word `async`.

Separate portable interface claims in [[std-io]] from the implementation facts
on this page.

## Task dispatch and allocation

`async_limit` defaults to one fewer than the detected logical CPU count. When
all permitted workers are busy, or allocation/thread creation fails, `async`
destroys any temporary task record and executes the function in the caller.

`concurrent_limit` defaults to unlimited. `concurrent` allocates a future and
grows the pool when necessary; lack of allocator capacity, thread creation,
implementation support, or configured capacity becomes
`error.ConcurrencyUnavailable`. It does not silently run the task inline.

The allocator passed to `Threaded.init` must be thread-safe. The implementation
uses it for task dispatch and some operation paths. Avoiding task dispatch
alone does not establish that a failing allocator is sufficient; inspect the
operations and their capacity thresholds too.

For [[select-and-batch|Batch]], the exact 0.16.0 poll-based
`batchAwaitConcurrent` path has a 64-entry stack `pollfd` buffer. At the 65th
poll descriptor it uses a slice sized to the batch's entire operation-storage
capacity, allocating it with the Threaded allocator if no slice is retained
from an earlier wait. Allocation failure returns
`error.ConcurrencyUnavailable`. The spill allocation is retained in
`Batch.userdata` until `batchCancel` frees it, even if all completion results
have been drained. Caller-provided operation slots therefore bound admission
without guaranteeing allocation-free waits. This is source evidence from
`poll_buffer_len`, `batchAwaitConcurrent`, and `batchCancel` in
[[zig-0.16.0-stdlib]], not a portable `std.Io` allocation contract or a Windows
implementation rule.

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

The [dispatch proof](../proofs/async_vs_concurrent.zig) covers the eager/failure
distinction. The [cancellation proof](../proofs/cancellation.zig) covers task
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
