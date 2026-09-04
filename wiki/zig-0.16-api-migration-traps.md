---
id: zig-0-16-api-migration-traps
title: Zig 0.16 API migration traps
kind: map
status: source-verified
zig: "0.16.0"
summary: Repair common pre-0.16 language, allocation, filesystem, diagnostics, build, and fuzzing patterns without importing obsolete API or representation assumptions.
updated: 2026-09-04
sources:
  - "[[zig-0.16.0-release-notes]]"
  - "[[zig-0.16.0-stdlib]]"
proofs: []
platforms:
  - cross-platform
---

# Zig 0.16 API migration traps

## Remember

Use this page when an example from the internet fails against Zig 0.16.0 or
quietly carries an older ownership assumption. It is a migration map, not a
compatibility layer: write the current form directly and then follow the linked
page for the system-design consequences.

The exact old-to-new changes below come from the official
[[zig-0.16.0-release-notes]]. Current signatures and qualifications were
checked against the installed [[zig-0.16.0-stdlib]].

## Language and representation

### `switch`

Zig 0.16 permits packed structs and packed unions as switch-prong items and
compares them by their backing integer, just as packed-union equality does.
Prong items may now use declarations and other expressions that require a
result type. Union-tag captures are accepted on every prong, not only `inline`
ones. An error value outside the switched error set is permitted only for a
prong whose body is `comptime unreachable`, and a switch may no longer discard
every prong capture.

These features do not relax the state-machine rule: centralize transitions and
keep an exhaustive decision tree at the policy boundary. See
[[function-shape-and-control-flow]]. For packed representations, compare or
switch only when backing-bit equality is the intended semantic equality; see
[[integer-widths-and-boundaries]].

### Packed and extern types

Zig 0.16 requires every field of a packed union to have the same bit size as
the union's backing integer. Packed unions may now name that backing integer.
Pointers are forbidden in packed structs and packed unions. Enums and packed
types used in extern contexts must name an explicit tag or backing integer
rather than letting ABI layout depend on inference. Packed-union equality
compares the backing integer representation.

Do not repair a forbidden packed pointer by serializing its `usize` value.
Integer conversion can represent a process-local address for a native API, but
it does not create a stable wire or disk representation. The full boundary
pattern is in [[integer-widths-and-boundaries]].

### Arrays, vectors, and explicit alignment

Array and vector values still coerce when their element and length contracts
permit it, but their memory is no longer interchangeable through `@ptrCast`.
Replace an old array/vector pointer cast with a value coercion. If the source is
inside an error union, unwrap the error union before coercing the payload.

`*T` and `*align(@alignOf(T)) T` are distinct types in Zig 0.16 even though
they coerce to one another, including through pointers, in almost all ordinary
uses. Metaprogramming must not depend on those type values comparing equal.
At an OS or allocator boundary, preserve the explicitly promised alignment
instead of treating coercibility as proof that a stronger alignment exists.

## Allocation and container ownership

### Arenas are allocation-thread-safe, not lifecycle-thread-safe

`std.heap.ArenaAllocator.allocator()` is thread-safe and lock-free in Zig
0.16 provided its child allocator is thread-safe. That does not make every
arena method concurrent: the installed source explicitly marks `deinit`,
`reset`, and `queryCapacity` as not thread-safe. Stop users before changing the
arena lifecycle or inspecting those structures.

The generic `std.heap.ThreadSafeAllocator` wrapper was removed. Do not restore
the old pattern as a local wrapper by reflex. Select an allocator whose own
implementation and child are appropriate for the sharing pattern, or put
explicit synchronization at the owning component boundary. For a strict
steady-state service, reserve bounded storage before admission rather than
using thread safety as permission for unbounded runtime allocation. See
[[process-init-and-capabilities]] and [[static-allocation-and-constant-work]].

### Containers take allocators at allocating operations

The standard library is migrating away from containers that store an allocator
field. Pass the allocator to each operation that may allocate, which keeps
allocation authority and lifetime visible at the call site. In Zig 0.16 the
managed `ArrayHashMap`, `AutoArrayHashMap`, and `StringArrayHashMap` names are
removed; the former unmanaged variants are named `array_hash_map.Custom`,
`array_hash_map.Auto`, and `array_hash_map.String`. `PriorityQueue` and
`PriorityDequeue` likewise no longer own an allocator field.

