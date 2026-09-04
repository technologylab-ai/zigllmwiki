---
id: zig-0-16-baseline
title: Zig 0.16 baseline
kind: concept
status: source-verified
zig: "0.16.0"
summary: All active guidance and executable examples target the exact stable compiler recorded in .zig-version.
updated: 2026-09-04
sources:
  - "[[zig-0.16.0-release-notes]]"
  - "[[zig-0.16.0-stdlib]]"
  - "[[fi-zig-0.16-migration]]"
proofs: []
platforms:
  - cross-platform
---

# Zig 0.16 baseline

## Remember

The active target is the exact version in `.zig-version`: currently Zig
0.16.0. The official downloads index lists 0.16.0 as the stable release and
0.17.0-dev as master. This wiki targets stable 0.16.x, not master.

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
