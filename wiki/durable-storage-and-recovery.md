---
id: durable-storage-and-recovery
title: Durable storage, bounded compaction, and recovery authority
kind: pattern
status: source-verified
zig: "n/a"
summary: Separate storage capacity, checkpoint publication, replication authority, block reuse, and cancellation before adapting TigerBeetle's durable-service design.
updated: 2026-09-04
sources:
  - "[[tigerbeetle-data-file]]"
  - "[[tigerbeetle-lsm]]"
  - "[[tigerbeetle-sync]]"
  - "[[tigerbeetle-vsr]]"
  - "[[tigerbeetle-storage-source]]"
  - "[[tigerbeetle-operations]]"
  - "[[tigerbeetle-architecture]]"
proofs: []
platforms:
  - cross-platform
---

# Durable storage, bounded compaction, and recovery authority

## Remember

A durable service needs an authority for deciding which state survives a
restart, a limit on the resources needed to reach that state, and an owner for
every operation still touching the old state. A checksum, a WAL, copy-on-write,
and replication solve different parts of that problem.

The example here is TigerBeetle at
`47aeb2212a255273dda508288412e537d11e4b7c`. These are source-verified design and
implementation facts, followed by explicitly labeled transfer recommendations.
They are not a port, a Zig 0.16 `std.Io` contract, or new runtime durability
evidence. [[tigerbeetle-storage-source]]

## Which layer decides what

| Layer | TigerBeetle's responsibility | Limit on the inference |
| --- | --- | --- |
| Grid and block references | Store fixed-size blocks; verify a block against the address/checksum expected by its parent. | A self-consistent block can still be the wrong block. Checksums detect a mismatch; an authoritative root or peer is needed to repair it. |
| Manifest and superblock | Describe reachable tables and the recovery checkpoint; retain local protocol state across restart. | The largest sequence number found on disk is not sufficient evidence of a valid root. |
| WAL and VSR | Retain the operations after the checkpoint and decide which operations may commit. | One successful local write is not a replication quorum or permission to overwrite uncheckpointed log entries. |
| Free set and compaction | Reserve output capacity and delay address reuse while old recovery state may still need it. | Logical removal from a current lookup does not mean a block is immediately reusable. |
| OS, filesystem, and device | Supply the actual I/O behavior assumed by the implementation. | Database source alone does not establish a flush or power-loss guarantee for a new deployment. |

The first four rows follow [[tigerbeetle-data-file]], [[tigerbeetle-vsr]], and
[[tigerbeetle-storage-source]]. The last is the evidence boundary: use
[[files-buffering-and-atomic-persistence]] and
[[platform-io-backend-decision-table]] for the separate platform questions.

## Storage layout and restart authority

TigerBeetle puts a replica's data in one file. Its main structures include the
WAL, superblock, and grid. The default grid block size is 512 KiB. Table index
blocks carry the addresses and expected checksums of value blocks; manifest
log entries describe table membership and visibility. The superblock points
to the persistent metadata needed to reconstruct that state. These are
configuration and layout facts, not block-size advice for other workloads.
[[tigerbeetle-data-file]], [[tigerbeetle-storage-source]]

New grid blocks can be written before a new checkpoint becomes the recovery
root. After a crash, replay from the retained checkpoint reconstructs later
state from the WAL. A checkpoint advances the recovery point only after its
required updates are durable in the grid; only then can its WAL range be
reused. Storage determinism lets replicas identify and repair a specific
block, rather than merely agree that logical query results look similar.
[[tigerbeetle-data-file]], [[tigerbeetle-vsr]], [[tigerbeetle-sync]]

The high-level Data File document simplifies superblock selection. The exact
implementation defaults to four copies: opening requires a valid quorum of
two, while update verification reads back a quorum of three. The selector
also considers copy identity, parent connection, and monotonic protocol
state. Local superblock-copy quorums are separate from replica quorums. Do not
replace the algorithm with “pick the newest valid checksum.”
[[tigerbeetle-storage-source]]

