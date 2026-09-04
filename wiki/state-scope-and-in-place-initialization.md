---
id: state-scope-and-in-place-initialization
title: State scope and in-place initialization
kind: pattern
status: source-verified
zig: "0.16.0"
summary: Keep one authoritative state value near its use, borrow large read-only values, initialize address-sensitive objects in their final storage, and revalidate invariants across suspension.
updated: 2026-09-04
sources:
  - "[[source-tigerstyle]]"
  - "[[zig-0.16.0-language-reference]]"
proofs:
  - proofs/state_lifetime_and_arithmetic.zig
platforms:
  - cross-platform
---

# State scope and in-place initialization

## Remember

Keep one authoritative representation of mutable state. Put each derived value,
validation, and use as close together as the contract permits. Pass large
read-only values by `*const` when copying is not intended, and construct an
address-sensitive value directly in its final storage.

These choices reduce cache invalidation in both senses: fewer names can become
logically stale, and fewer bytes move through the machine. They do not remove
the need for explicit ownership, concurrency, and lifetime rules.

## One state, one name, one short lifetime

A second mutable alias is another value that can disagree with the first. Do
not cache a field, count, pointer, or boolean merely to shorten its spelling.
Prefer the authoritative value, or calculate a derived value in the smallest
scope immediately before validating and using it.

This is especially important at a boundary:

- convert an external size to the domain type, validate it, then consume it;
- derive an index from the current generation and use it before state changes;
- obtain a slice only for the operation whose preconditions established it;
- keep loop-local state inside the bounded loop;
- delete variables whose only purpose is to mirror another variable.

Do not compress distinct concepts into one variable to reduce the name count.
Index, count, capacity, and byte size remain separate domains; see
[[integer-widths-and-boundaries]]. The goal is fewer simultaneously live facts,
not fewer types or weaker contracts.

## Borrow large values when copies are not intended

TigerStyle uses 16 bytes as a review threshold: a read-only argument larger
than that should normally be passed by `*const T` if the callee does not need a
copy. This is a project design rule, **not** a Zig 0.16 ABI guarantee. Target,
calling convention, optimization, and type layout still determine generated
code.

A const pointer communicates all three relevant facts:

1. the caller retains ownership;
2. the callee must not mutate through this reference;
3. copying the complete value is not part of the intended operation.

The pointer is valid only for the lifetime of its referent. Do not retain it
beyond that lifetime, cross an ownership transfer without a new contract, or
interpret `*const` as thread safety. Small values, values deliberately copied
as snapshots, and APIs where ownership transfer matters can reasonably use a
different shape; make the intent explicit.

## Initialize address-sensitive values in final storage

If a value stores a pointer to itself or one of its fields, is registered with
an OS, is observed by an asynchronous operation, or is otherwise immovable,
initialize it through its final pointer:

`var service: Service = undefined; Service.init(&service, options);`

The initializer must establish every field that may be observed before it
publishes the value. If initialization can fail, its contract must say whether
the output is unchanged, partially initialized but safe to deinitialize, or
invalid and unobservable. `undefined` storage must never escape before the
successful initialization boundary.

In-place initialization is viral. If `Service.table` must be initialized at
its final address, `Service.init` must initialize `&service.table`; it must not
initialize a temporary `StableTable` and copy it into `service` afterward.
The same rule propagates through every enclosing object until final storage is
known.

Zig does not automatically pin ordinary values. Returning, assigning, or
moving a self-referential value can invalidate its stored address. Prefer
stable owner-controlled storage, document when movement becomes forbidden,
and assert pointer identity at publication/use boundaries when it is a critical
invariant.

## Suspension opens a place-of-check/place-of-use gap

Run-to-completion code can validate a precondition and rely on it until return
when no callback, concurrent owner, or external actor can mutate the relevant
state. A suspension point changes that model. `io.async(...)`, `Future.await`,
`Group.await`, callbacks, locks released around waits, and user code may allow
state or ownership to change between check and use.

Across such a boundary, choose an explicit rule:

- move immutable input into task-owned storage;
- hold ownership whose protocol excludes mutation;
- serialize all mutations through one owner;
- capture a generation/version and revalidate it after resumption;
- reacquire the lock and repeat the predicate check;
- cancel and await the operation before releasing referenced storage.

Never assume the word `async` pins arguments, creates a thread, or preserves a
precondition. The implementation and operation determine progress; the owner
determines lifetime. See [[async-vs-concurrent]] and
[[task-lifetimes-and-structured-concurrency]].

## Ownership and cleanup stay visually paired

Install `defer` or `errdefer` immediately after successful acquisition, while
the resource and its release rule are visible together. If ownership moves,
make that transition explicit and ensure exactly one owner retains the cleanup
obligation. The visual pairing reduces scope mistakes; it does not define the
resource's terminal protocol. Futures, operations, processes, files, and
sockets may still require cancel/await/drain/close sequencing. See
[[bounded-retries-and-cleanup]].

## Review checklist

- Is there one authoritative mutable value rather than aliases that can drift?
- Is each derived value calculated, validated, and consumed near one another?
- Are unrelated names out of scope before the next state transition?
- Does a large read-only parameter communicate borrowing with `*const`?
- Is the 16-byte rule described as project policy rather than an ABI promise?
- Is every address-sensitive value initialized directly in final storage?
- Does in-place initialization propagate through enclosing objects?
- Can partial initialization be safely and unambiguously cleaned up?
- Can any suspension invalidate a pointer, generation, predicate, or owner?
- Is cleanup adjacent to acquisition and transferred exactly once?

## Evidence

The [state/lifetime proof](../proofs/state_lifetime_and_arithmetic.zig) defines
a value larger than 16 bytes passed by `*const`, then initializes a nested
self-address-checking table through its final containing object. Its tests ran
with Zig 0.16.0 on aarch64 macOS on 2026-09-04.

The proof establishes the Zig mechanics, not ABI behavior, immovability, or
cross-thread safety. Those remain design contracts backed by review and by the
specific asynchronous or OS API involved.

Related: [[tigerstyle]], [[integer-widths-and-boundaries]],
[[async-vs-concurrent]], [[task-lifetimes-and-structured-concurrency]],
[[invariants-and-assertions]], [[bounded-retries-and-cleanup]],
[[buffer-hygiene-and-division-intent]].
