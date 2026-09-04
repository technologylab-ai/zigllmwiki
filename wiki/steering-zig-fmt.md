---
id: steering-zig-fmt
title: Steering zig fmt
kind: pattern
status: source-verified
zig: "0.16.0"
summary: Use trailing commas, array line breaks, and deliberate expression boundaries to select readable layouts while retaining canonical Zig 0.16 formatting.
updated: 2026-09-04
sources:
  - "[[matklad-steering-zig-fmt]]"
proofs:
  - proofs/fmt_steering.zig
platforms:
  - cross-platform
---

# Steering `zig fmt`

## Remember

`zig fmt` is canonical but steerable. The source can select among layouts
without formatter-disable directives:

- A trailing comma asks a multiline construct to put one element or argument
  on each line.
- For array literals, the first deliberate line break can establish a column
  count that the formatter preserves and aligns.
- Array concatenation can separate a fixed prefix from a columnar sequence such
  as command-line key/value pairs.

The formatter does not choose conceptual structure. Blank lines, intermediate
variables, names, and expression boundaries remain the author's tools for
making control flow and data layout obvious.

## Agent rule

Express the intended shape, then run the formatter. Do not hand-align code
against the formatter or collapse a meaningful intermediate value merely to
reduce line count. Treat an unstable layout as feedback that the expression may
need a clearer boundary.

The [formatting fixture](../proofs/fmt_steering.zig) is compiled and included in
the repository-wide `zig fmt --check`. This proves that Zig 0.16.0 accepts and
preserves the checked-in shape; it does not claim that future versions make the
same formatting choices.

Related: [[tigerstyle]], [[zig-0.16-baseline]].
