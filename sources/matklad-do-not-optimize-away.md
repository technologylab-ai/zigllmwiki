---
id: source-matklad-do-not-optimize-away
title: matklad — Do Not Optimize Away
kind: source
status: captured
summary: Make benchmark inputs runtime-variable and consume a correctness witness so dead-code elimination, constant folding, and wrong optimizations become visible.
captured: 2026-09-04
revision: ff6734c93ac8b41677dee016af6bb67c39420101
url: https://matklad.github.io/2025/12/09/do-not-optimize-away.html
---

# matklad — Do Not Optimize Away

Pinned to the `matklad.github.io` repository commit recorded above. The essay's
benchmark rule is to make parameters runtime-overridable and externally consume
a result or digest, rather than relying only on an opaque compiler barrier.

Relevant page: [[trustworthy-microbenchmarks]].
