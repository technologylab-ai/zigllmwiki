const std = @import("std");
const builtin = @import("builtin");

const Watchdog = struct {
    write_fd: std.c.fd_t,
    done: std.atomic.Value(bool) = .init(false),

    fn run(watchdog: *Watchdog) void {
        const interval: std.c.timespec = .{ .sec = 0, .nsec = 10_000_000 };
        for (0..100) |_| {
            if (watchdog.done.load(.acquire)) return;
            _ = std.c.nanosleep(&interval, null);
        }

        const byte = [_]u8{0};
        _ = std.c.write(watchdog.write_fd, &byte, byte.len);
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

fn runMacosProof() !void {
    var threaded: std.Io.Threaded = .init(std.testing.allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    var pipe_fds: [2]std.c.fd_t = undefined;
    try std.testing.expectEqual(@as(c_int, 0), std.c.pipe(&pipe_fds));

    const read_file: std.Io.File = .{
        .handle = pipe_fds[0],
        .flags = .{ .nonblocking = false },
    };
    const write_file: std.Io.File = .{
        .handle = pipe_fds[1],
        .flags = .{ .nonblocking = false },
    };
    defer read_file.close(io);
    defer write_file.close(io);

    var watchdog: Watchdog = .{ .write_fd = pipe_fds[1] };
    const watchdog_thread = try std.Thread.spawn(.{}, Watchdog.run, .{&watchdog});
    defer watchdog_thread.join();
    defer watchdog.done.store(true, .release);

    var entered: std.Io.Event = .unset;
    var future = try io.concurrent(readOneByte, .{ read_file, io, &entered });
    try entered.wait(io);
    try io.sleep(.fromMilliseconds(20), .awake);

    try std.testing.expectError(error.Canceled, future.cancel(io));
}

test "Threaded cancellation interrupts a blocked pipe read on macOS" {
    if (builtin.os.tag == .macos) {
        try runMacosProof();
    } else {
        return error.SkipZigTest;
    }
}
