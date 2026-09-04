---
id: source-matklad-cancelation-terminology
title: matklad — Cancelation Terminology
kind: source
status: captured
summary: Design vocabulary separating stack unwinding, request-and-acknowledgement cancellation, graceful shutdown, and crash recovery.
captured: 2026-09-04
revision: ff6734c93ac8b41677dee016af6bb67c39420101
url: https://matklad.github.io/2026/08/31/cancelation-terminology.html
---

# matklad — Cancelation Terminology

Pinned to the `matklad.github.io` repository commit recorded above. The essay
calls ordinary error unwinding synchronous cancelation, calls cancellation of
in-flight concurrent work an asynchronous request/acknowledgement protocol, and
keeps both distinct from application-level graceful shutdown and crash safety.

Its TigerBeetle examples show why asynchronous cancellation should be confined
to the lowest layer that actually owns in-flight work when upper layers can be
reset synchronously.

Relevant pages: [[cancellation]], [[io-threaded]], [[evented-io-backends]].
