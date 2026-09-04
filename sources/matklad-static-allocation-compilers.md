---
id: source-matklad-static-allocation-compilers
title: matklad — Static Allocation for Compilers
kind: source
status: captured
summary: Explore bounded intermediate state over finite chunks while separating potentially unbounded immutable output into another storage domain.
captured: 2026-09-04
revision: ff6734c93ac8b41677dee016af6bb67c39420101
url: https://github.com/matklad/matklad.github.io/blob/ff6734c93ac8b41677dee016af6bb67c39420101/content/posts/2025-12-23-static-allocation-compilers.dj
---

# matklad — Static Allocation for Compilers

Pinned to the `matklad.github.io` repository commit recorded above. The essay
distinguishes startup-sized intermediate processing state from output whose
total size follows the input. It proposes processing finite chunks with
bounded scratch space while accumulating immutable output separately, and
observes that indexes make relocation and persistence easier than pointers.

This is an exploratory architecture argument, not measured evidence that every
compiler—or arbitrary stream processor—can use constant working memory.

Relevant pages: [[static-allocation-and-constant-work]],
[[integer-widths-and-boundaries]], and [[newtype-indexes]].
