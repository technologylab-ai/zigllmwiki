const std = @import("std");

test "buffered writes need flush and overwrites need end to truncate" {
    const io = std.testing.io;
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();

    var file = try temporary.dir.createFile(io, "buffered", .{ .read = true });
    defer file.close(io);

    var buffer: [64]u8 = undefined;
    var writer = file.writer(io, &buffer);
    try writer.interface.writeAll("short");

    try std.testing.expectEqual(0, try file.length(io));
    try writer.flush();
    try std.testing.expectEqual(5, try file.length(io));

    try writer.seekTo(0);
    try writer.interface.writeAll("new");
    try writer.flush();
    try std.testing.expectEqual(5, try file.length(io));

    try writer.end();
    try std.testing.expectEqual(3, try file.length(io));

    var read_buffer: [8]u8 = undefined;
    const contents = try temporary.dir.readFile(io, "buffered", &read_buffer);
    try std.testing.expectEqualSlices(u8, "new", contents);
}

test "atomic replacement publishes the completed temporary file" {
    const io = std.testing.io;
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();

    try temporary.dir.writeFile(io, .{ .sub_path = "state", .data = "old" });

    var atomic_file = try temporary.dir.createFileAtomic(io, "state", .{ .replace = true });
    defer atomic_file.deinit(io);

    var buffer: [64]u8 = undefined;
    var writer = atomic_file.file.writer(io, &buffer);
    try writer.interface.writeAll("replacement");
    try writer.flush();
    try atomic_file.file.sync(io);
    try atomic_file.replace(io);

    var read_buffer: [16]u8 = undefined;
    const contents = try temporary.dir.readFile(io, "state", &read_buffer);
    try std.testing.expectEqualSlices(u8, "replacement", contents);
}

test "allocated file reads reject data that reaches the configured limit" {
    const io = std.testing.io;
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();

    try temporary.dir.writeFile(io, .{ .sub_path = "bounded", .data = "abc" });

    try std.testing.expectError(
        error.StreamTooLong,
        temporary.dir.readFileAlloc(
            io,
            "bounded",
            std.testing.allocator,
            .limited(3),
        ),
    );

    const contents = try temporary.dir.readFileAlloc(
        io,
        "bounded",
        std.testing.allocator,
        .limited(4),
    );
    defer std.testing.allocator.free(contents);
    try std.testing.expectEqualSlices(u8, "abc", contents);
}
