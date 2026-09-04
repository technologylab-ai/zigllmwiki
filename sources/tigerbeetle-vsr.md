---
id: source-tigerbeetle-vsr
title: TigerBeetle VSR protocols
kind: source
status: captured
summary: Pinned consensus design for WAL acknowledgement, checkpoint authority, distinct quorums, repair, and retained replica promises.
captured: 2026-09-04
revision: 47aeb2212a255273dda508288412e537d11e4b7c
url: https://github.com/tigerbeetle/tigerbeetle/blob/47aeb2212a255273dda508288412e537d11e4b7c/docs/internals/vsr.md
---

# TigerBeetle VSR protocols

Read completely at the pinned revision. Relevant sections are Recovery,
Normal, Request/View, Repair Journal, Repair WAL, Repair Grid, and Quorums.
The document describes TigerBeetle's implementation choices rather than every
VSR implementation; it explicitly leaves reconfiguration unimplemented.

Use the implementation record [[tigerbeetle-storage-source]] for concrete
checkpoint/cancellation ownership. Replication, view-change, negative-
acknowledgement, and local superblock-copy quorums have different roles; do not
replace them with an undifferentiated majority rule.

Relevant page: [[durable-storage-and-recovery]].
