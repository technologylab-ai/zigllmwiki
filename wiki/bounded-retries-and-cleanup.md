---
id: bounded-retries-and-cleanup
title: Bounded retries, deadlines, and cleanup
kind: pattern
status: runtime-verified
zig: "0.16.0"
summary: Classify retryable failures, bound total attempts and elapsed time independently, preserve the terminal cause, and install cleanup at each ownership acquisition.
updated: 2026-09-04
sources:
  - "[[matklad-retry-loop]]"
  - "[[matklad-retry-loop-retry]]"
  - "[[matklad-zig-defer-patterns]]"
  - "[[source-tigerstyle]]"
  - "[[zig-0.16.0-language-reference]]"
  - "[[zig-0.16.0-stdlib]]"
proofs:
  - proofs/bounded_retries.zig
platforms:
  - macos
---

# Bounded retries, deadlines, and cleanup

## Remember

A retry policy needs at least two independent limits: maximum total attempts
and one absolute elapsed-time deadline. It also needs an explicit error
classification, no delay after the last attempt, and a terminal rule that
preserves the operational cause or deliberately reports deadline expiry.

Name the configuration `attempt_limit` when it includes the first call. This
removes the ambiguous “zero retries still means one attempt” arithmetic and
makes a bounded loop read directly as the maximum number of calls.

## Retry state machine

Treat each call as producing one of three outcomes:

1. **success** — return the owned value and stop;
2. **fatal/terminal error** — return it immediately;
3. **transient error** — retry only if another attempt and remaining time both
   exist.

The owner—not a generic low-level helper—classifies errors because context
changes retry safety. `ConnectionReset` may be retryable before any request
bytes were committed and ambiguous after a non-idempotent request might have
reached the peer. Cancellation, invalid input, authentication failure, and
violated invariants are not transient merely because repeating is possible.

For every transient failure:

`classify → check attempts remaining → check absolute deadline → delay → next attempt`

The ordering prevents an extra sleep after exhaustion. Keep the last transient
error so attempt exhaustion can return the concrete cause. If the deadline is
already expired before a retry delay, return `error.Timeout` when deadline
expiry is the public contract; record the last cause in bounded diagnostics if
operators need it. Do not replace every terminal failure with a generic
“retries exhausted.”

## Two bounds, not one

An attempt count alone permits a single attempt or delay to block without an
elapsed bound. A deadline alone can permit a tight loop to consume unbounded
CPU or hammer a dependency. Enforce both:

- `attempt_limit` is validated against a compile-time/configured maximum;
- one `.awake` or `.boot` deadline is captured before the first attempt;
- each operation and backoff receives that same deadline;
- per-attempt work, buffers, and in-flight operations have their own limits.

Passing the same relative `Io.Timeout.duration` repeatedly can refresh the
budget at each operation. Resolve it once to `Io.Timeout.deadline`; see
[[io-time-clocks-and-deadlines]]. Cap a calculated backoff at the remaining
deadline, check multiplication/addition overflow, and avoid a final sleep when
no attempt remains.

Production fleets also need a resonance policy: capped backoff and jitter can
avoid synchronized retry storms. Keep the PRNG explicit so deterministic tests
can replay the chosen delays, and make the maximum delay and total deadline
part of admission. Jitter does not replace server-side backpressure.

## Retrying side effects

Timeout or connection loss does not prove an operation failed; it may have
committed and lost only its acknowledgement. Before retrying a side effect,
choose one of:

- a protocol idempotency key and deduplication window;
- a naturally idempotent operation with a verified key/version;
- a read/reconcile step that discovers whether the prior attempt committed;
- an explicit ambiguous outcome returned to a higher-level owner.

Never hide this decision inside a loop that sees only an error code. The
deduplication table, request identity, and reconciliation work also need
capacity and deadline bounds.

## Cleanup and ownership transfer

Place `defer` or `errdefer` immediately after successful acquisition so the
resource and cleanup are visible together. Then make ownership transfer an
explicit state change. `errdefer` runs only when the current function returns
an error; it does not run on success, cancellation handled as success, process
exit, or ownership silently moved to another object.

Useful patterns from the pinned defer note, with their constraints:

- Assert a precondition, then `defer` its postcondition where every scope exit
  must re-establish it. Do not use this when ownership legitimately transfers
  and the local postcondition changes.
- After all fallible reservation/acquisition is complete, an
  `errdefer comptime unreachable` can prove that no later generated path
  returns an error. Place it only at a truly infallible commit boundary.
- A deferred increment can pair “return current slot” with committing the
  count, but an explicit commit is clearer when later control flow or ownership
  is nontrivial.
- Contextual error reporting belongs at the owning presentation boundary. A
  logging `errdefer` in every retry/propagation layer duplicates reports and
  mislabels expected cancellation; see [[error-context]].

Defers execute in reverse order, so acquire resources in an order whose
reverse cleanup is valid. A terminal `Future`, `Group`, `Select`, child
process, file, socket, or atomic-file owner must still follow its own
await/cancel/wait/close/deinit protocol; defer is syntax for placing that
protocol, not a substitute for defining it.

## Cancellation during retry

Treat `error.Canceled` as the owner's shutdown signal unless the API explicitly
defines a narrower behavior. Do not classify it as transient and start another
attempt. Cancellation can race with successful completion, so first reconcile
the completed result and any ownership it returns, then release attempt state.

Shutdown order remains:

`stop new attempts → request cancellation → await acknowledgement → drain raced results → release resources`

A backoff sleep is itself cancelable `std.Io`. Scheduling it with `async` does
not guarantee independent progress under `Io.Threaded`; use native operation
deadlines or required concurrency with an explicit unavailable path.

## Review checklist

- Is `attempt_limit` total attempts, validated, nonzero, and visibly bounded?
- Are transient errors enumerated by operation phase rather than “all errors”?
- Does attempt exhaustion return the last concrete cause?
- Is there exactly one absolute deadline for the whole operation?
- Is there no delay after the last attempt or after a terminal error?
- Are backoff, jitter, arithmetic, and per-attempt work bounded?
- Can a timed-out side effect have committed, and how is ambiguity resolved?
- Does cancellation stop retries and complete terminal ownership cleanup?
- Is every acquisition adjacent to cleanup, and every ownership transfer
  explicitly disarming or moving that obligation?
- Is user-facing context reported once by the owner?

## Evidence

The [bounded-retry proof](../proofs/bounded_retries.zig) uses an explicit
three-outcome action, a maximum of eight total attempts, one clock-tagged
deadline, and a counted delay seam. Four tests prove success after two
transient failures with exactly two delays; exhaustion returning the last
transient error with no final delay; immediate fatal/expired termination; and
rejection of zero/excessive attempt limits. They ran with Zig 0.16.0 on
aarch64 macOS on 2026-09-04.

The proof exercises control-flow mechanics, not real dependency idempotency,
backoff distribution, or remote failure timing. Those require protocol-level
tests and deterministic fault injection.

Related: [[io-time-clocks-and-deadlines]], [[cancellation]],
[[function-shape-and-control-flow]], [[error-context]],
[[error-handling-and-diagnostics]], [[invariants-and-assertions]],
[[task-lifetimes-and-structured-concurrency]],
[[deterministic-simulation-testing]], [[tigerstyle]].
