const std = @import("std");

// Compile-only failure witness for aarch64-macos. Declaration presence does
// not establish that this experimental backend's interface constructor works.
export fn instantiateKqueueIo(kqueue: *std.Io.Kqueue) void {
    _ = kqueue.io();
}
