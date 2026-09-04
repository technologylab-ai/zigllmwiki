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
| `switch` | integrated | [[zig-0.16-api-migration-traps]] records the new prong forms and packed backing-integer comparison; [[function-shape-and-control-flow]] owns the state-machine consequence. |
| Equality Comparisons on Packed Unions | integrated | [[integer-widths-and-boundaries]] records backing-integer equality and its serialization limits. |
| `@cImport` Moving to Build System | watch | Build/API migration fact; add guidance when a platform wrapper needs C headers. |
| `@Type` Replaced with Individual Type-Creating Builtin Functions | watch | Migration fact; use the 0.16 compiler/source when metaprogramming is required. |
| Allow Small Integer Types to Coerce to Floats | out of scope | No current systems-I/O decision depends on implicit integer-to-float coercion. |
| Forbid Runtime Vector Indexes | watch | Relevant only when SIMD enters a measured implementation. |
| Vectors and Arrays No Longer Support In-Memory Coercion | integrated | [[zig-0.16-api-migration-traps]] distinguishes value coercion from the removed array/vector pointer reinterpretation. |
| Forbid Trivial Local Address Returned from Functions | watch | Migration and lifetime-safety fact; add focused guidance only when a concrete ownership pattern needs it. |
| Unary Float Builtins Forward Result Type | out of scope | No current systems-I/O decision depends on these float builtins. |
| `@floor`, `@ceil`, `@round`, `@trunc` Conversion to Integers | out of scope | No current systems-I/O decision depends on float-to-integer builtins. |
| Forbid Unused Bits in Packed Unions | integrated | [[integer-widths-and-boundaries]] requires every field to match the backing integer's bit size. |
| Forbid Pointers in Packed Structs and Unions | integrated | [[integer-widths-and-boundaries]] records the prohibition and why a process-local integer address is not serialization. |
| Allow Explicit Backing Integers on Packed Unions | integrated | [[integer-widths-and-boundaries]] requires explicit widths at representation boundaries. |
| Forbid Enum and Packed Types with Implicit Backing Types in Extern Contexts | integrated | [[integer-widths-and-boundaries]] requires explicit tag/backing types at ABI boundaries. |
| Lazy Field Analysis | watch | Compiler semantic change; create guidance only for a concrete generic design. |
| Pointers to Comptime-Only Types Are No Longer Comptime-Only | watch | Compiler semantic change; create guidance only for a concrete generic design. |
| Explicitly-Aligned Pointer Types Now Distinct from Naturally-Aligned Pointer Types | integrated | [[zig-0.16-api-migration-traps]] records distinct type identity, ordinary coercibility, and the OS/allocator alignment consequence. |
| Simplified Dependency Loop Rules | watch | Architecture/build context; no present I/O decision depends on it. |
| Zero-bit Tuple Fields No Longer Implicitly `comptime` | watch | Migration fact; no standalone systems guidance planned. |

## Standard library: I/O interface

| Release-note topic | Disposition | Route / reason |
| --- | --- | --- |
| Standard Library | integrated | [[std-io]] is the primary 0.16 standard-library entry point for this corpus. |
| I/O as an Interface | integrated | [[std-io]], [[io-threaded]], and [[evented-io-backends]]. |
| Future | integrated | [[task-lifetimes-and-structured-concurrency]] and executable cancellation proofs. |
| Group | integrated | [[task-lifetimes-and-structured-concurrency]] and executable cancellation proofs. |
| Cancelation | integrated | [[cancellation]]; task semantics and blocked pipe-read runtime evidence are integrated on macOS, Linux, and Windows. |
| Batch | integrated | [[select-and-batch]] covers `Select`, fixed operation storage, result ownership, cancellation, and partial completion. |
| Sync Primitives | integrated | [[io-synchronization-primitives]] covers `Event`, `Queue`, `Mutex`, `RwLock`, `Condition`, `Semaphore`, and futex operations. |
| Entropy | integrated | [[entropy-and-deterministic-randomness]] distinguishes process-state randomness from cancelable fresh external entropy and its failure semantics. |
| Time | integrated | [[io-time-clocks-and-deadlines]] covers clock resolution, timestamps, durations, deadlines, timeouts, sleeping, and the 0.16 migration. |
| File System | integrated | [[files-buffering-and-atomic-persistence]] owns current file/directory behavior; [[zig-0.16-api-migration-traps]] preserves the important old-to-new API shapes. |
| Networking | integrated | [[networking-and-dns-racing]] covers the portable DNS/socket interface; M3 retains backend-specific evidence. |
| Process | integrated | [[process-init-and-capabilities]] covers initialization and [[child-process-lifecycles]] covers execution, output, and terminal ownership. |
| `File.MemoryMap` | integrated | [[zig-0.16-api-migration-traps]] covers ownership, explicit synchronization, resizing, pointer invalidation, limits, and implementation freedom. |
| `posix` and `os.windows` removals | integrated | [[zig-0.16-api-migration-traps]] and [[platform-io-backend-decision-table]] make the higher-level `std.Io` versus lower native-surface choice explicit. |

