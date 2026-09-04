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

Use the repository command layer before manual work:

- `python3 tools/wiki.py query TERMS... --format json` returns a deterministic,
  read-only ranking with each page's Zig/platform scope, sources, and proofs.
- `python3 tools/wiki.py ingest SOURCE --revision REVISION --format json`
  screens obvious moving names, reports a revision-syntax assessment, and emits
  a read-only ingest plan. It does not verify a remote revision's immutability.
  For local files it computes and checks SHA-256. It never creates or rewrites
  a record.
- `python3 tools/wiki.py lint --format json` runs `zig build verify` and emits
  versioned machine-readable issues. Use `--deterministic-only` only for focused
  structural diagnosis when proof execution is intentionally deferred.
- `python3 tools/wiki.py upgrade VERSION --format json` inventories pages,
  proofs, and source records but never changes `.zig-version`. Pass
  `--compiler /exact/path/to/zig` to confirm the target compiler before edits.
- `python3 tools/wiki.py review --format json` performs a bounded read-only
  network check for coarse upstream-head differences and newer Zig releases.
  Treat every finding as an inspection prompt, never as rewrite authorization.
- `python3 tools/retrieval_benchmark.py --enforce-policy` protects the reviewed
  lexical-query regression set. Its result is not production relevance data.

The JSON field `mutates_repository` is the command boundary, not authorization
to skip the full agent workflow. `ingest` and `upgrade` are plan-only because a
deterministic wrapper cannot establish semantic correctness or platform runtime
evidence. Apply their plans as reviewable edits under `AGENTS.md`.

Prefer editing an existing page over adding a near-duplicate. Keep source facts,
inferences, measurements, and recommendations visibly distinct. Never turn
`std.Io` into shorthand for evented I/O or `async` into shorthand for guaranteed
concurrency.

Finish mutating operations only after `zig build verify` succeeds. Report the
active Zig version, affected pages, evidence added, and unresolved questions.
