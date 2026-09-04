---
id: source-tigerbeetle-architecture
title: TigerBeetle Architecture
kind: source
status: captured
summary: Primary architecture rationale for limits, deterministic execution, batching, concurrency, static allocation, and io_uring ownership.
captured: 2026-09-04
revision: 47aeb2212a255273dda508288412e537d11e4b7c
url: https://github.com/tigerbeetle/tigerbeetle/blob/47aeb2212a255273dda508288412e537d11e4b7c/docs/ARCHITECTURE.md
---

# TigerBeetle Architecture

Pinned to the TigerBeetle commit recorded above. This is a design source for
systems-engineering synthesis, not authority for Zig 0.16 standard-library
APIs. Particularly relevant sections cover systems thinking, single-threaded
execution, startup-sized memory, determinism, simulation testing, mechanical
sympathy, batching, control/data planes, concurrent pipelines, `io_uring`, and
direct I/O.

Relevant pages: [[tigerbeetle-engineering-corpus]],
[[static-allocation-and-constant-work]], [[deterministic-simulation-testing]],
and [[evented-io-backends]].
