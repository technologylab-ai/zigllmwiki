---
id: function-shape-and-control-flow
title: Function shape and centralized control flow
kind: pattern
status: runtime-verified
zig: "0.16.0"
summary: Keep one parent responsible for decisions and state transitions, push bounded repetitive mechanics into narrow leaves, and replace recursion with explicit capacity.
updated: 2026-09-04
sources:
  - "[[source-tigerstyle]]"
  - "[[matklad-push-ifs-up-fors-down]]"
  - "[[matklad-size-matters]]"
  - "[[zig-0.16.0-language-reference]]"
proofs:
  - proofs/control_flow_shape.zig
platforms:
  - macos
---

# Function shape and centralized control flow

## Remember

Shape functions around decisions and ownership, not around arbitrary line
chunks. A TigerStyle component usually has one parent function that sees the
state machine, validates transitions, decides error policy, and commits state.
Narrow helpers perform bounded repetitive mechanics or pure calculations and
return proposed values to the parent.

This is “push `if`s up and `for`s down”: branch where the domain decision is
visible; loop where one operation is repeated. It is a direction for reducing
scattered policy, not a literal ban on every guard inside a helper. A leaf must
still check bounds and arithmetic where it has the values needed to do so.

## Function size is a review bound

TigerStyle sets a hard maximum of 70 lines per function body. The constraint
keeps the complete local model within a reviewer's field of view and forces
poorly shaped control/state flow to become visible. It is not a license to
create dozens of tiny forwarding functions or to split a cohesive domain
module merely because its file is long.

Prefer the inverse-hourglass shape:

- a small, unambiguous parameter surface;
- a simple return type or narrow error set;
- enough implementation in the body to express one coherent responsibility.

The pinned “Size Matters” essay separates this physical review limit from
architectural surface area. A good module may contain substantial related
implementation behind a small public interface. Count lines as a mechanical
alarm; judge the refactoring by whether ownership, invariants, and decision
flow became easier to reconstruct.

## Parent decides; leaves compute

Keep these responsibilities in the parent owner:

- branch on events, modes, operation results, and cancellation;
- validate the current state and whether a transition is admitted;
- decide which operational errors are retried, rejected, or fatal;
- apply mutations to decisive component state;
- establish the terminal cleanup path.

Push these responsibilities into narrow helpers:

- scan, copy, encode, hash, compare, or accumulate a bounded collection;
- compute a candidate value or transition without mutating broad owner state;
- operate on explicit primitive slices/counts instead of an unconstrained
  `self` when that keeps dependencies honest;
- return enough typed information for the parent to make the policy decision.

This structure prevents a leaf called from several paths from quietly changing
the state machine. It also lets tests exhaust a pure calculation separately
from tests of accepted and rejected transitions.

Do not mechanically move a branch upward when the caller lacks the value or
invariant needed to decide it. Place validation near the data it validates,
then return a typed result. “Centralize control flow” means one owner decides
system policy, not that lower layers pretend failures and bounds do not exist.

## Applied transformations

| Scattered shape | Applied shape | Why it is safer |
| --- | --- | --- |
| Each per-item helper checks mode and mutates shared totals. | Parent selects the mode once; leaf folds the bounded batch and returns a delta; parent validates and commits it. | Policy and decisive state mutation have one location. |
| A recursive walk relies on input shape for termination. | Caller-owned fixed work stack plus explicit visit and stack-capacity limits. | Memory and worst-case work are visible; cycles fail as data, not stack overflow. |
| One compound condition mixes authorization, capacity, and health. | Positive nested cases with an explicit result for every negative branch. | Reviewers can see which condition owns each rejection and whether a case is missing. |
| A large function is split into wrappers that forward broad `self`. | Parent retains the state transition; helpers take only required values/slices and return narrow results. | The split reduces dependency/state dimensions rather than hiding them. |
| An external callback directly performs arbitrary work. | Callback records a bounded event; the component loop admits, batches, and applies work at its own pace. | External timing no longer owns internal control flow or per-tick work. |

## Positive decision trees

Prefer conditions stated in the same direction as their invariant. For an
index, branch on `index < length` and give the `else` case an explicit meaning.
For admission, make authorization, capacity, and readiness separate nested
decisions rather than one compound expression followed by a generic failure.

This can be more verbose, which is intentional when the cases carry different
operational consequences. It enables exhaustive tests over the decision table
and makes a missing negative case visible. Simple expressions whose parts have
one meaning need not be expanded merely to increase line count.

## Recursion and explicit work

Replace input-shaped recursion in systems paths with a work list whose storage
capacity and maximum operations are derived from the domain. These are two
different limits: a narrow but cyclic graph can exhaust the work budget without
filling the stack, while one very wide node can exceed stack capacity
immediately.

Choose whether exceeding either limit is rejected input, overload, or a
programmer assertion. External graph shape normally produces a typed error;
an impossible internal topology may justify an assertion after validation.
Intentionally infinite service loops are a separate case and should assert or
document the condition that keeps each iteration bounded.

## Suspension and callbacks

A function that suspends cannot assume its preconditions remained true while
another task ran. Keep mutable state behind one serialized owner, or revalidate
after every suspension before commit. Cancellation is also a state transition:
stop admission, request cancellation, await acknowledgement, reconcile raced
success, and only then release shared state.

Prefer run-to-completion callbacks over callbacks that retain borrowed owner
state across asynchronous work. When later completion is required, hand off an
owned operation record with a generation/identity that the parent validates on
return; see [[task-lifetimes-and-structured-concurrency]].

## Review checklist

- Does one visible owner decide every state transition and error policy?
- Are state mutations centralized after all fallible validation/computation?
- Do helpers accept only the dependencies and data they actually need?
- Is each loop bounded, including work-list growth and total visits?
- Has input-shaped recursion been replaced or proven impossible/bounded?
- Are negative branches explicit enough to test exhaustively?
- Does every suspension force revalidation before state commit?
- Is a function split reducing conceptual dimensions, or only hiding lines?
- Does every function body remain within the 70-line review limit?

## Evidence

The [control-flow shape proof](../proofs/control_flow_shape.zig) implements a
parent-owned batch state transition whose leaf only computes a delta, exhausts
a positive nested admission tree, and replaces recursive graph traversal with
a fixed eight-slot work stack plus a separate visit budget. Tests cover normal
state, rejected post-close mutation, every meaningful admission result, a
cycle exhausting work, and a wide node exhausting capacity. They ran with Zig
0.16.0 on aarch64 macOS on 2026-09-04.

The proof demonstrates the applied structure; it cannot mechanically prove
that an arbitrary program has centralized all policy. Repository line checks
are a guardrail, while semantic review still reconstructs control flow and
state mutation across the whole component.

Related: [[tigerstyle]], [[tigerstyle-coverage]],
[[invariants-and-assertions]], [[code-reading-and-mechanical-checks]],
[[integer-widths-and-boundaries]], [[static-allocation-and-constant-work]],
[[task-lifetimes-and-structured-concurrency]], [[cancellation]].
