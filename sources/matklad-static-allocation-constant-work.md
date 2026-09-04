---
id: source-matklad-static-allocation-constant-work
title: matklad — Static Allocation, Constant Work
kind: source
status: captured
summary: Design essay connecting startup-sized pools, explicit overload rejection, conserved state, assertions, and load-independent work.
captured: 2026-09-04
revision: ff6734c93ac8b41677dee016af6bb67c39420101
url: https://matklad.github.io/2026/09/02/static-allocation-constant-work.html
---

# matklad — Static Allocation, Constant Work

Pinned to the `matklad.github.io` repository commit recorded above. The essay
derives two related tools from TigerStyle: allocate a declared maximum during
startup and represent spare capacity as explicit neutral state so that state
transitions and maximum-load work stay visible.

Treat the “constant work” technique as a workload-specific design option, not a
universal rule or a substitute for measurement.

Relevant pages: [[static-allocation-and-constant-work]], [[tigerstyle]].
