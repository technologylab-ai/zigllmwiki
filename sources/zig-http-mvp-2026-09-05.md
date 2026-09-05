---
id: source-zig-http-mvp-2026-09-05
title: Bounded Zig HTTP first Linux and macOS implementation
kind: source
status: captured
summary: Exact standalone MVP source and runtime packet establish borrowed HTTP framing, fixed workers, flush/resume, finite admission and cancellation on named Linux/macOS hosts.
captured: 2026-09-05
revision: "6d622009abee5807eb0829e558c3173635e077ea"
url: https://github.com/technologylab-ai/zig-http/tree/6d622009abee5807eb0829e558c3173635e077ea
snapshot: sources/snapshots/zig-http-mvp-2026-09-05.json
sha256: "776a2ea199bdc1f3a6cb2705bdeb9495377b155dafd8e7a3c1f71608c1c2ba56"
---

# First HTTP implementation and runtime packet

The private origin commit was checked with GitHub's commit API. The byte-hashed
packet identifies every tracked source file, exact compiler, host, commands,
binary/asset hashes, unit/integration receipts and finite smoke measurements.
The server's `src/server.zig` SHA-256 is
`dc6d60aff0a6471829f7dce1465b40ae9b1d6f21e3ed8bc256dd441e63341e8d`.
Runnable application code lives once in the standalone project, where its own
`zig build verify` compiles/tests all Zig modules. No code is duplicated into
wiki guidance and this packet is not a new registered wiki proof.

Inspected files: `src/{http,api,budget,server,main,transport,transport_linux,
transport_macos}.zig`, `build.zig`, `tests/integration.py`, `tools/{benchmark,
smoke}.py`, and the ownership documentation. Actual startup-fixed application
workers communicate by atomic per-slot phases; Linux uses raw IoUring, macOS
nonblocking socket calls plus kqueue. This is not a std.Io backend implementation.

On 2026-09-05, exact Zig 0.16.0 Debug and ReleaseSafe each passed 14/14 build
steps and 44 test executions on maxross (M3 Max arm64, macOS 26.6.2 build 25G83)
and omarx1 (x86_64 Omarchy 4.0.2, kernel 7.1.9-arch1-2, io_uring_disabled=0).
The count includes imported tests run by more than one test root. ReleaseSafe
wire integration passed 26/26 on both, including four simultaneous exact-body
limit requests, admission refusal/recovery, partial flush/resume and cancellation.

The corrected slow-reader fixture requested SO_SNDBUF=4096, received a 2 MiB
body, and timed out while the echo remained incomplete: Mac 524,765 / Linux 66,013
bytes sent across the whole fixture, with only two healthy controls completed.
An earlier Linux fixture completed the echo into kernel buffers and expired a
later idle receive; it did not prove a response stall. The final receipt replaces
that interpretation without hiding the narrower result.

Finite smoke: three 10k-response workloads per host, eight clients, two workers,
128 admitted-slot capacity, 64 KiB body/16 KiB header/4 KiB output defaults and
ReleaseSafe. All 30k exact bodies validated; no refusals/timeouts/late framework
allocation attempts; final owned connections/operations zero. Input pipeline
compaction copied 7,563,688 bytes on each host. Ordinary kernel socket copies,
libc/pthread allocations, stack mappings, kernel rings/socket memory and arbitrary
application allocations remain outside the framework allocator metric.

No Windows HTTP implementation, dynamic borrow-release API, hard scheduling
guarantee, production capacity, NIC zero-copy, long saturation run or competitor
comparison is established. Read [[bounded-http-server-design]] and
[[zig-0.16-linux-crt-linker-workaround]] for synthesis and the linker probe.
