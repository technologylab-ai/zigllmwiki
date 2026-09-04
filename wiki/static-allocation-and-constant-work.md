---
id: static-allocation-and-constant-work
title: Static allocation and constant work
kind: principle
status: source-verified
zig: "0.16.0"
summary: Size capacity at startup, reject excess load explicitly, and consider conserved fixed-slot state when predictable maximum-load work matters.
updated: 2026-09-04
sources:
  - "[[source-tigerstyle]]"
  - "[[tigerbeetle-architecture]]"
  - "[[tigerbeetle-performance]]"
  - "[[matklad-static-allocation-constant-work]]"
  - "[[matklad-reserve-first]]"
  - "[[matklad-static-allocation-compilers]]"
  - "[[tigerbeetle-storage-source]]"
  - "[[zig-0.16.0-stdlib]]"
proofs:
  - proofs/static_pool.zig
platforms:
  - cross-platform
---

# Static allocation and constant work

## Remember

“Static allocation” in TigerBeetle does not mean that all storage lives in the
executable's static data. It means computing worst-case counts from startup
configuration, allocating those objects before the main loop, and performing no
dynamic allocation or deallocation afterward.

When capacity is full, reject or defer excess work while preserving service for
the admitted work. Trying one hopeful allocation beyond a declared limit can
turn overload into process-wide failure.

This is a design recommendation, not a claim that every TigerBeetle capacity
boundary rejects gracefully: the pinned `Grid.reserve` and manifest
`NodePool.acquire` terminate on exhaustion. Their limits and operational
consequences are examined in [[durable-storage-and-recovery]].
[[tigerbeetle-storage-source]]

## Capacity is part of the design

A bounded arena alone is not enough. An arena proves only that memory use has a
ceiling; it can still run out at an arbitrary point. The stronger design derives
the number of every in-flight object—connections, operations, buffers, timers,
queue entries, and cancellation records—from explicit limits and reserves that
capacity before serving requests.

This creates system-wide backpressure only if adjacent components honor one
another's limits. A bounded application queue does not help if an I/O runtime or
kernel submission path can still grow without bound.

### Reserve before mutation

When initialization or another permitted control-plane phase still allocates,
reserve every fallible capacity requirement before changing logical state.
Only after all participating collections and buffers can accommodate the
operation should code enter a commit phase made solely of infallible mutations.
This avoids half-applied changes when the second of several allocations fails
and makes rollback unnecessary for allocation errors.

Reservation is not transactional by itself: every later operation must truly
be infallible, external I/O may still fail, and reserving one collection does
not reserve dependent structures. TigerStyle's startup-only policy applies the
same separation at system scale—finish all fallible resource acquisition
before the steady-state loop begins.

### Bound the working set, not necessarily all output

Derive capacities from the physical shape of the problem. A service with a
finite maximum message size can bound per-message work while its durable data
continues to grow. The compiler essay explores the same split: finite chunks
and bounded intermediate state feed a separate arena or persistent store for
potentially unbounded immutable output.

This is a useful architecture question, not a general proof of constant-memory
processing. State which bytes count as input, scratch, retained output, cache,
and kernel/runtime state. Moving growth into an “output arena” or file changes
ownership and failure policy; it does not remove growth or `ENOSPACE`.

## Constant work is a separate option

Some pools can be modeled as a fixed set whose slots circulate between explicit
states such as `reserved` and `active`. The count is conserved: acquisition is a
state transition, not object creation, and release is its inverse. Assertions at
both transitions make double release, reuse, and leaked state easier to expose.

For small or latency-critical sets, scanning every slot and treating reserved
slots as no-ops can be simpler and more predictable than maintaining a second
active index. It exercises the maximum-load path continuously and can make the
data plane friendlier to prefetching and vectorization.

Do not turn this into a slogan. Fixed full scans can waste work, and fixed
algorithmic work does not by itself prove flat P100 latency on real hardware.
Choose it after a performance sketch and measurement at the configured maximum.

## The `std.Io.Threaded` seam

In the ordinary multithreaded Zig 0.16 implementation,
[[io-threaded|`std.Io.Threaded`]] calls `Future.create` for `async`/`concurrent`
and `Group.Task.create` for group dispatch; terminal cleanup destroys those
records. Prewarming worker threads may avoid thread growth, but does not remove
these per-dispatch allocator calls. Even an `async` call that ultimately runs
inline because its concurrency limit is reached first attempts to allocate
the future. [[zig-0.16.0-stdlib]]

A preallocated allocator can bound the backing storage while still performing
allocation/free operations. An application requiring strictly no steady-state
allocation must avoid these dispatch paths or choose an implementation whose
ownership model satisfies that requirement. This is a `Threaded` seam, not an
allocation guarantee imposed by the `std.Io` interface. The explicit
single-threaded build follows different paths described in
[[testing-io-and-single-threaded-builds]].

An evented design has the same obligation. Every in-flight kernel operation
needs a stable operation record, buffer lifetime, completion slot, and
cancellation state. Put those objects under the component that owns the limit.

## Applied pattern

1. Name the capacity and its unit in configuration.
2. Derive memory and kernel-resource requirements before startup succeeds.
3. Allocate all slots and initialize each to an explicit neutral state.
4. Reject, defer, or shed work before a slot or downstream resource is exceeded.
5. Assert legal transitions and conservation of the slot count.
6. Test empty, partial, full, over-capacity, cancellation, and reuse cases.
7. Benchmark at the configured maximum, not only at average load.

The [fixed-pool proof](../proofs/static_pool.zig) checks the bounded transition
mechanics with Zig 0.16.0. It does not claim to benchmark the approach.

Related: [[tigerstyle]], [[newtype-indexes]],
[[integer-widths-and-boundaries]], [[cancellation]],
[[select-and-batch]], [[io-synchronization-primitives]],
[[evented-io-backends]], [[durable-storage-and-recovery]].
