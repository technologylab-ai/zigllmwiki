const std = @import("std");

// Compile-only failure witness, registered by the exact-release verifier for
// aarch64-macos. Do not run this fixture or turn it into a skipped runtime test.
// The shipped constructor assigns removed processReplacePath/processSpawnPath
// fields and omits inheritParentDir/inheritParentFile. The expected first error
// is the missing processReplacePath member of Io.VTable.
export fn instantiateDispatchIo(dispatch: *std.Io.Dispatch) void {
    _ = dispatch.io();
}

export fn instantiateDispatchInit(dispatch: *std.Io.Dispatch) void {
    dispatch.init(std.heap.page_allocator, .{}) catch {};
}
