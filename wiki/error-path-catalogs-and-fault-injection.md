---
id: error-path-catalogs-and-fault-injection
title: Error-path catalogs and fault injection
kind: pattern
status: source-verified
zig: "0.16.0"
summary: Catalog each expected terminal error with ownership and side-effect state, then use bounded deterministic injection to prove every non-fatal path rather than merely propagating it.
updated: 2026-09-04
sources:
  - "[[source-tigerstyle]]"
  - "[[tigerbeetle-safety]]"
  - "[[tigerbeetle-vopr]]"
  - "[[zig-0.16.0-language-reference]]"
proofs:
  - proofs/error_path_catalog.zig
platforms:
  - cross-platform
---

# Error-path catalogs and fault injection

## Remember

“Handled” does not mean `catch {}` or `try` toward a remote caller. For every
expected non-fatal error, the owning boundary must choose a terminal policy,
restore or transfer every resource, preserve ambiguity about external effects,
and make the result observable at the correct layer.

Build the catalog before injection. Otherwise a fuzzer can exercise many paths
without showing which required path is missing.

## Catalog schema

Keep one row per operational terminal condition:

| Field | Required question |
| --- | --- |
| Stable ID | Which review, test, and diagnostic refer to this path? |
| Producer | Which call or state transition returns it? |
| Injection point | Is the fault before acquisition, before effect, after partial effect, or during cleanup? |
| Public category | Which exact error, termination tag, or protocol status reaches the policy owner? |
| State | Which transitions completed, and which must not have completed? |
| Ownership | Who closes, cancels, drains, frees, or retains every resource? |
| Retry | Is retry safe, unsafe, or conditional on idempotency/reconciliation? |
| Bound | Which attempt, time, queue, output, or diagnostic limit applies? |
| Observation | Which bounded diagnostic or metric records it once? |
| Evidence | Which deterministic test and platform-runtime test exercise it? |

Inventory at least invalid input, capacity exhaustion, unavailable concurrency,
timeout, cancellation request and acknowledgement, partial read/write, ambiguous
external completion, child termination, persistence/checksum rejection, cleanup
failure, and diagnostic overflow when those exist in the subsystem.

## Injection design

Use an explicit test-owned fault enum or scripted sequence. Keep it out of
ambient globals so parallel tests cannot change each other's path. Each fault
name should identify a semantic boundary, not an unstable source line.

Inject on both sides of irreversible effects. “Write failed” before submission
has different retry and ownership consequences from connection loss after a
peer may have accepted the write. Preserve that ambiguity instead of translating
both to a cheerful retryable error.

The harness itself needs limits: maximum injected events, bounded diagnostic
storage, a deterministic seed or explicit sequence, and a terminal progress
budget. Record the seed and fault script on failure. Combine this catalog with
[[deterministic-simulation-testing]] for reordered completions and long state
histories, but retain small direct tests for every row.

## Zig pattern and executable evidence

Use narrow public error sets when callers need exhaustive recovery branches.
An exhaustive `switch` maps every injection tag to its expected public error,
and an inline iteration over all enum tags exercises every catalog row. Adding a
new tag then requires an explicit expected result and automatically enters the
test traversal.

The [error-path catalog proof](../proofs/error_path_catalog.zig) injects failure
before acquisition and at decode, apply, and flush boundaries. It checks the
exact typed error, whether ownership cleanup ran, and that publication happens
only on success. The same file exports a bounded, stand-alone hot function for
the generated-code workflow in [[build-diagnostics-and-generated-code]].

Assertions remain for programmer defects. Do not turn an internal corrupt
state into an injectable “operational error” merely to make a coverage number
rise. Corrupt bytes arriving from disk or a peer are untrusted input and should
be rejected; an impossible state produced inside a trusted transition should
assert.

## What commonly goes wrong

- Testing an error code but not resource ownership or forbidden side effects.
- Injecting only before effects, where retry is easiest.
- Using allocator failure as a proxy for unrelated disk, cancellation, or
  protocol semantics.
- Enumerating leaf errors while missing the public translation and reporting
  branch.
- Assuming a compile proof exercises a kernel-specific cleanup race.
- Swallowing cleanup failure without specifying whether the original or cleanup
  error owns the report.

## Evidence boundary

The local proof establishes the Zig 0.16 harness pattern on the host test
runtime. OS-specific interruption, completion, and durability rows still need
runtime evidence on every named platform; source inspection and cross-target
compilation do not close those rows.

Related: [[error-handling-and-diagnostics]], [[cancellation]],
[[bounded-retries-and-cleanup]], [[invariants-and-assertions]],
[[deterministic-simulation-testing]], [[design-revision-and-exception-policy]],
[[tigerstyle-coverage]].
