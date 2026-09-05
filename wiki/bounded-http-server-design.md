---
id: bounded-http-server-design
title: Bounded HTTP/1.1 framework design exploration
kind: pattern
status: draft
zig: "0.16.0"
summary: Linux-first HTTP framework proposal with startup limits, borrowed request views, bounded response writing and explicit asynchronous buffer ownership.
updated: 2026-09-05
sources:
  - "[[http11-framing-and-limits]]"
  - "[[linux-network-zero-copy]]"
  - "[[techempower-http-test-requirements]]"
  - "[[zig-0.16.0-stdlib]]"
  - "[[source-tigerstyle]]"
  - "[[liburing-interface-and-cancellation]]"
  - "[[apple-xnu-kqueue-aio]]"
  - "[[microsoft-windows-winsock-batched-file-io]]"
proofs: []
platforms:
  - linux
  - macos
  - windows
---

# Bounded HTTP/1.1 framework design exploration

## Remember

M4 design discussion opened on 2026-09-05. These are requirements and candidate
decisions, not implemented APIs or verified HTTP behavior. The server will live
in a dedicated project; this page collects reusable design reasoning.

The user wants a Zig 0.16.0 framework with an `on_request` style API, Linux as
the primary production target, macOS and Windows support, asynchronous I/O,
startup-configured limits, minimal copying, and a response writer supporting
incremental writes and flush. Zap is the user's API inspiration; adopting its
implementation or dependencies is not decided. Higher-level framework features
follow a sound HTTP/1.1 core. M3-006 deployment qualification stays postponed.
The user additionally requires proper evented progress and extensive
TigerStyle assertions; these are core acceptance criteria.

## Which layer can promise what?

Proposed portable promise: no redundant request/body copies inside the
framework's borrowed-view path; bounded storage and explicit lifetimes.
Generated responses are written directly into reserved output storage. This is
different from eliminating kernel/user copies.

Linux `io_uring` provides asynchronous operations, not automatic network copy
avoidance. Registered buffers alone do not imply zero-copy socket receive.
The pinned Linux zero-copy receive facility requires specific NIC features and
configuration. Send copy avoidance has pinning/notification overhead, may fall
back to copying, and requires retaining memory until reuse notification. The
documented MSG_ZEROCOPY crossover is roughly 10 KB, not a universal tuning
constant. Its TCP/UDP loopback path copies. [[linux-network-zero-copy]]

Proposed platform substrates are a custom bounded Linux `io_uring` loop,
macOS nonblocking sockets with `kqueue`, and Windows overlapped sockets with
IOCP. These share an application operation/ownership model. Readiness and
completion semantics remain backend-specific. Zig 0.16's high-level evented
implementations are not ready-made production server runtimes, and passing
`std.Io` does not select these mechanisms. Regular-file work needs its own
bounded strategy, especially on macOS. [[platform-io-backend-decision-table]]

## Limits and the large-upload question

A server can deliberately refuse requests above its configured policy. A
200 MiB upload could use 800 separate requests of at most 256 KiB of content,
with upload identity, offset/index, retry/idempotency, finalization, expiry and
storage quotas handled by an upload protocol. This is an application design
choice. It trades a bounded per-request lifetime for more requests and upload
session state, which must also be bounded.

A single large request can also stream through a small fixed working buffer.
Total accepted content and resident memory are separate limits. Splitting a
file is not required merely to avoid allocating its entire size. HTTP chunked
transfer coding still carries one request; it does not bypass that request's
cumulative body limit. [[http11-framing-and-limits]]

Candidate initial policy: modest complete requests, with separate limits for
body bytes and wire/framing overhead. Values below are discussion examples,
not measured defaults or committed compatibility guarantees.

| Limit group | Candidate knobs / consequence |
| --- | --- |
| Admission | Worker count, max connections, active requests, pending accepts, per-worker/global quotas; reject or stop admitting before exhaustion. |
| Parsing | Request-line bytes, target bytes, total header bytes, header count, individual field bytes, trailer bytes/count; e.g. 16 KiB total headers and 64 fields. |
| Input | E.g. 256 KiB decoded body; separate request wire bytes, chunk metadata/count and buffer/span capacities; never treat a Content-Length as an allocation command. |
| Output | Response header bytes/count, output block size/count, per-response and global queued bytes, iovec count, optional finite total-response byte policy. |
| Time/work | Header, body and response absolute deadlines; keep-alive idle time, handler work budget, completion/parse batch limits, shutdown deadline. |
| Runtime | SQ/CQ entries, outstanding operations, timers, handler contexts, deferred jobs and logging capacity, including reserved cancellation/control capacity. |

