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

The clean pushed revision must pass the maintained Linux wrapper and the command and retrieval gates.
The documentation agent reserves the Mac for document rendering and embedding builds.
The prior Mac baseline remains evidence for its original tree.
The documentation change introduces no new macOS runtime claim.
Windows checks remain deferred under the user's current HTTP cadence.
Cross-target compilation remains compile evidence only.

The HTTP documentation links follow project main for navigation.
[[zig-http-arena-adoption-2026-09-05]] retains the pinned implementation and measurement authority.
