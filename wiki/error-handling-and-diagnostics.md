---
id: error-handling-and-diagnostics
title: Error handling and diagnostics
kind: concept
status: source-verified
zig: "0.16.0"
summary: Use Zig error sets for typed recovery branches, keep programmer invariants on the assertion/panic path, and carry human-facing evidence through a separate bounded diagnostics interface.
updated: 2026-09-04
sources:
  - "[[zig-0.16.0-stdlib]]"
  - "[[matklad-error-codes-for-control-flow]]"
  - "[[matklad-diagnostics-factory]]"
  - "[[matklad-second-error-model-convergence]]"
  - "[[matklad-zig-error-context]]"
proofs:
  - proofs/diagnostics_factory.zig
  - proofs/error_context.zig
platforms:
  - cross-platform
---

# Error handling and diagnostics

## Remember

Error management has at least two consumers:

- code needs a stable category on which it can recover, retry, cancel, reject,
  or escalate;
- a human or protocol client needs evidence explaining what happened in the
  vocabulary and format of that boundary.

Do not force both jobs into one ever-growing error payload. Zig's error sets are
well suited to the first job. A separate diagnostics sink or factory can serve
the second without weakening typed control flow.

## Classify the failure first

An operational error is an anticipated environmental or input condition for
which the caller has a policy: unavailable concurrency, missing file, refused
connection, invalid request, timeout, or [[cancellation]]. Return it.

A violated internal invariant is a detectable programmer defect. Assert it at
the boundary where the invariant should hold rather than turning it into a
normal recovery branch that lets corrupted state continue. A lower-layer
operational error may become an upper-layer invariant violation only when the
upper layer has genuinely established that the condition is impossible.

## Error sets are control-flow codes

Zig marks fallibility in the value type and at propagation sites. A caller must
explicitly `try`, `catch`, or otherwise consume an error union; changing an API
from infallible to fallible therefore changes its call sites.

Use narrow explicit error sets at public boundaries where callers must handle
specific conditions exhaustively. In private composition code, inferred sets
can avoid repeating additive plumbing. At an isolation/reporting boundary it
can be reasonable to care only that an operation failed, but do not erase a
specific recovery category before the last layer that needs it.

The symbolic error name should describe the branch, not duplicate every piece
of diagnostic context. Several detailed diagnostics may intentionally share one
coarse error code, and a collecting checker may emit many diagnostics before
returning that code once.

## Diagnostics factory

Expose named producer functions such as “add banned item” or “add malformed
header.” Each accepts facts naturally available at the detection site. The sink
decides whether to stream text, collect structured records, count, colorize,
localize, or capture expected output for tests.

This shape has useful consequences:

- producer call sites do not depend on the representation or presentation;
- offsets can become line/column locations centrally;
- all diagnostic creation sites and supported categories are searchable;
- tests can swap terminal output for a collector;
- presentation can evolve without changing the typed error contract.

The tradeoff is deliberate indirection. If diagnostics must cross process
boundaries, persist, or support arbitrary downstream matching, define a stable
structured representation rather than hiding it forever behind functions.

## TigerStyle bounded diagnostics

A collecting sink is itself a resource. Give it a startup-derived maximum,
store fixed-size records or bounded references, and make overflow explicit with
a dropped count, truncation marker, early stop, or streaming policy. Never let
an error storm create the allocation failure that destroys the original
evidence.

The [diagnostics-factory proof](../proofs/diagnostics_factory.zig) separates one
typed error code from a fixed-capacity diagnostic representation and records
overflow without allocation. The [context proof](../proofs/error_context.zig)
shows telescoping context capture.

## Reporting boundary

The boundary that owns the operation decides whether to retry, translate,
ignore expected cancellation, or emit diagnostics. It should include the final
error code, relevant structured context, and correlation identity exactly once.
Lower layers should enrich evidence, not independently produce duplicate logs.

Related: [[error-context]], [[cancellation]], [[tigerstyle]],
[[static-allocation-and-constant-work]].
