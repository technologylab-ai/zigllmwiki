---
id: child-process-lifecycles
title: Child processes, output limits, and terminal ownership
kind: pattern
status: runtime-verified
zig: "0.16.0"
summary: Choose run for bounded collected output or spawn for explicit pipe ownership, use one absolute deadline, and terminate every child through wait or kill.
updated: 2026-09-04
sources:
  - "[[zig-0.16.0-stdlib]]"
  - "[[zig-0.16.0-release-notes]]"
  - "[[fi-zig-0.16-migration]]"
proofs:
  - proofs/network_process_entropy.zig
platforms:
  - macos
---

# Child processes, output limits, and terminal ownership

## Remember

`std.process.run` is the bounded convenience path: it spawns a child, drains
stdout and stderr concurrently, waits for termination, and returns owned byte
slices plus a tagged termination result. `std.process.spawn` is the lower-level
path: the caller owns the child, optional pipe files, concurrent drain/write
tasks, cancellation, and exactly one terminal `wait` or `kill` path.

Neither path is steady-state allocation-free. `run` grows captured output with
the supplied allocator. Set explicit output limits and reserve amount from the
protocol; do not accept the defaults of unlimited stdout and stderr in a
bounded service.

## `run`: bounded capture

`RunOptions` has separate `stdout_limit` and `stderr_limit`, both
`std.Io.Limit` and both unlimited by default. Unlike `Dir.readFileAlloc`, these
are inclusive maximums in the Zig 0.16 implementation: output equal to the
limit succeeds and output beyond it returns `error.StreamTooLong`.
`reserve_amount` is only initial allocation capacity; it is not a limit.

On success, the caller owns both `RunResult.stdout` and `stderr` and frees them
with the same allocator passed to `run`. Handle every `Child.Term` tag rather
than checking only an integer exit code: `exited`, `signal`, `stopped`, and
`unknown` represent different outcomes.

`run` repeatedly waits while jointly filling its two output readers. Pass one
absolute `.awake` or `.boot` deadline if the timeout is intended to cover the
whole child execution. Reusing a relative duration can grant another duration
to each fill iteration. On errors or timeout, `run`'s terminal guard kills and
reaps the child before returning.

## `spawn`: explicit lifecycle

`spawn(io, options)` treats `argv[0]` as a path when it contains `/`; otherwise
it resolves the executable using the parent process's `PATH`. Supplying a
replacement `environ_map` does not change that lookup rule: even its `PATH`
entry is not used to find `argv[0]`. Use `spawnPath(io, dir, options)` when the
executable must be resolved relative to an already-authorized directory; its
`argv[0]` is always a path.

Each standard stream can be inherited, ignored, passed as an existing file,
created as a pipe, or closed. A `.pipe` choice populates the matching optional
file field in `Child`. Those files and their buffers remain part of the child
owner's protocol. Drain stdout and stderr concurrently: sequentially waiting
for one pipe to reach EOF can deadlock while the child blocks writing a full
other pipe. Close or finish stdin when the child protocol expects EOF.

Install a terminal cleanup immediately after successful spawn. `Child.wait`
is cancelable, blocks until termination, returns `Term`, and cleans up child
resources. `Child.kill` requests forced termination, blocks until termination,
and cleans up; it is uncancelable, idempotent, and does nothing after `wait`
has completed. The standard `defer child.kill(io)` pattern therefore covers
early errors while a normal successful `wait` makes the defer harmless.

Uncancelable kill is a shutdown guarantee and a latency risk. Bound the number
of live children, stop admission first, and keep platform escalation behavior
in the process owner rather than scattering it across worker tasks.

## Common failures

- Using unlimited capture for output controlled by a child or external input.
- Treating `reserve_amount` as a hard cap.
- Passing a relative timeout when the intent is one end-to-end deadline.
- Forgetting to free either successful output slice.
- Matching only `.exited` and ignoring signal/stopped/unknown termination.
- Replacing the child environment and assuming its `PATH` selects `argv[0]`.
- Reading piped stdout and stderr sequentially.
- Returning from an error path without a terminal `wait` or `kill`.
- Assuming canceling a wait proves the child has terminated.

## Evidence

The [network/process/entropy proof](../proofs/network_process_entropy.zig)
runs `/bin/sh` with an absolute five-second deadline, independently bounded
stdout/stderr, owned-result cleanup, and a nonzero exit status. A second test
proves that three output bytes exceed a two-byte process-output limit while
three bytes at a three-byte limit succeed. It ran with Zig 0.16.0 on aarch64
macOS on 2026-09-04; shell paths and child semantics need separate Linux and
Windows runtime coverage.

Related: [[process-init-and-capabilities]], [[std-io]],
[[io-time-clocks-and-deadlines]], [[task-lifetimes-and-structured-concurrency]],
[[cancellation]], [[static-allocation-and-constant-work]], [[tigerstyle]].
