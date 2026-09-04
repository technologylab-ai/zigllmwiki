---
id: zig-0-16-release-inventory
title: Zig 0.16 release-note scope inventory
kind: map
status: source-verified
zig: "0.16.0"
summary: Every named Zig 0.16 release-note topic is routed to current guidance, a numbered roadmap item, an upgrade watch, or an explicit out-of-scope decision.
updated: 2026-09-04
sources:
  - "[[zig-0.16.0-release-notes]]"
proofs: []
platforms:
  - cross-platform
---

# Zig 0.16 release-note scope inventory

## How to use this map

This is a coverage map for the official [[zig-0.16.0-release-notes]], not a
replacement for them. Every named section in their table of contents appears
below. Follow the route for current wiki guidance or the numbered work item.

- **integrated** — useful claims are already represented on the linked page.
- **queued** — in scope, with a named roadmap destination; do not improvise
  guidance before that work lands.
- **watch** — retain as baseline, platform, or upgrade context; create a page
  only when a concrete systems decision needs it.
- **out of scope** — intentionally not part of the present systems-I/O corpus.

An entry being `integrated` does not mean that every detail in its release-note
section has been copied. It means the wiki has extracted the part needed for
its declared scope and preserved the primary-source link.

## Target support

| Release-note topic | Disposition | Route / reason |
| --- | --- | --- |
| Target Support | watch | Baseline for backend and runner claims; [[zig-0.16-baseline]] and M3. |
| Tier System | watch | Use the official tiers when qualifying portability evidence. |
| Tier 1 | watch | Release/CI context; no standalone guidance. |
| Tier 2 | watch | Release/CI context; no standalone guidance. |
| Tier 3 | watch | Release/CI context; no standalone guidance. |
| Tier 4 | watch | Release/CI context; no standalone guidance. |
| Support Table | watch | Re-check when choosing M3 test runners and on every Zig upgrade. |
| OS Version Requirements | watch | [[zig-0.16-baseline]] owns the compiler baseline; M3 pages must separately state minimum and actually tested OS versions. |
| Additional Platforms | watch | Revisit only when an additional platform becomes a project target. |

## Language changes

| Release-note topic | Disposition | Route / reason |
| --- | --- | --- |
| Language Changes | integrated | [[zig-0.16-baseline]] and the portable [[fi-zig-0.16-migration]] evidence define the migration boundary. |
| `switch` | queued | M2-005, centralized control flow and exhaustive state handling. |
| Equality Comparisons on Packed Unions | queued | M2-004, representation and serialization boundaries. |
| `@cImport` Moving to Build System | watch | Build/API migration fact; add guidance when a platform wrapper needs C headers. |
| `@Type` Replaced with Individual Type-Creating Builtin Functions | watch | Migration fact; use the 0.16 compiler/source when metaprogramming is required. |
| Allow Small Integer Types to Coerce to Floats | out of scope | No current systems-I/O decision depends on implicit integer-to-float coercion. |
| Forbid Runtime Vector Indexes | watch | Relevant only when SIMD enters a measured implementation. |
| Vectors and Arrays No Longer Support In-Memory Coercion | queued | M2-004, explicit representation boundaries. |
| Forbid Trivial Local Address Returned from Functions | watch | Migration and lifetime-safety fact; add focused guidance only when a concrete ownership pattern needs it. |
| Unary Float Builtins Forward Result Type | out of scope | No current systems-I/O decision depends on these float builtins. |
| `@floor`, `@ceil`, `@round`, `@trunc` Conversion to Integers | out of scope | No current systems-I/O decision depends on float-to-integer builtins. |
| Forbid Unused Bits in Packed Unions | queued | M2-004, explicit layout and serialization boundaries. |
| Forbid Pointers in Packed Structs and Unions | queued | M2-004, layout and pointer-ownership boundaries. |
| Allow Explicit Backing Integers on Packed Unions | queued | M2-004, explicit widths and wire/storage representation. |
| Forbid Enum and Packed Types with Implicit Backing Types in Extern Contexts | queued | M2-004, ABI and serialization boundaries. |
| Lazy Field Analysis | watch | Compiler semantic change; create guidance only for a concrete generic design. |
| Pointers to Comptime-Only Types Are No Longer Comptime-Only | watch | Compiler semantic change; create guidance only for a concrete generic design. |
| Explicitly-Aligned Pointer Types Now Distinct from Naturally-Aligned Pointer Types | queued | M2-004 and M2-008, alignment and platform API seams. |
| Simplified Dependency Loop Rules | watch | Architecture/build context; no present I/O decision depends on it. |
| Zero-bit Tuple Fields No Longer Implicitly `comptime` | watch | Migration fact; no standalone systems guidance planned. |

