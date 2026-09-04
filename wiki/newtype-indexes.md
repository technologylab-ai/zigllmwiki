---
id: newtype-indexes
title: Newtype indexes with non-exhaustive enums
kind: pattern
status: source-verified
zig: "0.16.0"
summary: Use non-exhaustive enums as compact, type-distinct indexes while retaining explicit conversion, bounds, generation, and serialization checks.
updated: 2026-09-04
sources:
  - "[[matklad-zig-newtype-index-pattern]]"
  - "[[zig-0.16.0-stdlib]]"
proofs:
  - proofs/newtype_index.zig
platforms:
  - cross-platform
---

# Newtype indexes with non-exhaustive enums

## Remember

A non-exhaustive `enum(u32)` gives an index its own type while allowing every
`u32` representation. Distinct index types prevent accidentally passing, for
example, a connection index to a buffer table. Convert deliberately with
`@enumFromInt` and `@intFromEnum` at the array boundary.

This is type distinction, not encapsulation or validity. Any code can construct
an arbitrary value, and a value can still be out of bounds or stale.

## Why indexes fit bounded systems

Indexes can be half the width of pointers on a 64-bit machine, improve density
and cache behavior, make cyclic structures straightforward, survive relocation,
and support compact range representations into shared arrays. They also make
ownership visible: define the collective storage (`Tree`, `Pool`, `Table`)
before the element handle.

Nest the backing record under the index type when that clarifies the pair, and
reserve named values such as `root` or `invalid` only when their semantics are
explicit. A compile-time size assertion documents a layout premise and forces a
review when it changes.

## Safety boundaries

- Check the integer against the owning array before indexing untrusted data.
- A simple index cannot detect release-and-reuse. Add a generation when stale
  handles must be rejected.
- Do not use the same newtype for different owners if values can cross them.
- On-disk or network serialization still needs explicit endianness, version,
  padding, checksum, and bounds rules; bulk-copy convenience is not a format.
- Keep arithmetic in a checked integer domain and convert only after proving
  the result fits the backing type.

The [Zig 0.16 proof](../proofs/newtype_index.zig) ports the source pattern,
checks the compact representation and named sentinels, and demonstrates access
through the owning collection. It does not attempt to compile an intentional
wrong-type call.

Related: [[static-allocation-and-constant-work]], [[tigerstyle]].
