---
id: source-matklad-retry-loop
title: matklad — Retry Loop
kind: source
status: captured
summary: Derive a retry loop with a visible attempt bound, no sleep after the last attempt, transient-versus-fatal classification, and preservation of the last operational error.
captured: 2026-09-04
revision: ff6734c93ac8b41677dee016af6bb67c39420101
url: https://github.com/matklad/matklad.github.io/blob/ff6734c93ac8b41677dee016af6bb67c39420101/content/posts/2023-12-21-retry-loop.dj
---

# matklad — Retry Loop

Pinned to the `matklad.github.io` repository commit recorded above. The essay
frames retry as three outcomes—success, fatal failure, and transient failure—
and requires a syntactically visible bound, no useless final sleep, and return
of the underlying last error when attempts are exhausted.

The original example predates Zig 0.16 and remains source material rather than
copyable code. Current guidance and executable syntax live in
[[bounded-retries-and-cleanup]].
