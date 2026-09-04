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
  - "[[tigerbeetle-lsm]]"
  - "[[tigerbeetle-sync]]"
  - "[[tigerbeetle-vsr]]"
  - "[[tigerbeetle-storage-source]]"
  - "[[tigerbeetle-operations]]"
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
| Safety | What fault model spans callers, nodes, storage, software, and operators? | [[deterministic-simulation-testing]], with storage and operator boundaries in [[durable-storage-and-recovery]]. |
| Performance | How do interface design, batching, layout, and headroom dominate local tricks? | [[tigerstyle]], [[static-allocation-and-constant-work]] |
| VOPR | How can production code experience years of seeded faults and still replay exactly? | [[deterministic-simulation-testing]] |
| Data File | How do checksums, copy-on-write roots, replicas, and a WAL divide recovery responsibilities? | [[durable-storage-and-recovery]] separates layout, checkpoint authority, and unproved platform durability. |
| LSM and `src/lsm` | How are compaction work, output reservations, manifest nodes, and snapshot visibility bounded? | [[durable-storage-and-recovery]] records per-beat implementation reservations and fatal capacity-exhaustion seams. |
| Sync, VSR, and `src/vsr` | Who may replace recovery state, drain old I/O, reclaim blocks, and acknowledge replication? | [[durable-storage-and-recovery]] distinguishes quorums, lazy repair, cancellation completion, and retained promises. |
| Hardware, monitoring, and recovering | Which deployment assumptions and operator actions preserve the fault model? | [[durable-storage-and-recovery]] connects capacity/status signals to recovery authority; upstream policies remain scoped to the pin. |
| `src/io` | How can one caller-owned completion interface preserve platform-specific I/O truth? | [[tigerbeetle-io]], [[io-uring]], and [[evented-io-backends]] |

## Current boundary

The selected storage/recovery/operations slice is synthesized for one question:
what must a bounded durable service establish about allocation, storage layout,
recovery authority, compaction/sync ownership, and operational failures?
[[tigerbeetle-storage-source]] lists the implementation symbols inspected; this
is not an audit of every file under `src/vsr` or `src/lsm`.

The upstream engine was not built or run for this curation. Persistent
historical snapshot queries and reconfiguration are unimplemented in the
pinned design documents. Database power-loss/device qualification and a new
service's deterministic harness need their own experiments. They are explicit
transfer limits, not missing synthesis hidden behind a completed queue.

New sources enter [the curation ledger](../CURATION.md) only for a named
question. A new upstream revision gets a new immutable record.

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
[[tigerbeetle-io]], [[durable-storage-and-recovery]].
