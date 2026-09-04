---
id: source-matklad-memory-safety-hardest-problem
title: matklad — Memory Safety's Hardest Problem
kind: source
status: captured
summary: A pointer into one tagged-union variant can outlive an overwrite of that storage and become a type-confused view of another variant.
captured: 2026-09-04
revision: ff6734c93ac8b41677dee016af6bb67c39420101
url: https://github.com/matklad/matklad.github.io/blob/ff6734c93ac8b41677dee016af6bb67c39420101/content/posts/2026-07-20-memory-safety-hardest-problem.dj
---

# matklad — Memory Safety's Hardest Problem

Pinned to the `matklad.github.io` repository commit recorded above. The source
demonstrates that memory safety is also a storage-lifetime and representation
problem: a pointer into an active tagged-union payload can remain typed after
the containing union is overwritten with another variant.

The wiki uses the example to motivate stable ownership and validated handles;
it does not claim that indexes alone prevent use-after-reuse or type confusion.

Relevant pages: [[newtype-indexes]], [[integer-widths-and-boundaries]].
