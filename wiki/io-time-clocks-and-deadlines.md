---
id: io-time-clocks-and-deadlines
title: std.Io clocks, durations, deadlines, timeouts, and sleeping
kind: pattern
status: runtime-verified
zig: "0.16.0"
summary: Choose a clock by suspend and wall-time semantics, capture one absolute deadline for a multi-step budget, and treat sleeping as cancelable I/O whose progress depends on the implementation.
updated: 2026-09-04
sources:
  - "[[zig-0.16.0-stdlib]]"
  - "[[zig-0.16.0-release-notes]]"
  - "[[fi-zig-0.16-migration]]"
  - "[[matklad-strictly-monotonic-time]]"
  - "[[hermit-io-timeout-proof]]"
proofs:
  - proofs/io_time.zig
platforms:
  - macos
---

# `std.Io` clocks, durations, deadlines, timeouts, and sleeping

## Remember

Use `.real` for calendar timestamps and `.awake` or `.boot` for elapsed-time
budgets. Capture a single `Clock.Timestamp` deadline when one budget spans
multiple operations. Passing the same relative duration to each retry grants a
fresh full budget every time.

`std.Io.sleep` is potentially blocking, cancelable I/O. It neither creates a
task nor guarantees concurrent caller progress. In particular, putting a sleep
behind `async` does not by itself create a working timeout race; see
[[async-vs-concurrent]].

## The five clock domains

`std.Io.Clock` names intent as well as an OS time source:

| Clock | Interface meaning | Appropriate use |
| --- | --- | --- |
| `.real` | Settable wall clock, represented as Unix-epoch nanoseconds; it can jump and be frequency-adjusted. | Persisted or displayed civil timestamps, never an elapsed-time invariant. |
| `.awake` | Nonsettable, non-decreasing clock intended to exclude system suspend, though an implementation may include it. | Latency or work budgets that should normally pause during suspend. |
| `.boot` | Like `.awake`, but intended to include system suspend; an implementation may behave identically to `.awake`. | Expiry or retry budgets that should normally continue across suspend. |
| `.cpu_process` | CPU time consumed by the process in user or kernel mode. | Profiling CPU consumption, not elapsed deadlines. |
| `.cpu_thread` | CPU time consumed by the calling thread in user or kernel mode. | Per-thread CPU accounting, not sleeps or service timeouts. |

The interface promises only that `.awake` and `.boot` do not go backwards.
Successive reads may be equal: they are monotonic, not strictly monotonic.
Their suspend distinction is an expressed intent with a documented fallback,
so code that requires exact suspend behavior needs implementation/platform
evidence.

`Clock.now` and `Io.Timestamp.now` return a raw timestamp without an error.
Call `Clock.resolution` beforehand when availability matters; it can return
`error.ClockUnavailable` or `error.Unexpected`, and its duration may be zero.
Do not mistake nanosecond storage for nanosecond clock resolution.

## Raw values versus clock-tagged values

`Io.Timestamp` and `Io.Duration` each store a signed `i96` nanosecond count.
They provide explicit constructors/conversions; conversions to seconds,
milliseconds, and microseconds truncate toward zero and return `i64`.
`Io.Duration` formats through `{f}` in Zig 0.16; the old `{D}` format is gone.

Prefer `Clock.Timestamp` and `Clock.Duration` inside deadline logic. These wrap
the raw value together with its clock. Their comparison and arithmetic methods
assert that both operands use the same clock, turning mixed-domain arithmetic
into a detected programming error instead of a plausible-looking result.

`Clock.Timestamp.toClock` samples both clocks and projects the old remaining
duration into the new domain. That is an approximate bridge, not evidence that
two independently acquired clock values share an epoch. Pick the deadline
clock at the ownership boundary and avoid repeated conversion.

Arithmetic is signed and not saturating. Validate untrusted durations and
bound additions before constructing deadlines; a negative or overflowing
budget should be an explicit input/admission decision, not an accidental sleep
policy.

