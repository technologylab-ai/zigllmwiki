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
- [[zig-0.16-release-inventory]] — every named 0.16 release-note topic routed
  to current guidance, a numbered roadmap item, a watch, or an explicit
  out-of-scope decision.
- [[zig-0.16-api-migration-traps]] — current replacements and ownership
  consequences for stale language, allocation, filesystem, build, diagnostic,
  path, reader/writer, and fuzzing examples.
- [[process-init-and-capabilities]] — use `std.process.Init` at the executable
  root and thread narrower I/O, allocation, configuration, and authority into
  components.
- [[std-io]] — the explicit I/O capability and implementation landscape.
- [[io-threaded]] — how the production Zig 0.16 implementation schedules and
  cancels blocking work.
- [[async-vs-concurrent]] — the scheduling distinction most likely to produce
  subtly wrong code.
- [[cancellation]] — request/acknowledgement, ownership, shutdown, and crash
  recovery boundaries.
- [[task-lifetimes-and-structured-concurrency]] — `Future`/`Group` ownership,
  state generations, serialized callbacks, and child processes.
- [[select-and-batch]] — typed task races, fixed low-level operation slots,
  completion identity, result draining, and cancellation-buffer traps.
- [[io-synchronization-primitives]] — `Event`, `Queue`, `Mutex`, `RwLock`,
  `Condition`, `Semaphore`, and futex cancellation/capacity rules.
- [[io-time-clocks-and-deadlines]] — clock domains, absolute deadlines,
  timeout conversion, cancelable sleep, and strict-clock application guards.
- [[bounded-retries-and-cleanup]] — transient classification, total-attempt
  and absolute-time bounds, ambiguous side effects, and ownership cleanup.
- [[files-buffering-and-atomic-persistence]] — bounded reads, buffered writer
  state, truncation, atomic namespace publication, and the directory-durability
  seam.
- [[networking-and-dns-racing]] — hostname lookup queues, connection racing,
  absolute deadlines, stream ownership, datagrams, and admission limits.
- [[child-process-lifecycles]] — bounded output capture, process deadlines,
  pipe ownership, termination tags, and wait/kill cleanup.
- [[entropy-and-deterministic-randomness]] — infallible process randomness,
  fallible fresh entropy, and deterministic replay boundaries.
- [[testing-io-and-single-threaded-builds]] — host-backed test I/O, the fixed
  hostile `Io.failing` profile, bounded stream adapters, and explicit
  single-threaded compilation.
- [[error-context]] — structured diagnostics without misreporting handled
  cancellation.
- [[error-handling-and-diagnostics]] — typed recovery codes, invariant failures,
  bounded diagnostic factories, and reporting boundaries.
- [[evented-io-backends]] — production readiness and the Linux/macOS/Windows
  research boundary.
- [[platform-io-backend-decision-table]] — select portable or platform-specific
  file/network backends by guarantees, limits, ownership, and evidence level.
- [[io-uring]] — Linux submission/completion ownership, finite rings, ordering,
  and cancellation races.
- [[macos-kqueue-and-aio]] — `kqueue` readiness, Dispatch I/O/POSIX AIO
  completion, exact Zig 0.16 backend gaps, and measured macOS evidence.
- [[windows-iocp-and-overlapped-io]] — IOCP ordering and capacity, stable
  `OVERLAPPED` ownership, immediate success, and cancellation races.
- [[tigerbeetle-io]] — source-verified comparison of TigerBeetle's Linux
  `io_uring`, Darwin `kqueue`, and Windows IOCP backend choices.

## Engineering system

- [[tigerstyle]] — safety-first design principles and their integration seams
  with Zig 0.16.
- [[tigerstyle-coverage]] — complete rule inventory with covered, partial, and
  missing guidance made explicit.
- [[tigerstyle-seams-with-zig-and-os]] — strict-core versus exception labels
  for `usize`, allocators, concurrency runtimes, and finite OS resources.
