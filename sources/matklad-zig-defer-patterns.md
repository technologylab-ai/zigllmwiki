---
id: source-matklad-zig-defer-patterns
title: matklad — Zig defer Patterns
kind: source
status: captured
summary: Show defer as a tool for postconditions, compile-time exclusion of later error paths, grouped resource lifetimes, contextual reporting, and delayed state increments.
captured: 2026-09-04
revision: ff6734c93ac8b41677dee016af6bb67c39420101
url: https://github.com/matklad/matklad.github.io/blob/ff6734c93ac8b41677dee016af6bb67c39420101/content/posts/2024-03-21-defer-patterns.dj
---

# matklad — Zig defer Patterns

Pinned to the `matklad.github.io` repository commit recorded above. The essay
explores `defer` beyond one-resource-per-object RAII: asserting postconditions,
using `errdefer comptime unreachable` after the last fallible phase, attaching
local error reports, and committing a state increment at scope exit.

These are sharp patterns, not universal prescriptions. Current guidance keeps
ownership transfer explicit and reports an operational error once at the
owning boundary; see [[bounded-retries-and-cleanup]] and [[error-context]].
