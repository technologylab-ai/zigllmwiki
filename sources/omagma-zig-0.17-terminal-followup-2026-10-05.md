---
id: source-omagma-zig-0-17-terminal-followup-2026-10-05
title: Zig 0.17 allocator removal and terminal input findings
kind: source
status: captured
summary: Pin allocator API removal, a pre-existing libc terminal-wrapper gap, and bounded UTF-8 input ownership evidence.
captured: 2026-10-05
revision: "9c1f66ba4ddf2ac27e919793b7ed5ea8b8310527"
url: https://github.com/technologylab-ai/omagma/blob/9c1f66ba4ddf2ac27e919793b7ed5ea8b8310527/docs/ZIG017-WIKI-FOLLOWUP.md
snapshot: sources/snapshots/omagma-zig-0.17-terminal-followup-2026-10-05.json.gz
sha256: "76da7177c430c708ad27f2e425465ff183d298e33ecbbf0e599c8572021acc32"
---

# Allocator and terminal input follow-up

The curator selected three findings from Omagma's later terminal-development handoff.
The snapshot preserves 27 original files with individual SHA-256 values and immutable origin identifiers.
Earlier source records retain their original bytes.
Private receipts remain outside the capture.
Application bug histories are not synthesized into migration guidance.

## Pinned inputs

| Input | Revision | Selected scope |
| --- | --- | --- |
| Zig 0.16.0 | `44d9672fed001115e674fd5ddb32747ef43a7af4` | Allocator, POSIX, C and raw Linux source. |
| Zig 0.17.0 | `7647adab80dd088f4de3610fd245915a912eb6ad` | The same files and three bundled musl ABI files. |
| libvaxis | `6fd944a27fb3d6f596e981076381a3131f2448b4` | Manifest, POSIX input loop, parser and grapheme cache. |
| uucode | `ea62149739404a73c202b48a33bf6dd2af4bd9b0` | UTF-8 iterator and grapheme iterator. |
| Omagma terminal runtime | `7568a2467b5a93142259bc50057a177c3acf7150` | Manifest, bounded input adapter and independent PTY fixture. |
| Omagma follow-up | `9c1f66ba4ddf2ac27e919793b7ed5ea8b8310527` | Public handoff, qualification report and adapter identity. |
| Omagma release CI | `550a0128fe9a5532c0b253585e1426f8f9c927bc` | Completed run `37254556329` metadata. |
| Omajot 0.1.11 | `c7c1ffd082f77f47640990e7c01ed2d3ec6748b4` | Manifest, POSIX TUI loop and input consumer. |

The curator checked all eleven installed Zig captures against their immutable upstream source bytes.
The Omagma adapter is byte-identical at the runtime and follow-up revisions above.
The captured release metadata reports successful native Linux x86_64 and ARM64 jobs.
The public qualification report records nineteen PTY cases in both Debug and Safe.
These remain reported project results, separate from newly executed wiki proofs.

## Actual allocator API removal

Exact 0.16 `Allocator.zig:459` defines deprecated `dupeZ` as `dupeSentinel(T, m, 0)`.
Exact 0.17 removes `dupeZ` and retains `dupeSentinel` at line 487.
For byte paths, `dupeSentinel(u8, path, 0)` returns owned `[:0]u8` storage.
The caller frees the original sentinel slice with the same allocator.
Ordinary `dupe` returns an unsentinel slice and does not preserve this termination contract.
Sentinel allocation does not validate embedded NUL bytes.

The inspected allocator hashes are `f6ad8a10185701ef1399350f127692ed5e89141773ea3c7e5ccc54a652120397` for 0.16 and `25099a1aaed1fe80b811e1eaedf8c3e2059a3fe7b6c29db868a68da3085b7997` for 0.17.
This finding is an exact release API change, independently established by source comparison.

## Pre-existing linked-libc terminal-wrapper gap

Both releases select `std.c` as `posix.system` when libc is linked.
Their `posix.tcgetpgrp` and `tcsetpgrp` call pointer-shaped raw wrapper signatures.
Neither release's `c.zig` declares those functions.
The reported linked-libc executable compilation exposes the missing members.
This source gap already exists in 0.16; it is not a new compiler regression.

The bundled musl header and implementations independently establish the C signatures.
Libc `tcgetpgrp(fd)` returns a PID; `tcsetpgrp(fd, pid)` takes a scalar PID.
Adding pointer-shaped C declarations would preserve the wrong ABI.
Correct C declarations would also require adapting the POSIX callers.
Linux-specific code can use raw Linux ioctl wrappers with `std.os.linux.errno`.
Those wrappers do not establish portable terminal behavior.
Reported Omagma PTY checks cover editor return, child completion, and terminal-settings restoration.
The fixture does not directly compare foreground process-group IDs before and after transfer.
The curator did not rerun those terminal checks or a new compile-failure witness.

## Incomplete UTF-8 input and queued ownership

The pinned POSIX libvaxis loop reads at most 1,024 bytes per batch.
A short read can split a codepoint at any position.
The loop retains parser input only when the consumed length is zero.
The pinned uucode iterator instead returns U+FFFD for truncated input.
The parser can emit incomplete original bytes as key text with a nonzero consumed length.

The loop separately discards the remaining batch after selected malformed-input errors.
That error branch is not established as the cause of Omagma's missing-emoji witness.
The reported byte mismatch and boundary alignment support an input-framing diagnosis.
The curator did not reproduce the precise downstream loss path.

Omagma's adapter retains up to three trailing bytes of an incomplete codepoint.
Pending control sequences share a fixed 1,024-byte bound.
A full unresolved sequence terminates input with `InputSequenceTooLong`.
Complete-codepoint preservation does not guarantee identical grapheme grouping across reads.
The adapter also does not validate every malformed UTF-8 fragment.

Queued text has owned storage; rejected pushes release that storage.
The consumer borrows text until the next `nextEvent` call begins, or until loop stop.
A blocked or failed `nextEvent` call still ends the prior borrow.
Longer retention requires another ownership transfer or copy.
The independent PTY fixture fragments eight inputs and checks persisted bytes.
The reported qualification includes preservation of the original 2,349-byte body.

Omajot selects the same parser graph and directly uses the POSIX loop.
Its search and prompt consumers copy key text and can concatenate fragments later.
Shared source exposure does not establish an Omajot failure.
The capture establishes no hub HTTP, Windows-input, arbitrary-terminal, or big-endian runtime claim.

Read [[zig-0.17-upgrade-assessment]], [[child-process-lifecycles]], and [[buffer-hygiene-and-division-intent]] for selected guidance.
