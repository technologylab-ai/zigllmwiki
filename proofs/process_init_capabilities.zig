const std = @import("std");

const Runtime = struct {
    io: std.Io,
    temporary: std.mem.Allocator,
    permanent: std.mem.Allocator,
};

fn zeroDelay(runtime: Runtime) !void {
    try std.Io.sleep(runtime.io, .zero, .awake);
}

fn countArguments(args: std.process.Args, allocator: std.mem.Allocator) !usize {
    var iterator = try std.process.Args.Iterator.initAllocator(args, allocator);
    defer iterator.deinit();

    var count: usize = 0;
    while (iterator.next()) |_| count += 1;
    return count;
}

/// This executable entry point is built and run by `zig build verify`, proving
/// that Zig 0.16's runtime accepts and supplies the full process initializer.
pub fn main(init: std.process.Init) !void {
    const runtime: Runtime = .{
        .io = init.io,
        .temporary = init.gpa,
        .permanent = init.arena.allocator(),
    };

    _ = init.environ_map.get("ZIG_LLM_WIKI_UNUSED");
    std.debug.assert(try countArguments(init.minimal.args, init.gpa) >= 1);
    try zeroDelay(runtime);
}

test "a service accepts its caller's Io and allocators" {
    const runtime: Runtime = .{
        .io = std.testing.io,
        .temporary = std.testing.allocator,
        .permanent = std.testing.allocator,
    };
    try zeroDelay(runtime);
}

test "the full initializer exposes explicit process capabilities" {
    comptime {
        std.debug.assert(@hasField(std.process.Init, "minimal"));
        std.debug.assert(@hasField(std.process.Init, "arena"));
        std.debug.assert(@hasField(std.process.Init, "gpa"));
        std.debug.assert(@hasField(std.process.Init, "io"));
        std.debug.assert(@hasField(std.process.Init, "environ_map"));
        std.debug.assert(@hasField(std.process.Init, "preopens"));
    }
}
