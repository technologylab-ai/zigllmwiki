---
id: design-revision-and-exception-policy
title: Design revision, dependencies, and exception policy
kind: principle
status: source-verified
zig: "n/a"
summary: Revise a bounded design before implementation, reject known safety debt, and admit dependencies or tooling exceptions only through an owned evidence-backed record.
updated: 2026-09-04
sources:
  - "[[source-tigerstyle]]"
proofs: []
platforms:
  - cross-platform
---

# Design revision, dependencies, and exception policy

## Remember

“Simple” describes the result of disciplined revision, not the first sketch.
Before implementation, make ownership, states, bounds, failure behavior, and
resource arithmetic reviewable. A design that cannot name these is not yet
simple enough to implement safely.

TigerStyle's zero-technical-debt stance is strict: do not knowingly ship a
correctness or safety violation on the promise of repairing it later. Missing
features are acceptable when the supported surface is honest. Known defects in
the supported surface are release blockers.

## Start with a one-page design sketch

Keep the sketch short enough to replace. It must still answer every row:

| Area | Required decision |
| --- | --- |
| Goals | Safety, performance, then developer experience; define success and explicit non-goals. |
| Workload | Arrival rates, request and batch sizes, concurrency, and overload shape. |
| Fault model | Invalid input, resource exhaustion, timeout, cancellation, partial effects, crash, and recovery. |
| Trust boundaries | What is checked on entry, persisted, transmitted, and checked independently on return. |
| State | Owner, valid states, transitions, generations, and terminal cleanup. |
| Limits | Count, byte, time, attempt, queue, descriptor, task, and memory maxima. |
| Allocation | Startup reservation, steady-state reuse, and every dependency allocation seam. |
| I/O | Interface versus backend guarantees, platform differences, and completion ownership. |
| Performance | Network, disk, memory, and CPU bandwidth plus latency arithmetic. |
| API | Information each caller must act on; information the callee can keep private. |
| Evidence | Assertions, negative tests, fault injections, generated-code checks, and measurements that could falsify the design. |

Link the accepted sketch from implementation and preserve why each surprising
choice exists. A diagram is useful only when it clarifies ownership, state, or
sequence; decorative architecture boxes are not evidence.

## Revise in explicit passes

1. Trace the success state machine and ownership transfers.
2. Add every operational and corrupt-input terminal path.
3. Put finite capacity and time bounds before resource acquisition.
4. Calculate memory and the four performance resources.
5. Remove duplicate state, aliases, unnecessary result variants, and policy
   from mechanical leaf functions.
6. Challenge the platform and dependency assumptions with primary evidence.
7. Name the assertions, fault cases, and measurements that can disprove the
   sketch.

At least one revision should try a materially different ownership or batching
shape. Record why it lost. Iterating only on names inside one architecture is
not the “hardest revision” TigerStyle calls simplicity.

## Exception and technical-debt policy

Classify an issue before accepting work:

- **release blocker:** a known violation of correctness, safety, durability, or
  the documented supported contract; it cannot receive an exception;
- **bounded design exception:** a consciously non-strict seam, isolated from
  the strict core and prevented from silently widening;
- **feature gap:** behavior not promised by the supported surface, with no false
  compatibility claim;
- **investigation:** an unresolved question that blocks the affected claim from
  becoming verified guidance.

Every bounded exception needs a durable record with an ID, owner, date, exact
boundary, violated rule, rationale, alternatives rejected, maximum exposure,
detection and test, removal condition, and next review trigger. Its callers
must not claim strict TigerStyle conformance. Expiry without removal is a new
review decision, never an automatic extension.

## Dependency acceptance gate

“Zero dependencies” is TigerBeetle's project policy, not an evidence-free rule
for every Zig project. Before accepting a dependency, require:

- a necessary capability and documented standard-library or in-house
  alternatives;
- an immutable version, integrity mechanism, license, maintainer and release
  history, and complete transitive dependency inventory;
- security and trust-boundary review, including build scripts and generated
  artifacts;
- allocation, blocking, cancellation, thread, descriptor, queue, and failure
  behavior compatible with local limits;
- target-platform, toolchain, installation, cross-compilation, and deterministic
  build evidence;
- a benchmark or resource sketch when it enters a hot or high-frequency path;
- an isolation adapter, upgrade cadence, rollback/fork plan, and removal cost;
- tests that exercise the adapter's success, error, overload, and shutdown
  contract.

Reject the dependency when its behavior cannot be bounded or its ownership and
failure contract cannot be determined. Convenience alone does not offset an
unknown production boundary.

## This wiki's deliberate Python/Zig seam

This repository has one explicit tooling deviation from TigerBeetle's
Zig-primary preference. Zig 0.16 owns build orchestration, executable proofs,
target compilation, and runtime claims. Python 3.10 or newer, using only its
standard library, owns Markdown parsing, graph analysis, source hashes, command
reports, and generated-text inspection under `tools/`.

The seam is accepted because these Python programs are development-time content
tools, not examples of Zig runtime behavior or code linked into a shipped
system. `zig build verify` remains the obvious entry point and invokes the
Python lint, so the extra dependency is visible in CI rather than tribal setup.

Treat this as exception `TOOL-001`, owned by the repository maintainers. Review
it if Python enters a target artifact, gains third-party packages, interprets
Zig semantics, produces trusted evidence without independent checking, or
causes cross-platform installation failures. In any of those cases, narrow the
seam or migrate the affected check to Zig.

## What commonly goes wrong

- Calling a first draft “simple” while queues, cancellation, and overload are
  still implicit.
- Renaming a known safety defect an exception so a date can ship.
- Recording an exception without a detection mechanism or removal trigger.
- Counting only direct dependencies while build tools execute transitive code.
- Migrating a small text check to Zig for ideological purity without measuring
  whether that actually reduces operational dimensions.

## Review evidence

The design and zero-debt rules come from [[source-tigerstyle]]. The exception
taxonomy, acceptance gate, and `TOOL-001` are this repository's explicit policy
for applying those rules; they are not claims about TigerBeetle's own process.

Related: [[tigerstyle]], [[tigerstyle-coverage]],
[[static-allocation-and-constant-work]], [[performance-sketches-and-batching]],
[[source-archaeology]], [[code-reading-and-mechanical-checks]],
[[error-path-catalogs-and-fault-injection]],
[[lower-dimensional-api-contracts]].
