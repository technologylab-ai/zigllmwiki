---
id: tigerbeetle-engineering-corpus
title: TigerBeetle engineering corpus
kind: map
status: source-verified
zig: "n/a"
summary: Curated map from TigerBeetle documentation to reusable systems-engineering questions, current syntheses, and the next evidence needed.
updated: 2026-09-04
sources:
  - "[[source-tigerstyle]]"
  - "[[tigerbeetle-architecture]]"
  - "[[tigerbeetle-safety]]"
  - "[[tigerbeetle-performance]]"
  - "[[tigerbeetle-vopr]]"
  - "[[tigerbeetle-data-file]]"
  - "[[tigerbeetle-io-source]]"
proofs: []
platforms:
  - cross-platform
---

# TigerBeetle engineering corpus

## Remember

TigerBeetle's documentation is useful because it connects principles to a real
system, not because every database choice should be copied. Use each document
to answer a concrete design question, then verify Zig APIs and OS behavior with
their own primary sources.

## Integrated in this pass

| Source | Reusable question | Current synthesis |
| --- | --- | --- |
| TigerStyle | Which constraints make safety, performance, and operability reinforce one another? | [[tigerstyle]] |
| Architecture | How do limits, ownership, batching, determinism, concurrency, and I/O compose as one design? | [[static-allocation-and-constant-work]], [[deterministic-simulation-testing]], [[evented-io-backends]] |
| Safety | What fault model spans callers, nodes, storage, software, and operators? | [[deterministic-simulation-testing]]; broader fault-model page is next. |
| Performance | How do interface design, batching, layout, and headroom dominate local tricks? | [[tigerstyle]], [[static-allocation-and-constant-work]] |
| VOPR | How can production code experience years of seeded faults and still replay exactly? | [[deterministic-simulation-testing]] |
| Data File | How do checksums, copy-on-write roots, replicas, and a WAL divide recovery responsibilities? | Captured; storage synthesis is deliberately pending OS and source-code evidence. |
| `src/io` | How can one caller-owned completion interface preserve platform-specific I/O truth? | [[tigerbeetle-io]], [[io-uring]], and [[evented-io-backends]] |

## Selected next

These pinned-repository paths are selected, not yet synthesized:

- `docs/internals/lsm.md` — bounded compaction, manifest invariants, snapshots,
  and background-work scheduling.
- `docs/internals/sync.md` — state-transfer triggers, cancellation boundaries,
  storage determinism, and recovery ownership.
- `docs/internals/vsr.md` — protocol state machines, quorums, repair, and
  message-driven concurrency.
- `docs/operating/hardware.md`, `monitoring.md`, and `recovering.md` — the
  operational half of limits, direct I/O assumptions, signals, and recovery.
- implementation under `src/vsr/` and `src/lsm/` — exact operation ownership,
  intrusive queues, state machines, storage limits, and recovery.

The source files are pinned by commit in [the curation ledger](../CURATION.md).
They become guidance only after a source record and focused synthesis land.

## Transfer test

Before carrying a TigerBeetle technique into another project, answer:

- Which workload and fault-model assumption makes it appropriate?
- Is it an interface guarantee, an implementation detail, or an operational
  policy?
- Which explicit limit and owner make it safe under overload and cancellation?
- Does it depend on Linux, direct I/O, `io_uring`, fixed-size records, trusted
  inputs, or replication?
- What proof or measurement would falsify the proposed transfer?

Related: [[tigerstyle]], [[static-allocation-and-constant-work]],
[[deterministic-simulation-testing]], [[evented-io-backends]],
[[tigerbeetle-io]].
