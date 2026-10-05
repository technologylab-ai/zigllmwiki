# Migrate Zig 0.16.0 projects to 0.17.0

This guide records the Baz dependency migration performed on 2026-10-04.
It covers Baz, [bounded/http](https://technologylab-ai.github.io/bounded-http/), Mustache, zli, and Omajot.
Omajot adds libvaxis, zigimg, and uucode dependency findings.
The wiki's active compiler and maintained proofs now target **0.17.0**.
Use this guide for an explicit project upgrade to **0.17.0**.

The compiler's exact source defines APIs and semantics.
Read the [release notes](https://ziglang.org/download/0.17.0/release-notes.html) after that source.
The pinned [source record](../sources/zig-0.17.0-stdlib.md) identifies the release commit and inspected files.
The [project evidence record](../sources/zig-0.17-project-ports-2026-10-04.md) identifies revisions, gates, and limits.
The [final verification record](../sources/zig-0.17-final-verification-2026-10-04.md)
closes the initial application and ordinary wiki gates, with the experimental full ARM64 gate deferred.
The [Omajot follow-up record](../sources/omajot-zig-0.17-2026-10-04.md) adds final Baz integration and consumer evidence.
The [Omagma follow-up record](../sources/omagma-zig-0.17-stdlib-followup-2026-10-05.md) adds descriptor-flag and HTTP-header findings.
The [terminal follow-up record](../sources/omagma-zig-0.17-terminal-followup-2026-10-05.md) adds allocator removal, libc wrappers, and input-fragment findings.

## Port the complete dependency graph

1. Record the initial commits, local edits, compiler, platforms, and dependency hashes.
2. Create isolated branches for the application and each dependency that needs changes.
3. Read each repository's agent contract and shared-host reservation protocol.
4. Port dependencies first. Keep parser, transport, and scheduler changes in their owning repository.
5. Pin the application to immutable dependency commits and hashes.
6. Verify the final URL graph, including an independent consumer package.
7. Run native correctness gates before writing the final migration conclusions.

Use the exact compiler through both its path and the task's `PATH`.
Python version checks and nested builds can otherwise invoke the old compiler.
Our first Linux attempt found this mismatch before running its gates.
Keep the machine's default compiler unchanged when other projects still require 0.16.0.

Do not trust a successful build as a semantic audit.
Some changes compile while altering bytes, reflection visibility, or application behavior.
Inspect every cast and reflection consumer separately.

## Audit every `@bitCast` by its intended meaning

Zig 0.17 changes `@bitCast` from memory reinterpretation to logical bit conversion.
For arrays and vectors, element zero occupies the least significant bits.
This ordering is independent of host endianness.
Padding does not become value bits.
Source and destination require equal logical bit counts; equal `@sizeOf` is insufficient.
Extern structs and unions cannot use this conversion.
Vectors of pointers cannot use `@bitCast` in 0.17.

Classify each cast before replacing it:

| Intended result | Migration action | Independent oracle |
| --- | --- | --- |
| Scalar or packed value bits | Check bit widths, signedness, and enum validity. | Expected numeric value or backing value. |
| Array/vector lane bits | Keep logical conversion when lane zero must map to low bits. | Scalar algorithm across lanes and tails. |
| Bytes in native memory | Use an explicit memory operation with the required native representation. | Compare object bytes with literal bytes. |
| Protocol numeric field | Decode or encode with the protocol's explicit byte order. | Fixed wire bytes and expected number. |

Do not use a cast followed by its inverse as the oracle.
Both operations can agree while the external representation is wrong.
Little-endian hosts can also conceal an endianness error.

### IPv4 socket storage

The original engine converted four address bytes to a native `u32` with `@bitCast`.
For `[127, 0, 0, 1]`, the new logical result is `0x0100007f` on every target.
Storing that number produces the desired bytes on little-endian hosts.
It produces different bytes on big-endian hosts.

The port uses `std.mem.readInt(u32, &bind_address, std.lang.Endian.native)`.
The socket field needs the same in-memory bytes as the address array.
A big-endian numeric read alone would break the little-endian representation.
The new tests inspect `std.mem.asBytes` against literal IPv4 bytes.
They do not convert back with `@bitCast`.

Mac, Linux, and Windows evidence here uses little-endian machines.
The big-endian probe is compile-time evidence only.
It proves the representation distinction; it does not establish native big-endian socket behavior.

### Parser masks and delimiter lanes

The engine keeps seven intentional parser casts.
Boolean vector lane `i` must become bit `i` before trailing-zero counting.
The parser now has scalar oracles for fixed names, ASCII case folding, delimiters, tails, and competing matches.

Repeat `0x20` as typed byte lanes when building a case-fold mask.
A scalar integer value of `0x20` does not represent repeated `0x20` bytes.
Test lengths across vector widths and every possible delimiter lane.

Baz had no direct `@bitCast` calls before this migration.
That fact did not exempt its dependencies or fixtures from inspection.

Use `@backingInt` and `@fromBackingInt` for enum backing values and packed
types with explicit backing integers. The old enum builtin names are deprecated.
The constructor requires the exact backing integer type; `zig fmt` may insert
an `@intCast` while porting it. Check ranges and valid enum tags before accepting
that rewrite. The engine uses `@backingInt` for explicit packed OS flags,
keeping their numeric representation intent clear.

## Preserve array and string meaning

Array repetition with `**` is removed. `zig fmt` does not port it.
Use a typed `@splat` when each element has the same value.
Use a bounded compile-time copy when a multi-byte pattern must repeat.

Preserve the caller's type contract: array, slice, string pointer, and sentinel are different requirements.
Mustache treats a raw array as iterable input.
Replacing a string pointer with an array can compile and change rendering.
The port keeps borrowed string-pointer behavior for those fixtures.

Baz's large fixture helper exposed a compiler performance trap.
An `undefined` destination plus doubling copies made a five-MiB compile-time fixture very slow.
The 0.17 evaluator scanned partially initialized array storage while updating elements.
Initializing the destination with `@splat(0)` avoided that repeated scan.
The same response unit compiled in about two seconds after the change.
Loop iteration count alone did not predict evaluator cost.

One borrowed-body fixture uses repeated byte arrays and `std.mem.asBytes`.
Its elements are `u8`, so this fixture has no inter-element padding.
It requires a borrowed slice, not a sentinel string.
Do not generalize that representation shortcut to arbitrary element types.

A helper file also triggered duplicate ownership when two modules imported it independently.
Share a dedicated module, or keep a fixture private to one module.
Do not import the same file into separate module roots by relative path.

### Replace removed sentinel allocation helpers

Exact 0.16 defines deprecated `Allocator.dupeZ` as a wrapper around `dupeSentinel(T, m, 0)`.
Exact 0.17 removes `dupeZ` and retains `dupeSentinel`.
For a byte path, use `allocator.dupeSentinel(u8, path, 0)` to obtain owned `[:0]u8` storage.
Ordinary `dupe` returns an unsentinel slice and does not preserve the termination contract.
Free the original sentinel slice with the same allocator.
Sentinel allocation does not validate embedded NUL bytes; validate paths before passing them to C APIs.
The [terminal follow-up](../sources/omagma-zig-0.17-terminal-followup-2026-10-05.md) pins both exact allocator sources.
This removal is a release API change, separate from the terminal bugs described below.

## Migrate reflection as related columns

Zig 0.17 reflection uses separate names, types, and attributes.
Keep each field's original index across those columns.
Filtering one column and indexing another by the filtered position changes the association.
zli needed this rule for interleaved positional arguments and option aliases.

| Old shape | New shape to inspect |
| --- | --- |
| Struct field records | `field_names`, `field_types`, `field_attrs` |
| Type declarations | `decl_names` |
| Function parameter records | `param_types` |
| Error-set records | `error_names` |
| Pointer qualifiers | Pointer `attrs` |
| Constructed tuple/integer types | `@Tuple`, `@Int` |
| Field type queries | `@FieldType` |

Use the typed attribute method `attrs.defaultValue(FieldType)` for default values.
`FieldType` must match the associated `field_types` entry.
Distinguish a missing default from a present default whose optional value is null.
For an optional field, the returned outer optional identifies whether a default exists.
The zli regression tests cover required positionals, null defaults, aliases, and field ordering.

Generated structs need consistent names, types, and `std.lang.Type.Struct.FieldAttributes`.
Use typed attribute storage and `@Struct` after checking the exact release signatures.
Avoid mechanical substitutions that discard qualifiers or defaults.

## Check visibility and cleanup hooks

`@hasDecl` now reports public declarations.
Code that inspected private declarations in the same file can change behavior without a compile error.
Baz requires public endpoint hooks and a public optional state `deinit` hook.

The port publishes intended hooks and tests rejected private hooks.
Its lifecycle test covers six terminal paths.
The test checks cleanup exactly once, cleanup before local storage release, and slot reuse.
Include error, cancellation, deadline, and shutdown paths when reflection controls cleanup.

The removed `errdefer |err|` capture syntax required a wrapper and explicit `catch` in `Stream.copyFrom`.
Ordinary `errdefer` remains available.
The wrapper preserves the first sticky error.
Existing tests still cover write failures, cancellation, short input, and later errors.
Moving syntax must preserve error ordering and ownership.

## Update build APIs and machine-readable output

The optimization enum tags are `debug`, `safe`, `fast`, and `small`.
Use `-Doptimize=safe` for ReleaseSafe builds.
The old command-line spelling remains accepted as an alias.
However, `@tagName(builtin.mode)` now emits `safe` instead of `ReleaseSafe`.
Update READY parsers, receipts, CLI fixtures, and generators that consume that output.

Keep assertions enabled. Baz and bounded/http reject `fast` and `small`.
Run correctness in Debug and Safe.
Run performance workloads and warmups only in Safe.

| Build-system change | Applied port |
| --- | --- |
| Removed `b.args` | Run steps call `addPassthruArgs()`. |
| Formatting paths | Use `b.pathList(...)` with the new path type. |
| Configuration-time `LazyPath.getPath` removed | Pass lazy file/directory arguments to dependent steps. |
| Generated output directory | Use `addOutputDirectoryArg2` and preserve the dependency edge. |
| Directory creation for arguments | Use the explicit argument options, including `make_absolute` where required. |

The engine embedding fixture passes `--prefix` and its value as separate arguments.
The joined `--prefix=value` form did not work in that port.
Baz's documentation normalizer receives known module roots from the build graph.
It does not resolve generated paths during configuration.

Keep an independent package-consumer gate.
An in-repository build can pass while packaging, exports, or generated paths remain wrong.

## Verify download and package behavior

At capture time, the official download index omitted 0.17.0.
The versioned notes, release archives, and valid signatures were available.
The ports use checked-in archive URLs and SHA-256 values.
The curator verified all five selected archive signatures with the official minisign key.
Do not silently substitute a development compiler when an index entry is missing.

Standalone `zig fetch URL` exposed another 0.17 issue for GitHub tarballs.
It printed the correct package hash but cached an extra archive root directory.
A later build then reported a naked-package `N-V-...` hash mismatch.
Source inspection suggests the cause: global-only fetching recompresses the temporary root instead of the stripped package directory.
The captured archive entries confirm the extra directory.

First quarantine task-created malformed entries, or select a clean isolated global cache.
Then fetch through a real build, or use a disposable manifest with `--save` for local storage.
Verify the resulting package through an independent consumer.
Quarantine only the cache files your task created if you reproduce this issue.
Keep the original archive entries and failure log for diagnosis.
Do not weaken or replace correct package hashes to accept the malformed cache.

## Preserve current upstream behavior before porting

Fetch current main before creating upgrade branches.
Compare it with the local base and each consumer's pinned revision.
A compiler port from an old main can pass tests while losing existing features.
The first Baz port started from `2258ff87`; Omajot already consumed `c7d489a2`.
That newer revision added route deadlines and removed forced libc linkage.
Omajot's native executable failed because the initial port lacked `RouteOptions.timeout_ms`.
Baz `55099ec6` integrates current main with the compiler port.
Qualify that merged revision with new gates.
Keep earlier receipts attached to their original revisions.

## Review dependency upgrades for behavior changes

Prefer a tested upstream compatibility revision that preserves the required APIs.
Pin its commit and complete dependency graph.
A moving compatibility branch is insufficient.
Omajot selects libvaxis `6fd944a2`, zigimg `c701c9f9`, and uucode `ea621497`.
The separately inspected uucode `1fb73433` changes compiler metadata but has identical source files and Unicode inputs.
Retain libvaxis's published graph unless evidence requires a dependency fork.

Deprecated spellings alone do not prove an incompatible dependency.
Exact 0.17 source still supports `std.builtin` aliases, `OptimizeMode`, and uppercase optimization constants.
Inspect their definitions and compile the selected package before replacing them.

The uucode update also moves its Unicode data from 17 to 18.
Changes include Indic-conjunct/emoji grapheme state, codepoint widths, and default versus Turkic case folding.
The update also fixes typed packed/signed table initialization and generator input tracking.
These changes affect TUI cursor movement, deletion, wrapping, and width calculations.
Omajot's replication core still uses UTF-8, UTF-16 positions, `std.unicode`, and JSON.
Run the dependency's oracle suites and the application's native TUI tests.
A successful compile does not qualify Unicode behavior.
Keep their results separately scoped.

### Qualify fragmented terminal input

The pinned POSIX libvaxis loop can consume incomplete UTF-8 bytes instead of retaining them for another read.
The pinned uucode iterator substitutes U+FFFD; the parser can still expose the original incomplete bytes as key text.
The loop's separate malformed-input discard branch is not established as the cause of Omagma's lost-emoji witness.
Treat the missing persisted bytes as reported project evidence and the parser behavior as a source conclusion.
This finding does not establish a Zig compiler regression.

Retain incomplete codepoints with an explicit byte bound and a bounded malformed-input policy.
Bound pending control sequences separately from codepoint length.
Give queued text an owner beyond the parser buffer's reuse.
Test forced read splits with literal expected bytes and independently persisted output.
Complete-codepoint preservation does not establish identical grapheme grouping across reads.
Omajot shares the pinned POSIX loop, but its different input consumers do not establish the same application failure.
Read [[buffer-hygiene-and-division-intent]] and the [terminal follow-up](../sources/omagma-zig-0.17-terminal-followup-2026-10-05.md).

Uucode's generated `[N]int` to `[N]packed Row` cast preserves logical bits and row indices.
Zigimg's SIMD mask intentionally maps lane zero to bit zero for `@ctz`.
Zigimg replaces selected extern-structure casts with field assignments.
Its TGA encoder retains explicit little-endian scalar conversions.
A separate source audit found native-endian SIMD loads in its existing encoder.
That mismatch remains a big-endian portability limit.
Little-endian native gates do not qualify big-endian encoding.
Retain independent expected-value, lane, and format oracles for these cases.

## Run dependency suites explicitly

Libvaxis's test step does not invoke uucode's or zigimg's test steps.
Its upstream CI runs libvaxis tests in default Debug mode.
Run each dependency's own test step with the exact compiler.
Run Debug and Safe correctness gates separately.

Uucode commits its Unicode 18 corpus, including `GraphemeBreakTest.txt`.
Its test step registers separate library, generator, config, storage, and build-script test binaries.
Do not fetch replacement UCD data during qualification.
Its grapheme tests intentionally tailor emoji-modifier boundaries.
Report upstream corpus coverage with that documented tailoring.
Do not claim unqualified strict UAX #29 conformance.
Uucode fixes its generator and generator-test module to Debug, including top-level Safe runs.
Record that limitation without presenting generation timings as performance evidence.


### Review lifetime failures before blaming cast semantics

Uucode's separate Debug suite passed all 167 tests.
Its unmodified Safe suite failed the Greek final-sigma condition test: 166/167 passed.
The generated table contained the correct value.
The getter copied that table row into a local value.
An embedded slice then escaped into the caller after the local storage expired.
The same getter and storage path existed in Omajot's older dependency pin.
This finding identifies a pre-existing ownership defect, rather than changed `@bitCast` semantics.

Libvaxis generates only four scalar Unicode fields in this graph.
Those fields exclude the affected casing helper and other embedded-slice getters.
Keep that boundary explicit when qualifying the application.
Never report the whole unmodified helper suite as passing Safe.
A separate diagnostic repair borrows static table rows instead of local copies.
Its receipts identify the patch separately from the published dependency graph.

Zigimg needs a separate fixture checkout beside its source checkout.
Its tests read `../test-suite/fixtures/`.
The selected fixture commit is `072fcaa45201a6c48d65a741881b8f3eab77412e` from `zigimg/test-suite`.
Its immutable archive is:

```text
https://github.com/zigimg/test-suite/archive/072fcaa45201a6c48d65a741881b8f3eab77412e.tar.gz
```

Record fixture hashes before and after testing.
Missing image files can silently skip tests.
Missing PNG corpus directories can pass without examining images.
Missing PNG reference files generate new references from actual decoder output.
Require existing references and capture actual traversal and skips.
The selected fixture tree includes references for all 168 valid PNG inputs.
This inventory is not a count of executed tests.

The selected zigimg GIF corpus loops omit newline consumption after `takeDelimiterExclusive`.
Each loop therefore reads only the first of 79 fixture-list entries.
Dedicated GIF tests remain available, but a passing suite cannot establish complete GIF corpus coverage.
Zigimg's selected CI workflow still requests Zig 0.16 and floating fixtures.
Keep direct 0.17 results separate from that upstream CI configuration.

## Track and package embedded assets

Use `b.root.openDir` for directories beneath a build root.
The root is a `Cache.Path`; preserve its `sub_path` when another build consumes the package.
Keeping only the underlying directory handle loses that package location.
Omajot's removed `b.build_root.handle` access required this distinction.

A configuration-time directory walker must declare `b.dependOnDirectoryContents(b.path("web/dist"))`.
Copy path bytes with `b.allocator.dupe(u8, entry.path)` before normalizing separators.
`b.dupe` returns immutable bytes in this release.
Keep lazy file dependencies for embedded asset content.
Include the directory in the package's `.paths`.
Omajot previously omitted `web/dist` despite reading it during build configuration.
Verify the immutable published package from a separate consumer.
That consumer can exercise Omajot's full native/WASM verification graph.
Check fetched assets against committed bytes and record the executed gate's result.

Rebuild committed WASM before rebuilding the native binary that embeds it.
Omajot's Linux gate checks that the hub serves current WASM bytes without a filesystem override.
The unchanged result protocol explicitly encodes a little-endian `u32` length.
JavaScript reads it with `DataView.getUint32(..., true)`.
Do not replace that wire contract with a logical cast.

An optional dependency can participate in build-script configuration when its feature is disabled.
The first Omajot `-Dtui=false` attempt encountered the old libvaxis build script's reflection API.
Audit dependency configuration as well as the selected executable imports.

## Qualify platform paths and linking

Keep checked-in text in LF form when a native Windows gate runs `zig fmt --check`.
Omajot's first Windows checkout converted Zig files to CRLF.
Formatting failed despite successful compilation.
A tracked `* text=auto eol=lf` rule preserves canonical bytes across hosts.
Its socket-path fixture also needed native Windows separator expectations.
The fix changes expected paths; production path construction is unchanged.

Do not infer libc-free linkage from `.link_libc = false` on the executable root.
A dependency can require libc and propagate that requirement.
Libvaxis does so in this graph; Omajot's Linux build is a static musl binary.
Keep historical size measurements dated.
Measure the new compiler separately before making new size or performance claims.

### Inspect linked-libc terminal wrappers

Exact 0.16 and 0.17 `std.posix.tcgetpgrp` and `tcsetpgrp` select `std.c` when libc is linked.
Both callers use pointer-shaped raw wrapper signatures, while both releases omit the corresponding C declarations.
The reported linked-libc executable build exposes this pre-existing gap.
Libc `tcgetpgrp(fd)` returns a PID; `tcsetpgrp(fd, pid)` takes a scalar PID.
Do not copy raw pointer signatures into C declarations.
Correct C declarations would also require adapting the POSIX callers.
Linux-specific adapters can use raw Linux ioctl wrappers with `std.os.linux.errno`.
Those adapters do not provide portable terminal behavior.
Compile the actual executable and editor paths; unit-test roots can leave those paths unanalyzed.
Qualify foreground restoration and child exit through independent PTY checks, including error paths.
Read [[child-process-lifecycles]] and the [terminal follow-up](../sources/omagma-zig-0.17-terminal-followup-2026-10-05.md).

### Recheck OS flag layouts and comments

Exact Zig 0.17 fixes `std.os.linux.CLOSE_RANGE` by adding its leading reserved bit.
`UNSHARE` now has backing value two; `CLOEXEC` has backing value four.
The adjacent numeric comments still show the old values one and two.
Compare declarations and literal backing values with Linux UAPI before replacing a numeric workaround with typed flags.
Then check the intended kernel behavior independently.
`CLOEXEC` marks descriptors for closure at exec; it does not immediately close them.
Omagma's native Linux probes check marking, successful pre-exec I/O, post-exec closure, and an unflagged positive control.
Those probes do not exercise runtime `UNSHARE` behavior.
The typed wrapper still returns a raw Linux syscall result; use its matching error decoder.
The [pinned follow-up](../sources/omagma-zig-0.17-stdlib-followup-2026-10-05.md) preserves source and hosted qualification boundaries.

### Retain qualified HTTP header workarounds

Exact Zig 0.17 `std.http.Client.Request.sendHead` still does not emit `privileged_headers`.
The same omission exists in exact 0.16.
The public field, validation, and retained request storage do not prove wire emission.
The standard `headers.authorization` override is emitted.
Omagma retains that override, explicit destination restrictions, and `.redirect_behavior = .unhandled`.
Its synthetic peer checks the literal bearer on the wire and verifies that redirects receive no followed request.

The redirect code can clear `privileged_headers`, but retains `headers.authorization`.
Do not assume privileged-header stripping protects an authorization override.
Disable automatic redirects or enforce an explicit credential-forwarding policy.
Keep borrowed header bytes valid through every send or resend.
The omission and override retention are source conclusions; the application tests qualify the workaround and redirect rejection.
A credential-free TLS/401 check does not prove bearer transmission or stripping.
Read [[networking-and-dns-racing]] and the [pinned follow-up](../sources/omagma-zig-0.17-stdlib-followup-2026-10-05.md).

## Keep test budgets separate

Distinguish the server request deadline, idle timeout, client timeout, and harness watchdog.
Give clients and watchdogs enough time to observe the intended server result.
Prefer bounded polling for a condition over an assumed scheduling delay.
An external watchdog should leave time for child cleanup and evidence capture.
Budget cold compilation and follow-up native probes separately when a compiler
runs under emulation. The wiki's old Windows ARM64 gate covered one full Debug
build; the upgraded gate covers Debug and Safe plus separate native probes.
Its watchdog now allows 90 minutes. Compiler process architecture and the
architecture of executed proof binaries must remain separate in every receipt.
Windows x64 passed the upgraded suite. The additional ARM64 job had a runner
and remained in full verification for nearly an hour; live per-proof logs
were unavailable. The user chose to defer that experimental gate.
Do not infer an unavailable runner or a particular hang from that observation.
The wiki's ARM64 runtime suite is now opt-in (`native_arm64_runtime=true`).
Its five separate Debug Windows probes passed as native ARM64 executables
after cancellation; those narrower results do not replace the incomplete full gate.

The engine's hosted Mac continuation test initially failed after an idle pause.
Its idle limit was 500 ms, and the pause left roughly 100 ms of scheduling slack.
An identical retry passed. The first failure remains recorded.
The fixture now uses a separate three-second idle limit.
The request deadlines remain 500 ms and 1,000 ms.
The deliberately slow handlers also retain their original delays.
The changed suite passed on Mac, Linux, and native Windows.

This separation reduces unrelated scheduling failures while preserving the deadline checks.
Do not increase every timeout until a failure disappears.
First identify which clock and budget produced the terminal result.

## Preserve allocator and ownership checks

Do not rename allocator fixtures without checking their required properties.
Mustache's 32-KiB allocation-limit test needs `requested_memory_limit`.
The compatible deprecated `DebugAllocator` still provides that fixture behavior.
Replacing it with `SafeAllocator` would remove the intended limit check.

Keep storage until application and kernel borrows have returned.
Preserve preallocation and the absence of blocking work on the request I/O loop.
A compiler upgrade does not establish backend progress or resource guarantees.
Unchanged public `std.Io`, thread, or atomic signatures do not prove unchanged runtime behavior.

### Inspect infinite waits and ancillary data

In 0.17, `Io.Timeout.none.sleep` means wait forever until cancellation.
The old Threaded implementation treated it as an immediate return.
A mechanical test port can hang or exercise an entirely different behavior.
The shipped Linux Threaded body instead panics while converting its maximal
timestamp to POSIX seconds, before checking cancellation.
Its macOS nanosleep path can return immediately after an invalid timespec is
rejected, concealing the changed contract in a test that expects a no-op.

The wiki now tests delegation and cancellation with an injected sleep oracle.
A separate native Linux subprocess requires the exact shipped overflow panic.
That witness documents a defect; it does not qualify infinite Threaded sleep.
Its explicit step is `zig build verify-linux-none-sleep-defect`.
Regular verification only compiles this reproducer. The deliberate SIGABRT
still activates OS crash monitors even with core dumps disabled, so keep
crash witnesses separate from routine correctness gates.
Safe optimization omitted internal and caller frames from the witness trace.
Match the exact retained panic site and originating executable, rather than
assuming Debug and Safe preserve the same call frames. Keep the first overly
strict checker failure as evidence when correcting the harness.
Use a suitable cancellation primitive or finite waits where ownership and
shutdown require reliable progress. Baz and [bounded/http](https://technologylab-ai.github.io/bounded-http/)'s passing native
gates do not instantiate the experimental evented backends discussed below.

Review new socket control-data contracts even when a method keeps its name.
Threaded stream reads now accept ancillary storage and return `control_len`
and `control_truncated` alongside data length. Retain both data and control
buffers through completion, and handle truncation explicitly. Stream writes
clear control data after a successful write so it is delivered once; preserve
that state across partial progress instead of resending the control message.
`net_send` is message/datagram sending; `net_read` and `net_write` are streams.

## Record native evidence and exclusions

The [project evidence record](../sources/zig-0.17-project-ports-2026-10-04.md) names commits and captured receipts.
All four consumed projects passed Debug and Safe verification on Mac and `omarx1`.
The Linux run exercised every engine wire suite and all eleven Baz Python suites.
Hosted jobs provide separate native Windows evidence.
Cross-compilation remains separate from runtime evidence.

Mustache's optional compile-time suite remains disabled in its established build configuration.
Five historical sample/benchmark Zig files remain outside its exported package and verification graph.
This migration covers the dependency graphs consumed by Baz and Omajot.
Separate helper failures and excluded fixture coverage retain their stated limits.
It does not claim those excluded historical programs were ported.
The engine's preserved benchmark preparation recipe also remains a historical
0.16 reproducer outside the exported graph. Use an archived engine commit whose
compiler pin matches that recipe; a 0.17 performance comparison needs its own port.
The application upgrade ran no performance comparison.
Wiki verification runs its Safe timing fixture, which supplies no application throughput evidence.

The wiki upgrade retains the following separate 0.16 baseline diagnosis.
Its experimental macOS `std.Io.Dispatch` proof has a reproducible ReleaseSafe crash in the unchanged baseline.
Matched Debug runs pass; matched ReleaseSafe runs fail even with the same test filter.
The native Apple Dispatch shim test passes in both modes.
This separate baseline failure does not weaken the application's Safe gates.

### Requalify experimental backend bodies

The full wiki upgrade found stale vtable assignments in the shipped evented backends.
Dispatch and Uring still assign removed process-path members.
Kqueue also assigns removed network members.
Declaring a backend type does not prove that its method bodies compile.

These blockers do not affect the tested Baz dependency graph.
The engine owns its io_uring, kqueue, and IOCP transport adapters, using
low-level OS interfaces rather than those experimental `std.Io` backends.
Baz's service examples receive the default Threaded-backed process `Init.io`.
The native application gates qualify that specific graph and its exercised paths.

Dispatch initialization calls its broken `io()` method.
The active proof therefore cannot claim initialization or a positional read through that backend.
The Apple C-shim proof still supplies separate native Dispatch I/O evidence.
Registered compile-failure witnesses require the specific release diagnostic.
They reject unexpected compiler failures and force requalification when a later source fixes the blocker.

The old Dispatch teardown compile error has a different cause.
The free expression is unchanged, but 0.17 `Allocator.free` accepts pointers to arrays.
That source fix does not establish a usable backend lifecycle.
The revised timing program compares Threaded with the Apple shim.
It supplies no new measurement and preserves older three-way results as historical evidence.

## Final review checklist

- Read every cast against its intended numeric, logical-lane, memory, or wire representation.
- Use independent byte or scalar oracles for silently changed semantics.
- Preserve string types, sentinels, reflection indices, defaults, and public hook contracts.
- Verify generated files, exports, fixtures, and the final immutable URL graph.
- Review every affected README, exact version pin, workflow, and machine-readable mode tag.
- Keep short behavior deadlines separate from generous observation and cleanup budgets.
- Record native platforms, exact revisions, excluded suites, first failures, and reservation cleanup.
- Add new wiki source records before synthesis. Preserve prior evidence and its compiler scope.
