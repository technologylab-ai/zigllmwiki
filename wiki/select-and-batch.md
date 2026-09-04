---
id: select-and-batch
title: std.Io Select and Batch ownership
kind: pattern
status: source-verified
zig: "0.16.0"
summary: Select owns typed task results, while fixed Batch slots still require backend allocation budgeting, cleanup after wait errors, and completion draining.
updated: 2026-09-04
sources:
  - "[[zig-0.16.0-release-notes]]"
  - "[[zig-0.16.0-stdlib]]"
  - "[[zig-0.16-windows-io-source]]"
proofs:
  - proofs/select_and_batch.zig
  - proofs/windows_apc_batch.zig
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
For `Select`, count accepted tasks until their results are consumed, including
finished tasks whose results remain queued; result-buffer size does not itself
enforce a task-admission limit.

## `Select(U)`: typed task completion

`U` is a tagged union whose fields correspond to task result types. Scheduling
a function with a field stores that function's return value in the matching
union field. The select owns the spawned task resource; after every successful
schedule, its owner must eventually await results or cancel the select.

The scheduling distinction is the same as elsewhere in [[std-io]]:

- `select.async` may call and finish the function before returning;
- `select.concurrent` guarantees an independent concurrency unit or returns
  `error.ConcurrencyUnavailable`.

`await` returns one completion. `awaitMany` delegates to `Queue.get`: it normally
copies at least the requested minimum, but cancellation after partial delivery
can return a smaller count. Only that returned prefix contains results for the
caller to handle. Account for every owned result in it before propagating
cancellation. The buffer must be large enough for the requested minimum.

With a zero minimum, `awaitMany` does not wait for more results, but its queue
mutex can still contend. The partial-result and cancellation-check caveats are
documented once in [[io-synchronization-primitives]]. It is legal to schedule
more tasks after either await operation, which makes a select useful as a
bounded rolling task set rather than only a one-shot race.

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
at least one slot and fewer than `maxInt(u32)` slots: initialization temporarily
converts `index + 1` to an index whose maximum value is reserved for `.none`.
Choose a much smaller application limit and assert it before allocation. After
initialization it is safe to install an unconditional `defer batch.cancel(io)`
terminal guard.

Fixed operation slots do not guarantee allocation-free waits. The exact
Threaded poll implementation can allocate additional descriptor storage during
`awaitConcurrent`; see [[io-threaded]] for its threshold and cleanup lifetime.

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

### A wait error does not release operation ownership

An error from `awaitConcurrent` describes the wait or scheduling attempt, not
the terminal outcome of every operation. In particular, Windows Threaded can
return `error.Timeout` while its pending list is still nonempty. Keep the batch
storage, referenced buffers, and handles alive; if abandoning the batch, use
the cancellation-and-drain protocol below before releasing them. A deadline
on the wait does not also bound cancellation or cleanup.

This follows from `Io.Batch.awaitConcurrent` and Threaded's
`batchAwaitConcurrent` in [[zig-0.16.0-stdlib]] and
[[zig-0.16-windows-io-source]]. The existing Windows timeout/cancel witness
uses an explicit alert to release the initial cancellation wait; it does not
prove unassisted shutdown progress.

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
counts completions, and verifies byte counts and data. It arms indexes 0 and 1
but does not assert the returned `completion.index` values; that mapping is
supported here by the `Batch.addAt`/`next` source contract. It ran with
`std.testing.io` on aarch64 macOS on 2026-09-04.

The select test uses `await`, not `awaitMany`; the latter's partial-delivery
and mutex-contention boundaries are supported by the exact `Select.awaitMany`
and `Queue.get` source, not exercised by this proof.

The Windows-specific [APC/batch proof](../proofs/windows_apc_batch.zig) ran with
Zig 0.16.0 on x86_64 Windows Server 2025 build 26100.33296 on 2026-09-04.
It preserves completed results, reconciles 32 cancellation/write races, and
observes the initial-wait defect before an explicit NT alert releases it.
The exact environment and scope are in [[windows-iocp-and-overlapped-io]].
This page is now `source-verified`: the added Windows progress analysis must
not inherit the earlier macOS-only runtime label as a portable guarantee.

## Review checklist

- Is capacity derived from the maximum outstanding tasks or operations?
- Does the allocation budget include backend scratch storage during waits?
- Can any result carry ownership, and which path drains/releases it?
- Can eager `async` execution alter the intended race or deadline?
- Does correctness require the explicit failure-bearing concurrent variant?
- Is completion identity independent of completion order?
- Does shutdown stop admission before cancellation and reconcile raced success?
- Does a wait error retain ownership until terminal cleanup completes?
- Can every slot be shown to move exactly once back to unused state?

Related: [[async-vs-concurrent]], [[io-threaded]], [[cancellation]],
[[task-lifetimes-and-structured-concurrency]],
[[static-allocation-and-constant-work]], [[io-uring]],
[[windows-iocp-and-overlapped-io]].
