---
id: source-matklad-zig-error-context
title: matklad — Minimal Viable Zig Error Contexts
kind: source
status: captured
summary: Zig 0.16 error-reporting pattern using telescoping errdefer context, with a critical caveat for handled cancellation.
captured: 2026-09-04
revision: ff6734c93ac8b41677dee016af6bb67c39420101
url: https://matklad.github.io/2026/05/03/zig-error-context.html
---

# matklad — Minimal Viable Zig Error Contexts

Pinned to the `matklad.github.io` repository commit recorded above. The essay
distinguishes typed error handling from human-facing reporting and proposes
low-friction, key/value context installed with `errdefer`.

It also identifies the important failure mode: `errdefer` logging fires while
an error is still propagating, even when an outer layer will handle it. That is
especially relevant for expected `error.Canceled` control flow in Zig 0.16.

Relevant pages: [[error-context]], [[cancellation]], [[std-io]].
