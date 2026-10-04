---
id: source-omajot-zig-0-17-2026-10-04
title: Omajot and final Baz Zig 0.17 qualification
kind: source
status: captured
summary: Preserve current-main integration, native Omajot gates, dependency ownership failures, diagnostic repair, and completed application merges.
captured: 2026-10-04
revision: "d470dbf65b76f88be9e25fcbcfe9416e59dfc8f6"
url: https://github.com/renerocksai/omajot/blob/d470dbf65b76f88be9e25fcbcfe9416e59dfc8f6/build.zig
snapshot: sources/snapshots/omajot-zig-0.17-2026-10-04.json.gz
sha256: "0fec374fa54a0cbee320b133e9afb8e702b714f463cb6da55cd41026bccd1166"
---

# Omajot and final Baz qualification

This capture supplements [[zig-0.17-final-verification-2026-10-04]].
Earlier records retain their original revisions and bytes.
The snapshot preserves 695 files, with original bytes and individual SHA-256 values.
The packet includes selected source, native receipts, hosted artifacts, original failures, and merge-tree checks.

## Current-main integration

The initial Baz compiler port started from local main `2258ff87`.
Omajot already consumed newer main `c7d489a2`.
That revision added route deadlines and removed forced libc linkage.
The initial Omajot executable failed because the older port lacked `RouteOptions.timeout_ms`.
Baz port `55099ec6ab894149088e5d6ca506e793f684bd34` integrates both branches.
The engine's selected port already contains the required current-main changes.

Fresh native omarx1 Debug/Safe gates passed at that Baz port.
Each mode passed 73 steps, 251 unit tests, and five independent consumer tests.
All eleven Python suites passed, covering 556 groups.
Fresh Mac Debug/Safe and the 27-example documentation projection also passed.
Final [Linux/macOS CI](https://github.com/technologylab-ai/baz/actions/runs/37229152901),
[Windows x64 CI](https://github.com/technologylab-ai/baz/actions/runs/37229152937),
and [documentation build](https://github.com/technologylab-ai/baz/actions/runs/37229153004) passed.
Earlier Baz receipts still qualify their earlier revisions.

## Omajot graph and native gates

Omajot port `d470dbf65b76f88be9e25fcbcfe9416e59dfc8f6` pins that Baz revision.
The application selects these immutable upstream dependencies:

| Dependency | Revision |
| --- | --- |
| libvaxis | `6fd944a27fb3d6f596e981076381a3131f2448b4` |
| zigimg | `c701c9f99779d7ddf594dcc6da8f858fd277d61f` |
| uucode | `ea62149739404a73c202b48a33bf6dd2af4bd9b0` |
| Image qualification fixtures | `072fcaa45201a6c48d65a741881b8f3eab77412e` |

Native execution used x86_64 omarx1, Linux `7.2.5-3-omarchy`, and exact Zig 0.17.0.
The system's default Zig remains 0.16.0.
Omajot's complete Debug/Safe graph passed 16 steps with 102 unit tests.
Final clean checks reran 58 executable-module tests and reused 44 exact-input core tests.
The immutable final package consumer also passed the complete graph.
Its exported files matched the canonical checkout, including committed embedded assets.

WASM smoke, plugin models, Qt V4, and 60 web unit tests passed.
CLI integration, offline synchronization, TUI interaction, Chromium editing, and service-worker updates passed.
The embedded hub served WASM bytes identical to committed assets without a web override.
Those runtime suites retain their precommit input manifests.
The packet distinguishes subsequent source, asset, test-only, and documentation changes.
Final [hosted Linux/macOS/Windows](https://github.com/renerocksai/omajot/actions/runs/37230575581) passed 102 tests per mode.
Windows CLI/sync and interactive TUI remain outside that hosted gate.

The first sync invocation omitted `--local`; its command failure remains captured.
The [first hosted run](https://github.com/renerocksai/omajot/actions/runs/37230205639) preserves its Windows failures.
CRLF checkout broke formatting, and one path fixture expected POSIX separators.
Tracked LF rules and native-separator expectations fixed those checks.
Production path construction did not change.

## Separate dependency evidence and limits

Libvaxis passed 48 steps per mode on native Linux musl.
Its graph passed 216 of 219 tests, with three skips, plus C runtime fixtures.
Zigimg passed 499 of 502 tests per mode, with three skips.
Each image run records traversal of 182 PNG files.
Tracked source and fixture bytes remained unchanged.
Missing fixtures can silently skip checks, and missing PNG references can generate new baselines.
The selected references were present before these runs.
GIF corpus loops consume only the first of 79 listed fixtures.
The source audit also identifies a pre-existing big-endian TGA SIMD/scalar byte-order mismatch.
These little-endian gates do not establish complete GIF or big-endian qualification.

Uucode's unmodified Debug suite passed 167 tests.
Its unmodified Safe suite passed 166 and failed the Greek final-sigma condition test.
The generated row held the correct `.final_sigma` value.
The getter copied the row locally and returned a slice into embedded local storage.
That borrowed storage expired when the getter returned.
The relevant getter and storage bodies are byte-identical in old pin `2826a37` and selected pin `ea62149`.
The source identifies a pre-existing ownership defect, without blaming changed cast semantics or the optimizer.
Libvaxis's four selected scalar fields exclude the affected slice getters.

An isolated diagnostic patch borrows static table rows while preserving the value-based `getAll` API.
That patched checkout passed all 167 tests in both modes.
The packet retains the exact patch and the original failure.
The published dependency graph remains unchanged; the unmodified full helper Safe suite remains failed.
Five additional synthetic pointer probes are included as unexecuted source material.
Uucode's corpus includes documented emoji tailoring; generator modules remain Debug during top-level Safe tests.

## Completed application merges

The curator merged these five PRs with merge commits.
Each merge tree equals its qualified port tree.
Immutable consumed commits remain in main history.

| Project | PR | Merge commit |
| --- | --- | --- |
| [bounded/http](https://technologylab-ai.github.io/bounded-http/) | [9](https://github.com/technologylab-ai/bounded-http/pull/9) | `7ed9ca3c3373a3ba4194359e85449a5bf2cd1eb4` |
| Mustache | [2](https://github.com/technologylab-ai/mustache-zig/pull/2) | `c57fbc89f7a1065fc3a9ce9a7116ab3f36cc83d5` |
| zli | [2](https://github.com/renerocksai/zli/pull/2) | `06d6a296ce770cfa53b47587af12d066400c0a69` |
| Baz | [13](https://github.com/technologylab-ai/baz/pull/13) | `8c8a3edf5363492d6cf7aaba5c535920cd9b5e7e` |
| Omajot | [1](https://github.com/renerocksai/omajot/pull/1) | `650e6267da8ec4399343d280123633186b3b77e0` |

All own host reservations were released after child cleanup.
No application performance comparison, new Windows ARM64 full gate, or intentional Linux crash reproduction ran.
Read [[zig-0.17-upgrade-assessment]] and the [migration guide](../docs/zig-0.16-to-0.17-migration.md) for synthesis.
