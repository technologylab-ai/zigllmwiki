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
  - "[[http-overload-refusal]]"
  - "[[linux-network-zero-copy]]"
  - "[[techempower-http-test-requirements]]"
  - "[[techempower-plaintext-validator]]"
  - "[[microsoft-thread-termination]]"
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
Further requirements: create all framework threads at startup, interpret
nonessential headers lazily, and compare leading benchmark implementations on
the same hardware using fixed plaintext and a small index.html as first workloads.
Backpressure must be finite: refuse new work before resource exhaustion and
resume admission only after real capacity returns.

## Reliability at the configured maximum

The user's clarified responsibility split: the framework enforces its configured
resource and admission limits and exposes measurements; application developers
choose their workload-specific limits and own latency/throughput guarantees.
The reference server should demonstrate a defined normal web workload, starting
with fixed plaintext and a small HTML page. "Normal" needs a recorded request
mix, sizes, concurrency, arrival rates and client behavior before numeric limits
are selected; it is not a claim about every possible web application.

The framework's guarantee covers the resources and work it owns. It must not
silently exceed them, grow a queue/pool or create threads to accommodate demand.
That is also a useful performance property: overload reaches an explicit
refusal/deadline boundary instead of hidden resource growth and ever-longer
queues. Application allocations and computation remain the application's
responsibility; an interface cannot bound arbitrary code by declaration.

The user's governing requirement is to provision for, and validate, the full
supported workload. Limits are admission commitments rather than aspirational
numbers. If the server is configured for 1,024 connections, no 1,025th connection
may enter its owned connection pool. Startup must reject configurations whose
combined limits cannot be supported; a derived connection cap is preferable
to independent knobs that overcommit shared resources.

Define exactly what that cap promises. Supporting 1,024 open connections with
128 active-request slots is different from supporting 1,024 simultaneous
maximum-sized active requests. If the latter is promised, every required pool
must cover that case, including request parsing, bodies, handler/continuation
state, outstanding I/O, output, completion backlog and cancellation reserve.
For example, 1,024 fully buffered 256 KiB bodies require 256 MiB before headers,
output, stacks and kernel resources. Sharing a pool must not conceal a smaller
active-work guarantee. [[static-allocation-and-constant-work]]

Derive capacity from checked worst-case resource products, taking the tightest
constraint across memory, handles and operation/buffer/queue credits. Then
validate the chosen concurrency and admitted request rate against the stated
CPU, network and handler-work budget. A finite connection count does not bound
requests per second, handler duration or the time a peer takes to read.
Worker queues must fit the latency budget as well as the memory budget.
[[performance-sketches-and-batching]]

Distinguish the guarantees under test:

- **Safety/capacity:** stay within provisioned resources, preserve ownership and
  protocol invariants, and refuse excess work before overcommit.
- **Progress/failure:** under documented scheduler/backend assumptions, bounded
  framework work continues; slow or invalid clients reach a defined timeout,
  refusal or close path without unbounded queues or unsafe reclamation.
- **Performance:** meet a stated latency/throughput target for the tested
  hardware, workload, handler and client-progress conditions, with headroom.
  Static bounds alone do not prove a real-time or arbitrary-application SLO.

Test empty, typical, near-limit, exact-limit and over-limit states. At the
maximum, combine supported worst cases rather than testing each resource cap
in isolation. Include overload/refusal cost in the budget and bound admission
work per loop turn so rejecting traffic cannot monopolize the I/O owner. Verify
recovery after real credits return. Fixed-body/HTML measurements establish
those workloads only; the same acceptance procedure must later cover each
expanded workload contract. [[invariants-and-assertions]],
[[deterministic-simulation-testing]]

Proposed measurement tools: allocation/thread counters after startup; current
and peak pool use; queue occupancy and queue delay; handler execution time;
event-loop lag; output stalls; admitted/rejected/expired request counts with
reasons; and response latency/throughput by workload. Counters, histograms and
trace/export queues must themselves have startup-fixed capacity and bounded
update cost. Declare histogram ranges/overflow, clock cost and sampling/drop
policy; a blocked metrics exporter must not stall request handling. Reports
should connect a rejected request or latency increase to the limiting resource,
and publish both steady-load and overload/recovery results.

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

