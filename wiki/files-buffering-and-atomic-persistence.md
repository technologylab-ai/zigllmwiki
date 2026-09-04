---
id: files-buffering-and-atomic-persistence
title: Files, buffering, atomic publication, and durability
kind: pattern
status: runtime-verified
zig: "0.16.0"
summary: Treat writer flush, file synchronization, atomic namespace publication, and directory durability as separate steps with separate guarantees.
updated: 2026-09-04
sources:
  - "[[zig-0.16.0-stdlib]]"
  - "[[fi-zig-0.16-migration]]"
proofs:
  - proofs/files_and_atomic_persistence.zig
platforms:
  - macos
---

# Files, buffering, atomic publication, and durability

## Remember

A successful write into a Zig buffer does not mean bytes reached the file. A
successful flush does not mean the file reached stable storage. A successful
atomic replacement does not mean the containing directory entry survived a
crash. Model these as distinct transitions:

| Transition | Zig 0.16 operation | What it establishes |
| --- | --- | --- |
| Application state → writer | `writer.interface.writeAll` | Bytes are accepted by the writer and may remain buffered. |
| Writer → file | `File.Writer.flush` | Buffered bytes have been handed to the file operation; underlying write failures are reported. |
| File → filesystem/device contract | `File.sync(io)` | Pending contents and file metadata are synchronized according to the filesystem/OS contract. |
| Temporary name → destination name | `File.Atomic.link` or `replace` | The completed temporary file is published atomically in the namespace. |
| Directory metadata → stable storage | Platform-specific directory synchronization | The new or replaced name is made crash-durable; `File.sync` explicitly does not establish this. |

Choose the last transition the application truly requires. “Readers never see
a half-written configuration” needs atomic publication. “A power loss after
success must retain the new configuration” additionally needs a documented
platform/filesystem durability protocol.

## Files and resource ownership

`Dir.createFile`, `Dir.openFile`, and `Dir.openDir` return resources that the
owner closes with the same `std.Io`. `File.Atomic` is a separate owner: always
call `deinit(io)`, even after `link` or `replace` succeeds. Its cleanup closes
an open temporary file, removes a named temporary file when necessary, and may
close an internally opened directory.

Prefer directory-relative operations over check-then-open sequences. The
`Dir.access` documentation calls out the time-of-check/time-of-use race:
attempt the intended operation and handle its error instead of first asking
whether the path exists.

Opening a directory does not automatically permit iteration. Pass
`OpenOptions.iterate = true` before calling `iterate`; iteration itself is a
convenience API with an internal fixed 2048-byte reader buffer and yields one
entry at a time. Use the lower-level reader or selective walker when traversal
capacity and syscall shape are part of the design.

## Readers, writers, and position

`File.reader` and `File.writer` default to positional I/O and fall back to
streaming when positional operations are unavailable. Positional mode avoids
changing the descriptor's global seek position and is therefore safer for
independent users of the same file. `readerStreaming` and `writerStreaming`
skip the initial positional attempt when stream semantics are intended.

Reader and writer values carry state; do not manufacture multiple wrappers and
assume they share buffering or logical position. A `File.Reader` memoizes such
facts as file size, current position, seek failures, and its positional versus
streaming mode. A `File.Writer` tracks the completed file position separately
from buffered bytes; `logicalPos()` includes both.

Before seeking a writer, use `seekTo`, which flushes first.
`seekToUnbuffered` asserts that no bytes remain buffered and belongs only where
the caller already proved that precondition.

### Flush is not truncation

When a positional writer overwrites the prefix of an existing longer file,
`flush` writes the new prefix but leaves the old tail and length intact. Call
`File.Writer.end()` to flush and set the file length to the final writer
position. This distinction does not apply in the same way to an already
truncated newly created file, which is why it is easy to miss in tests.

## Bounded reads

`Dir.readFile` uses caller-provided storage and allocates nothing for the
result. When the returned length equals the entire buffer length, EOF is
ambiguous: the file may fit exactly or may have been truncated. Reserve an
extra byte, compare against a separately trusted size, or use a streaming
protocol when that distinction matters.

`Dir.readFileAlloc` returns owned storage that the caller must free. Its
`std.Io.Limit` is an exclusive ceiling: a file whose size reaches or exceeds
the limit returns `error.StreamTooLong`. A three-byte file therefore needs at
least `.limited(4)`, not `.limited(3)`. If the size is already known, the
standard-library documentation recommends initializing a `File.Reader`
instead.

For TigerStyle code, make the maximum input size part of validated
configuration and prefer caller-owned fixed storage in the steady state.
Allocation convenience does not remove the need for an admission limit.

## Atomic publication protocol

For replace-in-place data such as a generated manifest or configuration:

1. Create a `File.Atomic` with `replace = true` and install `defer deinit(io)`
   immediately.
2. Write the complete new representation into `atomic.file` through one owned
   writer.
3. Flush the writer and handle the underlying write error.
4. If crash durability is required, synchronize the temporary file before it
   is published.
5. Call `replace(io)` to atomically replace an existing destination. Use
   `link(io)` when an existing path must instead cause
   `error.PathAlreadyExists`.
6. For a crash-durable namespace change, perform the platform-specific
   containing-directory synchronization required by the target filesystem.

Zig 0.16's `File.Atomic` performs the atomic namespace operation; it does not
implicitly call `File.sync`. The public `std.Io.Dir` surface also does not
provide a portable directory-sync operation. That is a real portability seam,
not permission to collapse atomic visibility and crash durability into one
claim. On Windows, `replace` additionally documents a transient interval in
which some destination operations may return `error.AccessDenied`.

`Dir.updateFile` is a useful atomic-update convenience for copying a source
file when size, timestamp, or permissions differ. Its implementation flushes
the copied data before replacement, but it does not add the file and directory
synchronization protocol required for a stronger crash-durability claim.

## What commonly goes wrong

- Closing a file while bytes still live only in a writer buffer.
- Calling `flush` after a short overwrite and unknowingly retaining the old
  suffix instead of using `end`.
- Sharing a descriptor while assuming independently constructed streaming
  readers or writers have independent positions.
- Treating an exact-fit `readFile` result as proof of EOF.
- Passing `.unlimited` or an input-size value itself to `readFileAlloc` and
  losing either a memory bound or the exact-boundary case.
- Publishing an atomic file without `deinit`, especially on an error path.
- Describing rename/replace atomicity as power-loss durability without file
  and directory synchronization evidence for the target platform/filesystem.

## Evidence

The [file and atomic-publication proof](../proofs/files_and_atomic_persistence.zig)
runs three Zig 0.16 tests. It observes that a small buffered write leaves file
length zero until flush, proves that flush retains an overwritten stale suffix
until `end` truncates it, synchronizes and atomically replaces a temporary
file, and checks the exclusive `readFileAlloc` limit boundary. It ran through
`std.testing.io` on aarch64 macOS on 2026-09-04.

The proof establishes API behavior on that runtime; it is not a simulated
power-loss test and makes no claim about other filesystems' durability.

For a database's additional root-selection, WAL, replication, block-reuse,
and crash-repair decisions, see [[durable-storage-and-recovery]]. Its
TigerBeetle synthesis is source evidence; it does not strengthen this proof's
runtime or power-loss scope.

Related: [[std-io]], [[io-threaded]], [[static-allocation-and-constant-work]],
[[invariants-and-assertions]], [[tigerstyle]], [[evented-io-backends]],
[[durable-storage-and-recovery]].
