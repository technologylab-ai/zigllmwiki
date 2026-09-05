---
id: source-zig-0-16-linux-crt-linker-workaround
title: Zig 0.16 Linux Debug CRT linker failure and ReleaseSafe workaround
kind: source
status: captured
summary: Exact Linux probe reproduces Debug R_X86_64_PC64 failure and successful default ReleaseSafe and explicit Debug LLVM/LLD runtime tests.
captured: 2026-09-05
revision: "Zig 0.16.0; zig-http 6d622009abee5807eb0829e558c3173635e077ea"
url: https://ziglang.org/download/0.16.0/release-notes.html
snapshot: sources/snapshots/zig-http-mvp-2026-09-05.json
sha256: "776a2ea199bdc1f3a6cb2705bdeb9495377b155dafd8e7a3c1f71608c1c2ba56"
---

# Linux CRT linking observation

The exact release notes' x86 Backend, Incremental Compilation and New ELF Linker
sections explain default x86 Debug backend selection and the self-hosted ELF
linker path, while documenting explicit linker selection. Installed exact
`std/Build.zig` and `std/Build/Step/Compile.zig` expose independent `use_llvm`,
`use_lld` and optimization controls. This is a default-selection consequence,
not a universal rule forbidding custom linkers in optimized builds.

At the user's suggestion, ReleaseSafe was retried with no LLVM/LLD overrides.
The complete HTTP project passed all its then 43 tests and runtime integration.
A separate probe of the final committed transport source ran on omarx1,
2026-09-05T14:51:36Z–14:51:48Z. Zig 0.16.0; Intel Core Ultra 7 258V x86_64;
kernel 7.1.9-arch1-2; glibc 2.44; GCC 16.2.1 20260810; io_uring_disabled=0.

| Exact command in the pinned HTTP project | Observed result |
| --- | --- |
| `zig test src/transport.zig -lc -ODebug` | Exit 1 before execution: R_X86_64_PC64 at 0x1c/0x2c/0x3c in system crt1.o:.sframe. |
| `zig test src/transport.zig -lc -OReleaseSafe` | Exit 0; six transport tests actually executed and passed. |
| `zig test src/transport.zig -lc -ODebug -fllvm -flld` | Exit 0; six transport tests actually executed and passed. |

Failing `/usr/lib/crt1.o` SHA-256:
`e4c262fda945a76df8aaefc8343a4d09dd2add671735a322797c7dfe9352645e`.
Transport source SHA-256:
`dfa97a8d5f68028775218c1bf529ce40e10fecd477a7f7305068c1195ee2f8a7`.
The packet retains all commands, exit codes, compiler/CRT/source hashes and host
metadata. The remote temporary directory was removed and authoring checkouts
were preserved. No compiler or system object was patched.

Use this observation in [[build-diagnostics-and-generated-code]] and
[[bounded-http-server-design]]. It does not predict every architecture, CRT,
linker flag combination or future Zig release.