All resource products need checked startup arithmetic. Kernel socket memory,
thread stacks and pending completions belong in the budget even when the
framework performs no heap allocation after startup. Do not reserve a maximum
body for every idle connection by accident: 10,000 × 256 KiB is about 2.44 GiB
for bodies alone. Separate connection capacity from active body/output pools.
Finite slots circulate through states; hidden growable collections and
per-dispatch allocation are outside the proposed strict core.
[[static-allocation-and-constant-work]], [[performance-sketches-and-batching]]

## Request views and callback lifetime

Candidate first API: invoke `on_request` when a bounded request is fully framed,
with borrowed method/target/header/body views and a response writer. Later, a
headers-first admission hook and streaming body interface can share the same
ownership model. `Expect: 100-continue` still needs a framing/size decision
before waiting for the body. These callback phases are not settled.

The parser must handle every TCP split/coalescing position. A receive is not a
request. Two storage candidates should be compared before choosing:

1. Receive into a preallocated contiguous request slot: simple views and
   parsing, with larger active-slot memory reservation.
2. Receive into fixed blocks: retain bounded spans and parse across them,
   avoiding body coalescing at the cost of more ownership/descriptor work.

Neither choice may move or recycle memory while application or kernel borrows
remain. A segmented body need not be exposed as one contiguous slice. A small
explicit copy to normalize a split header may be a reasonable measured
exception; an unconditional zero-copy claim would then be inaccurate. Transport
fragmentation must not allocate one unbounded descriptor per receive.

A conceptual borrow/consume cursor is a better core contract than promising
that any Reader operation is zero-copy. Exact Zig 0.16 `Io.Reader.take/peek`
can refill and invalidate earlier views. `std.http.Server.Request.head` strings
are invalidated when body streaming is initialized. An adapter must state
whether it borrows, copies or suspends; the stdlib cannot silently provide a
stronger lifetime guarantee. [[zig-0.16.0-stdlib]]

Proposed callback rule: short synchronous work returns promptly. Deferred work
requires a bounded request handle and explicit terminal completion; callback
return alone is not permission to recycle buffers used by pending sends.
Foreign blocking calls or unbounded CPU work cannot run on the I/O loop.
An ordinary pull Reader/Writer cannot suspend an arbitrary Zig callback without
an execution mechanism. Explicit pending/resume operations versus bounded
stackful tasks is an open API decision, not solved by naming a function async.
[[async-vs-concurrent]], [[task-lifetimes-and-structured-concurrency]]

## Evented progress and assertion discipline

Proposed requirement: no blocking operation on an event-loop worker, no busy
wait for a completion, and no unbounded callback or drain loop. Bound accepts,
bytes parsed, requests dispatched and completions processed per turn so that
one connection cannot monopolize progress. Yield/re-arm when the work budget
expires. A bounded queue must return pending/overload rather than synchronously
waiting on its own consumer. Preserve capacity for cancellation and control
wakeups even under saturation. These are design obligations, not demonstrated
latency guarantees. [[platform-io-backend-decision-table]]

Database clients, filesystem metadata, name resolution, logging, compression,
TLS and application callbacks require the same audit. Unsupported blocking or
CPU-heavy work goes to a fixed-capacity worker lane with bounded completion
handoff, or the API rejects it. Workers are not permission for hidden queue
growth. Arbitrary application code cannot be forcibly made cooperative; a
callback budget is not preemption. OS scheduling, page faults and devices also
preclude a literal promise that execution never stalls. Measure event-loop lag
and tail latency alongside throughput. [[io-threaded]],
[[performance-sketches-and-batching]]

Use assertions derived from invariants, ideally on both sides of a transition:

- Pool conservation: free, reserved, submitted, application-borrowed and
  terminal-awaiting-release slots account for the entire configured pool.
  Model overlapping borrows separately rather than double-counting slots.
- Validate slot index, generation and state when submitting and consuming a
  completion; each operation reaches exactly one terminal state.
- Assert parsed offsets stay within initialized received bytes, counters stay
  within validated limits, and arithmetic cannot wrap.
- Assert only committed output bytes are submitted, partial-send cursors stay
  within them, and reused buffers have neither application nor kernel borrows.
- Assert HTTP response order and framing state: headers become immutable once
  committed, finish occurs once, and emitted content matches declared length.
- Assert shutdown leaves no owned operation, request handle or queued callback
  before pool destruction.

Malformed internet input is expected failure: validate it and return a bounded
protocol error or close. Assertions check the internal state after validation;
a client exceeding a configured limit must not crash the process. Test each
invariant's valid and forbidden transitions, including cancellation and partial
progress. Many meaningful assertions are desirable; assertion count alone is
not evidence. [[invariants-and-assertions]],
[[error-path-catalogs-and-fault-injection]], [[tigerstyle]]

## Response writer, flush and backpressure

