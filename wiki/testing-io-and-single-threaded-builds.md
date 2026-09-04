---
id: testing-io-and-single-threaded-builds
title: Testing Io and single-threaded builds
kind: pattern
status: runtime-verified
zig: "0.16.0"
summary: Choose std.testing.io for host-backed integration tests, std.Io.failing for a fixed hostile capability profile, and explicit single-threaded builds to prove code handles unavailable concurrency.
updated: 2026-09-04
sources:
  - "[[zig-0.16.0-language-reference]]"
  - "[[zig-0.16.0-release-notes]]"
  - "[[zig-0.16.0-stdlib]]"
  - "[[zig-0.16.0-test-runner]]"
proofs:
  - proofs/testing_io_modes.zig
platforms:
  - macos
---

# Testing `Io` and single-threaded builds

## Remember

These are three different tools, not interchangeable names for a test runtime:

| Tool | What it actually gives the test |
| --- | --- |
| `std.testing.io` | A real `std.Io.Threaded` initialized by Zig's test runner for the current test. |
| `std.Io.failing` | One static `Io` with a fixed hostile/no-capability response for each operation. |
| `-fsingle-threaded` | A whole-compilation promise that only one thread exists; it changes language and standard-library behavior. |

None of them is a deterministic event scheduler, virtual clock, programmable
fault injector, or in-memory filesystem. Use [[deterministic-simulation-testing]]
for the requirements of such a backend.

## `std.testing.io` uses the host

In Zig 0.16.0, `std.testing.io` is an `std.Io` whose implementation value is
the mutable `std.testing.io_instance`. The default test runner initializes that
instance as `std.Io.Threaded` before each test, passing `std.testing.allocator`
and the runner's arguments and environment, then deinitializes it after the
test. Tests in the same test executable therefore receive a fresh threaded
instance per test, not one process-lifetime instance with deliberately retained
scheduler state.

Consequences:

- filesystem, process, network, entropy, and clock calls observe the host;
- sleeps consume real elapsed time;
- task dispatch follows `Io.Threaded` limits and allocation behavior;
- scheduling and completion order are not deterministic;
- the backing allocator is leak-checking, but that does not make host I/O
  simulated or failure-injected.

Use it for focused integration tests against the actual platform backend. Pass
the `Io` through the same component boundary used in production rather than
having library code import `std.testing.io` itself; see
[[process-init-and-capabilities]].

## What `-fsingle-threaded` changes

The Zig 0.16 language contract says `-fsingle-threaded` makes
`builtin.single_threaded` true, treats thread-local variables as ordinary
container-level variables, and permits single-threaded optimizations in
userland APIs. `std.Thread.spawn` becomes a compile error. In a build script,
the corresponding module option is `single_threaded = true`.

For `std.Io.Threaded`, the consequence is precise:

- `async` executes the function inline before returning;
- `concurrent` returns `error.ConcurrencyUnavailable` without running it;
- grouped `async` work is likewise eager and grouped `concurrent` work is
  unavailable;
- cancellation has no worker to interrupt;
- ordinary synchronous I/O operations still use the `Io.Threaded` operation
  implementations. The flag does not turn them into an event loop.

The same dispatch behavior is available in a normally compiled program through
`std.Io.Threaded.init_single_threaded`. Its global instance exists for narrow
cases such as debugging, but its own source warns that applications should
choose the implementation and libraries should accept an `Io` parameter.
Hardcoding `global_single_threaded` in library code discards the backend seam.

Treat `error.ConcurrencyUnavailable` as a capability result. If correctness
requires caller/task overlap, propagate or handle it; switching the call to
`async` changes the guarantee and may block the caller inline.

## What `std.Io.failing` guarantees

`std.Io.failing` is useful for proving that a path does not need ambient
capabilities, and for exercising representative hard failures without touching
the host. Its exact Zig 0.16.0 profile includes:

- `async` runs eagerly, while `concurrent` returns
  `error.ConcurrencyUnavailable`;
- ordinary random bytes are all zero, while secure randomness returns
  `error.EntropyUnavailable`;
- directory creation returns `error.NoSpaceLeft`, and opening absent paths
  returns `error.FileNotFound`;
- network operations report `error.NetworkDown` or a related fixed unsupported
  result;
- process spawn/replace operations report `error.OperationUnsupported`;
- `std.Io.Reader.failing` and `std.Io.Writer.failing` are separate stream
  adapters that report `error.ReadFailed` and `error.WriteFailed`.

Do not generalize this profile into “all operations fail.” Several operations
deliberately succeed or return inert values. Most importantly, the installed
0.16.0 implementation returns the zero timestamp from `now`, makes `sleep` a
no-op that succeeds, and reports `error.ClockUnavailable` from clock
`resolution`. This implementation behavior contradicts the broader prose above
`Io.failing`, which says clock calls return `error.UnsupportedClock`; the exact
vtable functions and the executable proof are the guidance for 0.16.0.

Also do not use `Io.failing` as a programmable fault campaign. It cannot choose
“fail the third write,” advance virtual time, reorder completions, or model a
crash after persistence step N. Build a purpose-specific implementation when a
test needs those controls.

## Fixed stream adapters are not `Io` backends

`std.Io.Reader.fixed` reads a provided byte slice and ends.
`std.Io.Writer.fixed` writes into caller-provided capacity and returns
`error.WriteFailed` when full. They are useful, deterministic, allocation-free
stream adapters. `Reader.failing` and `Writer.failing` fail when asked to
produce or drain bytes. These types test parsers, encoders, and bounded-buffer
handling; they do not replace the filesystem/network/process operations of an
`std.Io` implementation.

## Bound the test runner too

Zig 0.16 adds `zig build --test-timeout <duration>`. The duration applies to
each individual Zig test block. When one exceeds the real-time limit, the build
runner kills and restarts the test process, records that test as timed out, and
continues with the next test. Accepted units include `ns`, `us`, `ms`, `s`,
`m`, and `h`.

This is containment for hangs and unexpectedly slow tests, not virtual time and
not a semantic operation deadline. Because it measures real time, a heavily
loaded scheduler can cause false timeouts. Keep an explicit, generous runner
timeout around tests while testing operation-level deadlines with the chosen
`Io` clock model.

## Evidence

The [testing-I/O proof](../proofs/testing_io_modes.zig) checks four behaviors:
the current test backend's `async`/`concurrent` contract in both normal and
`-fsingle-threaded` compilations; the statically initialized single-threaded
backend; representative `Io.failing` filesystem, entropy, clock, and dispatch
results; and fixed/failing reader and writer boundaries. Both compilation modes
ran with Zig 0.16.0 on aarch64 macOS on 2026-09-04.

The runtime proof does not claim deterministic task ordering and does not test
the build runner by intentionally timing out. Test-timeout behavior is
source-verified from the official release notes and installed build-runner
source.

Related: [[std-io]], [[io-threaded]], [[async-vs-concurrent]],
[[process-init-and-capabilities]], [[deterministic-simulation-testing]],
[[io-time-clocks-and-deadlines]].
