const std = @import("std");

const OwnedResult = union(enum) {
    left: []u8,
    right: []u8,
};

fn returnOwned(bytes: []u8) []u8 {
    return bytes;
}

fn freeOwned(result: OwnedResult) void {
    switch (result) {
        inline else => |bytes| std.testing.allocator.free(bytes),
    }
}

test "Select cancel is drained when results own memory" {
    const io = std.testing.io;
    const left = try std.testing.allocator.dupe(u8, "left");
    const right = try std.testing.allocator.dupe(u8, "right");

    var result_buffer: [2]OwnedResult = undefined;
    var select = std.Io.Select(OwnedResult).init(io, &result_buffer);
    select.async(.left, returnOwned, .{left});
    select.async(.right, returnOwned, .{right});

    freeOwned(try select.await());
    while (select.cancel()) |result| freeOwned(result);
}

test "Batch uses fixed operation storage and reports completion indexes" {
    const io = std.testing.io;
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();

    try temporary.dir.writeFile(io, .{ .sub_path = "left", .data = "L" });
    try temporary.dir.writeFile(io, .{ .sub_path = "right", .data = "R" });

    const left_file = try temporary.dir.openFile(io, "left", .{});
    defer left_file.close(io);
    const right_file = try temporary.dir.openFile(io, "right", .{});
    defer right_file.close(io);

    var left_buffer: [1]u8 = undefined;
    var right_buffer: [1]u8 = undefined;
    var left_vectors = [_][]u8{&left_buffer};
    var right_vectors = [_][]u8{&right_buffer};
    var operation_storage: [2]std.Io.Operation.Storage = undefined;
    var batch: std.Io.Batch = .init(&operation_storage);
    defer batch.cancel(io);

    batch.addAt(0, .{ .file_read_streaming = .{
        .file = left_file,
        .data = &left_vectors,
    } });
    batch.addAt(1, .{ .file_read_streaming = .{
        .file = right_file,
        .data = &right_vectors,
    } });

    var completion_count: usize = 0;
    while (completion_count < 2) {
        try batch.awaitAsync(io);
        while (batch.next()) |completion| {
            switch (completion.result) {
                .file_read_streaming => |result| {
                    try std.testing.expectEqual(1, try result);
                    completion_count += 1;
                },
                else => unreachable,
            }
        }
    }

    try std.testing.expectEqualSlices(u8, "L", &left_buffer);
    try std.testing.expectEqualSlices(u8, "R", &right_buffer);
}
