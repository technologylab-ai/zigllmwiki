const std = @import("std");

fn observeCancellationProtocol(
    lock: *std.Io.RwLock,
    io: std.Io,
    finished: *bool,
) anyerror!void {
    defer finished.* = true;

    try std.testing.expectEqual(error.Canceled, lock.lockShared(io));

    io.recancel();
    const previous = io.swapCancelProtection(.blocked);
    try std.testing.expectEqual(std.Io.CancelProtection.unblocked, previous);
    try io.checkCancel();
    try std.testing.expectEqual(
        std.Io.CancelProtection.blocked,
        io.swapCancelProtection(previous),
    );

    try io.checkCancel();
}

test "Future.cancel joins, recancel re-arms, and protection defers observation" {
    var threaded: std.Io.Threaded = .init(std.testing.allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    var lock: std.Io.RwLock = .init;
    lock.lockUncancelable(io);
    defer lock.unlock(io);

    var finished = false;
    var future = try io.concurrent(
        observeCancellationProtocol,
        .{ &lock, io, &finished },
    );

    try std.testing.expectEqual(error.Canceled, future.cancel(io));
    try std.testing.expect(finished);
}

fn waitForGroupCancellation(
    lock: *std.Io.RwLock,
    io: std.Io,
    finished: *bool,
) std.Io.Cancelable!void {
    defer finished.* = true;
    try lock.lockShared(io);
    lock.unlockShared(io);
}

test "Group.cancel waits for members and releases the group" {
    var threaded: std.Io.Threaded = .init(std.testing.allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    var lock: std.Io.RwLock = .init;
    lock.lockUncancelable(io);
    defer lock.unlock(io);

    var finished = false;
    var group: std.Io.Group = .init;
    try group.concurrent(io, waitForGroupCancellation, .{ &lock, io, &finished });

    group.cancel(io);
    try std.testing.expect(finished);
    try group.await(io);
}
