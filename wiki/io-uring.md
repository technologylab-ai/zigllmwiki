---
id: io-uring
title: io_uring interface and operation lifecycle
kind: platform
status: runtime-verified
zig: "0.16.0"
summary: io_uring is a Linux-specific batched asynchronous syscall interface whose out-of-order completions, retained resources, finite rings, and cancellation races must shape the owner model.
updated: 2026-09-04
sources:
  - "[[liburing-interface-and-cancellation]]"
  - "[[liburing-registered-resources]]"
  - "[[linux-io-uring-uapi-history]]"
  - "[[matklad-what-is-io-uring]]"
  - "[[matklad-cancelation-terminology]]"
  - "[[tigerbeetle-architecture]]"
  - "[[tigerbeetle-io-source]]"
  - "[[zig-0.16.0-release-notes]]"
  - "[[zig-0.16.0-stdlib]]"
proofs:
  - proofs/linux_io_uring.zig
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

## Kernel and feature floor

Kernel version is only a first filter. Setup flags and features have independent
introduction points, distributions can backport changes, security policy can
deny the syscalls, and an advertised opcode is not a guarantee for every file
type or device. Check setup errors, inspect `io_uring_params.features`, probe
required opcodes, and exercise the actual workload.

| Released kernel | Capability relevant here | Consequence |
| --- | --- | --- |
| 5.1 | Base SQ/CQ ABI, fixed files and buffers, fixed reads/writes | Historical ABI floor, not a Zig 0.16 backend floor. |
| 5.4 | `IORING_FEAT_SINGLE_MMAP` | Minimum accepted by Zig 0.16's low-level `std.os.linux.IoUring` wrapper. |
| 5.5 | `IORING_OP_ASYNC_CANCEL` | Cancellation by target `user_data` becomes available. |
| 5.6 | `IORING_REGISTER_PROBE` | Opcode detection is available; use it instead of version-only dispatch. |
| 5.7 | `IORING_FEAT_FAST_POLL` | Useful networking capability signal, not a promise for regular files. |
| 5.11 | `IORING_ENTER_EXT_ARG` | Required by the pinned TigerBeetle loop for bounded waits. |
| 5.13 | Resource tags and `IORING_CQE_F_MORE` | Enables safer resource-update notification and multi-CQE lifecycles. |
| 5.17 | `IOSQE_CQE_SKIP_SUCCESS` | Successful helper operations may deliberately omit CQEs. |
| 5.18 | `IORING_OP_MSG_RING` | Rings can wake or message one another. |
| 5.19 | Cooperative task running, provided-buffer rings, multishot accept | Adds important server and scheduler building blocks. |
| 6.0 | Single-issuer setup and fixed-file cancellation matching | Effective source-derived floor for Zig 0.16 `std.Io.Uring`, which unconditionally requests single-issuer mode. |

That last row is an inference from the exact Zig 0.16 implementation and the
pinned Linux UAPI history, not a Zig stability or production-support promise.
The backend also depends on earlier CQE-skip and message-ring facilities for
its task scheduling and cross-ring cancellation paths.

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

## Registered resources

Registered files replace a per-operation file-descriptor lookup/reference with
a bounded ring-owned table. An SQE using `IOSQE_FIXED_FILE` addresses a table
index, not the process descriptor number. The kernel-held registration remains
usable after the application closes the original descriptor; the Linux proof
observes exactly that behavior. Treat each table slot as a typed handle with a
generation when late application completions could otherwise refer to a
replaced entry.

Registered buffers have two different lifetimes. The `iovec` array describing
them is needed only during registration, but the underlying byte regions must
keep a stable address and remain reserved while registered. They may also be
borrowed by submitted operations until their terminal CQEs. Do not resize,
free, repurpose, update, or unregister such memory under in-flight operations.

A safe bounded update protocol is: stop admission to the affected slots, drain
and reconcile every operation using them, update or unregister the slots, then
increment the application's generation before reuse. Resource tags can help
with update notification on capable kernels, but they do not remove the need
for an application ownership state machine. Registration consumes finite file,
locked-memory, and kernel resources; failure belongs in startup/admission
policy, and performance benefit must be measured.

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

The Linux proof submits a read against an empty pipe, then submits cancellation
with a distinct identity. It consumes both CQEs by `user_data` and regains the
target buffer only after seeing the target's `ECANCELED` completion. This is one
observed outcome, not permission to hard-code it: production code must also
handle a normally completed target and cancel results such as `ENOENT` or
`EALREADY` while still waiting for the target's terminal CQE.

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

Keep two Zig layers distinct:

- `std.os.linux.IoUring` is a low-level Zig wrapper around rings, SQEs, CQEs,
  registration, probing, and many opcodes. The proof on this page uses it
  directly.
- `std.Io.Uring` is the high-level experimental `std.Io` implementation. Its
  Zig 0.16 vtable deliberately reports the networking operations as
  unavailable even though the low-level wrapper can prepare networking SQEs.

The release notes classify the high-level implementation as a proof of concept
with missing networking, error handling, test coverage, and task-stack work.
Do not select it for a production server merely because `std.Io` presents a
portable interface. The low-level wrapper passing focused tests also does not
upgrade the high-level backend's readiness.

## Runtime evidence and remaining gaps

The [Linux proof](../proofs/linux_io_uring.zig) ran with Zig 0.16.0 on x86_64
Omarchy 4.0.2, Linux `7.1.9-arch1-2`, on 2026-09-04. The host reported
`kernel.io_uring_disabled=0`. Three tests verified finite SQ behavior and
runtime opcode probing, a fixed-file read after closing the original descriptor
using a registered buffer, and reconciliation of separate target/cancel CQEs.

This does not measure performance, test older kernels, cover resource tags or
multishot operations, establish behavior across filesystems/devices, or prove
the high-level `std.Io.Uring` backend production-ready. Those remain explicit
gaps for any concrete server design.

Related: [[evented-io-backends]], [[task-lifetimes-and-structured-concurrency]],
[[cancellation]], [[tigerbeetle-io]],
[[tigerbeetle-engineering-corpus]].
