---
id: source-apple-xnu-kqueue-aio
title: Apple XNU kqueue and POSIX AIO manual pages
kind: source
status: captured
summary: Pinned Apple source documentation for kqueue readiness and batching, descriptor-specific filters, POSIX asynchronous file I/O ownership, cancellation outcomes, and terminal cleanup.
captured: 2026-09-04
revision: f6217f891ac0bb64f3d375211650a4c1ff8ca1ea
url: https://github.com/apple-oss-distributions/xnu/tree/f6217f891ac0bb64f3d375211650a4c1ff8ca1ea/bsd/man/man2
---

# Apple XNU `kqueue` and POSIX AIO manual pages

Pinned to Apple XNU commit
`f6217f891ac0bb64f3d375211650a4c1ff8ca1ea`. The focused paths are
`bsd/man/man2/kqueue.2`, `aio_read.2`, `aio_cancel.2`, `aio_error.2`, and
`aio_return.2`.

Use these pages for current source-level documentation of `kevent` identity,
aggregation, batching, one-shot/read/write/vnode/process/timer/AIO filters, and
for POSIX AIO control-block and buffer lifetime, queue pressure, cancellation,
status, and cleanup. They do not establish the performance or suitability of a
particular macOS storage design; that needs runtime evidence.

Relevant pages: [[macos-kqueue-and-aio]], [[evented-io-backends]], and
[[cancellation]].
