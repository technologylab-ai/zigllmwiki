---
id: source-zig-0-17-stdlib
title: Zig 0.17.0 compiler and standard-library source
kind: source
status: captured
summary: Exact release source for bit conversions, reflection, build APIs, and package fetching.
captured: 2026-10-04
revision: "7647adab80dd088f4de3610fd245915a912eb6ad"
url: https://codeberg.org/ziglang/zig/src/commit/7647adab80dd088f4de3610fd245915a912eb6ad
---

# Zig 0.17.0 compiler and standard-library source

The installed compiler reports exactly `0.17.0`.
The release tag resolves to the full commit recorded above.
The curator compared selected release files with that immutable remote source.

| File | SHA-256 |
| --- | --- |
| `lib/std/lang.zig` | `80b809ddaf742757bed5913b82094b5f79569acff886cdfcdabc526fe085dde1` |
| `lib/std/meta.zig` | `af1d7b90ee1a3f019aae7c6b94b7db3845402af86434f6f2847bafcbfe2cd76a` |
| `lib/std/mem.zig` | `db78007af4878dd75a0fc1c24f1fdb90f44f2d15c4c6177c43e388262a17a44e` |
| `src/Sema.zig` | `d387679b8190af4a59b3032a43fb59e8fea581d167dfb2855d4b25ed739b4b85` |

`Sema.zig` defines logical bit conversion and uses bit size when checking casts.
`lang.zig` defines reflection columns, pointer attributes, and optimization tags.
`mem.zig` defines explicit integer reads and object-byte access.
`Build.zig` and build steps define lazy path and argument dependencies.
`lib/compiler/Maker/Fetch.zig` defines global and local package storage and archive recompression.

The I/O review matched ten additional interface, backend, allocator, startup, and Windows files to the same immutable commit.
The project snapshot preserves those file hashes and match results.
The shipped Dispatch, Uring, and Kqueue interface constructors contain stale vtable assignments.
Maintained negative proofs require their exact compiler errors.
Dispatch initialization calls its interface constructor and is therefore also blocked.
`Allocator.free` now accepts pointer-to-array arguments; that removes the old teardown compile error without qualifying the backend.

The global-only fetch path recompresses the temporary root rather than its stripped package subdirectory.
The project packet captures the resulting nested cache archive and later hash mismatch.
Treat that finding as exact 0.17 evidence, not a claim about future releases.

The explicit wiki upgrade uses this source and separately requalifies maintained proofs.
See [[zig-0.17-upgrade-assessment]] and [[zig-0.17-project-ports-2026-10-04]].
