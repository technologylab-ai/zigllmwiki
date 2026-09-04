---
id: task-lifetimes-and-structured-concurrency
title: Task lifetimes and structured concurrency
kind: pattern
status: source-verified
zig: "0.16.0"
summary: Bind every task, operation, snapshot, and child process to an owner whose scope cannot finish before its dependents have completed or acknowledged cancellation.
updated: 2026-09-04
sources:
  - "[[zig-0.16.0-stdlib]]"
  - "[[matklad-cancelation-terminology]]"
  - "[[matklad-unix-structured-concurrency]]"
  - "[[matklad-zig-language-server-cancellation]]"
  - "[[matklad-on-async-mutexes]]"
  - "[[tigerbeetle-architecture]]"
proofs:
  - proofs/cancellation.zig
platforms:
  - cross-platform
---

# Task lifetimes and structured concurrency

## Remember

Concurrent work must not outlive the state and resources it can access. Give
every task a lexical or component owner, require that owner to await successful
completion or acknowledged cancellation, and make it impossible for a borrowed
buffer or mutable state generation to be reused first.

Structured concurrency is an ownership rule, not a promise made by `async`
syntax. [[async-vs-concurrent|`std.Io.async`]] may execute eagerly, and an
operating-system process can survive the parent scope whose `defer` intended to
kill it.

## `Future` and `Group` in Zig 0.16

A `Future` owns one result and a possible implementation resource. End its
lifecycle exactly once with `await` or `cancel`; both operations are idempotent
but not thread-safe. `cancel` requests cancellation and, like `await`, does not
return until the result is available.

A `Group` owns an unordered set of tasks. Once a task is added, eventually call
`Group.await` or `Group.cancel`. Resources for a member are released when that
member returns, rather than being retained until the whole group is collected.
However, an async group member is not guaranteed to run until the group is
awaited or canceled, so abandoning the group can still abandon resources and
work.

Use a group when the tasks share one cancellation and join scope. Use separate
futures when individual results or cancellation decisions have distinct owners.
Neither replaces capacity limits on the task records or their downstream I/O.

The [cancellation proof](../proofs/cancellation.zig) exercises `Future` and
`Group` terminal paths on `std.Io.Threaded` with Zig 0.16.0.

## Mutable state: three valid shapes

When new input makes in-flight computation stale, choose the consistency model
before choosing primitives:

1. **Finish sequentially.** Simple and strongly ordered, but stale reads can
   delay newer writes.
2. **Publish immutable generations.** New work reads a new snapshot while old
   work safely finishes against the old one. This costs bounded extra memory
   and possibly wasted computation.
3. **Cancel, join, then mutate.** Reuse one mutable state only after every old
   reader acknowledges cancellation. The join—not the request—is what makes
   mutation safe.

A bounded `ready`/`working`/`pending` model can combine fast current syntax,
deep but older semantic state, and one background generation. It avoids
unbounded snapshot accumulation, but the API must say which queries may be stale
and which operations require a fully current barrier.

## Actor/state-machine versus task-oriented concurrency

An actor-style event loop can keep many I/O operations in flight while applying
their completions to shared state one callback at a time. The dispatcher is the
mutual-exclusion boundary. This can remove per-component mutexes and make every
mutation a named, asserted state transition.

That guarantee is fragile if callbacks can block, suspend, re-enter the
dispatcher, or run on multiple threads. “Single-threaded” prevents simultaneous
memory access; it does not prevent stale-event and invalid-state logic bugs.
Callbacks should identify the operation generation, assert expected state, make
a bounded transition, and return promptly.

Task-oriented/CSP designs instead give mostly independent tasks their own
control flow and synchronize the smaller amount of shared state explicitly.
Choose the architecture from the shape of ownership, not from a general rule
that async mutexes are always necessary or never necessary.

## Child-process boundary

A normal `defer` can kill and join a child during ordinary unwinding, but it
cannot run after abrupt parent termination. Having a controlled child watch a
dedicated pipe or stdin for EOF is a useful cooperative fallback for integration
tests, not true structured ownership: stdin may be `/dev/null`, an unrelated
process may retain the pipe, and the parent does not wait for descendant exit.

Linux, macOS, and Windows have different stronger lifetime facilities. This
wiki will recommend them only after primary OS evidence and Zig 0.16 proofs are
added to the platform matrix.

## Review questions

- Which component owns each task, result, buffer, and state generation?
- Which exact terminal path awaits or cancels it on every branch?
- What capacity bounds the number of live dependents?
- Can cancellation race with successful completion or a newer generation?
- Does a supposedly serialized callback ever suspend or re-enter?
- What happens to child processes after `SIGKILL`, crash, or power loss?

Related: [[cancellation]], [[select-and-batch]], [[io-threaded]], [[io-uring]],
[[static-allocation-and-constant-work]], [[deterministic-simulation-testing]].
