---
id: source-matklad-diagnostics-factory
title: matklad — Diagnostics Factory
kind: source
status: captured
summary: Producer-oriented diagnostics API based on named constructor functions with independently replaceable streaming or captured representations.
captured: 2026-09-04
revision: ff6734c93ac8b41677dee016af6bb67c39420101
url: https://matklad.github.io/2026/02/16/diagnostics-factory.html
---

# matklad — Diagnostics Factory

Pinned to the `matklad.github.io` repository commit recorded above. Rather than
requiring producers to construct a large diagnostic sum type, named functions
accept facts already available at the failure site and hide whether diagnostics
are printed, captured, counted, formatted, or tested.

Relevant page: [[error-handling-and-diagnostics]].