This API shape helps review but does not impose a bound. A TigerStyle owner
must still derive capacity, reserve it during startup where possible, and make
exhaustion behavior explicit.

## Files, memory maps, and process capabilities

### Choose the portable or native layer deliberately

Many medium-level `std.posix` and `std.os.windows` functions were removed.
For portable capability-based operations, move upward to `std.Io`. When an
application deliberately owns a platform backend, move downward to the native
surface such as `std.posix.system` and keep the platform/error-translation seam
local. Do not infer native nonblocking or evented behavior from the portable
interface; use [[platform-io-backend-decision-table]].

### `File.MemoryMap` synchronizes only at explicit points

`std.Io.File.MemoryMap.create(io, file, options)` returns an owner that must be
released with `destroy(io)`. Its `memory` may or may not stay coherent with the
file: call `read(io)` to synchronize file contents into memory and `write(io)`
to synchronize memory into the file. This contract permits an implementation
to use ordinary file operations rather than a native mapping, and permits an
evented implementation to perform evented file I/O at the sync points.

The mapping length is explicit and must be bounded by the application.
`setLength` does not synchronize, may change the `memory` pointer, and leaves
the file length unspecified until `write`. Never retain a pointer into
`memory` across `setLength`. The offset is asserted to be page-aligned; the
requested length itself has no alignment requirement.

### Directory walking and metadata are explicit

Use `Dir.walkSelectively` when recursion needs filtering. It does not descend
automatically: after accepting a directory entry, call `walker.enter(io,
entry)`. `depth` reports traversal depth, and `leave` permits abandoning a
subtree. This avoids opening skipped directories and makes admission policy
visible.

`Io.File.Stat.atime` is optional. Treat `null` as access time unavailable; do
not substitute a fabricated timestamp or assume every filesystem maintains
fresh access times. Timestamp updates use independent access/modify choices so
an omitted value can remain unchanged.

For broader ownership, bounded-read, flush, atomic-publication, and durability
rules, use [[files-buffering-and-atomic-persistence]]. Preopened authority comes
from `std.process.Init.preopens`; see [[process-init-and-capabilities]].

### Windows path parsing is explicit and changed behavior

Zig 0.16 changed many `std.fs.path` results for UNC, rooted, and
drive-relative Windows paths. Do not preserve an older expected string without
retesting it against the exact path category. The old `windowsParsePath`,
`diskDesignator`, and `diskDesignatorWindows` entry points remain in the exact
0.16 source as deprecated compatibility declarations; migrate to `parsePath`,
`parsePathWindows`, and `parsePathPosix`. `getWin32PathType` was added, and
component-iterator initialization is no longer fallible.

The `relative`, `relativeWindows`, and `relativePosix` functions are now pure:
pass the current working-directory path and optional environment map needed for
Windows drive-relative resolution instead of expecting the helper to query
ambient OS state. Obtain and validate those inputs at the process-capability
boundary, then pass them explicitly to the component that owns path policy.

### Current path, application-data policy, and protected memory

The old `std.process.getCwd` and `getCwdAlloc` names became
`currentPath(io, buffer)` and `currentPathAlloc(io, allocator)`. Prefer passing
an opened directory or configured path into components instead of repeatedly
querying mutable process-global current-directory state.

`std.fs.getAppDataDir` was removed because its policy was too opinionated for
the standard library. Application startup must choose or receive the location,
validate it, and pass it as configuration; do not hide the replacement behind
another ambient global lookup.

Memory locking and protection moved from the medium-level POSIX surface to
`std.process`. Current calls include `lockMemory`, `lockMemoryAll`,
`unlockMemory`, `unlockMemoryAll`, and `protectMemory`, with typed option
structures and explicit unsupported/permission/resource errors. Locked memory
is a finite process/OS resource: configure a maximum, page-align the range
where required, and handle a refused lock rather than asserting universal
support.

### Reader, writer, and allocating-read migrations

The old generic and erased reader types converge on `std.Io.Reader`:

| Old shape | Zig 0.16 shape |
| --- | --- |
| `std.io` | `std.Io` |
| `std.Io.GenericReader` or `std.Io.AnyReader` | `std.Io.Reader` |
| reading `std.io.fixedBufferStream(data)` | `std.Io.Reader.fixed(data)` |
| writing `std.io.fixedBufferStream(buffer)` | `std.Io.Writer.fixed(buffer)` |
| `std.leb.readUleb128` / `readIleb128` | `Reader.takeLeb128` |

