const std = @import("std");

fn mark_ran(ran: *bool) void {
    ran.* = true;
}

test "Threaded async executes inline when async capacity is zero" {
    var threaded: std.Io.Threaded = .init(std.testing.allocator, .{
        .async_limit = .nothing,
    });
    defer threaded.deinit();
    const io = threaded.io();

    var ran = false;
    var future = io.async(mark_ran, .{&ran});

    try std.testing.expect(ran);
    future.await(io);
}

test "Threaded concurrent reports unavailable instead of executing inline" {
    var threaded: std.Io.Threaded = .init(std.testing.allocator, .{
        .concurrent_limit = .nothing,
    });
    defer threaded.deinit();
    const io = threaded.io();

    var ran = false;
    try std.testing.expectError(
        error.ConcurrencyUnavailable,
        io.concurrent(mark_ran, .{&ran}),
    );
    try std.testing.expect(!ran);
}
