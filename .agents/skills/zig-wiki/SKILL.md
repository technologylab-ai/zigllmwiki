---
name: zig-wiki
description: Consult, ingest, lint, maintain, or upgrade the source-driven Zig 0.16 systems-programming wiki in this repository. Use for std.Io, concurrency, TigerStyle, platform I/O, or wiki health work; do not use as a generic Zig coding skill when the repository wiki is not involved.
---

# Zig Wiki

Operate the repository as a persistent knowledge compiler: pinned sources go in,
cross-linked agent-oriented guidance comes out, and executable claims stay
coupled to proofs.

Before acting, read the repository's `AGENTS.md`, `.zig-version`, and `index.md`.
Read `ROADMAP.md` when maintaining content or planning an upgrade. Those files
are authoritative for schema, evidence order, status, and scope.

Choose the operation from the request:

- **Consult:** search the index and vault, open the smallest relevant page set
  plus its evidence, and answer with exact Zig/backend/platform scope. Do not
  change files unless asked to preserve the result.
- **Ingest:** pin the source, create a source record, refactor affected pages,
  add runnable proofs for code claims, refresh the index, append the log, and
  run `zig build verify`.
- **Lint:** run deterministic verification, then inspect contradictions,
  outdated backend assumptions, unsupported platform claims, missing links,
  missing limits/cancellation/allocation analysis, and roadmap drift.
- **Upgrade:** follow the release-upgrade operation in `AGENTS.md`; preserve old
  evidence, invalidate claims before re-verifying them, and report every gap.

Prefer editing an existing page over adding a near-duplicate. Keep source facts,
inferences, measurements, and recommendations visibly distinct. Never turn
`std.Io` into shorthand for evented I/O or `async` into shorthand for guaranteed
concurrency.

Finish mutating operations only after `zig build verify` succeeds. Report the
active Zig version, affected pages, evidence added, and unresolved questions.
