---
id: source-bounded-http-windows-shards-2026-09-06
title: bounded/http Windows acceptor handoff and native shard verification
kind: source
status: captured
summary: Native x64 fixtures qualify bounded acceptor handoff across one through four IOCP owners, preserving shared admission and terminal shutdown ownership.
captured: 2026-09-06
revision: "419de5445901a87ea6973020df5b13a420917483"
url: https://github.com/technologylab-ai/bounded-http/blob/419de5445901a87ea6973020df5b13a420917483/reports/2026-09-06-windows-shards.md
snapshot: sources/snapshots/bounded-http-windows-shards-2026-09-06.json.gz
sha256: "1fd1bd5d5624a4d800aac77fd6c50f56a5738028c14c43f88a5f6075853d1b99"
---

# Windows acceptor handoff evidence

The qualified feature revision is `419de5445901a87ea6973020df5b13a420917483`.
The preserved report describes earlier candidate `514c901fafd005f140a0a6fdf10ee28d0ff8796a` and run 34043829095.
The later [run 34044844060](https://github.com/technologylab-ai/bounded-http/actions/runs/34044844060) passed on the qualified feature revision.
The report retains its original candidate identity.
The snapshot preserves 89 files, including the report, candidate packet, final hosted archive, and 28 qualified source inputs.
The curator checked 295 candidate Git file digests and all 28 final native input digests.
The curator also checked the report packet's 29 recorded file hashes.

Merge `1c74a4e379c365ec0a201e6fe3df1a5a9718d504` has the qualified revision as a parent.
Both commits have Git tree `7b6f43cecff06791c7f91ad4ac794eb3d024119d`.
The curator checked that equality against local Git objects and GitHub metadata.
Tree equality preserves verified inputs; it does not relabel the feature run as a merge run.
[[bounded-http-windows-iocp-2026-09-06]] retains the earlier single-owner evidence unchanged.

## Implemented ownership

An I/O completion port (IOCP) delivers completed operations to its owning server shard.
Shard zero owns one exclusive listener and accepts without receiving request data.
The acceptor distributes sockets round-robin, including its own connection share.
Each secondary shard owns an independent IOCP and private connection storage.
No extra accepting thread exists.

A single-producer, single-consumer (SPSC) queue transfers socket metadata to each secondary owner.
The acceptor collects terminal `AcceptEx` completion and updates accepted-socket context before export.
The destination associates the previously unassociated socket before receiving request bytes.
Transfer failure preserves one socket owner for retry or closure.
The transfer never copies request payloads between shards.

Let `C` denote configured connections and `S` denote configured shards.
Shared admission includes producer transit, queue residence, consumer transit, and adopted connections.
The successful reservation count never exceeds `C`.
Each secondary queue provides `C` usable positions within `C + 1` optional entries.
Startup accounting includes `(S - 1) × (C + 1)` entries, queue metadata, full per-owner storage, and requested stacks.
One pending accept can retain an additional staging socket.
Application ownership therefore permits `C + 1` nonlistener sockets plus one listener.
That ceiling excludes kernel backlog, provider allocations, and background TCP cleanup.

Queue residence retains the original acceptance deadline.
Each destination checks time before adoption and drains at most `C` queued entries per turn.
Remaining entries force nonblocking polling; notifications retain a ten-millisecond polling fallback.
Any stopping owner propagates cluster-wide stop.
Receivers acquire `producer_done`, then recheck queue emptiness before exiting.
That flag ends publication; a failed producer can still retain kernel operations.
Failed owners retain storage under the process-termination boundary.
Successful shutdown drains queued sockets, local operations, and separate cancellation acknowledgements before destruction.
The listener and Winsock startup references remain alive until every owner exits.

[[microsoft-windows-iocp-api]] pins permanent association and terminal cancellation contracts.
[[microsoft-windows-acceptex-provider]] pins accept setup and provider-resource limits.
[[microsoft-windows-winsock-cleanup]] pins final process-wide cleanup.
These adapter rules do not extend `std.Io` or `std.Io.Threaded` guarantees.

## Final native gate

The final supervisor ran from 16:16:06 to 16:20:11 UTC on 2026-09-06.
Both Debug and ReleaseSafe passed 16 build steps and 95 tests, with four POSIX skips per mode.
Both independent embedding probes passed three exact responses.
Nine comparator tests, 89 wire cases, and 30,000 exact smoke bodies passed.
Four maximum-cell wire fixtures require POSIX suspension and remain skipped.
The final checkout remained clean.
Saved final ownership records contain zero live connections, operations, and late framework allocations.
Every shard wire session matched handoff publications with removals.

Nine shard wire cases exercise two, three, and four owners.
Their witnesses cover distinct borrowed pipelines, concurrent clients, shared capacity, slot reuse, half-close, flushes, and Ctrl-Break shutdown.
Deterministic Zig fixtures separately exercise queued admission, receiver-only stop, original deadlines, association failure, and publication visibility.
The live wire suite does not force mailbox interleavings.
The supervisor bounds builds at 300 seconds, wire processes at 150 seconds, and smoke at 180 seconds.
The hosted job has a 35-minute timeout.
Queued-socket Zig fixtures add five-second watchdog threads.

## Environment and limits

The native x64 host ran Windows Server 2025 Datacenter 24H2, build `26100.33296`.
Its image was `win25-vs2026`, version `20260824.214.3`.
The host exposed two AMD EPYC 7763 cores, four logical processors, and 17,174,360,064 memory bytes.
The host used NTFS, Python 3.12.10, PowerShell 7.6.5, and exact native x64 Zig 0.16.0.
Compiler and server executables used PE machine `8664`.

| Identity | SHA-256 |
| --- | --- |
| Official Zig x64 Windows archive | `68659eb5f1e4eb1437a722f1dd889c5a322c9954607f5edcf337bc3684a75a7e` |
| Final ReleaseSafe executable | `98e3f0c32c81d596ce3acc512c35549d6c3234f322be8ff9617836d5d2e431d6` |
| Hosted artifact ZIP, ID `9992846068`, 35,153 bytes | `972ded4fad43fa7417b8aa6376b6682259c232369d6cec5840a0baedeb173745` |

The curator checked the downloaded ZIP against GitHub's digest and each extracted file against the ZIP.
Windows defaults to one shard; explicit inline configurations accept one through 64 shards.
Native fixtures cover one through four owners; five through 64 have no separate runtime coverage here.
Worker execution requires one shard.
Ordinary Winsock transfers retain kernel copies.
The evidence supplies no Windows performance, capacity, latency, hard real-time, ARM64, WOW64, service-control, or external-deployment qualification.
Application callbacks remain cooperative and cannot be arbitrarily preempted.
M3-006 physical deployment qualification remains postponed.

Synthesis: [[bounded-http-server-design]], [[windows-iocp-and-overlapped-io]], and [[platform-io-backend-decision-table]].
