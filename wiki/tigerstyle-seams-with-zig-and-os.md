---
id: tigerstyle-seams-with-zig-and-os
title: TigerStyle seams with Zig and operating systems
kind: map
status: source-verified
zig: "0.16.0"
summary: Label where strict TigerStyle ends at Zig integer/API boundaries, allocator-using standard-library implementations, concurrency runtimes, and finite OS resources.
updated: 2026-09-04
sources:
  - "[[source-tigerstyle]]"
  - "[[zig-0.16.0-stdlib]]"
  - "[[zig-0.16.0-language-reference]]"
  - "[[zig-0.16.0-release-notes]]"
  - "[[tigerbeetle-io-source]]"
  - "[[apple-xnu-kqueue-aio]]"
  - "[[liburing-interface-and-cancellation]]"
  - "[[microsoft-windows-iocp]]"
proofs:
  - proofs/async_vs_concurrent.zig
  - proofs/files_and_atomic_persistence.zig
  - proofs/integer_boundaries.zig
  - proofs/network_process_entropy.zig
  - proofs/static_pool.zig
  - proofs/testing_io_modes.zig
platforms:
  - cross-platform
---

# TigerStyle seams with Zig and operating systems

## Remember

Strict TigerStyle is an application design contract. Zig's language and
standard library give useful mechanisms, but neither `std.Io`, an explicit
allocator, nor a fixed application array makes the whole transitive system
startup-allocated, constant-work, or platform-independent.

Label every boundary as one of:

- **inside the strict core** — all memory, work, ownership, and failure bounds
  are derived and enforced;
- **isolated exception** — a named control-plane or dependency operation may
  allocate or block, with a measured bound and no hidden path into the data
  plane;
- **nonconforming dependency** — the selected implementation cannot satisfy
  the required property and must be replaced or the product claim weakened.

The honest label is more useful than saying “TigerStyle-inspired” while
hiding an unbounded runtime underneath.

## Seam map

| Seam | What Zig 0.16 guarantees | What strict TigerStyle still requires |
| --- | --- | --- |
| Domain integer ↔ `usize` | Slices, indexes, allocator sizes, and many APIs use target-sized `usize`. Checked conversions and explicit-width integers are available. | Keep protocol/count/offset domains explicitly sized; validate arithmetic and narrowing at the boundary. |
| Explicit allocator ↔ allocation lifetime | Allocation is visible in many APIs, and `process.Init` supplies a GPA and process arena. | Prove which phase may allocate; an allocator argument or process-lifetime arena is not startup reservation. |
| Fixed application state ↔ `Io.Threaded` | The implementation has configured dispatch limits and explicit concurrency failure, but may allocate futures and grow worker threads. | Reserve/provision the transitive runtime or isolate/replace it; application queue bounds alone do not prove no steady-state allocation. |
| `std.Io` interface ↔ backend behavior | Callers can inject an implementation; operations expose cancellation, timeouts, buffers, and ownership. | Name the implementation and resource bounds. `async` is not an event-loop guarantee and `concurrent` may be unavailable. |
| Portable operation ↔ OS primitive | The interface normalizes error/operation shapes across targets. | Retain descriptor, request, buffer, kernel-queue, cancellation, and completion rules specific to the target. |
| Atomic name change ↔ durable persistence | `File.Atomic` can atomically link/replace a completed temporary file; `File.sync` synchronizes that file. | Supply the target filesystem's directory-sync and crash-consistency protocol; atomic visibility is not power-loss durability. |
| Fixed userspace queue ↔ kernel/runtime capacity | Caller-owned `Queue`, `Batch`, socket buffers, listen backlog, and platform rings expose some capacities. | Derive a system-wide admission bound including descriptors, kernel memory, pending operations, worker stacks, and completion drain rate. |

## `usize` is a boundary type

Use `usize` where the language or local memory API requires an address-sized
index or byte count. Do not persist it, put it on a stable wire, or use it as a
domain identifier merely because it avoids casts. A configured `u32`
connection maximum and a slice length describe different domains even on a
32-bit target.

The safe direction is:

`validated external integer → explicit domain type → checked arithmetic → checked conversion → local slice/API`

The reverse direction also needs a range decision before storage. An in-memory
length that does not fit the wire field is an operational encoding error, not
a reason to truncate. See [[integer-widths-and-boundaries]].

## Standard-library allocation remains allocation

