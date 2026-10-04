---
id: zig-0-16-baseline
title: Zig 0.16 baseline
kind: concept
status: superseded
zig: "n/a"
summary: Preserve the previous 0.16 baseline and route current guidance to exact Zig 0.17.0.
updated: 2026-10-04
sources:
  - "[[zig-0.16.0-release-notes]]"
  - "[[zig-0.16.0-stdlib]]"
  - "[[fi-zig-0.16-migration]]"
proofs: []
platforms:
  - cross-platform
---

# Zig 0.16 baseline

This page preserves the dated 0.16 migration context.
Current guidance targets [[zig-0.17-baseline]] and [[zig-0.17-upgrade-assessment]].
Do not use this historical map as the current API reference.

## Remember

Zig 0.16.0 was the active target before the explicit upgrade on 2026-10-04.
The current target is [[zig-0.17-baseline]].
See [[zig-0.17-upgrade-assessment]] for project migration findings and their evidence limits.

Old material is useful only as source evidence. Before an older technique
becomes guidance, port it to the active release, place runnable code in
`proofs/`, and compile it with `zig build verify`.

## Evidence order

For Zig APIs, prefer the installed source matching `.zig-version`, then official
versioned documentation and release notes. The [[fi-zig-0.16-migration]] guide
is valuable real-project evidence and explicitly records corrections to
plausible but wrong migration advice.

## Upgrade rule

A new release does not become active because a source watcher noticed it. An
explicit upgrade run must change `.zig-version`, inventory every page and proof,
recompile, migrate useful examples, invalidate stale verification statuses, and
record remaining gaps in `log.md`.

See [[std-io]] for the defining 0.16 library change.
Use [[zig-0.16-release-inventory]] to route every named release-note topic to
current guidance, planned work, an upgrade watch, or an explicit scope decision.
Use [[zig-0.16-api-migration-traps]] when repairing a stale pre-0.16 code shape.
