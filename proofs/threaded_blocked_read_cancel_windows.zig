const std = @import("std");
const builtin = @import("builtin");

const Watchdog = struct {
    write_file: std.Io.File,
    io: std.Io,
    done: std.atomic.Value(bool) = .init(false),

    fn run(watchdog: *Watchdog) void {
        for (0..100) |_| {
            if (watchdog.done.load(.acquire)) return;
            watchdog.io.sleep(.fromMilliseconds(10), .awake) catch return;
        }

        watchdog.write_file.writeStreamingAll(watchdog.io, &.{0}) catch {};
    }
};

fn readOneByte(
    file: std.Io.File,
    io: std.Io,
    entered: *std.Io.Event,
) std.Io.File.ReadStreamingError!usize {
    var byte: [1]u8 = undefined;
    entered.set(io);
    return file.readStreaming(io, &.{&byte});
}

fn runWindowsProof() !void {
    var threaded: std.Io.Threaded = .init(std.testing.allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const pipe_handles = try threaded.windowsCreatePipe(.{
        .server = .{ .mode = .{ .IO = .SYNCHRONOUS_NONALERT } },
        .client = .{ .mode = .{ .IO = .SYNCHRONOUS_NONALERT } },
        .inbound = true,
    });
    const read_file: std.Io.File = .{
        .handle = pipe_handles[0],
        .flags = .{ .nonblocking = false },
    };
    const write_file: std.Io.File = .{
        .handle = pipe_handles[1],
        .flags = .{ .nonblocking = false },
    };
    defer read_file.close(io);
    defer write_file.close(io);

    var watchdog: Watchdog = .{ .write_file = write_file, .io = io };
    const watchdog_thread = try std.Thread.spawn(.{}, Watchdog.run, .{&watchdog});
    defer watchdog_thread.join();
    defer watchdog.done.store(true, .release);

    var entered: std.Io.Event = .unset;
    var future = try io.concurrent(readOneByte, .{ read_file, io, &entered });
    try entered.wait(io);
    try io.sleep(.fromMilliseconds(20), .awake);

    try std.testing.expectError(error.Canceled, future.cancel(io));
}

test "Threaded cancellation interrupts a blocked synchronous pipe read on Windows" {
    if (builtin.os.tag == .windows) {
        try runWindowsProof();
    } else {
        return error.SkipZigTest;
    }
}
