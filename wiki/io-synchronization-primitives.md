---
id: io-synchronization-primitives
title: std.Io synchronization primitives
kind: concept
status: source-verified
zig: "0.16.0"
summary: Choose synchronization by state and ownership; Queue minimums do not remove mutex contention, partial-transfer accounting, or the need to join blocked participants.
updated: 2026-09-04
sources:
  - "[[zig-0.16.0-release-notes]]"
  - "[[zig-0.16.0-stdlib]]"
proofs:
  - proofs/io_sync_primitives.zig
platforms:
  - macos
  - linux
  - windows
---

# `std.Io` synchronization primitives

## Remember

Zig 0.16's synchronization waits accept the caller's `std.Io`. A wait may
suspend a task, block an implementation worker, observe cancellation, or wake
spuriously according to the primitive and concrete backend. Do not reason about
them as thin aliases for one operating-system thread API.

Choose the primitive from the state transition being represented:

| Need | Primitive | Central obligation |
| --- | --- | --- |
| Persistent one-bit readiness/latch | `Event` | Do not reset while waiters are pending. |
| Bounded many-producer/many-consumer handoff | `Queue(T)` | Bound both buffered elements and blocked participants; close and drain. |
| Exclusive critical section | `Mutex` | Unlock exactly once after successful acquisition. |
| One writer or many readers | `RwLock` | Match exclusive/shared unlock and avoid assuming undocumented fairness. |
| Wait for a predicate protected by a mutex | `Condition` | Recheck the predicate in a loop after reacquisition. |
| Counted permits/admission | `Semaphore` | Keep permit creation and consumption balanced and bounded. |
| Low-level wait on a 32-bit atomic word | `futexWait`/`futexWake` | Use an atomic predicate loop and tolerate spurious/lost-race wakeups. |

The cancelable wait/lock forms are cancellation points. Their
`Uncancelable` counterparts exist for narrow cleanup and invariant-preserving
regions, but can make shutdown wait forever if the required wakeup never comes.

## `Event`: a manual-reset latch

An `Event` is `unset`, `waiting`, or `is_set`. `set(io)` publishes the set state,
wakes all pending waiters, and stays set until `reset()`. Later waits return
without blocking. The acquire/release contract makes writes before `set`
visible to a waiter that observes completion.

`reset` assumes there is no pending `wait` or `waitUncancelable`. Join or
otherwise prove all waiters have returned before resetting. Concurrent
`isSet`, `set`, and `reset` calls are allowed, but this does not relax the
pending-wait precondition.

`waitTimeout` can return `error.Timeout` both when the deadline expires and
when a spurious wake occurs while the event is still unset. Treat it as “not
observed set,” not as precise proof that the clock deadline elapsed.

## `Queue(T)`: bounded handoff and shutdown

`Queue(T)` is thread-safe, many-producer/many-consumer, and backed by the exact
caller-provided ring buffer. An empty consumer and full producer can wait; those
blocked task stacks/records are resources outside `queue.capacity()` and need
their own admission limits.

### Minimums and partial transfers

The slice APIs accept `min`, bounded by the supplied slice length. With
`min == 0`, they transfer what is available without waiting for more elements
or space. The public comments call this nonblocking, but the installed 0.16.0
`TypeErasedQueue.put/get` first acquire an internal `Mutex` for nonempty
slices. Contention can therefore still wait or return `error.Canceled`.
The uncancelable variants acquire that mutex uncancelably. A zero minimum is
not a lock-free probe or a bound on call latency.

With a positive minimum, cancellation or closure after a partial transfer can
return a count below `min`. A returned error means no elements were transferred
by that call. Always account for exactly the returned prefix before propagating
cancellation or retrying the remainder; `min` is not an all-or-nothing boundary.

The public `Queue.put/get` comments promise subsequent `Canceled` or `Closed`
after such a short result. There is an implementation caveat for cancellation:
`TypeErasedQueue.putLocked/getLocked` re-arm it with `io.recancel()` when a
condition wait returns `Canceled` after some transfer, but a later call can
acquire an uncontended mutex and transfer available data without consulting
`Io`. Do not depend on the immediately following queue call observing the
request. In a loop that can keep making immediate progress, account for owned
elements and use `io.checkCancel()` at a bounded batch boundary when prompt
cancellation matters; its contract remains subject to cancellation protection.

These distinctions follow from `Queue`, `TypeErasedQueue`, `Mutex.lock`,
`recancel`, and `checkCancel` in [[zig-0.16.0-stdlib]].

`putAll` is convenient, but on cancellation or closure its error path does not
report how many elements were transferred. Do not use it where the operation
must be transactional or retryable without duplication; add item identity or a
higher-level acknowledgement protocol.

### Close, drain, and join

`close(io)` is idempotent. New nonempty puts fail after acquiring the mutex
and observing closure, even if capacity remains. Gets drain existing elements
before reporting `error.Closed`; an empty slice returns zero without checking
closure. A successful `close` signals waiting producers and consumers, but
does not join them. It also acquires the internal mutex uncancelably.

The implementation links blocked callers' stack-local pending records and
their transfer slices into the queue. Keep the queue, ring storage, and caller
buffers alive until all calls have returned. A shutdown owner stops new
admission, closes the queue, drains or accounts for transferred elements, and
joins both producers and consumers before reclaiming storage. Trying to join a
producer blocked on a full queue before arranging consumption or closure can
prevent shutdown from progressing.

