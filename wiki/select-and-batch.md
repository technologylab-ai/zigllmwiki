---
id: select-and-batch
title: std.Io Select and Batch ownership
kind: pattern
status: source-verified
zig: "0.16.0"
summary: Select owns typed tasks and their result queue, while Batch owns a fixed set of low-level operation slots; both require explicit draining and terminal cancellation paths.
updated: 2026-09-04
sources:
  - "[[zig-0.16.0-release-notes]]"
  - "[[zig-0.16.0-stdlib]]"
  - "[[zig-0.16-windows-io-source]]"
proofs:
  - proofs/select_and_batch.zig
platforms:
  - macos
  - windows
---

# `std.Io.Select` and `std.Io.Batch` ownership

## Remember

Use `std.Io.Select(U)` to wait for typed task results. Use `std.Io.Batch` to
submit low-level `std.Io.Operation` values from fixed caller-provided storage.
They solve related but different problems and expose different cleanup traps.

| Property | `Select(U)` | `Batch` |
| --- | --- | --- |
| Level | Functions/tasks | Low-level `Io.Operation` values |
| Result identity | Tagged-union field | Stable caller-chosen storage index plus result-union tag |
| Capacity | Caller-provided result queue | Caller-provided `Operation.Storage` slots |
| Progress choice | `async` or `concurrent` per task | `awaitAsync` or `awaitConcurrent` per wait |
| Terminal cleanup | `cancel` and drain, or `cancelDiscard` when safe | `cancel`, then inspect raced successful completions with `next` |

Neither abstraction makes capacity or resource ownership disappear. Size the
buffers from the maximum outstanding work and define who consumes every result.

## `Select(U)`: typed task completion

`U` is a tagged union whose fields correspond to task result types. Scheduling
a function with a field stores that function's return value in the matching
union field. The select owns the spawned task resource; after every successful
schedule, its owner must eventually await results or cancel the select.

The scheduling distinction is the same as elsewhere in [[std-io]]:

- `select.async` may call and finish the function before returning;
- `select.concurrent` guarantees an independent concurrency unit or returns
  `error.ConcurrencyUnavailable`.

`await` returns one completion. `awaitMany` copies at least the requested
minimum into a caller buffer and asserts that the buffer is large enough. It is
legal to schedule more tasks after either await operation, which makes a select
useful as a bounded rolling task set rather than only a one-shot race.

### The cancellation-buffer trap

`cancel` requests cancellation and waits for all remaining tasks before it
closes/drains the result queue. If the select's internal result buffer cannot
hold all results that may arrive while cancellation waits, the terminal path
can deadlock. The robust TigerStyle default is to size the buffer for the
maximum simultaneously outstanding tasks and assert admission against that
same limit.

`cancel` returns one queued `?U` per call. Loop until it returns `null` when a
result can own memory, a descriptor, or another cleanup obligation. Calling it
once is not a complete drain.

`cancelDiscard` closes the result queue and discards outstanding return values.
It avoids the drain API, but is incorrect when a task can return ownership: the
discarded value no longer has a caller that can release it. Use it only when
every result is ownership-free or cleanup is otherwise guaranteed.

Once cancellation begins, do not call `await` or `awaitMany` again. Both
`cancel` and `cancelDiscard` are safe to repeat according to the interface.

## `Batch`: fixed low-level operation slots

`Batch.init` takes a preallocated slice of `Operation.Storage`. That slice is
the exact maximum number of active operations; Zig 0.16's initializer requires
at least one slot. After initialization it is safe to install an unconditional
`defer batch.cancel(io)` terminal guard.

`add` consumes the first unused slot and returns its index. `addAt` consumes a
specific unused slot, allowing a component to bind operation identity to its
own stable slot. Exceeding the storage capacity or reusing an active index is a
programmer error asserted by the implementation, not a recoverable overflow
queue. Apply admission control before either call.

Both wait functions stop after at least one operation completes:

- `awaitAsync` permits implementation-provided concurrency but does not require
  it and therefore does not fail with `ConcurrencyUnavailable`;
- `awaitConcurrent` requires concurrent operation progress and accepts a
  timeout; its error set includes concurrency unavailable, cancellation, and
  timeout errors.

Call `next` to dequeue completions. Its `index` identifies the storage slot and
its tagged result matches the original operation. Dequeuing returns that slot
to the unused list, so it can be rearmed with `addAt`. Completion order is not
submission order, and it is legal—but often harder to reason about—to await
again before draining every already completed result.

## Batch cancellation

`batch.cancel(io)` removes operations that have not been submitted, requests
interruption of pending operations, and waits until the batch reaches a
well-defined terminal state. Successfully canceled operations are absent from
subsequent iteration. Operations that won the cancellation race still appear
through `next` and their results still require handling.

This means the terminal protocol is:

`stop admission → cancel/wait → drain raced completions → release result resources → reuse storage`

The batch owns operation machinery, not every resource referenced by an
operation. Files, sockets, buffers, and result-owned values remain the
application owner's responsibility according to their individual contracts.

The exact Windows 0.16.0 Threaded implementation has a pending-batch progress
defect: it performs an unbounded alertable wait before sending cancellation
requests. The platform analysis and bounded witness belong in
[[windows-iocp-and-overlapped-io]]. The terminal ownership contract above does
not itself guarantee a shutdown time bound on that implementation.

## Evidence

The [Select/Batch proof](../proofs/select_and_batch.zig) runs two Zig 0.16
tests. The select test puts owned allocations in task results, consumes one
through `await`, then loops over `cancel` until all remaining ownership is
released. The batch test supplies exactly two fixed operation slots, reads two
separate files, accepts arbitrary completion order, dispatches results by tag,
and verifies slot indexes/data. It ran with `std.testing.io` on aarch64 macOS on
2026-09-04.

## Review checklist

- Is capacity derived from the maximum outstanding tasks or operations?
- Can any result carry ownership, and which path drains/releases it?
- Can eager `async` execution alter the intended race or deadline?
- Does correctness require the explicit failure-bearing concurrent variant?
- Is completion identity independent of completion order?
- Does shutdown stop admission before cancellation and reconcile raced success?
- Can every slot be shown to move exactly once back to unused state?

Related: [[async-vs-concurrent]], [[cancellation]],
[[task-lifetimes-and-structured-concurrency]],
[[static-allocation-and-constant-work]], [[io-uring]],
[[windows-iocp-and-overlapped-io]].
