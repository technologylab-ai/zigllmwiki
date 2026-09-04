const std = @import("std");
const builtin = @import("builtin");

fn increment(value: *u32) u32 {
    value.* += 1;
    return value.*;
}

test "testing Io follows the compilation's single-threaded concurrency contract" {
    const io = std.testing.io;

    var async_value: u32 = 0;
    var async_future = io.async(increment, .{&async_value});
    if (builtin.single_threaded) {
        try std.testing.expectEqual(1, async_value);
    }
    try std.testing.expectEqual(1, async_future.await(io));
    try std.testing.expectEqual(1, async_value);

    var concurrent_value: u32 = 0;
    var concurrent_future = io.concurrent(increment, .{&concurrent_value}) catch |err| {
        try std.testing.expect(builtin.single_threaded);
        try std.testing.expectEqual(error.ConcurrencyUnavailable, err);
        try std.testing.expectEqual(0, concurrent_value);
        return;
    };
    try std.testing.expect(!builtin.single_threaded);
    try std.testing.expectEqual(1, concurrent_future.await(io));
    try std.testing.expectEqual(1, concurrent_value);
}

test "statically single-threaded Threaded Io runs async eagerly and rejects concurrent" {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();

    var value: u32 = 0;
    var future = io.async(increment, .{&value});
    try std.testing.expectEqual(1, value);
    try std.testing.expectEqual(1, future.await(io));

    try std.testing.expectError(
        error.ConcurrencyUnavailable,
        io.concurrent(increment, .{&value}),
    );
    try std.testing.expectEqual(1, value);
}

test "failing Io is a fixed hostile capability profile, not a scheduler" {
    const io: std.Io = .failing;

    var value: u32 = 0;
    var future = io.async(increment, .{&value});
    try std.testing.expectEqual(1, value);
    try std.testing.expectEqual(1, future.await(io));
    try std.testing.expectError(
        error.ConcurrencyUnavailable,
        io.concurrent(increment, .{&value}),
    );

    var random_bytes: [8]u8 = undefined;
    io.random(&random_bytes);
    try std.testing.expectEqualSlices(u8, &@as([8]u8, @splat(0)), &random_bytes);
    try std.testing.expectError(error.EntropyUnavailable, io.randomSecure(&random_bytes));

    try std.testing.expectEqual(std.Io.Timestamp.zero, std.Io.Timestamp.now(io, .awake));
    try std.testing.expectError(error.ClockUnavailable, std.Io.Clock.awake.resolution(io));
    try io.sleep(.fromNanoseconds(1), .awake);

    try std.testing.expectError(
        error.NoSpaceLeft,
        std.Io.Dir.cwd().createFile(io, "cannot-exist", .{}),
    );
    try std.testing.expectError(
        error.FileNotFound,
        std.Io.Dir.cwd().openFile(io, "cannot-exist", .{}),
    );
}

test "fixed and failing stream adapters expose bounded in-memory behavior" {
    var fixed_storage: [3]u8 = undefined;
    var fixed_writer: std.Io.Writer = .fixed(&fixed_storage);
    try fixed_writer.writeAll("abc");
    try std.testing.expectEqualSlices(u8, "abc", fixed_writer.buffered());
    try std.testing.expectError(error.WriteFailed, fixed_writer.writeAll("d"));

    var failing_writer: std.Io.Writer = .failing;
    try std.testing.expectError(error.WriteFailed, failing_writer.writeAll("x"));

    var fixed_reader: std.Io.Reader = .fixed("abc");
    var read_buffer: [3]u8 = undefined;
    try fixed_reader.readSliceAll(&read_buffer);
    try std.testing.expectEqualSlices(u8, "abc", &read_buffer);
    try std.testing.expectError(error.EndOfStream, fixed_reader.readSliceAll(&read_buffer));

    var failing_reader: std.Io.Reader = .failing;
    try std.testing.expectError(error.ReadFailed, failing_reader.readSliceAll(read_buffer[0..1]));
}