- [[design-revision-and-exception-policy]] — replaceable design sketches,
  zero-safety-debt boundaries, dependency admission, and owned exceptions.
- [[build-diagnostics-and-generated-code]] — exact Zig safety/diagnostic
  controls, foreign-source warnings, and reproducible machine-code review.
- [[error-path-catalogs-and-fault-injection]] — enumerate terminal failures,
  ownership, side effects, limits, observations, and deterministic injections.
- [[lower-dimensional-api-contracts]] — minimize caller state space without
  erasing absence, failure, cancellation, partial completion, or ownership.
- [[performance-sketches-and-batching]] — quantified network/disk/memory/CPU
  budgets, bounded control/data planes, batching, and a reproducible harness.
- [[naming-comments-and-api-shape]] — explicit TigerStyle/Zig naming seams,
  unit-bearing names, options structs, callback order, comments, and file shape.
- [[invariants-and-assertions]] — derive preserved properties, place assertions
  at transitions, and prove the positive and forbidden state space.
- [[function-shape-and-control-flow]] — inverse-hourglass functions,
  parent-owned policy/state, bounded leaf mechanics, and iterative traversal.
- [[code-reading-and-mechanical-checks]] — reconstruct whole-subsystem control
  flow and state, then turn stable findings into cheap repository checks.
- [[trustworthy-microbenchmarks]] — runtime-variable inputs, correctness
  witnesses, reproducibility, and one maintained test/build path.
- [[static-allocation-and-constant-work]] — limits, startup reservation,
  overload, and fixed-state transitions.
- [[newtype-indexes]] — compact typed handles for bounded collections.
- [[integer-widths-and-boundaries]] — domain widths, checked conversion and
  arithmetic, layout contracts, serialization, and stale-handle boundaries.
- [[state-scope-and-in-place-initialization]] — one authoritative state,
  short check/use gaps, const borrowing, final-address construction, and
  suspension-aware revalidation.
- [[buffer-hygiene-and-division-intent]] — complete observable-byte
  initialization, reusable-buffer clearing, explicit encoding, and named
  exact/floor/ceiling arithmetic.
- [[deterministic-simulation-testing]] — seeded virtual time, fault injection,
  assertions, and replay.
- [[tigerbeetle-engineering-corpus]] — curated TigerBeetle docs by reusable
  systems question and ingestion state.
- [[steering-zig-fmt]] — formatter controls that keep Zig code readable and
  canonical.

## Project operation

- [Agent contract](AGENTS.md) — schema plus query, ingest, lint, review, and
  upgrade workflows with explicit mutation boundaries.
- [Roadmap](ROADMAP.md) — persistent content, LLM, and backend work.
- [Session handoff](HANDOFF.md) — exact completion state, platform evidence,
  deliberate decisions, verification commands, and honest remaining gaps.
- [Platform testing runbook](docs/platform-testing.md) — exact macOS/Linux/
  Windows gates, evidence rules, hosted artifacts, and known portability traps.
- [Curation ledger](CURATION.md) — source pipeline, selected corpus, and what
  has or has not reached synthesis.
- [[source-archaeology]] — revision-pinned code history and recovered design
  intent for agents maintaining guidance.
- [Maintenance log](log.md) — append-only history.
- [Obsidian-first decision](docs/decisions/0001-obsidian-first.md).
- [Semantic lint procedure](tools/semantic_lint.md) and
  [latest report](reports/2026-09-04-semantic-lint.md) — repeatable agent audit
  plus reviewable findings.
- [Generated-code inspector](tools/inspect_generated_code.py) — exact-version,
  source-hashed assembly evidence for focused exported symbols.
- [Read-only source/release review](tools/wiki.py) and
  [weekly workflow](.github/workflows/wiki-review.yml) — coarse change signals,
  exact-baseline verification, and an out-of-tree review packet.
- [Retrieval benchmark](reports/2026-09-04-retrieval-benchmark.md) — 25 reviewed
  queries currently support keeping deterministic lexical retrieval.
