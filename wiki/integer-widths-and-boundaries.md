---
id: integer-widths-and-boundaries
title: Integer widths, layout, and serialization boundaries
kind: pattern
status: source-verified
zig: "0.16.0"
summary: Give domain values explicit widths, check every narrowing and arithmetic boundary, and keep native memory layout separate from stable wire or disk formats.
updated: 2026-09-04
sources:
  - "[[source-tigerstyle]]"
  - "[[zig-0.16.0-language-reference]]"
  - "[[zig-0.16.0-release-notes]]"
  - "[[zig-0.16.0-stdlib]]"
  - "[[matklad-zig-newtype-index-pattern]]"
  - "[[matklad-static-allocation-compilers]]"
  - "[[matklad-memory-safety-hardest-problem]]"
proofs:
  - proofs/integer_boundaries.zig
  - proofs/newtype_index.zig
  - proofs/persistence_assertion_pair.zig
platforms:
  - cross-platform
---

# Integer widths, layout, and serialization boundaries

## Remember

Choose an integer from the domain's declared maximum and representation—not
from the host pointer width. Keep indexes, item counts, byte counts, offsets,
timestamps, and identifiers as distinct types even when several use `u32`.
Convert at named boundaries only after proving the value fits.

`usize` is the right type for an in-process slice length, array index, pointer
offset, or standard-library API that requires it. It is usually the wrong
stored type for a protocol field, persistent record, configured cross-platform
limit, or stable identifier because its width follows the target.

## Three different representations

Do not collapse these layers into one struct:

| Layer | Contract | Pattern |
| --- | --- | --- |
| Domain model | Meaning, range, units, and legal operations. | Distinct enums or wrappers over explicit-width integers. |
| Native/ABI memory | Compiler or target ABI layout for live values. | Use ordinary structs by default; `extern` only for a named C ABI and `packed` only for a named bit-level representation. |
| Wire or disk | Stable bytes shared across process, version, machine, or language boundaries. | Encode and decode fields individually with explicit widths, byte order, version, reserved bytes, bounds, and integrity checks. |

An ordinary Zig struct has no stable external layout contract. An
`extern struct` follows the target C ABI; that makes it an FFI tool, not a
portable file format. A packed struct has a defined backing-integer layout, but
viewing that integer as bytes still involves target endianness. A stable
protocol should use an explicit byte encoding such as `std.mem.writeInt` and
`std.mem.readInt`.

Never write a live struct by copying all of its bytes unless the external
contract is explicitly that exact target ABI and every padding/disclosure rule
has been addressed. Otherwise field order, padding, native endianness, pointer
values, and later refactors silently become format decisions.

## Conversion and arithmetic boundaries

Treat conversion as validation, not syntax cleanup:

1. parse or receive into a type wide enough for the input contract;
2. validate semantic limits, reserved values, and the owning collection;
3. use `std.math.cast` or an explicit range check when failure is expected;
4. perform size arithmetic with overflow reporting before allocation or slice
   formation;
5. convert to `usize` only at the in-memory indexing/API boundary;
6. use `@intCast` only where failure already means a programmer invariant was
   broken, and use `@truncate` only when discarded high bits are the format's
   deliberate operation.

In safety-enabled builds, an out-of-range runtime `@intCast` traps; it is not a
recoverable validation result. In modes where relevant safety checks are
disabled, code must not depend on a trap to make unchecked arithmetic valid.
Return an operational error before the cast when external input or configured
capacity may legitimately exceed the destination.

Multiplication and addition need their own checks. Proving that an item count
fits `u32` does not prove that `count * item_size + header_size` fits `u32`,
`usize`, an allocator limit, or the maximum protocol frame.

## Zig 0.16 packed and extern boundaries

Zig 0.16.0 tightened explicit-representation rules:

- every packed-union field must occupy the same number of bits as its backing
  integer;
- packed unions may declare an explicit backing integer;
- pointers are no longer valid fields of packed structs or packed unions;
- enums and packed types with inferred backing integers are not valid in
  extern contexts; provide the tag or backing integer explicitly;
- packed union equality compares the backing integer representation.

These are language guarantees, not an invitation to use a packed value as a
long-lived file format. Protocol evolution, endianness, invalid/reserved bit
patterns, integrity, and trust-boundary validation remain application work.
Converting a pointer to `usize` can model a process-local address when an API
truly requires it, but does not make that address persistent or portable.

## Handles, relocation, and representation changes

Indexes are useful for bounded, relocatable collections and immutable output
arenas. The static-allocation compiler essay proposes separating bounded
scratch state from potentially unbounded immutable output; this is an
architectural hypothesis, but it illustrates why explicit-width indexes can be
easier to relocate or persist than live pointers.

An index by itself does not preserve lifetime. A slot can be released and
reused, so externally retained handles need an owner identity and generation
when stale use must be detected. Validate the index against the current owner
before access.

Likewise, a correctly typed pointer into a tagged-union payload does not remain
valid after the containing storage changes variant. The memory-safety source
demonstrates this representation-lifetime failure. Do not let an interior
pointer outlive mutation, relocation, or variant replacement of its owner;
exclusive borrows, stable storage, or validated handles must make that rule
structural.

## Serialization checklist

- State magic/version compatibility and the exact byte order.
- Assign an explicit integer width and semantic maximum to every field.
- Reject unknown required flags; require reserved bits and bytes to be zero.
- Check lengths before slicing and check combined size arithmetic before use.
- Encode each field rather than copying host padding or pointer values.
- Initialize every emitted byte, including reserved space.
- Validate external bytes before constructing trusted domain state.
- Pair producer and consumer assertions around the same critical invariant.
- Treat a checksum as corruption detection with stated strength, not as
  authentication or proof of atomic persistence.

## Executable evidence and limits

The [integer-boundary proof](../proofs/integer_boundaries.zig) uses distinct
`u32`-backed domains, rejects narrowing and total-length overflow, asserts
layout premises at compile time, encodes fields in a fixed little-endian byte
format, and rejects reserved bits. The
[persistence assertion-pair proof](../proofs/persistence_assertion_pair.zig)
checks one invariant before encoding and independently after decoding, and
tests malformed structure, stale integrity data, and semantically invalid
state.

Both proofs ran with Zig 0.16.0 on `aarch64-macos` on 2026-09-04 and passed
compile-only checks for `x86-linux`, `x86_64-linux`, and `x86_64-windows`.
Cross-compilation is not runtime evidence. The proofs exercise portable
language logic in memory; they do not prove C ABI equality across targets,
crash consistency, filesystem atomic replacement, `fsync` ordering, or
cryptographic integrity. Those persistence mechanics belong to M1-008.

Related: [[newtype-indexes]], [[invariants-and-assertions]],
[[static-allocation-and-constant-work]], [[tigerstyle]],
[[error-handling-and-diagnostics]].
