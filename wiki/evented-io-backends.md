---
id: evented-io-backends
title: Evented I/O backend landscape
kind: platform
status: source-verified
zig: "0.17.0"
summary: Zig 0.17 selects Threaded by default; experimental evented backends have source-visible interface and operation gaps.
updated: 2026-10-04
sources:
  - "[[zig-0.17.0-stdlib]]"
  - "[[zig-0.16.0-release-notes]]"
  - "[[zig-0.16.0-stdlib]]"
  - "[[source-tigerstyle]]"
  - "[[tigerbeetle-architecture]]"
  - "[[matklad-cancelation-terminology]]"
  - "[[matklad-what-is-io-uring]]"
  - "[[liburing-interface-and-cancellation]]"
  - "[[tigerbeetle-io-source]]"
  - "[[apple-xnu-kqueue-aio]]"
  - "[[microsoft-windows-iocp]]"
proofs:
  - proofs/dispatch_017_io_compile_error.zig
  - proofs/uring_017_io_compile_error.zig
  - proofs/kqueue_017_io_compile_error.zig
platforms:
  - linux
  - macos
  - windows
---

# Evented I/O backend landscape

## Remember

Zig 0.17.0 constructs `std.Io.Threaded` in the default `main` runtime.
The source also selects unfinished evented implementations.
A selected type does not establish a working `std.Io` interface. [[zig-0.17.0-stdlib]]

## Zig 0.17 source review

The review inspected `lib/std/Io.zig`, `Io/Threaded.zig`, `Io/Uring.zig`, `Io/Kqueue.zig`, and `Io/Dispatch.zig`.
The files match the immutable release commit. [[zig-0.17.0-stdlib]]

| Implementation | Exact 0.17 source state | Evidence boundary |
| --- | --- | --- |
| `Io.Threaded` | Default `main` implementation. Allocates task records and may grow its worker pool. | `async` can run inline. Windows concurrent network batches remain unavailable. |
| `Io.Evented` | Selects Uring on Linux, Kqueue on four BSD targets, and Dispatch on Apple targets. Requires supported fibers. Windows selects `void`. | Selection establishes type identity, not interface compatibility. |
| `Io.Uring` | `io()` assigns removed `processReplacePath`. Binding and message receive have source implementations; sending and reading remain stubs. Writing and network batching panic. | The exact compiler rejects the I/O interface. Low-level ring proofs test a separate wrapper. |
| `Io.Kqueue` | `io()` still assigns removed networking vtable fields. Many operation paths panic. | The exact compiler first rejects removed `fileWriteStreaming`. Apple targets do not select this backend. |
| `Io.Dispatch` | `io()` assigns removed `processReplacePath`. Network operation tags panic. Each allocated fiber reserves at least 60 MiB. | The exact 0.17 compiler rejects the I/O interface. Initialization and teardown remain unqualified. |

`Io.VTable` has no `processReplacePath`, `netRead`, `netSend`, or `netReceive` field.
Uring and Dispatch still initialize `processReplacePath`.
Kqueue still initializes the removed networking fields.
These source mismatches block use of the corresponding I/O interfaces. [[zig-0.17.0-stdlib]]

The registered [Dispatch](../proofs/dispatch_017_io_compile_error.zig),
[Uring](../proofs/uring_017_io_compile_error.zig), and
[Kqueue](../proofs/kqueue_017_io_compile_error.zig) witnesses require specific shipped-source compile failures.
The checker rejects other failures and unexpected successful compilation.
These gates establish interface blockers, not runtime behavior.

Dispatch teardown no longer has the old slice-only allocator restriction.
Zig 0.17 `Allocator.free` accepts the fixed-size pointer-to-array used by `Dispatch.deinit`.
That change does not establish fiber, cancellation, or networking behavior.
The dated 0.16 observations remain historical evidence on the platform pages.

## Research boundary

The desired end state is not “use `io_uring` everywhere.” It is a documented
mapping from workload and OS to the right mechanism:

- Linux: [[io-uring]] semantics and a bounded TigerStyle implementation.
- macOS/BSD: [[macos-kqueue-and-aio|`kqueue` readiness and POSIX AIO]], plus
  remaining dispatch I/O, worker-thread, and runtime comparison work.
- Windows: [[windows-iocp-and-overlapped-io|overlapped I/O and completion
  ports]], including cancellation and the exact Zig 0.17 Threaded/NtDll/APC
  mapping. Threaded is not an IOCP backend.

Primary Linux, Apple, and Microsoft interface semantics and pinned
TigerBeetle code are synthesized in [[platform-io-backend-decision-table]].
That table recommends choices with explicit evidence boundaries; it does not
promote a narrow lifecycle proof to production-load or arbitrary-device
coverage. Remaining platform work is tracked in `ROADMAP.md`.

## Current TigerBeetle implementation evidence

The pinned TigerBeetle source now provides a concrete comparison, summarized in
[[tigerbeetle-io]]:

| Platform | Implemented mechanism | Critical boundary |
| --- | --- | --- |
| Linux | `io_uring` for files, sockets, and kernel timeouts | Finite SQ/CQ lifecycle and Linux feature requirements remain part of the contract. |
| Darwin | `kqueue` one-shot readiness for operations that return `WouldBlock` | Regular-file reads/writes and durability work execute synchronously in callback dispatch. |
| Windows | IOCP with overlapped file and socket operations | Not every action is overlapped, and no public general-cancellation protocol is exposed. |

This is evidence about TigerBeetle's custom interface, not about the unfinished
Zig 0.17 evented `std.Io` backends. It confirms why “use `kqueue` instead of
`io_uring`” is too coarse: socket readiness and asynchronous regular-file I/O
are different problems.

Regardless of backend, an asynchronous operation owns a resumption record and
may retain buffers until completion. TigerBeetle places fixed operation contexts
inside the components that own their concurrency limits. This is a useful
architecture pattern, not yet a verified recipe for Zig 0.17's experimental
evented implementations.

Related: [[std-io]], [[io-threaded]], [[async-vs-concurrent]], [[io-uring]],
[[platform-io-backend-decision-table]],
[[macos-kqueue-and-aio]], [[windows-iocp-and-overlapped-io]],
[[tigerbeetle-io]], [[cancellation]],
[[static-allocation-and-constant-work]], [[tigerstyle]].