## Relative timeout versus absolute deadline

`Io.Timeout` has three forms:

- `.none` adds no timeout to an operation;
- `.duration` is a clock-tagged relative interval;
- `.deadline` is a clock-tagged absolute timestamp.

`toDeadline(io)` and `toTimestamp(io)` resolve a relative duration using that
clock's current time. `toDurationFromNow(io)` computes remaining time for a
deadline, which may be zero or negative after expiry. For a `.duration`,
however, it returns the original duration unchanged. Therefore resolve once:

`validated duration → one deadline → each operation/retry receives that deadline`

This keeps retry count, backoff, DNS/connect races, and cleanup inside the same
finite budget. A `.real` deadline can move when wall time changes. An
`.awake`/`.boot` deadline retains the selected monotonic domain and is the usual
choice for elapsed work.

`Timeout` describes when an operation that supports timeouts should return
`error.Timeout`. Calling `Timeout.sleep` instead waits until the timeout has
passed and returns only success or `error.Canceled`; it does not return
`error.Timeout`. Sleeping on `.none` is a no-op in the shipped
`std.Io.Threaded` implementation, matching the absence of a timeout rather
than meaning “sleep forever.”

## Sleeping, scheduling, and cancellation

The convenience forms all delegate to the implementation's `sleep` vtable
entry:

- `std.Io.sleep(io, raw_duration, clock)`;
- `Clock.Duration.sleep(io)`;
- `Clock.Timestamp.wait(io)`;
- `Timeout.sleep(io)`.

All are cancellation points and may return `error.Canceled`. The owner still
has to await or cancel every surrounding `Future`, `Group`, or `Select` branch.
A timeout racing a successful operation has the same terminal race as any
other cancellation: reconcile the actual completion before releasing buffers
or handles.

The production Zig 0.16 `std.Io.Threaded` implementation sleeps through
platform blocking/parking facilities. A direct sleep occupies the current
thread. If scheduled with `async`, resource saturation may execute that sleep
inline before the caller can reach its selection logic. Request `concurrent`
only when independent progress is required, handle
`error.ConcurrencyUnavailable`, and prefer an operation's native deadline when
it expresses the same ownership correctly.

## Strictly monotonic application time

When equal samples are ambiguous for application assertions, the pinned
matklad note proposes an application-owned guard that returns the greater of
the raw observation and the previous guarded value plus one representable
nanosecond. This permits strict `past < present` assertions and makes equal
guarded values evidence that the same observation was reused.

That is a derived application abstraction, not a stronger `std.Io.Clock`
guarantee. A production guard needs a single owner or synchronization, an
overflow policy, and a drift analysis: repeated increments within one raw
clock tick manufacture timestamps slightly ahead of the source. Do not use the
guard to timestamp external facts or replace wall-clock chronology.

## Evidence and review checklist

The [time proof](../proofs/io_time.zig) verifies Zig 0.16 duration conversion
and `{f}` formatting, clock-tagged deadline arithmetic, timeout conversion,
one-deadline sleeping, cancellation of a `std.Io.Threaded` sleep, and the pure
strict-guard transition. It ran on aarch64 macOS with Zig 0.16.0 on 2026-09-04.

- Is this calendar time, awake elapsed time, suspend-inclusive elapsed time, or CPU time?
- Was one absolute deadline captured for the entire operation?
- Are negative input, addition overflow, expiry, and timeout/cancellation races handled?
- Does every compared timestamp carry the same clock?
- Is `Clock.resolution` checked when the selected platform clock might be unavailable?
- Does a sleeping branch actually have the scheduling guarantee the race needs?
- Who joins/cancels every task and reconciles work that beat cancellation?

Related: [[std-io]], [[async-vs-concurrent]], [[cancellation]],
[[select-and-batch]], [[bounded-retries-and-cleanup]],
[[io-synchronization-primitives]],
[[deterministic-simulation-testing]], [[tigerstyle]].
