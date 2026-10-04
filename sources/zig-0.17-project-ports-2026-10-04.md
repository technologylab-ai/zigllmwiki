---
id: source-zig-0-17-project-ports-2026-10-04
title: Baz dependency and wiki Zig 0.17 migration evidence
kind: source
status: captured
summary: Preserve semantic audits, native Mac/Linux gates, helper Windows gates, package failures, and experimental backend blockers.
captured: 2026-10-04
revision: "74768283c375fdd6136ccf7fb6463bd29563721e"
url: https://github.com/technologylab-ai/baz/blob/74768283c375fdd6136ccf7fb6463bd29563721e/build.zig.zon
snapshot: sources/snapshots/zig-0.17-project-ports-2026-10-04.json.gz
sha256: "287ae0bd252146f72bc528e2161383bff08e387df79039aac812c9d6764be5a0"
---

# Zig 0.17 migration evidence

The snapshot preserves 409 files with individual SHA-256 values and encoded original bytes.
It includes native receipts, logs, compiler signatures, source identities, first failures, and cleanup records.
It also preserves the compile-only big-endian oracle and matched historical Dispatch diagnosis.

## Project revisions

| Project | Published port revision |
| --- | --- |
| Baz | `74768283c375fdd6136ccf7fb6463bd29563721e` |
| bounded/http | `65d584bf1a00451577235281a290303b10d0ae3b` |
| Mustache | `f46006f04a6bb4374a34250fb01fe72daf6a39c1` |
| zli | `36dfe7c506117af0e52533feb549282362b77e2a` |

Baz's runtime-qualified predecessor is `d1e9f19392eae2115ef95408543ed70ee9670615`.
The later Baz commit changes two CI watchdogs and HANDOFF only.
Its compiler, dependency pins, build graph, runtime source, and tests are unchanged.
Engine and zli README-only follow-ups have separate final URL graph checks.

## Native evidence

All four consumed projects passed Debug and Safe verification on arm64 macOS 26.6.2.
All four also passed on native x86_64 `omarx1`.
The Linux host runs Omarchy 4.0.4, kernel `7.2.5-3-omarchy`, glibc 2.44, and Python 3.14.7.
The final URL graph passed 72 Baz steps and 250 tests in each mode.
Each mode also passed the independent five-test consumer.
Fetched dependency inputs match the separately tested projects.

All engine wire suites and all eleven Baz Python suites passed on Linux.
Baz's Linux suites contain 540 groups.
Mac also passed the maintained suites, with explicitly recorded platform skips.
The changed idle/request-deadline fixture passed again on both hosts.
Reservations remained held through owned-child cleanup.
Unrelated Linux build overlap is recorded; no application performance claim is made.

[Baz Linux/Mac CI](https://github.com/technologylab-ai/baz/actions/runs/37215601568) passed at the runtime-qualified predecessor.
[Engine Linux/Mac CI](https://github.com/technologylab-ai/bounded-http/actions/runs/37215422123) passed at its final revision.
[Engine native Windows](https://github.com/technologylab-ai/bounded-http/actions/runs/37215739537) also passed.
[Mustache CI](https://github.com/technologylab-ai/mustache-zig/actions/runs/37213568712) and
[zli CI](https://github.com/renerocksai/zli/actions/runs/37215421239) passed on Linux, Mac, and Windows.
Baz's final native Windows gate was pending at this capture.
Later Windows qualification requires its own new source record.

## Findings and limits

The retained parser casts use logical lane bits.
IPv4 storage uses native-memory integer reads and independent object-byte oracles.
Reflection tests preserve column indices, optional defaults, and public cleanup hooks.
Fixture ports preserve string/sentinel contracts and avoid partially initialized compile-time array scans.
The cache packet preserves malformed standalone-fetch archives and later direct-build success.
The specific recompression cause is a source-based inference.

Mustache's optional compile-time suite remains disabled in its established configuration.
Five historical sample/benchmark Zig files remain outside its exported and verified graph.
The port qualifies the graph consumed by Baz, not those historical programs.
Big-endian results are compile-time evidence only.
No application throughput comparison or Windows performance measurement was made.

The wiki proof audit retains three exact shipped evented-backend compile failures.
Dispatch and Uring first reject removed `processReplacePath` vtable fields.
Kqueue first rejects removed `fileWriteStreaming`.
Dispatch initialization calls the broken interface constructor.
Type mapping and public signatures do not qualify an initialized backend.
The Apple Dispatch C shim remains a separate native proof.

Read [[zig-0.17.0-stdlib]] for exact release source.
Read [[zig-0.17-upgrade-assessment]] and the [migration guide](../docs/zig-0.16-to-0.17-migration.md) for synthesis.
