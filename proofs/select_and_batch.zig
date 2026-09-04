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
    var seen_indexes: [2]bool = @splat(false);
    while (completion_count < 2) {
        try batch.awaitAsync(io);
        while (batch.next()) |completion| {
            try std.testing.expect(completion.index < seen_indexes.len);
            try std.testing.expect(!seen_indexes[completion.index]);
            seen_indexes[completion.index] = true;
            switch (completion.result) {
                .file_read_streaming => |result| {
                    try std.testing.expectEqual(1, try result);
                    completion_count += 1;
                },
                else => unreachable,
            }
        }
    }

    try std.testing.expect(seen_indexes[0] and seen_indexes[1]);
    try std.testing.expectEqualSlices(u8, "L", &left_buffer);
    try std.testing.expectEqualSlices(u8, "R", &right_buffer);
}

const SelectWatchdog = struct {
    io: std.Io,
    done: std.atomic.Value(bool) = .init(false),

    fn run(self: *SelectWatchdog) void {
        for (0..3000) |_| {
            if (self.done.load(.acquire)) return;
            self.io.sleep(.fromMilliseconds(10), .awake) catch std.process.exit(125);
        }
        // Never unwind a queue or output slice while a waiter still owns it.
        std.process.exit(124);
    }
};

fn waitForSelectQueue(
    select: *std.Io.Select(OwnedResult),
    phase: enum { buffered, pending },
    io: std.Io,
) !void {
    // This inspects exact-release implementation state under its own mutex;
    // it is a deterministic transition witness, not a new public queue API.
    for (0..5000) |_| {
        const queue = &select.queue.type_erased;
        queue.mutex.lockUncancelable(io);
        const ready = switch (phase) {
            .buffered => queue.len == @sizeOf(OwnedResult),
            .pending => queue.getters.first != null,
        };
        queue.mutex.unlock(io);
        if (ready) return;
        try io.sleep(.fromMilliseconds(1), .awake);
    }
    return error.SelectQueueWitnessTimedOut;
}

const PartialSelectState = struct {
    select: *std.Io.Select(OwnedResult),
    output: [2]OwnedResult,
};

fn receivePartialSelect(state: *PartialSelectState, io: std.Io) !usize {
    const count = try state.select.awaitMany(&state.output, 2);
    defer for (state.output[0..count]) |result| freeOwned(result);
    try std.testing.expectEqual(1, count);
    try std.testing.expectEqualSlices(u8, "owned prefix", state.output[0].left);
    // Queue.get returned a prefix and re-armed the observed cancellation.
    try std.testing.expectError(error.Canceled, io.checkCancel());
    return count;
}

test "Select awaitMany cancellation transfers only the returned owned prefix" {
    const io = std.testing.io;
    var watchdog: SelectWatchdog = .{ .io = io };
    const watchdog_thread = try std.Thread.spawn(.{}, SelectWatchdog.run, .{&watchdog});
    defer watchdog_thread.join();
    defer watchdog.done.store(true, .release);

    // Two result slots, one owned result, one consumer, and a watchdog. The
    // untouched slot references separately owned storage that is never drained.
    const sentinel = try std.testing.allocator.dupe(u8, "untouched");
    defer std.testing.allocator.free(sentinel);
    var result_buffer: [2]OwnedResult = undefined;
    var select: std.Io.Select(OwnedResult) = .init(io, &result_buffer);
    defer while (select.cancel()) |result| freeOwned(result);
    const left = try std.testing.allocator.dupe(u8, "owned prefix");
    select.async(.left, returnOwned, .{left});
    try waitForSelectQueue(&select, .buffered, io);

    var state: PartialSelectState = .{
        .select = &select,
        .output = .{ .{ .right = sentinel }, .{ .right = sentinel } },
    };
    var future = try io.concurrent(receivePartialSelect, .{ &state, io });
    defer _ = future.cancel(io) catch {};
    // The first result was queued before the get began, so a pending getter
    // proves it already copied that result and is waiting for its second item.
    try waitForSelectQueue(&select, .pending, io);
    try std.testing.expectEqual(1, try future.cancel(io));
    try std.testing.expectEqual(
        std.meta.Tag(OwnedResult).right,
        std.meta.activeTag(state.output[1]),
    );
    try std.testing.expect(state.output[1].right.ptr == sentinel.ptr);
    try std.testing.expectEqualSlices(u8, "untouched", state.output[1].right);
    try std.testing.expect(select.cancel() == null);
}
