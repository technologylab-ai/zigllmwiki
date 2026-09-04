---
id: lower-dimensional-api-contracts
title: Lower-dimensional API contracts
kind: pattern
status: source-verified
zig: "0.16.0"
summary: Return and accept only distinctions the caller must act on, while preserving ownership, absence, failure, cancellation, and partial-completion states that are semantically real.
updated: 2026-09-04
sources:
  - "[[source-tigerstyle]]"
  - "[[zig-0.16.0-language-reference]]"
proofs:
  - proofs/error_path_catalog.zig
platforms:
  - cross-platform
---

# Lower-dimensional API contracts

## Remember

Every independent input or result variant multiplies the caller's state space.
Remove distinctions that no correct caller uses. Do not erase distinctions that
control ownership, retry, cancellation, partial completion, or data absence.

TigerStyle's ordering—plain completion before boolean, integer, optional, and
fallible results—is a pressure toward smaller contracts, not permission to
discard required information.

## Choose the smallest truthful result

| Caller obligation | Result shape |
| --- | --- |
| Success has one meaning and all effects live in caller-owned state | `void` |
| Caller must choose between exactly two successful policies | `bool`, preferably an enum when names prevent inversion |
| Caller uses a measured value | an explicitly sized domain integer or focused struct |
| Absence is a successful data state | optional value |
| An expected operational failure changes policy | narrow error union |
| Success can be partial and the remainder still has ownership | explicit result struct or tagged union |

Do not return “bytes written” when the operation promises all-or-error and the
caller has no legal partial-success branch. Conversely, do not reduce a
cancellable partial operation to `!void` if the caller must retain a buffer,
drain a result, or reconcile an external side effect.

Keep diagnostics separate from the typed control result as described in
[[error-handling-and-diagnostics]]. This prevents human context from expanding
every caller's recovery switch while preserving evidence at the reporting
boundary.

## Reduce input dimensions without hiding policy

- Pass unique capabilities with distinct types positionally.
- Group confusable same-typed values and nullable literals into an explicit
  options struct.
- Replace invalid combinations of booleans with a tagged domain state.
- Keep policy decisions in the parent; give mechanical leaves dense slices,
  primitive/domain values, and one exact job.
- Pass a narrow component or immutable view instead of broad `self` access when
  the callee does not own the whole object.
- Derive redundant values at the use site when one canonical value is enough.

An options struct may contain more named fields than a positional call. It still
reduces semantic ambiguity and invalid call-site interpretations. Dimensionality
means independently meaningful states, not character count.

## Evidence pattern

The [error-path catalog proof](../proofs/error_path_catalog.zig) returns
`PipelineError!void`: the caller needs to distinguish four operational failures
but no successful value. Publication count and cleanup are caller-owned state,
so returning a success boolean or count would duplicate them. An exhaustive
fault mapping demonstrates the branches the caller actually owns.

The exported `bounded_sum_u32` leaf in the same proof accepts only a pointer and
bounded count and returns the computed value. It has no allocator, I/O handle,
callback, or broad server pointer. [[build-diagnostics-and-generated-code]]
uses it as a stable generated-code inspection subject.

## What commonly goes wrong

- Replacing a meaningful enum with `bool` and moving ambiguity to every caller.
- Returning optional merely to avoid deciding whether absence is an error.
- Erasing cancellation acknowledgement or partial ownership behind `void`.
- Passing `self` for convenience and giving a hot leaf hidden mutable state.
- Creating a generic result object whose fields no single caller uses together.
- Counting parameters while ignoring invalid combinations and implicit globals.

## Review checklist

For every field and variant, name the caller branch that consumes it. Remove it
if there is none. For every removed field, prove it is derivable or irrelevant.
Then enumerate the cross-product that remains and reject impossible states by
construction or assertion.

Related: [[function-shape-and-control-flow]],
[[naming-comments-and-api-shape]], [[select-and-batch]],
[[task-lifetimes-and-structured-concurrency]],
[[design-revision-and-exception-policy]], [[tigerstyle-coverage]].