The user's requested writer should support incremental output. Proposed core
operations, expressed as design vocabulary rather than runnable Zig:

- **Reserve:** obtain a writable span from a fixed output pool. A full pool
  returns pending/would-block; it does not grow memory or block the I/O loop.
- **Commit:** publish the initialized prefix. The application gives up mutable
  access to those bytes until ownership returns. Empty/uninitialized capacity
  is never transmitted.
- **Flush:** submit committed bytes and expose progress/completion. This may
  require multiple partial socket sends. The API must distinguish queued,
  submitted and safe-to-reuse; none promises peer application receipt.
- **Finish:** close the response framing after all body data is committed,
  validate an advertised Content-Length, then retire the response only after
  every required completion. Errors/cancellation retain borrowed memory until
  terminal reconciliation.

The Linux backend submits socket I/O through `io_uring`; callers do not manipulate
SQEs to use the portable writer. A borrowed external-slice send path can avoid
another framework copy if the caller retains immutable storage to completion.
A conventional copying write helper may coexist, clearly labeled. A later
`std.Io.Writer` adapter must preserve these rules; compatibility does not prove
asynchronous progress or copy avoidance.

Separate generated header storage and body spans can be submitted as bounded
scatter/gather output. Partial sends advance a cursor without copying the
remaining payload. A zero-copy-send option adds its own release notification;
the initial operation completion alone may not release the backing storage.
Its exact kernel protocol needs a separate source/proof before implementation.

Application write chunks are not necessarily HTTP chunks or TCP packets.
Known-length responses can be written/flushed incrementally with Content-Length.
Unknown-length persistent HTTP/1.1 responses can use chunked transfer coding;
the writer owns chunk headers, terminators and final zero chunk, including their
bounded storage. Flush does not finish the response. HEAD and body-forbidden
status semantics need explicit handling. [[http11-framing-and-limits]]

Slow readers eventually fill output capacity. Stop producing, retain only the
bounded pending state, and enforce the response deadline. If a response borrows
request bytes, that also pins input capacity; account for this before admitting
more work. Keep responses ordered on each HTTP/1.1 connection. Initially one
executing handler per connection can consume pipelined requests serially while
preserving buffered suffixes; bounded ordered output batching can be measured
later. [[cancellation]], [[platform-io-backend-decision-table]]

## HTTP correctness and shutdown before speed claims

Implement incremental framing and checked counters for Content-Length and
chunked bodies, trailers, malformed/incomplete messages, Host validation and
conflicting length metadata. Proposed strict policy rejects ambiguous framing
and closes. Oversize content can receive 413, excessive headers 431 and targets
414, when a bounded error response is feasible. Rejecting early must not leave
unread body bytes to be interpreted as the next request; close rather than
performing an unlimited drain. Chunked support is required for general
HTTP/1.1 conformance. [[http11-framing-and-limits]]

Proposed shutdown: stop admission, finish or cancel active work within the
shutdown budget, reconcile every operation and application borrow, then reclaim
slots and close backend resources. A deadline is not proof that the kernel
released a buffer. Generation-tagged handles and conservation assertions should
detect stale completion, double release and leaked ownership. Untrusted input
is checked and rejected; assertions protect internal invariants.
[[invariants-and-assertions]], [[cancellation]]

## Evidence and next decisions

No M4 code, HTTP proof, NIC zero-copy test or server benchmark exists yet.
Existing platform proofs establish narrower lifecycle examples only.

Next design choices: complete-body versus headers-first callback, contiguous
versus segmented request storage, explicit pending/resume versus another bounded
execution model, and TLS termination. A plaintext first prototype is plausible;
public browser deployments still need a planned HTTPS path. TLS/compression
transform bytes and need their own buffers/ownership/copy audit.

Next proof targets: every parser split point, multiple coalesced requests,
size-counter overflow, framing conflicts, chunk/trailer overhead, slow clients,
partial writes, output exhaustion, request-to-response borrowing, cancellation
and stale handles. First server slice should then add keep-alive and an actual
incremental response writer before routing/upload conveniences.

Use maxross for parser/writer microbenchmarks and macOS HTTP measurements, and
omarx1 for the Linux `io_uring` path. Run equivalent competitors on the same
hardware/configuration; Mac requests/sec cannot determine a TechEmpower rank.
Plaintext includes pipelining and required response headers; JSON requires
real per-request serialization. Preserve correctness, allocation/copy counters,
CPU, memory and tail latency, and disclose loopback/client bottlenecks.
[[techempower-http-test-requirements]], [[trustworthy-microbenchmarks]]

Related: [[platform-io-backend-decision-table]], [[io-uring]],
[[static-allocation-and-constant-work]], [[lower-dimensional-api-contracts]],
[[tigerstyle]], [[buffer-hygiene-and-division-intent]].
