---
id: std-io
title: std.Io
kind: concept
status: source-verified
zig: "0.17.0"
summary: std.Io supplies explicit capabilities; Zig 0.17 changes network operations and retains implementation-specific behavior.
updated: 2026-10-04
sources:
  - "[[zig-0.17.0-stdlib]]"
  - "[[zig-0.16.0-release-notes]]"
  - "[[zig-0.16.0-stdlib]]"
  - "[[fi-zig-0.16-migration]]"
  - "[[matklad-neat-io-threaded]]"
  - "[[matklad-zig-error-context]]"
proofs: []
platforms:
  - cross-platform
---

# `std.Io`

## Remember

Starting in Zig 0.16.0, operations that may block control flow or introduce
nondeterminism receive an explicit `std.Io`. Thread it from
`std.process.Init.io` through application APIs like an allocator. The caller
chooses the implementation; library code should not secretly choose one.

`std.Io` is an interface and ownership boundary. It does not mean that an
operation is backed by a readiness event loop. The `main` runtime currently
supplies [[io-threaded|`std.Io.Threaded`]], whose file and network operations
use blocking OS operations with threads and whose task dispatch has explicit
limits.

## Guarantees versus implementations

The interface defines futures, groups, selection, cancellation, synchronization,
clocks, files, networking, processes, and entropy. Each implementation decides
how to provide those operations within the interface contract.

Zig 0.17 selects `std.Io.Threaded` in `lib/std/start.zig`.
The tree also contains unfinished evented implementations. [[zig-0.17.0-stdlib]]
Presence in `std` must not be presented as production readiness;
see [[evented-io-backends]].

## Zig 0.17 source review

The review inspected `lib/std/Io.zig` and `lib/std/start.zig` at the exact release commit.
`Io.Operation` now includes `net_send`, `net_read`, and `net_write` beside `net_receive`.
Networking reaches those operations through `operate` and batch submission.
A custom backend must implement the current operation tags and current vtable signatures.

The release source still selects platform-specific `Io.Evented` types when fibers are supported.
Type selection does not establish interface compatibility or runtime behavior.
The shipped Dispatch initializer assigns `processReplacePath`, which the current `Io.VTable` lacks.
See [[evented-io-backends]] for the exact backend gaps. [[zig-0.17.0-stdlib]]

The old 0.16 records remain historical sources.
Each maintained proof requires its own named 0.17 gate before runtime claims resume.

## Agent traps

- Do not create a global single-threaded `Io` deep inside a library because an
  API suddenly needs one. Accept or store the caller's capability.
- Do not describe all I/O as asynchronous. A sequential call through
  `std.Io.Threaded` can directly perform a blocking syscall.
- Do not confuse `async` operational independence with guaranteed concurrent
  progress. See [[async-vs-concurrent]].
- Cancellation is a request that may race with successful completion. Cleanup
  must handle both results and release the future/group resource. See
  [[cancellation]].
- A `Select` needs enough result capacity for terminal cancellation, while a
  `Batch` needs fixed operation storage and raced-completion draining. See
  [[select-and-batch]].
- Synchronization waits are part of the `Io` contract too: preserve predicate
  loops, cancellation, queue closure, and explicit capacity. See
  [[io-synchronization-primitives]].
- Use one clock-tagged absolute deadline for a multi-step budget; sleeping is
  cancelable I/O, not a scheduling guarantee. See
  [[io-time-clocks-and-deadlines]].
- Buffered writes, file synchronization, atomic replacement, and directory
  durability are separate transitions. See
  [[files-buffering-and-atomic-persistence]].
- DNS queues, connection attempts, socket buffers, subprocess output, and
  entropy failure all retain explicit capacity and ownership. See
  [[networking-and-dns-racing]], [[child-process-lifecycles]], and
  [[entropy-and-deterministic-randomness]].
- `std.testing.io`, `std.Io.failing`, fixed stream adapters, and
  `-fsingle-threaded` exercise different contracts; none is automatically a
  deterministic scheduler. See [[testing-io-and-single-threaded-builds]].
- Do not log every propagating I/O error from `errdefer`; expected cancellation
  may be handled by the owner. See [[error-context]].
- File writers are buffered; missing flushes and multiple independent writers
  over the same stream can lose or overwrite output.

## Design consequence

Make the `std.Io` owner visible near the application's allocator and resource
owners. State which implementation a behavioral claim assumes, and put limits,
cancellation, allocation lifetime, and cleanup in the same design discussion.

[[process-init-and-capabilities]] shows how a Zig executable obtains that
capability from `std.process.Init` without coupling reusable libraries to the
whole process initializer.

Related: [[zig-0.16-baseline]], [[io-threaded]], [[async-vs-concurrent]],
[[cancellation]], [[io-time-clocks-and-deadlines]],
[[files-buffering-and-atomic-persistence]], [[networking-and-dns-racing]],
[[child-process-lifecycles]], [[entropy-and-deterministic-randomness]],
[[testing-io-and-single-threaded-builds]], [[error-context]], [[tigerstyle]].
