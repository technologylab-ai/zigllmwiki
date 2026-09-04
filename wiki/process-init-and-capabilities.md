---
id: process-init-and-capabilities
title: std.process.Init and capability threading
kind: pattern
status: source-verified
zig: "0.16.0"
summary: Keep std.process.Init at the executable composition root, extract its I/O, allocation, argument, environment, and preopen capabilities, and pass narrower dependencies to libraries.
updated: 2026-09-04
sources:
  - "[[zig-0.16.0-release-notes]]"
  - "[[zig-0.16.0-stdlib]]"
  - "[[fi-zig-0.16-migration]]"
proofs:
  - proofs/process_init_capabilities.zig
platforms:
  - cross-platform
---

# `std.process.Init` and capability threading

## Remember

For a normal Zig 0.16 command, prefer `main(init: std.process.Init)`. The
runtime constructs a coherent process environment and gives the executable
explicit access to its default `std.Io`, allocators, arguments, environment
map, and preopened files.

Keep `std.process.Init` at the composition root. Application and library code
should accept the narrower capabilities it actually needs—often `io: std.Io`,
an allocator, and immutable configuration—rather than importing process-global
state or accepting the entire initializer.

## What the full initializer contains

| Field | Contract and ownership | Design consequence |
| --- | --- | --- |
| `minimal` | Raw `Args` and `Environ` supplied by the process. | Use for argument iteration or custom initialization. |
| `arena` | Thread-safe process-lifetime `*ArenaAllocator`, automatically deinitialized on exit. | Call `.allocator()`; do not deinitialize it. Allocation from it during service is still allocation, not TigerStyle startup reservation. |
| `gpa` | Thread-safe default allocator for temporary heap allocations; debug configurations enable leak checking when possible. | Do not wrap it in a redundant process GPA; free ordinary owned results according to their API. |
| `io` | Target-appropriate default `std.Io`; the ordinary 0.16 startup path constructs `std.Io.Threaded`. | Pass the interface onward and label behavior that depends on [[io-threaded|the implementation]]. |
| `environ_map` | Map initialized with `gpa`; explicitly not thread-safe and owned by startup. | Treat it as read-only after startup or copy selected values into owned immutable configuration before concurrency begins. |
| `preopens` | Named files supplied by the parent, especially relevant to WASI/capability-style execution. | Prefer provided authority over rediscovering global filesystem access. |

The runtime cleans up the allocators, environment map, preopens' arena storage,
and threaded I/O after `main` returns. A borrowed environment value remains
tied to its map; do not free or mutate it as if it were caller-owned storage.

## Accepted entry-point shapes

Zig 0.16 startup accepts a zero-parameter `main`, a first parameter of
`std.process.Init.Minimal`, or the full `std.process.Init`. A zero-parameter
entry point is still valid, but it deliberately declines the prepared
capabilities. `Minimal` supplies only raw arguments and environment; choose it
when the executable intends to construct the remaining runtime itself.

The full initializer is the normal application choice, not a value for every
function signature. Extract a small dependency aggregate near `main`, resolve
environment strings and configuration once, establish limits, then pass
specific fields or a `*const` application context down the call graph.

## Arguments and environment

Use `std.process.Args.Iterator.initAllocator(init.minimal.args, allocator)` for
one cross-platform argument path and always call `deinit`; POSIX may need no
internal allocation, while Windows and some WASI configurations do. The simpler
`Iterator.init` intentionally does not support Windows or WASI.

`init.environ_map.get(name)` returns a borrowed optional slice. Environment
access is now explicit rather than a hidden global lookup. The map is not
thread-safe, so startup should normally validate and copy only the values that
workers need. Do not repeatedly consult mutable ambient configuration in the
data plane.

## Capability boundary

Use this dependency direction:

`process startup → validated configuration and limits → component owners → leaf operations`

- `main` may know `std.process.Init`; reusable packages normally should not.
- A component that performs I/O accepts/stores the caller's `std.Io`; it does
  not create `std.Io.Threaded.global_single_threaded` as a convenience.
- An allocator parameter should name its lifetime/strategy in the owner, not
  disguise process-lifetime allocation as ordinary temporary allocation.
- Resolve environment and arguments into domain configuration before starting
  concurrent work.
- Preserve testability by allowing `std.testing.io`, a failing implementation,
  or a future evented backend to enter through the same boundary.

This is dependency injection in a very literal systems sense: authority,
nondeterminism, storage lifetime, and backend choice stay visible in APIs.

## TigerStyle seam

The runtime-provided arena and GPA improve defaults; they do not prove “all
memory allocated at startup.” A strict TigerStyle application still derives
maximum counts, reserves required state before admission begins, and audits
allocations inside the selected `std.Io` implementation. See
[[static-allocation-and-constant-work]].

Likewise, reading configuration once is not enough if its values leave limits
implicit. Parse sizes into explicit integer domains, reject invalid
relationships, calculate worst-case memory/kernel resources, and pass a
validated configuration to component owners.

## Evidence

The [process-init proof](../proofs/process_init_capabilities.zig) is both a test
module and an executable. `zig build verify` compiles and runs its real
`main(init: std.process.Init)`, checks the full field surface at compile time,
uses the cross-platform allocating argument iterator, and drives a leaf through
the caller-provided `std.Io`. It ran on aarch64 macOS with Zig 0.16.0 on
2026-09-04; other platforms retain source-level coverage until their runners
execute it.

Related: [[std-io]], [[io-threaded]], [[async-vs-concurrent]],
[[task-lifetimes-and-structured-concurrency]],
[[static-allocation-and-constant-work]], [[zig-0.16-baseline]].