## Admission and finite backpressure

The user requires refusal at the capacity boundary. Backpressure is a bounded
pause, not a promise to keep every request waiting. Derive admission from actual
free credits for connections, parsing/input, handler jobs, output and terminal
completion records. Reserve the next stage's working budget before committing
to it. All waiting states need a capacity and an absolute deadline; do not hide
an unbounded queue in futures, kernel backlog, suspended handlers or logging.

| Pressure point | Proposed bounded policy |
| --- | --- |
| Connection slots exhausted | Limit pending accepts/backlog and suspend further accepts or close an already accepted excess connection; no new connection state outside the pool. |
| Request/handler credits unavailable | Reject a framed request with 503 when a bounded response is feasible; otherwise close. Never queue unlimited work behind busy handlers. |
| Response credits exhausted | Pause the current producer using its existing continuation slot; retain only the configured output bytes and expire at the response deadline. Reduce further admission as required. |
| Paused/queued deadline expires | Stop that request's progress and close or emit the configured bounded error if framing still permits it. Keep application/kernel borrows until their actual release. |
| Capacity returns | Resume only when all required credits and healthy execution capacity are available; optional startup-configured high/low watermarks prevent repeated admission toggling. |

Reserve finite error/control capacity, but do not promise every rejected client
a delivered response. A client that does not read must not consume a permanent
503 slot. Early rejection with an unread request body normally closes the
connection; no unlimited drain to recover keep-alive. 413 is a request-size
policy result, while 503 reports temporary overload. A response already started
cannot be replaced with a fresh 503; close on an unrecoverable output failure.
[[http11-framing-and-limits]], [[http-overload-refusal]]

Timers do not return credits held by running callbacks or outstanding kernel
operations. Paused, expired and quarantined work remains included in the
resource accounting. A connection deadline alone does not restore a stuck
application-worker pool. Assert limits and credit conservation at admission,
transfer, timeout and terminal release. Optional per-route/client partitions
must themselves use bounded tables. [[static-allocation-and-constant-work]],
[[cancellation]]

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

Proposed callback rule after the execution discussion: general application
callbacks run on a fixed application-worker pool, separate from I/O loops.
Deferred work requires a bounded request handle and explicit terminal
completion; callback return alone is not permission to recycle buffers used
by pending sends. Foreign blocking calls or unbounded CPU work cannot run on
the I/O loop. An ordinary pull Reader/Writer cannot suspend an arbitrary Zig
callback without an execution mechanism. Explicit pending/resume is the current
candidate; a synchronous compatibility API would consume a worker while
waiting. Neither is made evented by naming a function async.
[[async-vs-concurrent]], [[task-lifetimes-and-structured-concurrency]]

## Separate application execution from network ownership

Candidate architecture, not an accepted or measured implementation:

`I/O owner → bounded request-handle queue → application worker`

`application worker → bounded response-command queue → same I/O owner`

Each connection belongs to one I/O shard. Its owner alone mutates parser,
socket, deadline and send state. It never directly invokes arbitrary user
code or waits for a worker, application lock or worker join. Workers receive
immutable request borrows and exclusive writable output reservations. Queue
messages carry handles, lengths and buffer identities rather than copying
payloads. Cross-thread publication needs a proved synchronization protocol;
logical ownership alone does not establish memory visibility.

The application writer transfers committed output to the I/O owner; partial
sends and completions stay there. Completion releases capacity and schedules
an explicit continuation on the worker side. At most one callback/continuation
owns a request context at a time. A full output pool must release execution
through pending/resume instead of occupying a worker until the client reads.
A queued continuation consumes a preallocated context, not a new thread or
unbounded suspended stack. [[task-lifetimes-and-structured-concurrency]]

Reserve queue/terminal-result credit when admitting work. Separate response
data capacity from cancellation/return capacity so a full data queue cannot
prevent an expired worker from returning its ownership. Never hold a framework
mutex while invoking application code. Per-route or per-worker partitions can
contain overload; their counts and fairness policy must be explicit. Fewer
threads and batched handle transfers are candidates to measure, not reasons
to introduce a second hidden queue. [[static-allocation-and-constant-work]]

