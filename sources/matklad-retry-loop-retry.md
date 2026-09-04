---
id: source-matklad-retry-loop-retry
title: matklad — Retry Loop Retry
kind: source
status: captured
summary: Refine retry control flow around a guaranteed first attempt while restoring an explicit maximum-iteration assertion.
captured: 2026-09-04
revision: ff6734c93ac8b41677dee016af6bb67c39420101
url: https://github.com/matklad/matklad.github.io/blob/ff6734c93ac8b41677dee016af6bb67c39420101/content/posts/2025-08-23-retry-loop-retry.dj
---

# matklad — Retry Loop Retry

Pinned to the `matklad.github.io` repository commit recorded above. The essay
revisits loop-and-a-half retry control: one attempt must occur even when the
retry count is zero, transient errors alone continue, no sleep follows the last
attempt, and an explicit maximum iteration restores a visible safety bound.

The wiki names `attempt_limit` as total attempts rather than overloading
“retries,” removing the zero-retry ambiguity. See
[[bounded-retries-and-cleanup]].
