---
id: source-tigerbeetle-data-file
title: TigerBeetle Data File
kind: source
status: captured
summary: Primary high-level storage design covering fixed-size blocks, external checksums, copy-on-write roots, replicated superblocks, WAL, and deterministic repair.
captured: 2026-09-04
revision: 47aeb2212a255273dda508288412e537d11e4b7c
url: https://github.com/tigerbeetle/tigerbeetle/blob/47aeb2212a255273dda508288412e537d11e4b7c/docs/internals/data_file.md
---

# TigerBeetle Data File

Pinned to the TigerBeetle commit recorded above. It is captured now as a
high-value storage-engine source; detailed synthesis is queued because its
claims require separate treatment of atomicity, direct I/O, checksums,
misdirected writes, recovery, and platform behavior.

Relevant page: [[tigerbeetle-engineering-corpus]].
