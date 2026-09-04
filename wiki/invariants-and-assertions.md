---
id: invariants-and-assertions
title: Invariants and assertion placement
kind: principle
status: runtime-verified
zig: "0.16.0"
summary: State the property preserved across every transition, assert it at ownership boundaries and independent paths, and test both the valid and forbidden state space.
updated: 2026-09-04
sources:
  - "[[source-tigerstyle]]"
  - "[[matklad-what-is-an-invariant]]"
  - "[[matklad-look-for-bugs]]"
  - "[[tigerbeetle-safety]]"
proofs:
  - proofs/invariants.zig
platforms:
  - cross-platform
---

# Invariants and assertion placement

## Remember

An invariant is a precise property that remains true while state evolves. It
compresses many possible execution histories into one condition that must hold
at every named transition. “This usually works” is not an invariant; a relation
such as `free_count + active_count == capacity` is.

Write the invariant before repairing a failing case. Then check four things:

1. it holds in the initial state;
2. each state transition preserves it;
3. termination plus the invariant implies the promised result;
4. invalid states and valid-to-invalid transitions are rejected.

## Three useful scales

| Scale | Example | Enforcement |
| --- | --- | --- |
| Local algorithm | A search interval always contains the answer. | Loop assertions, progress bound, exhaustive small cases. |
| Component state | Every operation slot has one owner and cannot be reused before terminal completion. | State tags, count conservation, entry/exit assertions, cancellation tests. |
| Whole system | No steady-state allocation, or transaction execution never waits for disk. | API shape, forbidden-dependency lint, capacity model, integration tests. |

System invariants are intentionally viral. If a rule has no consequence for
APIs, data structures, tests, or checks, it is probably an aspiration rather
than an invariant.

## Assertion placement

Use assertions to expose programmer defects, not to report expected operational
failure. Place them where ownership or representation changes:

- arguments and preconditions on entry;
- postconditions and return relationships before exit;
- the invariant before and after every nontrivial state transition;
- paired checks on independent paths, such as data construction and later
  interpretation;
- compile-time relationships among capacities, widths, layouts, and protocol
  constants;
- positive and negative space, including transitions from valid toward invalid.

Split unrelated predicates into separate assertions so the failed fact is
unambiguous. State relationships positively when possible: `index < count` is
easier to preserve than a double negative. Express implication at the point
where its premise is visible. A deliberately obvious assertion is worthwhile
only when it documents a critical, surprising fact that a future change might
otherwise erase.

Assertions must not mutate state, perform required cleanup, or replace input
validation. They may remain enabled in production precisely because crossing
an invariant boundary means the program's model is already unsound.

## Concurrency and I/O

Name the point at which a concurrent invariant is valid. A precondition checked
before suspension may no longer hold after resumption unless the state is
immutable, protected, versioned, or exclusively owned. Serialized callback
dispatch can provide a convenient transition boundary, but only if callbacks
run to completion and do not perform hidden blocking work.

For an asynchronous I/O operation, a useful invariant family is:

- every in-flight operation has exactly one completion owner;
- its buffer remains live until terminal completion;
- queued, kernel-owned, ready, and free counts reconcile with capacity;
- cancellation request and cancellation acknowledgement are distinct states;
- a completion slot is recycled only from a terminal state.

See [[task-lifetimes-and-structured-concurrency]], [[cancellation]], and
[[tigerbeetle-io]] for the backend consequences. Predicate loops, balanced
permits, and lock/queue terminal states are applied in
[[io-synchronization-primitives]].

## Proof shape

`proofs/invariants.zig` implements lower-bound insertion search from its
invariant instead of from example-by-example fixes. It asserts a bounded loop,
preservation of the search partition, and the return postcondition. Its test
checks every candidate position for small arrays with duplicates, so both the
unique valid answer and the negative space are exercised under Zig 0.16.0.

## Agent review checklist

- Can the invariant be written as a precise predicate over named state?
- Is initialization visible and is every writer/transition enumerated?
- Does each transition make bounded progress or have an asserted bound?
- Is the same property checked independently where data is produced and used?
- Are operational errors returned while impossible internal states assert?
- Do tests cross both sides of each boundary?
- Can a suspension, callback, cancellation, or late completion invalidate the
  property between check and use?

Related: [[tigerstyle]], [[deterministic-simulation-testing]],
[[static-allocation-and-constant-work]],
[[code-reading-and-mechanical-checks]].