## Standard library: I/O interface

| Release-note topic | Disposition | Route / reason |
| --- | --- | --- |
| Standard Library | integrated | [[std-io]] is the primary 0.16 standard-library entry point for this corpus. |
| I/O as an Interface | integrated | [[std-io]], [[io-threaded]], and [[evented-io-backends]]. |
| Future | integrated | [[task-lifetimes-and-structured-concurrency]] and executable cancellation proofs. |
| Group | integrated | [[task-lifetimes-and-structured-concurrency]] and executable cancellation proofs. |
| Cancelation | integrated | [[cancellation]]; Linux/Windows blocked-call evidence remains M1-005. |
| Batch | integrated | [[select-and-batch]] covers `Select`, fixed operation storage, result ownership, cancellation, and partial completion. |
| Sync Primitives | queued | M1-006: `Event`, `Queue`, `Mutex`, `RwLock`, `Condition`, `Semaphore`, and `Futex`. |
| Entropy | queued | M1-009, explicit `Io` capability use and failure semantics. |
| Time | queued | M1-007: clocks, durations, deadlines, timeouts, and sleeping. |
| File System | queued | M1-008: files, directories, buffering, flush, and atomic persistence. |
| Networking | queued | M1-009 and M3: portable interface, DNS/sockets, then backend-specific evidence. |
| Process | queued | [[process-init-and-capabilities]] covers initialization; M1-009 retains child-process execution and lifetime. |
| `File.MemoryMap` | queued | M1-008 and M2-008: mapping lifetime, alignment, limits, and platform seams. |
| `posix` and `os.windows` removals | queued | M2-008 and M3: document the portable-interface/native-API boundary. |

## Standard library: other changes