## Allocation and compaction are admission decisions

The LSM design bounds mutable/immutable memory tables and levels. Compaction
progress is tied to committed operations: a bar contains a configured number
of beats, with alternating level sets in the two half-bars. Snapshots hide
output tables until the half-bar finishes. Inputs cannot be removed while
still needed by a relevant snapshot. The document's persistent historical
snapshot queries remain unimplemented at this pin. [[tigerbeetle-lsm]]

**Implementation qualification:** the LSM document describes reservations for
an entire half-bar. `Forest.compact_trees_start` instead computes a half-bar
input-byte budget and divides remaining bytes across remaining beats.
`compact_trees_reserve_grid_blocks` reserves the beat's output upper bound,
including allowance for partial blocks and pacing overshoot. The forest
resumes compactions through a shared resource pool and joins tree work with
manifest work. The documentation's per-level concurrency count is not a
promise of that many simultaneously executing compactions or threads.
[[tigerbeetle-storage-source]]

That pool tracks blocks through free, building, reading, merging, and writing
states. Its fixed I/O resources constrain asynchronous work; some block
storage can remain owned between beats even when no I/O is executing.
`FreeSet.reserve` returns an exclusive reservation or no reservation; each
successful reservation has exactly one `forfeit`. `acquire` must stay within
that reservation. [[tigerbeetle-storage-source]]

Released addresses are retained until checkpoint/recovery constraints allow
reuse. In particular, `mark_checkpoint_durable` frees the previous released
set only after the checkpoint is durable on a commit quorum; releases made
before that point are tracked separately. `Grid` also waits for relevant
repair writes to stop before declaring those addresses reusable.
[[tigerbeetle-storage-source]]

**Capacity seam:** finite allocation does not imply graceful overload.
`Grid.reserve` terminates through `vsr.fatal` when the storage limit cannot
cover a reservation. `NodePool.acquire` similarly terminates when manifest
nodes are exhausted, and its source retains a TODO for rejecting new requests
before this happens. Treat the configured storage and manifest budgets as
operational limits, not a demonstrated admission-control guarantee.
[[tigerbeetle-storage-source]]

**Transfer recommendation:** reserve enough space for accepted writes, their
compaction output, metadata growth, repair work, and blocks awaiting safe
reuse before accepting work. Define a client-visible refusal or bounded wait
before entering a phase that cannot fail for capacity. If the chosen engine
instead stops at exhaustion, give that failure an operator, an alert, and a
recovery procedure. A byte-work quota is not a wall-clock latency guarantee;
measure the target workload and storage stack.
See [[static-allocation-and-constant-work]] and
[[performance-sketches-and-batching]].

## Cancellation before replacing recovery state

State sync is needed when a lagging replica cannot repair its WAL from the
cluster's retained log. A newer checkpoint is not automatically authoritative:
the protocol must establish that it is sufficiently replicated. A peer being
ahead does not by itself establish that condition. A `view` carries checkpoint
and matching log-header information together. [[tigerbeetle-sync]],
[[tigerbeetle-vsr]]

The implementation orders the transition as follows:

1. The replica waits for any uninterruptible commit stage to finish.
2. `Grid.cancel` discards queued grid work, cancels missing-block bookkeeping,
   and clears scheduled LSM callbacks.
3. The grid waits until executing read and write I/O counts both reach zero,
   then invokes its cancellation callback.
4. The replica releases message and repair-buffer references, resets old
   state-machine/free-set state, and starts installing the checkpoint.

These are `replica.zig` and `grid.zig` semantics. Clearing logical queues does
not cancel an already-submitted OS request, undo a write, or establish a
bounded shutdown time. A driver that never completes an outstanding request
can prevent the drain from finishing. The cancellation callback, rather than
the request to cancel, is the boundary that permits reuse of old state.
[[tigerbeetle-storage-source]], [[cancellation]]