[[select-and-batch]] applies this queue ownership model to typed task results;
its `awaitMany` also inherits partial counts and the zero-minimum mutex caveat.

## `Mutex` and `Condition`

`Mutex.tryLock()` is nonblocking and needs no `Io`. `lock(io)` can be canceled
while contended; an error means acquisition did not succeed. After successful
acquisition, pair `unlock(io)` immediately with `defer` so later I/O errors or
cancellation points cannot leak the critical section.

Avoid holding a mutex across unrelated, unbounded I/O. Even when memory safety
is preserved, one slow operation can couple independent progress and make
cancellation or shutdown depend on a remote peer.

`Condition.wait(io, mutex)` is for a predicate protected by that mutex. It
registers the waiter, unlocks while waiting, and reacquires the mutex
uncancelably before returning—even on cancellation. Always use it in a loop:
another waiter can consume the relevant state, or the predicate can change
again before this task runs. `signal` makes one signal available;
`broadcast` makes one available for each current unsignaled waiter.

## `RwLock`

`RwLock` permits either one exclusive owner or multiple shared owners. It has
cancelable and uncancelable acquisition variants plus nonblocking `tryLock` and
`tryLockShared`; the shared try operation accepts `io` because the
implementation may touch its internal mutex.

Match `unlock` only with exclusive acquisition and `unlockShared` with every
successful shared acquisition. In the 0.16 implementation, queued writers
disable the reader fast path; shared acquisition falls back to the internal
mutex. The public contract does not promise a
general fairness or starvation bound. If a latency guarantee depends on
fairness, build and test that policy explicitly.

## `Semaphore`

A semaphore owns an unsigned permit count, supports static initialization, and
needs no deinitialization. `wait` consumes one permit or blocks; `post` creates
one and signals a waiter. The primitive limits simultaneous admission only if
every entry path consumes and every terminal path returns exactly the intended
number of permits.

Give the count a domain maximum. An accidentally duplicated `post` weakens the
limit, while a missing post leaks capacity. A semaphore does not preallocate
the memory, descriptors, or downstream queue space represented by a permit;
those resources still need a startup capacity proof.

## Futex operations

The `std.Io` futex surface atomically compares a properly aligned, four-byte,
padding-free value with an expected value and waits only while it matches.
Wakeups are allowed to be spurious, and a wake can race with the transition.
The caller must load an atomic predicate in a loop, modify it with the matching
memory ordering, then call `futexWake` after publishing the change.

`futexWaitTimeout` returning successfully does not identify whether a matching
wake, spurious wake, or timeout occurred. Recheck state and, if required,
compare an explicit deadline. `max_waiters` limits how many pending calls a
wake requests; zero is a no-op.

Prefer `Event`, `Condition`, `Semaphore`, or `Queue` unless a compact custom
state machine genuinely needs the lower-level word protocol. Each higher-level
primitive already handles races that are easy to get subtly wrong.

## `Thread.Pool` is not the replacement model

Zig 0.16 removed the former public `std.Thread.Pool`. Task concurrency now
belongs to the `std.Io` abstractions described by [[async-vs-concurrent]],
[[task-lifetimes-and-structured-concurrency]], and [[select-and-batch]]. The
default [[io-threaded|`std.Io.Threaded`]] has an internal task pool, but that is
an implementation resource, not a public pool API to couple library code to.

## Evidence

The [synchronization proof](../proofs/io_sync_primitives.zig) runs six tests
with Zig 0.16 `std.testing.io`: event cancellation/reset after join; canceled
mutex acquisition and reuse; condition predicate handoff; queue capacity,
close, and drain; shared/exclusive lock and semaphore balance; and an atomic
futex predicate loop. It ran on aarch64 macOS on 2026-09-04. Interface claims
are source-verified cross-platform. The same six tests ran with Zig 0.16.0 on
x86_64 Linux 7.1.9 and x86_64 Windows Server 2025 build 26100.33296 on
2026-09-04; the Windows evidence is retained in
[Actions run 33911991858](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33911991858).

The queue test uses an uncontended two-element ring and checks zero-minimum
capacity plus close/drain behavior. It does not exercise mutex contention,
partial-transfer cancellation, or closure with blocked participants. Those
boundaries above are release-source evidence. This page is `source-verified`
so the existing six runtime tests are not mistaken for runtime coverage of
these additional cases; their recorded platform results remain valid.

## Review checklist

- Which state/predicate is guarded, and who owns every transition?
- Is a wait cancelable, and does cleanup still run after successful acquire?
- Can a spurious wake or partial queue transfer be handled without data loss?
- Does a zero-minimum call still contend on the queue mutex, and where does a
  continuously progressing loop explicitly check cancellation?
- Which count bounds buffered data, blocked tasks, permits, and downstream work?
- What closes/wakes the primitive during shutdown, and who joins every blocked
  producer and consumer before releasing storage?
- Is an uncancelable wait both necessary and guaranteed to terminate?

Related: [[std-io]], [[cancellation]], [[async-vs-concurrent]],
[[select-and-batch]], [[invariants-and-assertions]],
[[static-allocation-and-constant-work]].
