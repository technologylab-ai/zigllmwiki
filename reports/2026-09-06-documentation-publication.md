# Documentation publication — 2026-09-06

The change adopts the user's repository writing policy and links the HTTP project's documentation.
The change leaves existing source captures, executable proofs, and platform claims unchanged.

## Development verification

The reviewed input used wiki base `362da3b8023e6918d4b72c046821334ebd3722ca` with documentation edits.
The runner streamed an isolated copy to `omarx1`.
The copy was a development input with uncommitted edits.

| Environment | Value |
| --- | --- |
| Host | `omarx1` |
| Operating system | Omarchy 4.0.2 |
| Architecture | x86_64 |
| Kernel | `7.1.9-arch1-2` |
| Compiler | Zig 0.16.0 |
| `io_uring_disabled` | `0` |
| Reservation token | `9b7dd534ce6b497e91ce565eb8695770` |

The runner acquired `/tmp/zig-http-measurement.lock` after inspecting existing processes.
The runner retained the reservation through command completion and temporary-directory cleanup.
The runner then released its reservation.

| Gate | Result |
| --- | --- |
| `zig build verify --summary all` | 87/87 steps; 74/82 tests passed; eight platform skips. |
| Four command test modules | 28/28 tests passed. |
| Retrieval policy | 25 queries; MRR 0.98; hit@3 1.0; recall@5 0.96. |
| Full `tools/wiki.py lint` | Zero issues across 51 pages and 78 sources. |
| `git diff --check` | Passed. |

The command test modules cover wiki commands, retrieval, curation review, and scheduled curation.
The full lint invocation repeated the verifier successfully.
The local development packet remains at `/tmp/zigllmwiki-docs-development.e9znbf3r`.

## Publication boundary

Clean pushed revision `d9d26453844a24cc559320cb21c45c5662996935` passed `tools/verify_linux_ssh.sh omarx1`.
The wrapper streamed the clean tree into its validated temporary directory.
The wrapper passed 87/87 steps with 74 passing tests and eight platform skips.
The isolated command copy passed all 28 command tests and the same 25-query retrieval policy.
Structural lint found zero issues across 51 pages and 78 sources.
The publication packet remains at `/tmp/zigllmwiki-docs-publication.du105m1y`.
The publication reservation token was `9c0a5df8b3df491aa2a5f250f106c620`.
The runner released the reservation after both temporary directories were removed.

The receipt commit must repeat the maintained wrapper and target-independent gates at its clean pushed revision.
Linux handled verification while the Mac remained available for document rendering and embedding builds.
The prior Mac baseline remains evidence for its original tree.
The documentation change introduces no new macOS runtime claim.
Windows checks remain deferred under the user's current HTTP cadence.
Cross-target compilation remains compile evidence only.

The HTTP documentation links follow project main for navigation.
[[zig-http-arena-adoption-2026-09-05]] retains the pinned implementation and measurement authority.
