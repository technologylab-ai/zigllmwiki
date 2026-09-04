---
id: source-matklad-strictly-monotonic-time
title: matklad — Considering Strictly Monotonic Time
kind: source
status: captured
summary: Design note on adding an application-owned guard when unique, strictly increasing time samples are more useful than a clock's non-decreasing guarantee.
captured: 2026-09-04
revision: ff6734c93ac8b41677dee016af6bb67c39420101
url: https://matklad.github.io/2026/01/23/strictly-monotonic-time.html
---

# matklad — Considering Strictly Monotonic Time

Pinned to the `matklad.github.io` repository commit recorded above. The essay
distinguishes a monotonic clock's non-decreasing guarantee from a process-local
strictly increasing abstraction. It proposes clamping each raw observation
above a retained guard so equal values identify the same observation and
callers can assert strict ordering.

This is a design pattern, not a claim about Zig's clocks. Zig 0.16 explicitly
allows consecutive observations of its monotonic clocks to be equal. A shared
strict guard also needs synchronization, overflow policy, and enough value
resolution that repeated increments do not create unacceptable drift.

Relevant pages: [[io-time-clocks-and-deadlines]] and
[[bounded-retries-and-cleanup]].