An allocator parameter makes storage authority visible; it does not prove a
bounded lifetime. Audit every API used after admission begins, including
helpers whose allocation is easy to overlook:

- `std.process.run` grows stdout/stderr capture using the supplied allocator;
- `Dir.readFileAlloc` allocates the returned file contents;
- argument iteration may allocate on Windows or WASI;
- `Io.Threaded` task dispatch may allocate task state and grow its worker pool;
- higher-level protocol clients may allocate even when their socket read/write
  buffers are caller-owned.

Prefer caller-owned buffers and fixed storage when available. Otherwise move
the operation into startup/control-plane initialization, replace it with an
incremental bounded interface, or record a measured exception. Setting an
`Io.Limit` protects one result size but does not pre-reserve its memory or
prevent allocator fragmentation/failure.

## Concurrency runtime seam

`std.Io` is a valuable dependency boundary because libraries can accept the
caller's implementation. The production 0.16 implementation is
`std.Io.Threaded`, not an evented readiness/completion reactor.

Its `async` operation may execute eagerly when its async limit or allocation
path cannot dispatch work. Its `concurrent` operation either establishes
independent progress or returns `error.ConcurrencyUnavailable`. In an
explicitly single-threaded build, asynchronous work is inline and concurrent
work is unavailable. None of these modes supplies fixed worker stacks and task
records merely because the application preallocated its own connection pool.

For a strict data plane, choose among:

1. prove and reserve every runtime resource before admission;
2. drive a custom bounded backend with caller-owned operation/completion slots;
3. isolate an allocator-using runtime in a control plane and bound crossings;
4. weaken the strict claim and state the actual allocation/failure policy.

The shipped experimental `Uring`, `Kqueue`/`Dispatch`, and related source are
research inputs, not a feature-complete portable replacement. Presence in
`std` is not a production-readiness guarantee; see [[evented-io-backends]].

## OS resources are part of the bound

Startup-only userspace allocation does not reserve kernel resources. A systems
design must account for at least:

- file/socket handles and process/system descriptor quotas;
- listen backlog versus accepted-connection slots;
- socket send/receive memory and partial progress;
- submission/completion ring entries and overflow behavior;
- registered files/buffers and their lifetime until completion;
- worker threads and stacks in a blocking implementation;
- in-flight DNS, process pipe, timer, and cancellation records;
- completion capacity and the drain rate needed to release resources.

Linux `io_uring`, Darwin readiness/dispatch APIs, and Windows overlapped I/O
have different ownership and cancellation races. A common application
operation can sit above them, but the proof and limit table stays per backend.
Cross-compiling verifies types and symbols; only execution on the named OS
establishes runtime behavior.

## Practical component declaration

For every subsystem, record these four sections next to its limits:

1. **Strict core:** preallocated state, maximum live objects, maximum work per
   turn, and owner/terminal transitions.
2. **Implementation:** exact `std.Io` backend and whether dispatch allocates,
   blocks a worker, or can fail for missing concurrency.
3. **External resources:** descriptors, kernel queues/buffers, threads, and
   filesystem guarantees included in admission.
4. **Exceptions:** initialization/control-plane allocation or platform API
   seams, with failure handling and evidence.

This turns TigerStyle from a slogan into a falsifiable claim. If a dependency
cannot expose its limit or allocation behavior, call that out as unknown and
keep it outside a strict boundary until measured or replaced.

## Evidence and open limits

The linked proofs cover checked `usize` conversion and serialization, fixed
application pools, `Io.Threaded` saturation, single-threaded concurrency
unavailability, bounded process/file APIs, and the difference between writer
flush, atomic replacement, and file synchronization. They do not prove a
fully startup-reserved standard-library runtime or uniform OS behavior.

Platform pages retain the evidence still needed for Linux, macOS, and Windows.
The eventual HTTP synthesis project must publish its own transitive resource
budget and exception list before it can claim strict TigerStyle behavior.

Related: [[tigerstyle]], [[tigerstyle-coverage]],
[[static-allocation-and-constant-work]], [[integer-widths-and-boundaries]],
[[io-threaded]], [[testing-io-and-single-threaded-builds]],
[[files-buffering-and-atomic-persistence]], [[networking-and-dns-racing]],
[[io-uring]], [[macos-kqueue-and-aio]],
[[windows-iocp-and-overlapped-io]], [[tigerbeetle-io]].