| Release-note topic | Disposition | Route / reason |
| --- | --- | --- |
| `heap.ArenaAllocator` Becomes Thread-Safe and Lock-Free | queued | M2-002/M2-008: record where startup-only allocation still permits an arena. |
| `heap.ThreadSafeAllocator` Removed | queued | M2-002/M2-008: 0.16 allocator migration and explicit synchronization seam. |
| Add Deflate Compression, Simplify Decompression | out of scope | Add only if a concrete protocol or storage design requires compression. |
| Zlib Comparison | out of scope | Same compression boundary; no current decision depends on it. |
| Expanded target support for segfault handling/unwinding | queued | M1-012/M2-003: crash diagnostics and invariant-failure evidence. |
| Removal of `ucontext_t` and related types/functions | watch | Platform/runtime migration fact; relevant if implementing a scheduler. |
| Debug Information Reworked | queued | M1-012: diagnostics, stack traces, and bounded reporting boundaries. |
| Inter-Process Progress Reporting for Windows | watch | Toolchain UX, not the application I/O backend. |
| Windows Networking Without `ws2_32.dll` | queued | M3-004, current Zig source mapping beside IOCP and NtDll behavior. |
| Completed Migration to NtDll | queued | M3-004, native Windows system-call and error-translation boundary. |
| “Juicy Main” | integrated | [[process-init-and-capabilities]] covers entry-point shapes, runtime ownership, and narrower dependency threading. |
| Environment Variables and Process Arguments Become Non-Global | integrated | [[process-init-and-capabilities]] covers arguments, borrowed environment values, and the map's thread-safety boundary. |
| `mem`: introduce cut functions; rename “index of” to “find” | watch | Migration fact; use current names in all future proofs. |
| Selectively Walking Directory Trees | queued | M1-008, bounded directory traversal and cancellation. |
| `fs.path` Windows Paths | queued | M1-008/M3-004, portable path semantics versus native Windows paths. |
| `fs.path.relative` Became Pure | watch | Migration fact; integrate when path manipulation is taught. |
| `File.Stat`: Make Access Time Optional | queued | M1-008, optional metadata and unsupported-property handling. |
| “Preopens” | queued | [[process-init-and-capabilities]] covers startup ownership; M1-008 retains operational file-access guidance. |
| Atomic/Temporary Files | queued | M1-008 and M2-003, persistence protocols and assertion pairs. |
| Memory Locking and Protection API Moved to `process` | queued | M2-008, platform and capability seam for locked/protected memory. |
| Current Directory API Renamed | queued | M1-001/M1-008, explicit process capability and migration. |
| Migration to “Unmanaged” Containers | queued | M2-002/M2-008, explicit allocation ownership and limits. |
| `PriorityDequeue` | watch | Candidate for bounded schedulers; no current standalone decision. |
| `PriorityQueue` | watch | Candidate for bounded schedulers; no current standalone decision. |
| `Thread.Pool` Removed | queued | M1-006; do not confuse the removed public pool with [[io-threaded|`std.Io.Threaded`'s internal task pool]]. |
| Remove `builtin.subsystem` | watch | Platform migration fact; no current design depends on it. |
| Move `Target.SubSystem` to `zig.Subsystem` and update field names | watch | Platform migration fact; use current API if subsystem selection appears. |
| `Io`: delete `GenericReader`, `AnyReader`, `FixedBufferStream` | queued | M1-008, current reader/writer composition and buffering. |
| Replace `{D}` format specifier with `Io.Duration.format` method | queued | M1-007, duration representation and formatting. |
| `fs.getAppDataDir` Removed | queued | M1-001/M1-008, callers must supply policy/capability instead of global discovery. |
| `Io.Writer.Allocating` Alignment Field | queued | M1-008/M2-008, allocator and alignment ownership. |
| `fs.Dir.readFileAlloc` | queued | M1-008, allocation limits and caller-owned buffers. |
| `fs.File.readToEndAlloc` | queued | M1-008, allocation limits and untrusted input sizes. |
| `std.crypto`: add AES-SIV and AES-GCM-SIV | out of scope | Use only for a named protocol/security design with separate expert review. |
| `std.crypto`: add Ascon-AEAD, Ascon-Hash, Ascon-CHash | out of scope | Use only for a named protocol/security design with separate expert review. |

## Build system

| Release-note topic | Disposition | Route / reason |
| --- | --- | --- |
| Build System | watch | Proof compilation is centralized in `build.zig`; new build guidance needs a concrete maintenance problem. |
| Ability to Override Packages Locally | watch | Dependency-development workflow, not a current wiki decision. |
| Fetch Packages Into Project-Local Directory | watch | Dependency/reproducibility option; evaluate when the wiki gains dependencies. |
| Unit Test Timeouts | queued | M1-010 and M2-003, bounded behavioral proofs and hung-test containment. |
| Added `--error-style` Flag | queued | M1-012, human/agent diagnostic rendering and CI capture. |
| Added `--multiline-errors` Flag | queued | M1-012, human/agent diagnostic rendering and CI capture. |
| Temporary Files API | queued | M1-008, cleanup, atomic persistence, and bounded tests. |

## Compiler, linker, and fuzzer

| Release-note topic | Disposition | Route / reason |
| --- | --- | --- |
| Compiler | watch | Baseline context; backend details enter only when they change a system design or proof. |
| C Translation | watch | Relevant to native API ingestion; prefer maintained bindings/current headers. |
| LLVM Backend | watch | Target/code-generation context for performance and platform evidence. |
| Reworked Byval Syntax Lowering | watch | ABI/compiler fix; no standalone guidance. |
| Reworked Type Resolution | watch | Compiler implementation context; no standalone guidance. |
| Incremental Compilation | watch | Developer workflow; no present system-runtime decision. |
| x86 Backend | watch | Runner and code-generation context. |
| aarch64 Backend | watch | Runner and code-generation context. |
| WebAssembly Backend | out of scope | Not a current evented host-I/O target. |
| Generating Import Libraries from `.def` Files Without LLVM | watch | Relevant when producing Windows native bindings in M3-004. |
| Improved Code Generation of For Loop Safety Checks | queued | M2-003/M2-006, assertions and measured hot-loop design. |
| Linker | watch | Baseline/toolchain context. |
| New ELF Linker | watch | Linux build/runtime evidence context; no standalone guidance. |
| Fuzzer | queued | M2-003, negative-space testing and deterministic/fuzz testing boundaries. |
| Smith | watch | Compiler fuzzing technique; transfer only if a concrete grammar/state-machine test needs it. |
| Multiprocess Fuzzing | watch | Toolchain capability; evaluate for future protocol parsers. |
| Fuzzing Infinite Mode | watch | Toolchain capability; evaluate for future protocol parsers. |
| Crash Dumps | queued | M1-012/M2-003, actionable failure evidence from long-running tests. |
| Numerous bugs found and fixed with the help of an AST smith | watch | Evidence for generative testing, not application guidance by itself. |

## Bugs, toolchain, and project administration

| Release-note topic | Disposition | Route / reason |
| --- | --- | --- |
| Bug Fixes | watch | Do not treat the active stable release as bug-free; pin proofs and source revisions. |
| This Release Contains Bugs | integrated | [[zig-0.16-baseline]] requires executable evidence and explicit platform qualification. |
| Toolchain | watch | Re-check bundled versions and headers on every Zig upgrade. |
| LLVM 21 | watch | Code-generation and target-support baseline. |
| Loop Vectorization Disabled to Work Around Regression | watch | Performance evidence must name compiler/version and never assume vectorization. |
| musl 1.2.5 | watch | Linux libc and cross-compilation baseline. |
| glibc 2.43 | watch | Linux libc and cross-compilation baseline. |
| Linux 6.19 Headers | queued | M3-002, separate bundled headers from minimum runtime kernel/features. |
| macOS 26.4 Headers | queued | M3-003, separate SDK headers from minimum/tested macOS behavior. |
| MinGW-w64 | queued | M3-004, Windows ABI/header and native API mapping context. |
| FreeBSD 15.0 libc | watch | BSD platform context; no active runtime-proof lane. |
| WASI libc | out of scope | WASI is not a current evented host-I/O target. |
| zig libc | watch | Freestanding/cross-platform context; no current design depends on it. |
| zig cc | watch | Native dependency and cross-compilation tool; add guidance when required. |
| Support dynamically-linked OpenBSD libc when cross-compiling | watch | BSD cross-compilation context; no active runtime-proof lane. |
| Roadmap | watch | Upstream direction informs future upgrades but never changes this wiki's active baseline silently. |
| Thank You Contributors! | out of scope | Project acknowledgement, not technical guidance. |
| Thank You Sponsors! | out of scope | Project acknowledgement, not technical guidance. |

## Maintenance rule

When a queued entry is synthesized, change it to `integrated` in the same
commit and link the resulting page or proof. On a Zig upgrade, compare the new
release-note table of contents with this inventory: every added, removed, or
renamed topic requires an explicit disposition before the new baseline can be
declared active.
