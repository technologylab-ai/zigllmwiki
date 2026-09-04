---
id: source-microsoft-windows-iocp
title: Microsoft Windows IOCP, overlapped I/O, and CancelIoEx documentation
kind: source
status: captured
summary: Pinned Microsoft documentation for completion-port ordering and concurrency, OVERLAPPED ownership, synchronous completion, explicit offsets, and cancellation races.
captured: 2026-09-04
revision: 79eaaa46b30bd0efef0d0f5a65fd7d11fdd8e2de
url: https://github.com/MicrosoftDocs/win32/tree/79eaaa46b30bd0efef0d0f5a65fd7d11fdd8e2de/desktop-src/FileIO
---

# Microsoft Windows IOCP, overlapped I/O, and `CancelIoEx` documentation

Pinned to MicrosoftDocs/win32 commit
`79eaaa46b30bd0efef0d0f5a65fd7d11fdd8e2de`. The focused paths are
`desktop-src/FileIO/i-o-completion-ports.md`,
`synchronous-and-asynchronous-i-o.md`, and `cancelioex-func.md`.

Use these pages for IO completion-port queue/concurrency behavior, supported
file and socket operations, `FILE_FLAG_OVERLAPPED`, per-operation control-block
and buffer lifetime, explicit offsets, immediate-success handling, and the fact
that `CancelIoEx` requests cancellation without waiting for terminal status.

Relevant pages: [[windows-iocp-and-overlapped-io]],
[[evented-io-backends]], and [[cancellation]].
