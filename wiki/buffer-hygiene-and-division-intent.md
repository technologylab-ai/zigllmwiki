---
id: buffer-hygiene-and-division-intent
title: Buffer hygiene and division intent
kind: pattern
status: source-verified
zig: "0.16.0"
summary: Initialize every externally observable byte, clear reused storage according to its disclosure contract, encode fields explicitly, and name integer division rounding behavior.
updated: 2026-09-04
sources:
  - "[[source-tigerstyle]]"
  - "[[zig-0.16.0-language-reference]]"
  - "[[zig-0.16.0-stdlib]]"
proofs:
  - proofs/state_lifetime_and_arithmetic.zig
platforms:
  - cross-platform
---

# Buffer hygiene and division intent

## Remember

Initialize the complete representation that can leave a trust boundary—not
only its logical payload. Track logical length separately from capacity, never
serialize native struct memory as a wire format, and clear reused storage when
the disclosure or determinism contract requires it.

For integer division, choose exact, floor, or ceiling semantics by name. Plain
“divide and hope” hides both rounding policy and boundary errors.

## Prevent buffer bleed

A fixed buffer commonly contains more capacity than the current payload. If an
API can observe or transmit the capacity rather than the logical length, stale
bytes from an earlier use can escape. Prevent that with all of the following:

- initialize the entire buffer before its first observable use;
- carry an explicit validated logical length;
- pass only the initialized logical slice where the API accepts a slice;
- define reserved bytes as zero and validate them when decoding;
- clear the required region before reuse when a later call may expose it;
- keep capacity and payload length as distinct bounded domains.

Clearing only `buffer[0..new_len]` does not remove a longer previous payload
from the tail. Zero the full reusable region when its contract requires a
deterministic or non-disclosing representation. Conversely, do not spend hot
path work clearing capacity that is provably unobservable and contains no
sensitive data; record that proof in the buffer-owner contract.

## Padding is not a serialization format

Native structs may contain padding, target-dependent layout, endianness, and
bytes the program never explicitly initialized. Do not write `@sizeOf(T)` raw
bytes from an ordinary struct to disk or the network. Define a byte-level
format, encode each field at an explicit offset and endianness, initialize
reserved space, and decode with length/range/reserved-byte checks. See
[[integer-widths-and-boundaries]].

`extern` or `packed` layout solves only the particular layout properties that
its Zig contract states. It does not automatically establish a portable
protocol, validate input, clear old storage, or make an OS ABI safe on every
target.

## Ordinary zeroing is not guaranteed secure erasure

`@memset` is appropriate for establishing the program-visible contents tested
by this wiki's proof. Do not claim that an ordinary store is a guaranteed
cryptographic erase: optimization, copies, registers, crash dumps, swap, and
OS/device buffering can retain data. Secret-erasure requirements need a
platform/toolchain-specific primitive and threat model, pinned as separate
evidence.

## State division intent explicitly

For integers, first decide the contract:

- **Exact:** reject a remainder, then use `@divExact` once divisibility is
  established. This fits page counts, block alignment, and invariants where a
  fraction means corrupt input or a programmer defect.
- **Floor:** use `@divFloor` when the mathematical result must round toward
  negative infinity. This differs from truncation for negative operands.
- **Ceiling:** use `std.math.divCeil` when asking how many fixed-capacity
  groups cover a count. In Zig 0.16.0 it is fallible and reports division by
  zero and signed overflow.

Validate the denominator. For signed values, account for the minimum integer
divided by `-1`, which is not representable. Use checked addition or the
standard-library helper rather than implementing ceiling division as
`(numerator + denominator - 1) / denominator`; that familiar formula can
overflow and usually assumes nonnegative inputs.

Division does not erase domain distinctions. A byte count divided by a block
size produces a block count, not an index. Convert and range-check at the
boundary, retain explicit units in names, and separately test zero, one,
exact-multiple, one-past-multiple, maximum, and negative cases permitted by the
contract.

## Patterns

For a bounded encoder:

1. reject input exceeding fixed capacity;
2. create a fully zeroed output value;
3. copy only the validated payload;
4. publish the logical length with the initialized bytes;
5. serialize explicit fields, never native padding.

For work-unit arithmetic:

1. validate count and nonzero unit size in their domain types;
2. call exact/floor/ceiling division matching the specification;
3. handle the helper's error or prove the rejected state with an assertion;
4. validate the result against queue, loop, and resource limits before use.

## Evidence

The [buffer/arithmetic proof](../proofs/state_lifetime_and_arithmetic.zig)
zero-initializes a 16-byte representation, copies a bounded logical payload,
checks every unused byte, and clears the complete storage before reuse. Its
arithmetic tests distinguish exact rejection, negative floor versus ceiling,
positive ceiling, and division by zero. They ran with Zig 0.16.0 on aarch64
macOS on 2026-09-04.

The proof does not serialize a native struct and does not claim secure erasure.
It demonstrates program-visible initialization and Zig 0.16 operation
semantics only.

Related: [[integer-widths-and-boundaries]], [[invariants-and-assertions]],
[[static-allocation-and-constant-work]],
[[state-scope-and-in-place-initialization]], [[tigerstyle]].
