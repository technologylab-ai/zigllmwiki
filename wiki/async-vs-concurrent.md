---
id: async-vs-concurrent
title: std.Io async versus concurrent
kind: pattern
status: runtime-verified
zig: "0.16.0"
summary: async may execute work inline, while concurrent requires independent caller progress or returns ConcurrencyUnavailable.
updated: 2026-09-04
sources:
  - "[[zig-0.16.0-stdlib]]"
  - "[[zig-0.16.0-release-notes]]"
  - "[[hermit-io-timeout-proof]]"
  - "[[matklad-neat-io-threaded]]"
proofs:
  - proofs/async_vs_concurrent.zig
platforms:
  - macos
  - linux
---

# `std.Io` `async` versus `concurrent`

## Remember

`async` is permission to defer work, not a promise that the caller can progress
independently. The function may run and finish before `async` returns.
`concurrent` makes the stronger promise: the caller can continue while the task
waits on I/O, or scheduling fails explicitly with
`error.ConcurrencyUnavailable`.

That distinction belongs to the `std.Io` interface. The resource cliff below is
specific to [[std-io|`std.Io.Threaded`]].

## What `std.Io.Threaded` does

Its `async_limit` defaults to one less than the detected logical CPU count.
When all units are busy and the limit has been reached, `async` executes the
function immediately in the calling task. Allocation or thread-creation failure
can take the same eager fallback path.

Its `concurrent_limit` defaults to unlimited. `concurrent` may grow the thread
pool; if it cannot allocate a future, create a thread, support concurrency, or
stay within a configured limit, it returns `error.ConcurrencyUnavailable`
instead of executing the task inline.

## The sleeping-timeout trap

Racing work against a sleep with `async` can make the call that schedules the
sleep perform the entire sleep inline when the runtime is saturated. The
program has not reached `await`; the would-be timeout has blocked its caller.

Making only the timeout branch `concurrent` is not sufficient. The work branch
can then become the inline task, finish before selection begins, and defeat the
deadline. If correctness requires two branches to progress independently,
request `concurrent` for both and handle scheduling failure.

An event deadline can avoid consuming a second task for a sleeping timer, but it
does not repair an `async` work task that itself must progress concurrently.
Choose the ownership shape and the scheduling guarantee independently.

## Evidence

- [Local deterministic proof](../proofs/async_vs_concurrent.zig) configures
  zero async capacity and proves eager execution; it configures zero concurrent
  capacity and proves explicit failure. It ran on aarch64 macOS with Zig 0.16.0
  on 2026-09-04.
- [[hermit-io-timeout-proof]] records saturated Pi Zero 2 W measurements on
  aarch64 Linux with Zig 0.16.0. The naive async sleep race exceeded its intended
  deadline, while paired concurrent variants held it.

## Review questions

- Does correctness require the caller to progress before this task completes?
- What is the concrete `std.Io` implementation?
- Which limit applies, and how is `ConcurrencyUnavailable` handled?
- Who awaits or cancels the task on every return path?
- Does a timer consume another scheduling unit unnecessarily?

Related: [[std-io]], [[io-threaded]], [[cancellation]],
[[select-and-batch]], [[evented-io-backends]], [[tigerstyle]].
