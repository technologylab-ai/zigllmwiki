---
id: io-uring
title: io_uring interface and operation lifecycle
kind: platform
status: source-verified
zig: "0.16.0"
summary: io_uring is a Linux-specific batched asynchronous syscall interface whose out-of-order completions, retained resources, finite rings, and cancellation races must shape the owner model.
updated: 2026-09-04
sources:
  - "[[liburing-interface-and-cancellation]]"
  - "[[matklad-what-is-io-uring]]"
  - "[[matklad-cancelation-terminology]]"
  - "[[tigerbeetle-architecture]]"
  - "[[tigerbeetle-io-source]]"
  - "[[zig-0.16.0-release-notes]]"
  - "[[zig-0.16.0-stdlib]]"
proofs: []
platforms:
  - linux
---

# `io_uring` interface and operation lifecycle

## Remember

`io_uring` is a Linux-specific interface for submitting syscall-like operations
through a shared submission queue and receiving results through a shared
completion queue. Its attraction is not merely “nonblocking I/O”: it exposes
batching and concurrency at the syscall boundary and covers files as well as
network operations.

Submission order does not imply execution or completion order. Match every
completion to stable application-owned operation state, normally through
`user_data`, and do not recycle that state or its buffers until the operation's
terminal completion has been consumed.

## Ownership model

For each in-flight operation, the application needs a bounded record containing
at least its identity/generation, state, owned or borrowed resources, expected
completion shape, and continuation. A useful lifecycle is:

`free → prepared → submitted → completing → terminal → free`

The exact kernel ownership of individual arguments varies by opcode and feature.
The conservative application rule is that pointer-backed data and operation
state remain valid until the documented terminal CQE. Encode a slot index plus
generation in request identity when a late completion could otherwise address a
reused slot.

Both rings and the application's operation pool are finite. Queue exhaustion is
a backpressure event, not justification for an unbounded overflow allocation.
Account separately for prepared-but-not-submitted work, submitted operations,
CQEs not yet consumed, multishot operations, and cancellation operations.

## Cancellation is another operation

`IORING_OP_ASYNC_CANCEL` races with the target. The target may finish normally,
fail independently, already be completing, or be non-cancellable. The cancel
request and the target each produce their own completion, and those CQEs may
arrive in either order.

A cancel CQE reporting success says the kernel found and canceled matching
work; it is not the target's lifecycle completion. `-ENOENT` can mean the target
was not found or already completed, and `-EALREADY` means it was found but may
already be completing. None of these results alone authorizes reuse of the
target buffer. Consume and reconcile the target's CQE.

Closing the application's file descriptor does not automatically cancel pending
requests because `io_uring` retains its own file references. Cancel or otherwise
drain the operations, observe their completions, then release application
resources. This is the concrete Linux form of [[cancellation|request and
acknowledgement]].

## Performance and correctness

- Batch only where the workload has independent or explicitly linked work.
- Do not infer operation ordering from queue order.
- Keep the completion path bounded; an undrained CQ is part of the overload
  model.
- Detect supported opcodes and features for the running kernel instead of
  assuming the build machine's kernel.
- Registered files and buffers can reduce per-operation overhead, but introduce
  long-lived registration ownership and update/drain protocols.
- Measure batching and polling modes for the actual device and workload; they
  are not automatic wins.

## TigerBeetle implementation evidence

At the pinned TigerBeetle revision, each Linux operation uses a caller-owned
`Completion`; its address is stored in SQE `user_data` and recovered from the
CQE. The backend tracks queued and in-kernel counts separately, copies CQEs in
fixed batches of at most 256, then queues callbacks instead of recursively
running them while harvesting the ring.

If its SQ is full, the implementation flushes current submissions and retries.
That is an explicit bounded-pressure policy with a latency consequence, not an
unbounded spill path. The loop's bounded wait uses `IORING_ENTER_EXT_ARG`; the
source requires the corresponding feature and therefore Linux 5.11 or newer.

The public operation union at that revision has no asynchronous-cancel entry.
Use the primary cancellation lifecycle above when designing an adapter; do not
infer a reusable cancellation protocol from TigerBeetle merely because some
operation result types include `Canceled`.

TigerBeetle's component-owned callback contexts and sum-of-component limits are
a strong [[static-allocation-and-constant-work|startup-allocation]] pattern for
this interface. See [[tigerbeetle-io]] for the exact cross-platform comparison;
it remains implementation evidence, not a drop-in `std.Io` API.

## Zig 0.16 status

Zig 0.16's `std.Io.Uring` is a proof of concept, not the feature-complete
standard backend. The release notes identify missing networking, error
handling, test coverage, and elimination of small task-stack allocations. Do
not select it for a production server merely because `std.Io` presents a
portable interface.

This page establishes the Linux operation model and records the current
TigerBeetle mapping. A Zig wrapper design, broader kernel-version matrix,
registered-resource analysis, and Linux runtime proofs remain active M3 work.

Related: [[evented-io-backends]], [[task-lifetimes-and-structured-concurrency]],
[[cancellation]], [[tigerbeetle-io]],
[[tigerbeetle-engineering-corpus]].
