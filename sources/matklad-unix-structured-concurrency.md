---
id: source-matklad-unix-structured-concurrency
title: matklad — UNIX Structured Concurrency
kind: source
status: captured
summary: Cooperative child-process lifetime pattern using stdin EOF, together with its abrupt-parent-death and portability limitations.
captured: 2026-09-04
revision: ff6734c93ac8b41677dee016af6bb67c39420101
url: https://matklad.github.io/2023/10/11/unix-structured-concurrency.html
---

# matklad — UNIX Structured Concurrency

Pinned to the `matklad.github.io` repository commit recorded above. The essay
proposes a child watching stdin EOF as a pragmatic lifetime signal, then
carefully explains why it is cooperative and not truly structured. Its 2026
update points to direct parent-exit mechanisms on Linux and macOS; those need
their own primary OS evidence before this wiki recommends an implementation.

Relevant page: [[task-lifetimes-and-structured-concurrency]].
