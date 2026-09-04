---
id: index
title: Zig LLM Wiki index
kind: map
status: draft
zig: "0.16.0"
summary: Retrieval map for current Zig systems programming, std.Io, TigerStyle, and platform I/O.
updated: 2026-09-04
sources: []
proofs: []
platforms:
  - cross-platform
---

# Zig LLM Wiki

Read this page first, then follow only the pages needed for the task.

## Current Zig

- [[zig-0.16-baseline]] — active version, evidence standard, and upgrade rule.
- [[std-io]] — the explicit I/O capability and implementation landscape.
- [[io-threaded]] — how the production Zig 0.16 implementation schedules and
  cancels blocking work.
- [[async-vs-concurrent]] — the scheduling distinction most likely to produce
  subtly wrong code.
- [[cancellation]] — request/acknowledgement, ownership, shutdown, and crash
  recovery boundaries.
- [[task-lifetimes-and-structured-concurrency]] — `Future`/`Group` ownership,
  state generations, serialized callbacks, and child processes.
- [[error-context]] — structured diagnostics without misreporting handled
  cancellation.
- [[error-handling-and-diagnostics]] — typed recovery codes, invariant failures,
  bounded diagnostic factories, and reporting boundaries.
- [[evented-io-backends]] — production readiness and the Linux/macOS/Windows
  research boundary.
- [[io-uring]] — Linux submission/completion ownership, finite rings, ordering,
  and cancellation races.
- [[macos-kqueue-and-aio]] — `kqueue` readiness versus POSIX asynchronous file
  completion, with descriptor and buffer ownership kept distinct.
- [[windows-iocp-and-overlapped-io]] — IOCP ordering and capacity, stable
  `OVERLAPPED` ownership, immediate success, and cancellation races.
- [[tigerbeetle-io]] — source-verified comparison of TigerBeetle's Linux
  `io_uring`, Darwin `kqueue`, and Windows IOCP backend choices.

## Engineering system

- [[tigerstyle]] — safety-first design principles and their integration seams
  with Zig 0.16.
- [[tigerstyle-coverage]] — complete rule inventory with covered, partial, and
  missing guidance made explicit.
- [[invariants-and-assertions]] — derive preserved properties, place assertions
  at transitions, and prove the positive and forbidden state space.
- [[code-reading-and-mechanical-checks]] — reconstruct whole-subsystem control
  flow and state, then turn stable findings into cheap repository checks.
- [[trustworthy-microbenchmarks]] — runtime-variable inputs, correctness
  witnesses, reproducibility, and one maintained test/build path.
- [[static-allocation-and-constant-work]] — limits, startup reservation,
  overload, and fixed-state transitions.
- [[newtype-indexes]] — compact typed handles for bounded collections.
- [[deterministic-simulation-testing]] — seeded virtual time, fault injection,
  assertions, and replay.
- [[tigerbeetle-engineering-corpus]] — curated TigerBeetle docs by reusable
  systems question and ingestion state.
- [[steering-zig-fmt]] — formatter controls that keep Zig code readable and
  canonical.

## Project operation

- [Agent contract](AGENTS.md) — schema plus query/ingest/lint/upgrade workflows.
- [Roadmap](ROADMAP.md) — persistent content, LLM, and backend work.
- [Curation ledger](CURATION.md) — source pipeline, selected corpus, and what
  has or has not reached synthesis.
- [[source-archaeology]] — revision-pinned code history and recovered design
  intent for agents maintaining guidance.
- [Maintenance log](log.md) — append-only history.
- [Obsidian-first decision](docs/decisions/0001-obsidian-first.md).
