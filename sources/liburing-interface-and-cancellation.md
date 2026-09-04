---
id: source-liburing-interface-and-cancellation
title: liburing io_uring interface and cancellation manual pages
kind: source
status: captured
summary: Pinned primary Linux documentation for submission/completion queues, completion ordering, request identity, and cancellation races.
captured: 2026-09-04
revision: 4cf73437863c2e492d2a1d0f24330f391c0f075b
url: https://github.com/axboe/liburing/tree/4cf73437863c2e492d2a1d0f24330f391c0f075b/man
---

# liburing `io_uring` interface and cancellation manual pages

Pinned to liburing commit `4cf73437863c2e492d2a1d0f24330f391c0f075b`.
The source paths used in this ingestion are `man/io_uring.7` and
`man/io_uring_cancelation.7`.

Use these pages for the Linux interface model, arbitrary completion ordering,
`user_data` request association, explicit cancellation as another operation,
the two cancellation-related completions and their unordered arrival, and the
fact that closing an application file descriptor does not cancel requests for
which `io_uring` retains a reference.

Relevant pages: [[io-uring]], [[cancellation]].