## Standard library: other changes

| Release-note topic | Disposition | Route / reason |
| --- | --- | --- |
| `heap.ArenaAllocator` Becomes Thread-Safe and Lock-Free | integrated | [[zig-0.16-api-migration-traps]] distinguishes thread-safe allocation from non-thread-safe reset/deinit/query operations; [[static-allocation-and-constant-work]] owns steady-state policy. |
| `heap.ThreadSafeAllocator` Removed | integrated | [[zig-0.16-api-migration-traps]] routes callers to an allocator appropriate for the sharing pattern or explicit owner synchronization. |
| Add Deflate Compression, Simplify Decompression | out of scope | Add only if a concrete protocol or storage design requires compression. |
| Zlib Comparison | out of scope | Same compression boundary; no current decision depends on it. |
| Expanded target support for segfault handling/unwinding | integrated | [[zig-0.16-api-migration-traps]] records the current trace APIs and keeps trace quality qualified by build and platform evidence; [[error-handling-and-diagnostics]] owns bounded reporting. |
| Removal of `ucontext_t` and related types/functions | watch | Platform/runtime migration fact; relevant if implementing a scheduler. |
| Debug Information Reworked | integrated | [[zig-0.16-api-migration-traps]] records capture/render entry points and the no-guaranteed-symbolization caveat. |
| Inter-Process Progress Reporting for Windows | watch | Toolchain UX, not the application I/O backend. |
| Windows Networking Without `ws2_32.dll` | integrated | [[windows-iocp-and-overlapped-io]] maps Zig 0.16's direct asynchronous AFD/NtDll networking, cancellation, batch limitations, and the boundary from custom IOCP. |
| Completed Migration to NtDll | integrated | [[windows-iocp-and-overlapped-io]] records the exact stable NT syscall layer, operation-specific status translation, and why it is neither Winsock nor IOCP. |
| “Juicy Main” | integrated | [[process-init-and-capabilities]] covers entry-point shapes, runtime ownership, and narrower dependency threading. |
| Environment Variables and Process Arguments Become Non-Global | integrated | [[process-init-and-capabilities]] covers arguments, borrowed environment values, and the map's thread-safety boundary. |
| `mem`: introduce cut functions; rename “index of” to “find” | watch | Migration fact; use current names in all future proofs. |
| Selectively Walking Directory Trees | integrated | [[zig-0.16-api-migration-traps]] records explicit `enter`, depth, and subtree-leave semantics; [[files-buffering-and-atomic-persistence]] owns directory resources. |
| `fs.path` Windows Paths | integrated | [[zig-0.16-api-migration-traps]] records UNC/rooted/drive-relative behavior changes and the current parsing/type APIs. |
| `fs.path.relative` Became Pure | integrated | [[zig-0.16-api-migration-traps]] requires explicit current-path/environment inputs and keeps ambient state at the process boundary. |
| `File.Stat`: Make Access Time Optional | integrated | [[zig-0.16-api-migration-traps]] treats `atime == null` as unavailable and records the independent timestamp-update choices. |
| “Preopens” | integrated | [[process-init-and-capabilities]] covers `std.process.Init.preopens`, startup ownership, and capability-oriented file access. |
| Atomic/Temporary Files | integrated | [[files-buffering-and-atomic-persistence]] separates temporary-file ownership, atomic publication, file synchronization, and directory durability. |
| Memory Locking and Protection API Moved to `process` | integrated | [[zig-0.16-api-migration-traps]] records current process calls, typed options, alignment, finite limits, and failure handling. |
| Current Directory API Renamed | integrated | [[zig-0.16-api-migration-traps]] records `currentPath`/`currentPathAlloc`; [[process-init-and-capabilities]] keeps ambient process state at the composition root. |
| Migration to “Unmanaged” Containers | integrated | [[zig-0.16-api-migration-traps]] records allocator-at-operation ownership and the 0.16 container names; [[static-allocation-and-constant-work]] supplies the capacity policy. |
| `PriorityDequeue` | watch | Candidate for bounded schedulers; no current standalone decision. |
| `PriorityQueue` | watch | Candidate for bounded schedulers; no current standalone decision. |
| `Thread.Pool` Removed | integrated | [[io-synchronization-primitives]] routes task concurrency to `std.Io`; [[io-threaded]] keeps its internal pool an implementation detail. |
| Remove `builtin.subsystem` | watch | Platform migration fact; no current design depends on it. |
| Move `Target.SubSystem` to `zig.Subsystem` and update field names | watch | Platform migration fact; use current API if subsystem selection appears. |
| `Io`: delete `GenericReader`, `AnyReader`, `FixedBufferStream` | integrated | [[zig-0.16-api-migration-traps]] maps the removed forms to `Io.Reader`, `Reader.fixed`, and `Writer.fixed`. |
| Replace `{D}` format specifier with `Io.Duration.format` method | integrated | [[io-time-clocks-and-deadlines]] records `{f}` on `Io.Duration` and removal of `{D}`. |
| `fs.getAppDataDir` Removed | integrated | [[zig-0.16-api-migration-traps]] makes application-data location an explicit startup policy/capability. |
| `Io.Writer.Allocating` Alignment Field | integrated | [[zig-0.16-api-migration-traps]] records runtime alignment ownership, matching transfer, and deinitialization. |
| `fs.Dir.readFileAlloc` | integrated | [[files-buffering-and-atomic-persistence]] covers caller ownership and the exclusive `Io.Limit`/`StreamTooLong` boundary. |
| `fs.File.readToEndAlloc` | integrated | [[zig-0.16-api-migration-traps]] routes the removed method through `File.Reader.interface.allocRemaining` with a real limit. |
| `std.crypto`: add AES-SIV and AES-GCM-SIV | out of scope | Use only for a named protocol/security design with separate expert review. |
| `std.crypto`: add Ascon-AEAD, Ascon-Hash, Ascon-CHash | out of scope | Use only for a named protocol/security design with separate expert review. |

