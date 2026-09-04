const std = @import("std");
const builtin = @import("builtin");

const Io = std.Io;
const net = Io.net;

fn echoOne(server: *net.Server, io: Io) !void {
    var stream = try server.accept(io);
    defer stream.close(io);

    var read_buffer: [16]u8 = undefined;
    var reader = stream.reader(io, &read_buffer);
    var request: [4]u8 = undefined;
    try reader.interface.readSliceAll(&request);
    try std.testing.expectEqualSlices(u8, "ping", &request);

    var write_buffer: [16]u8 = undefined;
    var writer = stream.writer(io, &write_buffer);
    try writer.interface.writeAll("pong");
    try writer.interface.flush();
}

test "loopback stream ownership includes accept connect flush and close" {
    const io = std.testing.io;
    var listen_address: net.IpAddress = .{ .ip4 = .loopback(0) };
    var server = try listen_address.listen(io, .{});
    defer server.deinit(io);

    var server_future = io.concurrent(echoOne, .{ &server, io }) catch |err| switch (err) {
        error.ConcurrencyUnavailable => return error.SkipZigTest,
    };
    errdefer server_future.cancel(io) catch {};

    var stream = try server.socket.address.connect(io, .{ .mode = .stream });
    defer stream.close(io);

    var write_buffer: [16]u8 = undefined;
    var writer = stream.writer(io, &write_buffer);
    try writer.interface.writeAll("ping");
    try writer.interface.flush();

    var read_buffer: [16]u8 = undefined;
    var reader = stream.reader(io, &read_buffer);
    var response: [4]u8 = undefined;
    try reader.interface.readSliceAll(&response);
    try std.testing.expectEqualSlices(u8, "pong", &response);

    try server_future.await(io);
}

test "host names and IP literals are validated before network operations" {
    const host = try net.HostName.init("example.com");
    try std.testing.expectEqualStrings("example.com", host.bytes);
    try std.testing.expectError(error.InvalidHostName, net.HostName.init("-invalid.example"));

    const address = try net.IpAddress.parseLiteral("127.0.0.1:8080");
    try std.testing.expectEqual(@as(u16, 8080), address.getPort());
}

test "process.run owns bounded captured output" {
    const io = std.testing.io;
    const argv: []const []const u8 = if (builtin.os.tag == .windows)
        &.{ "cmd.exe", "/d", "/c", "echo out&1>&2 echo err&exit /b 7" }
    else
        &.{ "/bin/sh", "-c", "printf out; printf err >&2; exit 7" };
    const expected_stdout = if (builtin.os.tag == .windows) "out\r\n" else "out";
    const expected_stderr = if (builtin.os.tag == .windows) "err\r\n" else "err";
    const result = try std.process.run(std.testing.allocator, io, .{
        .argv = argv,
        .stdout_limit = .limited(expected_stdout.len),
        .stderr_limit = .limited(expected_stderr.len),
        .timeout = .{ .deadline = Io.Clock.Timestamp.fromNow(io, .{
            .raw = .fromSeconds(5),
            .clock = .awake,
        }) },
    });
    defer std.testing.allocator.free(result.stdout);
    defer std.testing.allocator.free(result.stderr);

    try std.testing.expectEqualSlices(u8, expected_stdout, result.stdout);
    try std.testing.expectEqualSlices(u8, expected_stderr, result.stderr);
    try std.testing.expectEqual(std.process.Child.Term{ .exited = 7 }, result.term);
}

test "process.run rejects output above its inclusive limit" {
    const io = std.testing.io;
    const argv: []const []const u8 = if (builtin.os.tag == .windows)
        &.{ "cmd.exe", "/d", "/c", "echo abc" }
    else
        &.{ "/bin/sh", "-c", "printf abc" };
    const output_len = if (builtin.os.tag == .windows) "abc\r\n".len else "abc".len;
    try std.testing.expectError(
        error.StreamTooLong,
        std.process.run(std.testing.allocator, io, .{
            .argv = argv,
            .stdout_limit = .limited(output_len - 1),
            .stderr_limit = .nothing,
        }),
    );
}

test "secure entropy is an explicit fallible operation" {
    const io = std.testing.io;
    var fresh_entropy: [32]u8 = undefined;
    try io.randomSecure(&fresh_entropy);

    var process_random: [32]u8 = undefined;
    io.random(&process_random);
}
