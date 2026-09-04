---
id: deterministic-simulation-testing
title: Deterministic simulation testing
kind: principle
status: source-verified
zig: "0.16.0"
summary: Put production logic behind deterministic clock, network, disk, and scheduler boundaries so seeded fault campaigns are fast, replayable, and assertion-rich.
updated: 2026-09-04
sources:
  - "[[tigerbeetle-vopr]]"
  - "[[tigerbeetle-architecture]]"
  - "[[tigerbeetle-safety]]"
  - "[[source-tigerstyle]]"
proofs: []
platforms:
  - cross-platform
---

# Deterministic simulation testing

## Remember

Deterministic simulation testing (DST) runs production logic with every source
of nondeterminism under a controlled environment. A failure is identified by at
least the seed, exact code revision, configuration, and harness version, so it
can be replayed locally rather than explained from a one-off timing trace.

TigerBeetle's VOPR replaces clock, network, and disk operations, accelerates
virtual time, injects network/storage/process faults, commits real workloads,
and checks both safety and liveness.

## Why it changes architecture

DST is not a test added after implementation. Time reads, randomness, I/O,
scheduling, and crash boundaries must be explicit inputs. Zig 0.16's explicit
`std.Io` capability is promising for this separation, but passing an `Io` alone
does not make a program deterministic: the chosen implementation and every
remaining nondeterministic dependency must be controlled.

Assertions turn randomized histories into precise counterexamples. External
checkers then validate properties too broad or expensive for a local assertion,
such as agreement between replicas. Keeping assertions enabled in production
also aligns tested invariants with deployed invariants.

## Harness requirements

- deterministic event ordering and pseudo-random generation;
- virtual monotonic and wall clocks with explicit advancement;
- modeled disk, network, process crash, restart, delay, loss, reorder, and
  corruption behaviors appropriate to the system's fault model;
- bounded workloads and termination/liveness criteria;
- positive state checkers and negative-space invariants;
- seed, revision, configuration, and event trace in every failure artifact;
- exact replay plus targeted regression tests for minimized failures.

## Limits

Simulation validates the implementation paths and assumptions represented by
the model. It does not prove unmodeled kernel semantics, hardware behavior, or
the simulator itself correct. Pair DST with focused real-platform tests,
property/fuzz testing, static analysis, and formal models where each provides
different evidence.

No Zig DST harness is proved in this repository yet. M1 must first inventory
`std.testing.io` and the failing/test `Io` implementations; a custom evented
backend and its deterministic model belong to M3/M4.

Related: [[tigerbeetle-engineering-corpus]], [[tigerstyle]], [[std-io]],
[[cancellation]].
