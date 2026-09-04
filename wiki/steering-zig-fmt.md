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
  - "[[zig-0.16.0-style-guide]]"
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

It also does not enforce the entire style policy. The Zig 0.16 guide recommends
four-space indentation and aiming for 100 columns, while strict TigerStyle
makes 100 characters a hard maximum and adds naming, comment, file-order,
callback, and call-site rules. Those non-formatting rules live in
[[naming-comments-and-api-shape]].

## Agent rule

Express the intended shape, then run the formatter. Do not hand-align code
against the formatter or collapse a meaningful intermediate value merely to
reduce line count. Treat an unstable layout as feedback that the expression may
need a clearer boundary.

The [style fixture](../proofs/fmt_steering.zig) is compiled and included in the
repository-wide `zig fmt --check`. A separate deterministic lint rejects lines
over 100 characters in maintained Zig sources. Together they prove that Zig
0.16.0 accepts and preserves the checked-in shape; they do not claim that
future versions make the same formatting choices or that formatting proves
good naming and API design.

Related: [[naming-comments-and-api-shape]], [[tigerstyle]],
[[zig-0.16-baseline]].