### Threads are startup resources

The user requires all framework threads to be created during startup. Configure
I/O and application thread counts, stack sizes, queue entries, handler contexts,
output credits and any blocking-work lanes as one resource budget. Allocate and
initialize their state, start workers, wait for an initialization barrier, then
admit traffic. If setup fails, stop and join the threads actually started and
release their resources. No request-path spawn, elastic growth or per-request
thread/future allocation belongs in this proposed strict core.

Exact Zig 0.16 `std.Thread.SpawnConfig` exposes stack size and allocator;
`join` waits for completion and frees spawn resources. Stack sizes are subject
to platform implementation behavior, and spawning at startup is not a proof
of resident pages or real-time scheduling. Shipped `Io.Threaded` task dispatch
can allocate per operation even with warm threads, so it must not silently
implement this promise. Application libraries that create hidden threads or
allocations require an explicit integration exception. [[zig-0.16.0-stdlib]],
[[io-threaded]], [[static-allocation-and-constant-work]]

### What a worker pool can and cannot isolate

The proposal removes application execution from the network owner's call stack.
A slow handler consumes finite application capacity; healthy network owners
can still process completions, expire requests and reject overload, subject to
OS scheduling and shared resource availability. It does not guarantee useful
application throughput if every worker is stuck. It also does not isolate
process-wide memory corruption, crashes, allocator/global-lock failures, or
CPU/memory-bandwidth contention. Leave CPU headroom and measure this boundary.

Timeout stops accepting results; it does not stop arbitrary machine code.
A running handler's input and output reservations remain charged until the
handler acknowledges return and every kernel borrow is released. Generation
checks reject stale messages but cannot prevent use of a retained pointer.
Quarantined slots count against the configured capacity. Never recycle them
at a timer tick or replace stuck workers indefinitely. A queued job can release
ownership only after dispatch/cancellation arbitration proves it never started.

Forcibly terminating an arbitrary thread is not the proposed recovery policy:
Microsoft documents skipped cleanup and shared-lock/state damage for
TerminateThread. If a handler never returns, an in-process server cannot promise
both bounded graceful shutdown and safe reclamation of its borrows. A supervisor
restart or a separately designed process/sandbox boundary is a future option;
process isolation still needs bounded IPC, resource controls, termination/join
and an audit of shared-memory permissions. [[microsoft-thread-termination]],
[[child-process-lifecycles]], [[cancellation]]

An optional trusted inline handler could later avoid worker handoff for
controlled bounded code, but weakens callback isolation. It must be explicit
and measured separately. A declared static response can instead be a bounded
framework operation with no user callback on the loop. The initial application
benchmark should exercise the ordinary callback/writer path, so a fast static
route does not hide the execution model's cost.

## Lazy header interpretation, complete framing validation

The user wants the few required headers interpreted eagerly and the rest
available on demand. Proposed design: one bounded incremental pass validates
the entire header block and identifies the fields needed for framing and
connection policy. Preserve borrowed bytes for everything else. RFC 9112
separates generic field-line parsing from interpreting individual values;
eagerly building a hash map is not required. [[http11-framing-and-limits]]

Eager work includes request-line/target handling, field-name and line syntax,
header byte/count limits, Host validity/duplicates, Content-Length values and
overflow, Transfer-Encoding/framing conflicts, Connection policy and Expect.
Unsupported upgrades or encodings must be recognized according to the supported
protocol policy. Interpret other fields eagerly only when an enabled feature
needs them. Do not stop scanning after the first Content-Length: a conflicting
field or malformed line may occur at the end of the block.

Cookies, user-agent structure, Accept negotiation, query decoding and other
application semantics can remain lazy. Avoid automatic lowercase copies,
string allocation, eager cookie maps and unconditional value normalization.
A first accessor can scan the bounded validated raw block and return borrowed
matches; repeated lookups trade CPU work against a fixed-capacity offset index.
Benchmark both. Preserve duplicate-field semantics instead of blindly combining
all values. Accessor results inherit request-buffer lifetimes and never outlive
their borrow. [[lower-dimensional-api-contracts]]

