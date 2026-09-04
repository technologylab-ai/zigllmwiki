---
id: source-zig-0-16-test-runner
title: Zig 0.16.0 compiler test runner
kind: source
status: captured
summary: Exact per-test initialization and teardown of std.testing.io in Zig 0.16.0's default test runner.
captured: 2026-09-04
revision: "zig tag 0.16.0; 44d9672fed001115e674fd5ddb32747ef43a7af4"
url: https://github.com/ziglang/zig/blob/44d9672fed001115e674fd5ddb32747ef43a7af4/lib/compiler/test_runner.zig
---

# Zig 0.16.0 compiler test runner

Pinned to the immutable Zig 0.16.0 revision. The default runner initializes
`std.testing.io_instance` as `std.Io.Threaded` before each individual test,
passes the testing allocator plus runner arguments and environment, and
deinitializes the instance after the test.

Use the official 0.16.0 release notes and installed build-runner sources for
the separate `zig build --test-timeout` process-control behavior.

Relevant page: [[testing-io-and-single-threaded-builds]].
