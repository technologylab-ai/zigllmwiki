---
id: evented-io-backends
title: Evented I/O backend landscape
kind: platform
status: draft
zig: "0.16.0"
summary: Zig 0.16 has a production Threaded backend and unfinished evented experiments; OS-specific recommendations still require proof.
updated: 2026-09-04
sources:
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
proofs: []
platforms:
  - linux
  - macos
  - windows
---

# Evented I/O backend landscape

## Remember

For Zig 0.16.0, `std.Io.Threaded` is feature-complete, well-tested, and selected
by `main`. The standard-library tree contains evented work, but the release
notes do not present it as a finished production replacement.

## Release state

| Implementation | Zig 0.16 release state | Do not infer |
| --- | --- | --- |
| `Io.Threaded` | Feature-complete, well-tested, default from `main`. | That `async` always gets another thread. |
| `Io.Evented` | Experimental work in progress using userspace stack switching/work stealing. | Stable API, production readiness, or allocation behavior. |
| `Io.Uring` | Linux `io_uring` proof of concept; release notes call out missing networking, error handling, test coverage, and minimal task-stack allocations. | A complete HTTP-server backend. |
| `Io.Kqueue` | Proof of concept only. | General-purpose macOS file and network support. |
| `Io.Dispatch` | Based on macOS Grand Central Dispatch. | Feature parity with Threaded or Uring. |

## Research boundary

The desired end state is not “use `io_uring` everywhere.” It is a documented
mapping from workload and OS to the right mechanism:

- Linux: [[io-uring]] semantics and a bounded TigerStyle implementation.
- macOS/BSD: [[macos-kqueue-and-aio|`kqueue` readiness and POSIX AIO]], plus
  remaining dispatch I/O, worker-thread, and runtime comparison work.
- Windows: [[windows-iocp-and-overlapped-io|overlapped I/O and completion
  ports]], including cancellation and the exact Zig 0.16 Threaded/NtDll/APC
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
Zig 0.16 evented `std.Io` backends. It confirms why “use `kqueue` instead of
`io_uring`” is too coarse: socket readiness and asynchronous regular-file I/O
are different problems.

Regardless of backend, an asynchronous operation owns a resumption record and
may retain buffers until completion. TigerBeetle places fixed operation contexts
inside the components that own their concurrency limits. This is a useful
architecture pattern, not yet a verified recipe for Zig 0.16's experimental
evented implementations.

Related: [[std-io]], [[io-threaded]], [[async-vs-concurrent]], [[io-uring]],
[[platform-io-backend-decision-table]],
[[macos-kqueue-and-aio]], [[windows-iocp-and-overlapped-io]],
[[tigerbeetle-io]], [[cancellation]],
[[static-allocation-and-constant-work]], [[tigerstyle]].
