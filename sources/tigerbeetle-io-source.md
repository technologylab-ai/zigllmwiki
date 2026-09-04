---
id: source-tigerbeetle-io-source
title: TigerBeetle cross-platform I/O source
kind: source
status: captured
summary: Pinned implementation evidence for TigerBeetle's callback-oriented Linux io_uring, Darwin kqueue, and Windows IOCP backends.
captured: 2026-09-04
revision: 47aeb2212a255273dda508288412e537d11e4b7c
url: https://github.com/tigerbeetle/tigerbeetle/tree/47aeb2212a255273dda508288412e537d11e4b7c/src/io
---

# TigerBeetle cross-platform I/O source

Pinned to TigerBeetle commit
`47aeb2212a255273dda508288412e537d11e4b7c`, dated 2026-08-31. The focused
source paths are `src/io.zig`, `src/io/common.zig`, `src/io/linux.zig`,
`src/io/darwin.zig`, `src/io/windows.zig`, and `src/io/test.zig`.

Use this record as implementation evidence for caller-owned completion records,
serialized callback dispatch, finite queues, queue-pressure behavior, and the
different mechanisms hidden behind TigerBeetle's application-specific `IO`
surface. It is not evidence that these backends implement Zig 0.16 `std.Io`,
and its Zig syntax has not been promoted as Zig 0.16 example code.

Relevant pages: [[tigerbeetle-io]], [[io-uring]],
[[evented-io-backends]], and [[tigerbeetle-engineering-corpus]].
