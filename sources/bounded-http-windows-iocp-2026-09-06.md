---
id: source-bounded-http-windows-iocp-2026-09-06
title: bounded/http Windows IOCP implementation and native x64 verification
kind: source
status: captured
summary: Pinned one-shard Windows HTTP implementation passed native x64 ownership and wire gates, with explicit provider-resource, fixture, and performance limits.
captured: 2026-09-06
revision: "bb14d98756152936fadb6e8353852a686e8d315d"
url: https://github.com/technologylab-ai/bounded-http/blob/bb14d98756152936fadb6e8353852a686e8d315d/reports/2026-09-06-windows-iocp.md
snapshot: sources/snapshots/bounded-http-windows-iocp-2026-09-06.json.gz
sha256: "45fd349991b468027c591480099b86f45585c0b5be67f6685d72acc54c9a8c51"
---

# Windows HTTP implementation and native x64 evidence

HTTP publication `bb14d98756152936fadb6e8353852a686e8d315d` preserves the committed report and raw native evidence.
The native candidate is `70f9ae5917076b664081db59c62edc4959ca5041`.
The publication retains identical candidate runtime, test, build, and embedding inputs.
The snapshot preserves the report, raw packet, manifest, GitHub metadata, and independently checked source identities.
All 26 native input digests match the candidate's Git blobs.

## Implemented boundary

The custom Windows I/O completion port (IOCP) adapter delivers terminal results to one server owner.
Windows requires one shard and binds plain HTTP to IPv4 loopback.
The adapter reserves `4 × connections + 2` stable operation cells and ready entries at startup.
Its socket table contains `connections + 1` entries, alongside a separate listener handle.
`AcceptEx` uses zero receive bytes and updates accepted-socket context before ordinary configuration.
`WSARecv` and `WSASend` retain borrowed storage through terminal completion.
The adapter preserves immediate-success notifications and checks each batched result separately.
Each dequeue accepts at most 256 entries.
Cancellation acknowledgement does not reclaim the target operation.
Console callback references drain before cluster destruction.

[[microsoft-windows-acceptex-provider]] pins setup and provider-resource contracts.
[[microsoft-windows-iocp-api]] pins IOCP notification and cancellation contracts.
[[microsoft-windows-winsock-batched-file-io]] pins descriptor capture, payload ownership, and batched-result contracts.
These implementation choices belong to bounded/http, rather than `std.Io.Threaded` or its APC paths.

## Successful native gate

[Run 34039591972](https://github.com/technologylab-ai/bounded-http/actions/runs/34039591972) passed on the exact candidate.
The native supervisor ran from 14:35:24 to 14:38:39 UTC on 2026-09-06.
The job completed at 14:38:46 UTC.
Both Debug and ReleaseSafe passed 16 build steps and 83 tests, with six explicit platform skips per mode.
Both modes passed the independent GET/HEAD/GET embedding probe.
Nine comparator tests and 80 wire cases passed.
The wire total includes eight arena, 25 batch, 11 gather, ten inline, and 26 general cases.
Four maximum-cell batch fixtures skipped because they require POSIX process suspension.
The client verified 30,000 smoke response bodies.
All 53 saved shutdown records show zero live connections, live operations, and late framework allocations.
The checkout remained clean before and after execution.

The six Zig skips comprise two POSIX transport fixtures repeated through imports and two Linux shard fixtures.
Separate Windows IOCP transport fixtures passed.
Windows arena wire cases use live input; they do not force the POSIX suspension timing.
Separate Zig tests force internal completion ordering.
The supervisor bounded builds at 300 seconds, integration phases at 150 seconds, and smoke at 180 seconds.
The hosted job also had a 35-minute timeout.

## Environment and identities

The native x64 host ran Windows Server 2025 Datacenter 24H2, build `26100.33296`.
Its image was `win25-vs2026`, version `20260824.214.3`.
The host exposed two AMD EPYC 9V74 cores, four logical processors, and 17,174,360,064 memory bytes.
The host used NTFS, Python 3.12.10, and PowerShell 7.6.5.
Both compiler and executable used native x64 execution.
The compiler was exact Zig 0.16.0.

| Identity | SHA-256 |
| --- | --- |
| Official Zig Windows x64 archive | `68659eb5f1e4eb1437a722f1dd889c5a322c9954607f5edcf337bc3684a75a7e` |
| ReleaseSafe executable, PE machine `8664` | `9130774c8df265c8fba2340b50577d3b828289c42643ff5e650c8a038fcbf02a` |
| Original hosted artifact ZIP | `f609ead5afca81bf0b38e062454e8462365053b6db571ad58373d51a17e6a046` |

GitHub artifact `9991312374` is named `bounded-http-windows-x64-34039591972-1`.
Its ZIP contains 29,689 bytes and matches GitHub's digest.
The curator checked every extracted file against that ZIP.
The committed HTTP packet preserves the evidence beyond the hosted artifact's 30-day retention.

## Other native regression gates

The same clean candidate passed Mac and Linux regression gates with exact Zig 0.16.0.
Each Mac mode passed 16 steps and 78 tests, with two Linux-only skips.
Each Linux mode passed 16 steps and 80 tests.
Each host passed both embedding probes, 84 wire cases, nine comparator tests, and 30,000 exact smoke responses.
The Mac ran macOS 26.6.2 build `25G83` on Apple M3 Max arm64.
Linux ran kernel `7.1.9-arch1-2` and glibc 2.44 on Intel Core Ultra 7 258V x86_64.
Both runners released their reservations after child cleanup.
The captured report retains complete environments and the separately labelled development browser checks.

## Failed run and limits

Initial candidate `02f0e2b32c2ca67e44e017a2c8814600c154a17d` failed [run 34039231092](https://github.com/technologylab-ai/bounded-http/actions/runs/34039231092).
The native Zig modes, both embedding probes, and comparator tests passed before a Python fixture failed on Windows `SIGSTOP`.
That full gate remains failed.
The successful follow-up changes fixture scheduling without changing server or transport source.
The initial host used AMD EPYC 7763, so the two environments remain distinct.

Winsock can create provider resources during admission and retain resources during background close cleanup.
Application heap sealing does not bound every operating-system allocation.
Ordinary socket transfers retain kernel copies.
The evidence supplies no kernel zero-copy, hard real-time, Windows comparative-performance, server-capacity, or latency claim.
Windows child CPU accounting remains unavailable in the saved Python receipt.
Windows ARM64, WOW64, TLS, external deployment, console closure, logoff, and service controls remain unqualified.
Older wiki proofs do not supply missing HTTP executable evidence.
M3-006 physical deployment qualification remains postponed.

Synthesis: [[bounded-http-server-design]], [[windows-iocp-and-overlapped-io]], and [[platform-io-backend-decision-table]].
