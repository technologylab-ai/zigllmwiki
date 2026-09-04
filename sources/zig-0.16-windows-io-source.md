---
id: source-zig-0-16-windows-io
title: Zig 0.16.0 Windows std.Io implementation source
kind: source
status: captured
summary: Exact-release source evidence for Windows std.Io.Threaded APC, NtDll, AFD networking, batch cancellation, and error-translation paths.
captured: 2026-09-04
revision: "zig tag 0.16.0; 44d9672fed001115e674fd5ddb32747ef43a7af4"
url: https://github.com/ziglang/zig/tree/44d9672fed001115e674fd5ddb32747ef43a7af4/lib/std
---

# Zig 0.16.0 Windows `std.Io` implementation source

Pinned to Zig commit `44d9672fed001115e674fd5ddb32747ef43a7af4`,
which is the source revision recorded for the installed `0.16.0` release.
The focused paths are:

- `lib/std/Io.zig` for the `Evented` platform selection, `Operation`, and
  `Batch` contracts;
- `lib/std/Io/File.zig` and `lib/std/Io/Dir.zig` for the meaning of a Windows
  `File.Flags.nonblocking` handle and the public file-open surface;
- `lib/std/Io/Threaded.zig` for synchronous-worker, alertable APC,
  `NtCancelSynchronousIoFile`, `NtCancelIoFileEx`, AFD networking, batch, and
  NTSTATUS translation behavior;
- `lib/std/os/windows.zig`, `lib/std/os/windows/ntdll.zig`, and
  `lib/std/os/windows/kernel32.zig` for the exact Windows declarations exposed
  by Zig 0.16.0.

Use this record only for Zig 0.16.0 implementation facts. It does not make
private `Threaded` helpers or the AFD device protocol stable public APIs, and
source inspection is not Windows runtime evidence.

Relevant page: [[windows-iocp-and-overlapped-io]].
