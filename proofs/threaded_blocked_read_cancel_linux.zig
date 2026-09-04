const std = @import("std");
const builtin = @import("builtin");

const linux = std.os.linux;

const Watchdog = struct {
    write_fd: linux.fd_t,
    done: std.atomic.Value(bool) = .init(false),

    fn run(watchdog: *Watchdog) void {
        const interval: linux.timespec = .{ .sec = 0, .nsec = 10_000_000 };
        for (0..100) |_| {
            if (watchdog.done.load(.acquire)) return;
            _ = linux.nanosleep(&interval, null);
        }

        const byte = [_]u8{0};
        _ = linux.write(watchdog.write_fd, &byte, byte.len);
    }
};

fn pipe() ![2]linux.fd_t {
    var fds: [2]linux.fd_t = undefined;
    return switch (linux.errno(linux.pipe2(&fds, .{ .CLOEXEC = true }))) {
        .SUCCESS => fds,
        else => |err| std.posix.unexpectedErrno(err),
    };
}

fn readOneByte(
    file: std.Io.File,
    io: std.Io,
    entered: *std.Io.Event,
) std.Io.File.ReadStreamingError!usize {
    var byte: [1]u8 = undefined;
    entered.set(io);
    return file.readStreaming(io, &.{&byte});
}

fn runLinuxProof() !void {
    var threaded: std.Io.Threaded = .init(std.testing.allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const pipe_fds = try pipe();
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

test "Threaded cancellation interrupts a blocked pipe read on Linux" {
    if (builtin.os.tag == .linux) {
        try runLinuxProof();
    } else {
        return error.SkipZigTest;
    }
}
