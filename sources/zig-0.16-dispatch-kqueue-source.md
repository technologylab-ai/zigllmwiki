---
id: source-zig-0-16-dispatch-kqueue-source
title: Zig 0.16.0 Dispatch and Kqueue backend source
kind: source
status: captured
summary: Release-pinned Zig source maps Apple Evented I/O to Dispatch, exposes unfinished Kqueue separately, and shows the exact dispatch-source and synchronous syscall paths.
captured: 2026-09-04
revision: 44d9672fed001115e674fd5ddb32747ef43a7af4
url: https://github.com/ziglang/zig/tree/44d9672fed001115e674fd5ddb32747ef43a7af4/lib/std/Io
---

# Zig 0.16.0 `Dispatch` and `Kqueue` backend source

Pinned to the Zig 0.16.0 release commit
`44d9672fed001115e674fd5ddb32747ef43a7af4`. The focused paths are
`lib/std/Io.zig`, `lib/std/Io/Dispatch.zig`, `lib/std/Io/Kqueue.zig`, and
`lib/std/c/darwin/dispatch.zig`.

`Io.zig` selects `Dispatch` as `Io.Evented` on Apple targets when fiber context
switching is supported. It selects `Kqueue` only for DragonFlyBSD, FreeBSD,
NetBSD, and OpenBSD. Both concrete types remain directly importable, but this
selection is evidence against describing `Io.Kqueue` as Zig's macOS evented
backend.

`Dispatch.zig` creates a concurrent Grand Central Dispatch queue and implements
stackful tasks. Its streaming file path first tries a nonblocking `readv` or
`writev`; on `WouldBlock`, it installs a dispatch read/write source, yields the
fiber, and retries after readiness. Its positional regular-file path invokes
`preadv` and `pwritev` directly, and durability invokes `fsync` directly. It
does not call the `dispatch_io_*` channel API.

The release source also exposes material readiness limits:

- the fiber allocation reserves a 60 MiB minimum stack per allocated fiber;
- the `Dispatch` vtable maps networking operations to unavailable stubs and
  still contains unimplemented operation and process paths;
- `Kqueue.zig` contains many panicking `TODO` implementations, including
  cancellation, groups, filesystem operations, clocks, and major networking
  operations;
- `Dispatch.deinit` passes a fixed-length pointer slice to `Allocator.free` in
  a form rejected by the 0.16.0 compiler. The macOS proof records the resulting
  isolated-process workaround rather than claiming clean teardown.

Relevant pages: [[macos-kqueue-and-aio]] and [[evented-io-backends]].
