---
id: std-io
title: std.Io
kind: concept
status: source-verified
zig: "0.16.0"
summary: std.Io is an explicit capability interface for potentially blocking or nondeterministic operations, not a synonym for evented I/O.
updated: 2026-09-04
sources:
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

Zig 0.16 ships one feature-complete and well-tested implementation:
`std.Io.Threaded`. The tree also contains experimental or proof-of-concept
evented work. Presence in `std` must not be presented as production readiness;
see [[evented-io-backends]].

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
- Do not log every propagating I/O error from `errdefer`; expected cancellation
  may be handled by the owner. See [[error-context]].
- File writers are buffered; missing flushes and multiple independent writers
  over the same stream can lose or overwrite output.

## Design consequence

Make the `std.Io` owner visible near the application's allocator and resource
owners. State which implementation a behavioral claim assumes, and put limits,
cancellation, allocation lifetime, and cleanup in the same design discussion.

Related: [[zig-0.16-baseline]], [[io-threaded]], [[async-vs-concurrent]],
[[cancellation]], [[error-context]], [[tigerstyle]].
