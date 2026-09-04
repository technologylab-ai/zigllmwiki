---
id: source-matklad-zig-language-server-cancellation
title: matklad — Zig Language Server and Cancellation
kind: source
status: captured
summary: Design exploration of cancellation, immutable snapshots, consistency contracts, and bounded state generations in an interactive concurrent service.
captured: 2026-09-04
revision: ff6734c93ac8b41677dee016af6bb67c39420101
url: https://matklad.github.io/2023/05/06/zig-language-server-and-cancellation.html
---

# matklad — Zig Language Server and Cancellation

Pinned to the `matklad.github.io` repository commit recorded above. This is a
design source, not guidance for current Zig language-server internals. Its
lasting value is the comparison between sequential completion, immutable
snapshots, cancel-before-mutate, and a bounded ready/working/pending state model.

Relevant pages: [[task-lifetimes-and-structured-concurrency]],
[[cancellation]].
