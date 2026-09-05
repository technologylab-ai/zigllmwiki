---
id: deterministic-simulation-testing
title: Deterministic simulation testing
kind: principle
status: source-verified
zig: "0.16.0"
summary: Put production logic behind deterministic clock, network, disk, and scheduler boundaries so seeded fault campaigns are fast, replayable, and assertion-rich.
updated: 2026-09-05
sources:
  - "[[tigerbeetle-vopr]]"
  - "[[tigerbeetle-architecture]]"
  - "[[tigerbeetle-safety]]"
  - "[[source-tigerstyle]]"
  - "[[tigerbeetle-sync]]"
  - "[[tigerbeetle-storage-source]]"
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

## Derive storage faults from ownership boundaries

[[durable-storage-and-recovery]] supplies concrete targets from TigerBeetle's
pinned sync and storage implementation: delay completion past a sync request,
crash between root publication and lazy repair completion, return a valid
block with an unexpected identity, and exhaust compaction or manifest
capacity. The sync design also describes a crash that needs a block already
used and released during repair, which is why its unfinished-sync marker
survives until a later checkpoint. [[tigerbeetle-sync]],
[[tigerbeetle-storage-source]]

For a new service, make these proposed fault cases deterministic before
claiming recovery coverage. Check both the durable state selected after
restart and the lifetime of operations still accessing the old state. These
are harness design recommendations; no such storage campaign ran in this wiki.

## Limits

Simulation validates the implementation paths and assumptions represented by
the model. It does not prove unmodeled kernel semantics, hardware behavior, or
the simulator itself correct. Pair DST with focused real-platform tests,
property/fuzz testing, static analysis, and formal models where each provides
different evidence.

No custom Zig DST harness is proved in this repository yet. The completed
[[testing-io-and-single-threaded-builds]] inventory distinguishes host-backed
`std.testing.io` from the fixed hostile `Io.failing` profile; neither is a
deterministic disk/network scheduler. An application-specific harness belongs
with the separate M4 synthesis project.

Related: [[tigerbeetle-engineering-corpus]], [[tigerstyle]], [[std-io]],
[[cancellation]], [[durable-storage-and-recovery]],
[[testing-io-and-single-threaded-builds]].

Design application: [[bounded-http-server-design]] proposes fixed worker
execution, explicit buffer borrows and replayable HTTP state transitions;
these remain design notes without an implemented HTTP simulation or server.
