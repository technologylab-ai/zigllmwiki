const std = @import("std");

// Compile-only failure witness for x86_64-linux. This is the experimental
// std.Io backend, separate from the working low-level std.os.linux.IoUring API.
// The shipped constructor still assigns removed processReplacePath and
// processSpawnPath fields and omits inheritParentDir and inheritParentFile.
export fn instantiateUringIo(uring: *std.Io.Uring) void {
    _ = uring.io();
}
