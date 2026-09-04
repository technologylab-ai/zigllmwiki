---
id: source-matklad-reserve-first
title: matklad — Reserve First
kind: source
status: captured
summary: Reserve every fallible capacity requirement before mutating a data structure so the commit phase can be infallible.
captured: 2026-09-04
revision: ff6734c93ac8b41677dee016af6bb67c39420101
url: https://github.com/matklad/matklad.github.io/blob/ff6734c93ac8b41677dee016af6bb67c39420101/content/posts/2025-08-16-reserve-first.dj
---

# matklad — Reserve First

Pinned to the `matklad.github.io` repository commit recorded above. The essay
uses two Zig allocation bugs to motivate a two-phase pattern: reserve all
fallible capacity without changing logical state, then perform mutation only
through capacity-assuming operations.

The source discusses dynamically allocated programs as well as TigerBeetle's
stronger startup-only policy. Do not turn the reservation pattern into a claim
that allocation failure is always recoverable or that a capacity reservation
alone makes a multi-object mutation atomic.

Relevant pages: [[static-allocation-and-constant-work]],
[[invariants-and-assertions]].
