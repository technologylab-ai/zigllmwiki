const std = @import("std");
const builtin = @import("builtin");

const linux = std.os.linux;
const IoUring = linux.IoUring;

fn initRing(entries: u16) !IoUring {
    return IoUring.init(entries, 0) catch |err| switch (err) {
        error.PermissionDenied, error.SystemOutdated => error.SkipZigTest,
        else => |e| return e,
    };
}

fn pipe() ![2]linux.fd_t {
    var fds: [2]linux.fd_t = undefined;
    return switch (linux.errno(linux.pipe2(&fds, .{ .CLOEXEC = true }))) {
        .SUCCESS => fds,
        else => |err| std.posix.unexpectedErrno(err),
    };
}

fn closeFd(fd: linux.fd_t) void {
    const result = linux.close(fd);
    std.debug.assert(linux.errno(result) == .SUCCESS);
}

fn writeAll(fd: linux.fd_t, bytes: []const u8) !void {
    var written: usize = 0;
    while (written < bytes.len) {
        const result = linux.write(fd, bytes[written..].ptr, bytes.len - written);
        switch (linux.errno(result)) {
            .SUCCESS => written += result,
            .INTR => continue,
            else => |err| return std.posix.unexpectedErrno(err),
        }
    }
}

test "io_uring exposes finite queues and runtime-probed operations" {
    if (builtin.os.tag != .linux) return error.SkipZigTest;

    var ring = try initRing(2);
    defer ring.deinit();

    const probe = try ring.get_probe();
    try std.testing.expect(probe.is_supported(.NOP));
    try std.testing.expect(probe.is_supported(.READ));
    try std.testing.expect(probe.is_supported(.READ_FIXED));
    try std.testing.expect(probe.is_supported(.ASYNC_CANCEL));
    try std.testing.expect(ring.features & linux.IORING_FEAT_SINGLE_MMAP != 0);

    _ = try ring.nop(1);
    _ = try ring.nop(2);
    try std.testing.expectError(error.SubmissionQueueFull, ring.nop(3));
    try std.testing.expectEqual(@as(u32, 2), try ring.submit());

    var completions: [2]linux.io_uring_cqe = undefined;
    var completed: usize = 0;
    while (completed < completions.len) {
        completed += try ring.copy_cqes(completions[completed..], 1);
    }
    try std.testing.expectEqual(@as(u32, 0), ring.cq_ready());
}

test "registered file and buffer stay owned through their terminal CQE" {
    if (builtin.os.tag != .linux) return error.SkipZigTest;

    var ring = try initRing(8);
    defer ring.deinit();

    const pipe_fds = try pipe();
    var read_fd_open = true;
    defer if (read_fd_open) closeFd(pipe_fds[0]);
    defer closeFd(pipe_fds[1]);

    try ring.register_files(&.{pipe_fds[0]});
    var files_registered = true;
    defer if (files_registered) ring.unregister_files() catch unreachable;

    var bytes: [16]u8 = undefined;
    var registered_buffer: std.posix.iovec = .{
        .base = &bytes,
        .len = bytes.len,
    };
    try ring.register_buffers(&.{registered_buffer});
    var buffers_registered = true;
    defer if (buffers_registered) ring.unregister_buffers() catch unreachable;

    // The fixed-file table owns a kernel reference independent of the original fd.
    closeFd(pipe_fds[0]);
    read_fd_open = false;

    const expected = "fixed-resource";
    try writeAll(pipe_fds[1], expected);
    const read_sqe = try ring.read_fixed(
        10,
        0,
        &registered_buffer,
        std.math.maxInt(u64),
        0,
    );
    read_sqe.flags |= linux.IOSQE_FIXED_FILE;
    try std.testing.expectEqual(@as(u32, 1), try ring.submit());

    const completion = try ring.copy_cqe();
    try std.testing.expectEqual(@as(u64, 10), completion.user_data);
    try std.testing.expectEqual(linux.E.SUCCESS, completion.err());
    try std.testing.expectEqual(expected.len, @as(usize, @intCast(completion.res)));
    try std.testing.expectEqualSlices(u8, expected, bytes[0..expected.len]);

    // Unregister only after the terminal completion has transferred ownership back.
    try ring.unregister_buffers();
    buffers_registered = false;
    try ring.unregister_files();
    files_registered = false;
}

test "cancel and target each complete before target resources are reusable" {
    if (builtin.os.tag != .linux) return error.SkipZigTest;

    var ring = try initRing(8);
    defer ring.deinit();

    const pipe_fds = try pipe();
    defer closeFd(pipe_fds[0]);
    defer closeFd(pipe_fds[1]);

    const target_id: u64 = 21;
    const cancel_id: u64 = 22;
    var target_buffer: [1]u8 = undefined;

    _ = try ring.read(
        target_id,
        pipe_fds[0],
        .{ .buffer = &target_buffer },
        std.math.maxInt(u64),
    );
    try std.testing.expectEqual(@as(u32, 1), try ring.submit());

    _ = try ring.cancel(cancel_id, target_id, 0);
    try std.testing.expectEqual(@as(u32, 1), try ring.submit());

    var saw_target = false;
    var saw_cancel = false;
    while (!saw_target or !saw_cancel) {
        const completion = try ring.copy_cqe();
        switch (completion.user_data) {
            target_id => {
                try std.testing.expect(!saw_target);
                saw_target = true;
                try std.testing.expectEqual(linux.E.CANCELED, completion.err());
            },
            cancel_id => {
                try std.testing.expect(!saw_cancel);
                saw_cancel = true;
                try std.testing.expectEqual(linux.E.SUCCESS, completion.err());
            },
            else => return error.UnexpectedCompletionIdentity,
        }
    }
}