Checkpoint installation also does not mean every referenced block is already
local. Sync repairs data lazily and retains an on-disk unfinished-sync range
until a later checkpoint. Clearing that marker as soon as current reads finish
could leave restart replay needing a block that was used and released during
the interval. The sync ratchet completes an older table range before moving
to a newer one, avoiding endless restart of the same repair work.
[[tigerbeetle-sync]]

**Transfer recommendation:** give recovery its own state machine. Record both
the selected recovery root and unfinished repair obligations durably. Stop
admission, join the old generation's operations, then replace its state. If a
watchdog ends the process, recovery must resume from durable markers; a timeout
does not make old buffers safe to free inside the still-running process.

## Replication promises survive missing data

In normal VSR processing, replicas write a prepare to the WAL and forward it;
they acknowledge after the WAL write. The primary commits after the required
replication quorum and preceding prepares, then replies. View-change and
negative-acknowledgement quorums have other roles. For example, this pin's
default four-replica configuration requires two replicas for replication but
three for a view change. “Always a majority” would erase that distinction.
[[tigerbeetle-vsr]]

A corrupt or missing WAL entry is not evidence that an operation never
existed. TigerBeetle therefore does not negatively acknowledge a corrupt
prepare as if it were known absent. Similarly, permanently losing a replica's
data file does not erase the promises that the cluster remembers it making.
The pinned recovery guide requires `recover`, followed by normal startup and
state sync, rather than reusing `format`. Recovery requires a healthy cluster
capable of changing views. This page does not establish a procedure for loss
of that authority. [[tigerbeetle-vsr]], [[tigerbeetle-operations]]

**Transfer recommendation:** distinguish unknown, corrupt, absent, accepted,
committed, and checkpointed states. Recover from an authority that can justify
the transition; do not repair an availability incident by silently weakening
the protocol's safety conditions.

## Operations belong to the fault model

These are pinned TigerBeetle policies, not universal Zig requirements:

| Operational assumption | Consequence for a transfer |
| --- | --- |
| Production ECC requirement; local NVMe recommendation; independent storage fault domains across replicas | List the memory/storage faults the design assumes and how replicas can fail independently. Replication count alone does not establish independent failures. |
| Explicit startup memory/cache sizing | Monitor available capacity and cache misses before assuming more accepted work can be absorbed. |
| Experimental StatsD metrics; separate replica status and sync-stage signals | Pin metric semantics and alert on non-normal states, while allowing for known startup/recovery transitions in the operational policy. |
| Replica request timing excludes some client/network delay | Measure client-observed latency as well as internal stage timing. |
| Disk-space, clock-sync, memory/CPU, network and disk-bandwidth observations | Connect a signal to a capacity or liveness limit and an action, rather than collecting counters with no owner. |

[[tigerbeetle-operations]] supplies these policies. Its ext4/XFS testing claims
are upstream observations; this wiki has not run a TigerBeetle storage matrix.
Direct-I/O and completion choices must be inspected separately in
[[tigerbeetle-io]]. No filesystem durability guarantee follows from bypassing
a cache or receiving an asynchronous completion.

## Evidence and falsification

All selected storage, recovery, and operating documents were read at the pin;
the source record lists the precise implementation symbols inspected. No
TigerBeetle engine was built or run during this ingest, and no executable Zig
was copied from it. The existing file proof covers the Zig 0.16 API mechanics
described by [[files-buffering-and-atomic-persistence]]; it does not prove the
checkpoint, replication, or power-loss protocol above.

For a new durable service, derive tests from the boundaries: crash between
block writes and root publication; return a valid block at the wrong address;
exhaust output or manifest capacity; delay I/O past a sync request; crash after
lazy sync has used and released a block; and replace a lost replica without
forgetting old promises. These are proposed fault cases, not tests claimed to
have run here. Use [[deterministic-simulation-testing]] for the controlled
model and real platform tests for assumptions outside it.

Related: [[tigerbeetle-engineering-corpus]], [[invariants-and-assertions]],
[[error-path-catalogs-and-fault-injection]],
[[bounded-retries-and-cleanup]].