`File.readToEndAlloc` became a `File.Reader` operation: create the file reader,
then call `file_reader.interface.allocRemaining(allocator, limit)`. Supply a
real `std.Io.Limit`; returned storage belongs to the caller.

`Dir.readFileAlloc` now accepts `io`, allocator, and `std.Io.Limit`. Its ceiling
is exclusive: reaching or exceeding it returns `error.StreamTooLong`, not the
old `error.FileTooBig`. [[files-buffering-and-atomic-persistence]] covers the
exact-fit trap and the fixed-storage alternative.

`std.Io.Writer.Allocating` stores a runtime `std.mem.Alignment` and uses the
allocator raw operations to honor it. Initialize the writer with the required
alignment, preserve that value when transferring owned storage, and call
`deinit` unless ownership was explicitly transferred. Converting to an aligned
array list asserts that the requested alignment matches the stored one.

`Io.Duration` uses its formatting method through `{f}`; the old `{D}` format is
removed. See [[io-time-clocks-and-deadlines]] for clock-domain and deadline
rules.

## Diagnostics and build tooling

Zig 0.16 expanded crash/error-return unwinding and reworked the standard debug
APIs. Use `std.debug.captureCurrentStackTrace` to capture, and
`std.debug.writeStackTrace` to render a captured trace to an `Io.Terminal`;
`dumpStackTrace` is the stderr-oriented debugging convenience. Treat symbol
quality as a build-and-platform property that needs evidence: an error path
must remain actionable even when a trace is absent or incomplete. Keep typed
recovery separate from bounded presentation as described in
[[error-handling-and-diagnostics]].

For build output, `zig build --error-style` accepts `verbose` (the default),
`minimal`, `verbose_clear`, or `minimal_clear`. The clear variants are intended
for watch mode. `ZIG_BUILD_ERROR_STYLE` supplies the default when the flag is
absent. The removed `--prominent-compile-errors` behavior maps to
`--error-style minimal`.

`zig build --multiline-errors` accepts `indent` (the default), `newline`, or
`none`; `ZIG_BUILD_MULTILINE_ERRORS` supplies the default when the flag is
absent. CI should choose a stable non-clearing style and retain the failed
command/context needed by the agent rather than optimizing only for terminal
appearance.

Build-script temporary files also changed. `RemoveDir` and
`Build.makeTempPath` are gone. Use `Build.addTempFiles` plus the `WriteFile`
step, or `Build.tmpPath`; successful build completion owns cleanup and these
temporary outputs are not cacheable. Use `UpdateSourceFiles` for intentional
source-tree mutations rather than treating source files as temporary output.

Per-test real-time containment is already documented in
[[testing-io-and-single-threaded-builds]]: `zig build --test-timeout` kills and
restarts the test process after an individual test times out, then continues.

## Fuzzing and crash reproduction

Zig 0.16 fuzz callbacks receive `*std.testing.Smith` rather than an arbitrary
`[]const u8` input. Smith supplies typed generation (`value`), buffer filling
(`bytes` and `slice`), and eventual end-of-stream generation (`eos`), with
weighted variants for biasing cases and work. Bound generated collection sizes
and operation counts inside the model even when the external runner is also
limited.

The fuzzer writes a crashing input to the path in its crash message. Preserve
that artifact and turn it into a deterministic regression corpus with
`std.testing.FuzzInputOptions.corpus` and `@embedFile`. A saved input without a
replay test is unfinished evidence. See [[deterministic-simulation-testing]]
for the distinction between reproducible state exploration and host-backed
fuzz scheduling, and [[error-path-catalogs-and-fault-injection]] for choosing
the terminal paths a campaign must cover.

## Toolchain facts are not runtime floors

Zig 0.16.0 bundles Linux 6.19 headers and macOS 26.4 system headers. That says
which declarations may be available while compiling; it does not prove that a
target kernel supports a syscall, flag, or completion behavior. Keep runtime
feature probing and tested OS/kernel floors separate. The concrete Linux matrix
is in [[io-uring]], and Apple backend evidence is in
[[macos-kqueue-and-aio]].

Related: [[zig-0.16-release-inventory]], [[zig-0.16-baseline]], [[std-io]],
[[integer-widths-and-boundaries]], [[process-init-and-capabilities]],
[[files-buffering-and-atomic-persistence]], [[platform-io-backend-decision-table]].