## Build system

| Release-note topic | Disposition | Route / reason |
| --- | --- | --- |
| Build System | watch | Proof compilation is centralized in `build.zig`; new build guidance needs a concrete maintenance problem. |
| Ability to Override Packages Locally | watch | Dependency-development workflow, not a current wiki decision. |
| Fetch Packages Into Project-Local Directory | watch | Dependency/reproducibility option; evaluate when the wiki gains dependencies. |
| Unit Test Timeouts | integrated | [[testing-io-and-single-threaded-builds]] covers per-test real-time containment, process restart, continuation, and scheduler-load caveats. |
| Added `--error-style` Flag | integrated | [[zig-0.16-api-migration-traps]] records all four values, the environment default, and replacement of `--prominent-compile-errors`. |
| Added `--multiline-errors` Flag | integrated | [[zig-0.16-api-migration-traps]] records `indent`, `newline`, `none`, and the environment default. |
| Temporary Files API | integrated | [[zig-0.16-api-migration-traps]] distinguishes build-step temporary outputs from runtime `File.Atomic` and records build-owned cleanup. |

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
| Improved Code Generation of For Loop Safety Checks | watch | Compiler optimization data point, not an application pattern; keep safety checks and use [[trustworthy-microbenchmarks]] before changing a measured hot loop. |
| Linker | watch | Baseline/toolchain context. |
| New ELF Linker | watch | Linux build/runtime evidence context; no standalone guidance. |
| Fuzzer | integrated | [[zig-0.16-api-migration-traps]] records the `*std.testing.Smith` input model, bounding requirement, and deterministic crash replay; [[deterministic-simulation-testing]] owns scheduler distinctions. |
| Smith | integrated | [[zig-0.16-api-migration-traps]] records typed, byte/slice, end-of-stream, and weighted generation at the level needed for current fuzz-test migration. |
| Multiprocess Fuzzing | watch | Toolchain capability; evaluate for future protocol parsers. |
| Fuzzing Infinite Mode | watch | Toolchain capability; evaluate for future protocol parsers. |
| Crash Dumps | integrated | [[zig-0.16-api-migration-traps]] turns saved fuzzer crash inputs into embedded deterministic regression corpus entries. |
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
| Linux 6.19 Headers | watch | Bundled declarations are compile-time context, not a runtime feature floor; [[zig-0.16-api-migration-traps]] states the distinction and [[io-uring]] owns tested kernel/feature evidence. |
| macOS 26.4 Headers | watch | Bundled declarations are compile-time context, not a minimum or tested OS claim; [[zig-0.16-api-migration-traps]] states the distinction and [[macos-kqueue-and-aio]] owns runtime evidence. |
| MinGW-w64 | watch | Zig 0.16 retains pinned MinGW-w64 commit `38c8142f660b6ba11e7c408f2de1e9f8bfaf839e` while moving more libc functions into zig libc; this is cross-compilation/toolchain context, not Windows runtime evidence. |
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
