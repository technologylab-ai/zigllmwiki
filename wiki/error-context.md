---
id: error-context
title: Error context and diagnostics
kind: pattern
status: source-verified
zig: "0.16.0"
summary: Keep typed errors for control flow, accumulate structured context along the happy path, and emit diagnostics only at the boundary that knows an error is unhandled.
updated: 2026-09-04
sources:
  - "[[matklad-zig-error-context]]"
  - "[[matklad-error-codes-for-control-flow]]"
  - "[[matklad-diagnostics-factory]]"
  - "[[zig-0.16.0-stdlib]]"
proofs:
  - proofs/error_context.zig
platforms:
  - cross-platform
---

# Error context and diagnostics

## Remember

Zig's error values answer “what control-flow category occurred?” They do not
automatically answer “which file, peer, request, offset, or operation made this
failure meaningful to a human?” Preserve the typed error and collect that
context separately.

For reusable or production code, prefer a structured diagnostics sink owned by
the caller; see [[error-handling-and-diagnostics]]. For a small executable,
concise key/value context installed with `errdefer` can be a useful minimum—but
emission belongs at the final reporting boundary.

## The telescoping pattern

Each layer adds stable facts already in scope: operation, path, address,
request ID, offset, limit, or state. On failure, `errdefer` records those facts
without wrapping every `try` in a custom message. Outer layers add their own
context, producing a telescoping description of the failed operation.

The [diagnostics proof](../proofs/error_context.zig) uses fixed storage and
`errdefer` to capture inner and outer context while preserving the original
error. It intentionally does not log inside the propagating functions.

## Why immediate `errdefer` logging is dangerous

An `errdefer` runs when an error leaves its scope, not when the application has
decided the error is fatal or even noteworthy. An outer retry, optional lookup,
or cancellation owner may handle it normally. Logging in the lower layer then
creates a scary but false diagnostic.

This matters throughout Zig 0.16 I/O because `error.Canceled` is intended
control flow at cancellation points. Capture context if useful, propagate the
error, and let the future/group owner decide whether it represents expected
cancellation, an operational failure, or a programmer invariant violation.

## Diagnostic design

- Keep the machine-readable error value intact.
- Use fields rather than prose where possible; format prose once at the edge.
- Bound diagnostic storage and define truncation behavior.
- Record facts, not guesses about root cause.
- Avoid secrets and unbounded user strings.
- Clear or version the sink per top-level operation so stale context cannot leak.
- Test handled errors and cancellations to prove they do not emit failure logs.

Related: [[cancellation]], [[std-io]], [[tigerstyle]].
