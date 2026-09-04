---
id: source-matklad-neat-io-threaded
title: matklad — Zig's Io.Threaded is Neat
kind: source
status: captured
summary: Implementation-oriented explanation of cancellable blocking I/O and Zig's may-run versus must-run concurrency distinction.
captured: 2026-09-04
revision: ff6734c93ac8b41677dee016af6bb67c39420101
url: https://matklad.github.io/2026/08/06/neat-io-threaded.html
---

# matklad — Zig's `Io.Threaded` is Neat

Pinned to the `matklad.github.io` repository commit recorded above. Use it as a
guided reading of `std.Io.Threaded`, then verify exact behavior against the
installed Zig 0.16.0 standard-library source.

The central topics are cancellation of blocking syscalls, POSIX signal races,
the direct Windows cancellation facility, pooled threads, and the stronger
failure-bearing contract of `concurrent` compared with `async`.

Relevant pages: [[io-threaded]], [[async-vs-concurrent]], [[cancellation]].
