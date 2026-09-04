---
id: source-tigerbeetle-storage-source
title: TigerBeetle bounded storage and recovery implementation
kind: source
status: captured
summary: Exact implementation evidence for compaction resource ownership, finite reservations, delayed block reuse, superblock quorums, and draining state-sync cancellation.
captured: 2026-09-04
revision: 47aeb2212a255273dda508288412e537d11e4b7c
url: https://github.com/tigerbeetle/tigerbeetle/tree/47aeb2212a255273dda508288412e537d11e4b7c/src
---

# TigerBeetle bounded storage and recovery implementation

The inspected checkout was clean at the exact commit above. This is a focused
reading of the symbols below, not an audit of every file under `src/vsr` or
`src/lsm`. All paths are relative to this immutable revision.

| Path / symbol | Evidence boundary |
| --- | --- |
| `src/config.zig`, cluster defaults; `src/constants.zig`, storage/compaction constants | Default 512 KiB blocks, four superblock copies, seven LSM levels, growth factor eight, and 32 operations per compaction bar are configuration facts. |
| `src/vsr/superblock.zig`, `SuperBlockHeader`, `read_working`; `superblock_quorums.zig`, `Threshold.count`, `working` | For four copies, startup requires two matching valid copies; writes are read back with a threshold of three. Copy identity, ancestry, and monotonic VSR state constrain selection. |
| `src/vsr/free_set.zig`, `reserve`, `forfeit`, `acquire`, `release`, `mark_checkpoint_durable` | Exclusive finite reservations, exactly one forfeit, and delayed reuse of released addresses until recovery and checkpoint-durability constraints permit it. |
| `src/vsr/grid.zig`, `reserve`, `cancel`, `cancel_join_callback`, `read_block_validate` | Reservation exhaustion is fatal; cancellation clears queued work and waits for zero executing reads/writes; validation checks both the block and expected identity. |
| `src/vsr/replica.zig`, `sync_start_from_committing`, `sync_dispatch`, `sync_cancel_grid_callback`, `sync_superblock_update_start` | Uninterruptible commit stages finish before grid cancellation; reference cleanup precedes state reset and checkpoint installation. |
| `src/lsm/forest.zig`, `compact`, `compact_trees_start`, `compact_trees_reserve_grid_blocks`, `compact_trees_resume`, `compact_finish`, `checkpoint` | Half-bar input quotas are divided into beats; output reservations are per beat; the shared pool owns asynchronous compaction work and the forest joins manifest/tree progress. |
| `src/lsm/compaction.zig`, `ResourcePool`, `compaction_dispatch_enter`, `beat_complete` | Fixed block states and I/O slots govern ownership; blocks can remain retained between beats. |
| `src/lsm/node_pool.zig`, `init`, `acquire`, `release`, `deinit` | Startup allocation, finite manifest nodes, fatal exhaustion, and all-nodes-returned teardown assertion. |

The upstream implementation was not compiled or run for this ingest. Its Zig
syntax is source material only; it does not implement the wiki's Zig 0.16
`std.Io` interface. Useful facts are synthesized in
[[durable-storage-and-recovery]], with documentation/implementation seams
identified rather than silently reconciled.
