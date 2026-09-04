---
id: networking-and-dns-racing
title: Networking, DNS, and connection racing
kind: pattern
status: runtime-verified
zig: "0.16.0"
summary: Bound DNS and connection-result queues, use one absolute deadline, drain and close losing connections, and keep stream and datagram ownership distinct.
updated: 2026-09-04
sources:
  - "[[zig-0.16.0-stdlib]]"
  - "[[zig-0.16.0-release-notes]]"
  - "[[fi-zig-0.16-migration]]"
proofs:
  - proofs/network_process_entropy.zig
platforms:
  - macos
  - linux
  - windows
---

# Networking, DNS, and connection racing

## Remember

Zig 0.16 networking is under `std.Io.net` and every operation that can consult
the OS or wait for the network receives `std.Io`. The interface supplies
addresses, hostname lookup, connection racing, stream sockets, datagram
sockets, listeners, deadlines, and explicit close/shutdown operations. It does
not promise an event loop: the shipped [[io-threaded|`Io.Threaded`]] backend
may perform blocking socket operations on threads.

For a bounded service, derive limits for accepted connections, application
queues, per-connection buffers, in-flight DNS results, attempts, and deadlines.
The listen backlog is only a kernel admission queue; it is not the
application's connection limit.

## Parse before resolving

Use `IpAddress.parse` or `parseLiteral` for numeric IPv4/IPv6. These are pure
except that IPv6 scope names need `IpAddress.resolve(io, ...)` to ask the OS for
an interface index. Ports are native-endian values in the Zig types.

`HostName.init` validates a borrowed byte slice: maximum 255 bytes excluding a
trailing dot; each label is non-empty, no more than 63 bytes, begins and ends
with an ASCII alphanumeric character, and otherwise contains only ASCII
alphanumeric characters or hyphens. The caller must keep the backing bytes
alive. Validation is not DNS resolution and does not prove the host exists.

## DNS queues and connection races

`HostName.lookup` pushes zero or more addresses and exactly one canonical-name
result into a caller-owned `Io.Queue`, then closes that queue on every return
path. It is guaranteed not to block only when the queue has capacity at least
16. With less capacity, the caller must drain concurrently; calling lookup
sequentially and reading afterward can wait forever on its own full queue.
The canonical hostname points into the optional caller-supplied canonical-name
buffer, so that buffer must outlive consumption.

`HostName.connectMany` performs lookup and schedules a connection attempt for
each returned address. It writes successes and non-cancellation failures into
the caller's result queue and closes the queue before returning. Capacity and
consumer progress belong to the caller. Every successful result owns a stream,
including successes that arrive after another address has already won.

The convenience `HostName.connect` uses internal 32-element lookup and
connection-result queues. It returns the first successful stream, then cancels
the producer and drains the result queue, closing every losing successful
stream. This is a useful ownership protocol, but it does not make connection
attempt order, degree of parallelism, or latency a portable guarantee.
`connectMany` uses `Group.async`, whose work may run eagerly under
`Io.Threaded` saturation.

Pass an absolute monotonic deadline in `IpAddress.ConnectOptions.timeout` when
all address attempts share one budget. A relative duration can be interpreted
afresh by separate operations; see [[io-time-clocks-and-deadlines]]. DNS lookup
also has resolver-specific attempts/timeouts, so a strict end-to-end budget
needs an owning task whose cancellation and result-drain protocol covers both
lookup and connection work.

## Streams

`IpAddress.listen` creates a `Server` and resolves an ephemeral port into
`server.socket.address` when port zero was requested. Always call
`Server.deinit(io)`. Each successful `accept` or `connect` returns a separately
owned `Stream`; close it exactly once after every reader/writer using it has
finished.

Stream readers translate a zero-byte network read into `error.EndOfStream`.
Stream writers are buffered like file writers, so flush before expecting the
peer to receive a small response. `Stream.shutdown` closes one or both protocol
directions without releasing the socket resource; `Stream.close` releases the
resource. Use half-close only as part of an explicit protocol state machine.

The listen option `kernel_backlog` defaults to 128. It bounds connections the
kernel may hold on the application's behalf, not live streams already accepted
or tasks processing them. Admission should still check an application-owned
maximum before assigning per-connection buffers and work slots.

## Datagrams

`IpAddress.bind` returns a `Socket` for UDP and other message-oriented modes.
`Socket.send` treats one payload as one message and returns
`error.MessageOversize` rather than silently accepting a partial message.
`receive` returns an `IncomingMessage` whose data slice points into the
caller-supplied buffer. Its flags report truncated payload or control data;
never treat a full buffer as a complete datagram without checking `trunc`.

`receiveManyTimeout` uses caller-provided message and data buffers and can
batch multiple datagrams. Each message's `control` field must be initialized
before the call. The returned pair separates an optional error from the count:
process the reported completed prefix according to the operation contract
instead of assuming “error means zero work.”

## Common failures

- Treating hostname validation as lookup or authorization.
- Giving `lookup` a queue smaller than 16 and no concurrent consumer.
- Returning the first connection while leaking successful losers.
- Reusing a relative timeout for a multi-stage DNS/connect budget.
- Equating kernel backlog with bounded application state.
- Forgetting a stream-writer flush or closing a stream while another task owns
  its buffer/operation.
- Applying stream framing assumptions to datagrams, or ignoring truncation.
- Inferring evented progress from the `std.Io` interface.

## Evidence

The [network/process/entropy proof](../proofs/network_process_entropy.zig)
validates hostnames and IP literals and runs an actual IPv4 loopback exchange:
one required-concurrent task accepts a stream, both sides use buffered
reader/writer adapters, both flush and close their resources, and the owner
awaits the server task. It ran with Zig 0.16.0 on aarch64 macOS 26.6.2,
x86_64 Linux 7.1.9, and x86_64 Windows Server 2025 build 26100.33296 on
2026-09-04. DNS and packet batching retain source-level coverage; this loopback
stream test does not prove either. The Windows run is retained in
[Actions run 33911991858](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33911991858).

Related: [[std-io]], [[async-vs-concurrent]], [[select-and-batch]],
[[io-time-clocks-and-deadlines]], [[task-lifetimes-and-structured-concurrency]],
[[evented-io-backends]], [[tigerstyle]].

For a custom Windows completion backend, [[windows-iocp-and-overlapped-io]]
tracks the separate public Winsock TCP-to-file fixture, partial-transfer
ownership, per-entry errors, and native-evidence status. That custom loop does
not implement the entire `std.Io` interface.
