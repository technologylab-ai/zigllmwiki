---
id: source-tigerbeetle-sync
title: TigerBeetle state synchronization
kind: source
status: captured
summary: Pinned state-transfer design covering durable checkpoint authority, commit interruption, lazy block repair, and crash-safe sync completion.
captured: 2026-09-04
revision: 47aeb2212a255273dda508288412e537d11e4b7c
url: https://github.com/tigerbeetle/tigerbeetle/blob/47aeb2212a255273dda508288412e537d11e4b7c/docs/internals/sync.md
---

# TigerBeetle state synchronization

Read completely at the pinned revision. Algorithm, Scenarios, Conclusion,
Syncing Replica, Checkpoint Identifier, and Storage Determinism establish the
questions that must be answered before replacing a replica's recovery state.

Distinguish checkpoint installation from completion of all physical repair.
The document's cancellation description is narrowed by `Grid.cancel` and the
replica sync state machine in [[tigerbeetle-storage-source]]: submitted grid
I/O drains before the cancellation callback; logical queued work is discarded.
This is not a contract for Zig 0.16 `std.Io` or kernel cancellation.

Relevant pages: [[durable-storage-and-recovery]],
[[deterministic-simulation-testing]].
