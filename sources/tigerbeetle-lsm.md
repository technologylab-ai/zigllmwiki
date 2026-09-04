---
id: source-tigerbeetle-lsm
title: TigerBeetle LSM design
kind: source
status: captured
summary: Pinned LSM design for bounded tables, incremental compaction, snapshot visibility, and manifest ownership.
captured: 2026-09-04
revision: 47aeb2212a255273dda508288412e537d11e4b7c
url: https://github.com/tigerbeetle/tigerbeetle/blob/47aeb2212a255273dda508288412e537d11e4b7c/docs/internals/lsm.md
---

# TigerBeetle LSM design

Read completely at the pinned revision. Relevant sections are Tables,
Compaction, Snapshots and Compaction, and Manifest. This is design evidence,
not a Zig 0.16 API example or an independently measured latency bound.

The document describes half-bar block reservations and per-level concurrent
compactions. The implementation at the same revision has a forest-wide byte
quota, a shared resource pool, and per-beat output reservations; use
[[tigerbeetle-storage-source]] for that scheduling detail. Persistent snapshot
queries remain explicitly unimplemented in this design document. Resolve its
embedded moving `main` source links at the pinned revision above.

Relevant page: [[durable-storage-and-recovery]].