Assertions check scan cursors, initialized ranges, field counts and parsed-length
state. Malformed syntax and excessive headers remain ordinary rejection paths.
Measure no optional lookups, a few and many; equal framing checks must remain
enabled in all throughput comparisons.

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
versus segmented request storage, the fixed-worker queue/credit and explicit
pending/resume API, and TLS termination. A plaintext first prototype is plausible;
public browser deployments still need a planned HTTPS path. TLS/compression
transform bytes and need their own buffers/ownership/copy audit.

Next proof targets: every parser split point, multiple coalesced requests,
size-counter overflow, framing conflicts, chunk/trailer overhead, slow clients,
partial writes, output exhaustion, request-to-response borrowing, cancellation
and stale handles. First server slice should then add keep-alive and an actual
incremental response writer before routing/upload conveniences.

### Predictable workload and deterministic model

Separate repeatable logical behavior from wall-clock latency. Put protocol and
ownership transitions behind injected receive fragments, send completions,
worker-result events and virtual time. Replay the same event trace with the
same outputs and state changes. Explore alternate bounded interleavings and
failures with recorded seeds. A bounded callback body improves the workload's
predictability but does not make OS scheduling or network timing deterministic.
[[deterministic-simulation-testing]]

First workloads requested by the user:

| Workload | What it should demonstrate |
| --- | --- |
| Constant response | Route `/plaintext` through the ordinary callback/writer and emit `Hello, World!`: 13 ASCII bytes, no newline, `text/plain`, matching Content-Length, and generated protocol headers. Compare a borrowed static body with direct writer generation separately. |
| Small index.html | Read and size-check a chosen file into immutable startup-owned memory, then serve its known bytes through the ordinary callback/writer. This is memory-resident asset serving; a per-request file-read/cold-storage test is a separate workload. |
| Isolation under load | Mix the bounded baseline with deliberately blocked/CPU-heavy handlers, queue exhaustion, stalled response readers and late worker returns. Check event-loop progress, finite memory, overload responses and retained borrow accounting. |

Keep the immutable asset alive through all sends. Pin the HTML bytes/hash and
size in any published run. Preloading/touching during startup removes deliberate
request-path file reads, not every possible later page fault.

The TechEmpower plaintext driver pinned here uses pipeline depth 16. Its body
validator is lenient about case/extra bytes; use the exact published response.
The wiki's illustrative Content-Length of 15 does not match the bare 13-byte
body. Static plaintext body reuse is allowed, whereas caching the entire
response including headers is not. Date and Server headers are required; the
Date representation can be refreshed once a second. JSON later requires actual
per-request serialization. [[techempower-plaintext-validator]],
[[techempower-http-test-requirements]]

Select a few leading implementations for the relevant TechEmpower test when
the comparison is ready; pin the result round, category, framework commits and
configurations then. Run those implementations on our hardware, using the same
OS/architecture, response bytes, clients, concurrency/pipeline depth, transport,
CPU budget and build policy. Linux-only candidates need a common Linux
environment; do not compare native macOS with a competitor in a Linux VM as
though only the framework differs. No competitor selection or build is running.

Use maxross for portable work and macOS comparisons, omarx1 for native Linux
`io_uring` evidence; disclose any common VM experiment separately. Record client
CPU saturation, loopback versus NIC traffic, memory, allocation/copy counts,
queue occupancy, failures, event-loop lag and p50/p99/p99.9 latency across loads.
Include warmup, repeated runs and the point where overload begins. Fixed-work
fast-path results do not generalize to arbitrary application handlers.
Keep the selected production assertion/safety policy enabled in our measured
build; disabling invariant checks solely for a faster score changes the claim.
[[trustworthy-microbenchmarks]]

Related: [[platform-io-backend-decision-table]], [[io-uring]],
[[static-allocation-and-constant-work]], [[lower-dimensional-api-contracts]],
[[tigerstyle]], [[buffer-hygiene-and-division-intent]],
[[task-lifetimes-and-structured-concurrency]], [[deterministic-simulation-testing]].
