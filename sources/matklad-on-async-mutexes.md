---
id: source-matklad-on-async-mutexes
title: matklad — On Async Mutexes
kind: source
status: captured
summary: Distinguishes task-oriented concurrency from a serialized actor/state-machine event loop whose callbacks mutate shared state in discrete asserted steps.
captured: 2026-09-04
revision: ff6734c93ac8b41677dee016af6bb67c39420101
url: https://matklad.github.io/2025/11/04/on-async-mutexes.html
---

# matklad — On Async Mutexes

Pinned to the `matklad.github.io` repository commit recorded above. The essay
uses TigerBeetle callbacks to show that a single serialized dispatcher can be
the mutual-exclusion boundary for a state-machine/actor architecture. This is
not a blanket claim that single-threaded async code cannot have logical races.

Relevant page: [[task-lifetimes-and-structured-concurrency]].
