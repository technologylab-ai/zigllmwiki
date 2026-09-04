---
id: source-liburing-registered-resources
title: liburing registered file and buffer manual pages
kind: source
status: captured
summary: Pinned primary documentation for fixed file tables, registered buffers, updates, unregistration, and their resource costs.
captured: 2026-09-04
revision: 4cf73437863c2e492d2a1d0f24330f391c0f075b
url: https://github.com/axboe/liburing/tree/4cf73437863c2e492d2a1d0f24330f391c0f075b/man
---

# liburing registered files and buffers

Pinned to liburing commit `4cf73437863c2e492d2a1d0f24330f391c0f075b`.
The focused manual pages are `io_uring_register.2`, `io_uring_register_files.3`,
`io_uring_unregister_files.3`, `io_uring_register_buffers.3`,
`io_uring_unregister_buffers.3`, `io_uring_prep_read_fixed.3`, and
`io_uring_prep_write_fixed.3`.

Use these pages for the fixed-file table and direct-descriptor model, sparse
table limits, reduced per-operation file-reference work, fixed-buffer
registration, and the distinction between the temporary `iovec` description
and the underlying memory region that remains registered. Registration is an
ownership protocol and a measured optimization, not merely an alternate
spelling of ordinary reads and writes.

Relevant pages: [[io-uring]], [[static-allocation-and-constant-work]], and
[[tigerstyle-seams-with-zig-and-os]].
