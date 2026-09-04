---
id: source-tigerbeetle-operations
title: TigerBeetle hardware, monitoring, and recovery operations
kind: source
status: captured
summary: Pinned operational requirements and signals, including independent fault domains, finite configured memory, experimental metrics, and safe replacement of a lost replica.
captured: 2026-09-04
revision: 47aeb2212a255273dda508288412e537d11e4b7c
url: https://github.com/tigerbeetle/tigerbeetle/tree/47aeb2212a255273dda508288412e537d11e4b7c/docs/operating
---

# TigerBeetle hardware, monitoring, and recovery operations

Read `hardware.md`, `monitoring.md`, and `recovering.md` completely at the
pinned revision. These are TigerBeetle deployment policies and operational
observations; they are not generic filesystem guarantees or measurements made
by this wiki.

`hardware.md` recommends local NVMe and independent storage fault domains,
requires ECC for production, and describes startup-configured memory/cache
budgets. Its ext4/XFS testing comparison is an upstream claim only.

`monitoring.md` marks StatsD emission experimental, distinguishes replica and
sync state, and separates replica timing from client-observed latency. Its
metric values and transport choices are pinned, not claims about future
releases.

`recovering.md` explains why a lost replica must use `recover` rather than
`format`: losing remembered replication promises cannot be treated as proof
that an operation never existed. Recovery requires a healthy cluster capable
of changing views.

Relevant page: [[durable-storage-and-recovery]].
