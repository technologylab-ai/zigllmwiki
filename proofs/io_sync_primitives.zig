const std = @import("std");

fn waitForEvent(event: *std.Io.Event, entered: *std.Io.Event, io: std.Io) !void {
    entered.set(io);
    try event.wait(io);
}

test "Event wait is a cancellation point and reset follows joined waiters" {
    const io = std.testing.io;
    var event: std.Io.Event = .unset;
    var entered: std.Io.Event = .unset;
    var future = io.concurrent(waitForEvent, .{ &event, &entered, io }) catch |err| switch (err) {
        error.ConcurrencyUnavailable => return error.SkipZigTest,
    };

    try entered.wait(io);
    try std.testing.expectError(error.Canceled, future.cancel(io));

    event.set(io);
    try std.testing.expect(event.isSet());
    try event.wait(io);
    event.reset();
    try std.testing.expect(!event.isSet());
}

fn waitForMutex(mutex: *std.Io.Mutex, entered: *std.Io.Event, io: std.Io) !void {
    entered.set(io);
    try mutex.lock(io);
    defer mutex.unlock(io);
}

test "canceled Mutex acquisition leaves the mutex reusable" {
    const io = std.testing.io;
    var mutex: std.Io.Mutex = .init;
    var entered: std.Io.Event = .unset;

    mutex.lockUncancelable(io);
    var future = io.concurrent(waitForMutex, .{ &mutex, &entered, io }) catch |err| switch (err) {
        error.ConcurrencyUnavailable => {
            mutex.unlock(io);
            return error.SkipZigTest;
        },
    };
    try entered.wait(io);
    try std.testing.expectError(error.Canceled, future.cancel(io));
    mutex.unlock(io);

    try std.testing.expect(mutex.tryLock());
    mutex.unlock(io);
}

const ConditionState = struct {
    mutex: std.Io.Mutex = .init,
    condition: std.Io.Condition = .init,
    entered: std.Io.Event = .unset,
    ready: bool = false,
};

fn waitForCondition(state: *ConditionState, io: std.Io) !void {
    try state.mutex.lock(io);
    defer state.mutex.unlock(io);

    state.entered.set(io);
    while (!state.ready) try state.condition.wait(io, &state.mutex);
}

test "Condition wait releases and reacquires its mutex around a predicate loop" {
    const io = std.testing.io;
    var state: ConditionState = .{};
    var future = io.concurrent(waitForCondition, .{ &state, io }) catch |err| switch (err) {
        error.ConcurrencyUnavailable => return error.SkipZigTest,
    };

    try state.entered.wait(io);
    state.mutex.lockUncancelable(io);
    state.ready = true;
    state.condition.signal(io);
    state.mutex.unlock(io);
    try future.await(io);
}

test "Queue is bounded, drains after close, then reports Closed" {
    const io = std.testing.io;
    var storage: [2]u32 = undefined;
    var queue: std.Io.Queue(u32) = .init(&storage);

    try std.testing.expectEqual(2, queue.capacity());
    try std.testing.expectEqual(2, try queue.put(io, &.{ 10, 20, 30 }, 0));
    queue.close(io);
    try std.testing.expectError(error.Closed, queue.putOne(io, 40));

    var output: [3]u32 = undefined;
    const count = try queue.get(io, &output, 1);
    try std.testing.expectEqual(2, count);
    try std.testing.expectEqualSlices(u32, &.{ 10, 20 }, output[0..count]);
    try std.testing.expectError(error.Closed, queue.getOne(io));
}

test "RwLock shared access and Semaphore permits have explicit balance" {
    const io = std.testing.io;
    var rw_lock: std.Io.RwLock = .init;
    rw_lock.lockSharedUncancelable(io);
    try std.testing.expect(rw_lock.tryLockShared(io));
    try std.testing.expect(!rw_lock.tryLock(io));
    rw_lock.unlockShared(io);
    rw_lock.unlockShared(io);
    try std.testing.expect(rw_lock.tryLock(io));
    rw_lock.unlock(io);

    var semaphore: std.Io.Semaphore = .{ .permits = 2 };
    try semaphore.wait(io);
    try semaphore.wait(io);
    semaphore.post(io);
    semaphore.post(io);
    try semaphore.wait(io);
    try semaphore.wait(io);
}

const FutexState = struct {
    word: std.atomic.Value(u32) = .init(0),
    entered: std.Io.Event = .unset,
};

fn waitForWord(state: *FutexState, io: std.Io) !void {
    state.entered.set(io);
    while (state.word.load(.acquire) == 0) {
        try io.futexWait(u32, &state.word.raw, 0);
    }
}

test "futex wait is guarded by an atomic predicate loop" {
    const io = std.testing.io;
    var state: FutexState = .{};
    var future = io.concurrent(waitForWord, .{ &state, io }) catch |err| switch (err) {
        error.ConcurrencyUnavailable => return error.SkipZigTest,
    };

    try state.entered.wait(io);
    state.word.store(1, .release);
    io.futexWake(u32, &state.word.raw, 1);
    try future.await(io);
}

// These witnesses deliberately inspect the exact 0.16 Queue implementation's
// mutex and pending lists. They do not make those fields a portable API.
// Each fixture has one worker, one watchdog, and one or two element slots.
const QueueWatchdog = struct {
    io: std.Io,
    done: std.atomic.Value(bool) = .init(false),

    fn run(self: *QueueWatchdog) void {
        for (0..3000) |_| {
            if (self.done.load(.acquire)) return;
            self.io.sleep(.fromMilliseconds(10), .awake) catch std.process.exit(125);
        }
        // Terminate instead of unwinding storage still referenced by a waiter.
        // This is an outer process bound, not a kernel scheduling guarantee.
        std.process.exit(124);
    }
};

const QueueSide = enum { put, get };

fn waitForQueuePending(queue: *std.Io.Queue(u32), side: QueueSide, io: std.Io) !void {
    for (0..5000) |_| {
        queue.type_erased.mutex.lockUncancelable(io);
        const pending = switch (side) {
            .put => queue.type_erased.putters.first != null,
            .get => queue.type_erased.getters.first != null,
        };
        queue.type_erased.mutex.unlock(io);
        if (pending) return;
        try io.sleep(.fromMilliseconds(1), .awake);
    }
    return error.QueuePendingWitnessTimedOut;
}

fn queueZeroMinimum(
    queue: *std.Io.Queue(u32),
    side: QueueSide,
    entered: *std.Io.Event,
    io: std.Io,
) !usize {
    entered.set(io);
    var output: [1]u32 = undefined;
    return switch (side) {
        .put => queue.put(io, &.{77}, 0),
        .get => queue.get(io, &output, 0),
    };
}

test "Queue zero minimum still has a cancelable contended mutex acquisition" {
    const io = std.testing.io;
    var watchdog: QueueWatchdog = .{ .io = io };
    const watchdog_thread = try std.Thread.spawn(.{}, QueueWatchdog.run, .{&watchdog});
    defer watchdog_thread.join();
    defer watchdog.done.store(true, .release);

    for ([_]QueueSide{ .put, .get }) |side| {
        var storage: [2]u32 = undefined;
        var queue: std.Io.Queue(u32) = .init(&storage);
        // Both a get and a put could progress if they acquired the mutex.
        try queue.putOne(io, 11);
        var entered: std.Io.Event = .unset;
        queue.type_erased.mutex.lockUncancelable(io);
        defer queue.type_erased.mutex.unlock(io);
        var future = try io.concurrent(queueZeroMinimum, .{ &queue, side, &entered, io });
        defer _ = future.cancel(io) catch {};
        try entered.wait(io);
        try std.testing.expectError(error.Canceled, future.cancel(io));
        try std.testing.expectEqual(@sizeOf(u32), queue.type_erased.len);
    }
}

fn queuePartialTransfer(queue: *std.Io.Queue(u32), side: QueueSide, io: std.Io) !usize {
    var output: [2]u32 = .{ 0xdddddddd, 0xdddddddd };
    const count = switch (side) {
        .put => try queue.put(io, &.{ 31, 32 }, 2),
        .get => try queue.get(io, &output, 2),
    };
    try std.testing.expectEqual(1, count);
    // The condition wait re-armed cancellation after returning the prefix.
    // An uncontended operation can still succeed without checking Io.
    switch (side) {
        .put => try std.testing.expectEqual(31, try queue.getOne(io)),
        .get => {
            try std.testing.expectEqual(31, output[0]);
            try std.testing.expectEqual(0xdddddddd, output[1]);
            try queue.putOne(io, 99);
        },
    }
    try std.testing.expectError(error.Canceled, io.checkCancel());
    return count;
}

test "Queue partial cancellation returns a prefix before immediate progress and checkCancel" {
    const io = std.testing.io;
    var watchdog: QueueWatchdog = .{ .io = io };
    const watchdog_thread = try std.Thread.spawn(.{}, QueueWatchdog.run, .{&watchdog});
    defer watchdog_thread.join();
    defer watchdog.done.store(true, .release);

    for ([_]QueueSide{ .put, .get }) |side| {
        var storage: [1]u32 = undefined;
        var queue: std.Io.Queue(u32) = .init(&storage);
        if (side == .get) try queue.putOne(io, 31);
        var future = try io.concurrent(queuePartialTransfer, .{ &queue, side, io });
        defer _ = future.cancel(io) catch {};
        // With exactly one initial slot/item, observing the pending record
        // while holding its mutex proves that one element already transferred.
        try waitForQueuePending(&queue, side, io);
        try std.testing.expectEqual(1, try future.cancel(io));
        if (side == .get) try std.testing.expectEqual(99, try queue.getOne(io));
        var output: [1]u32 = undefined;
        try std.testing.expectEqual(0, try queue.get(io, &output, 0));
        queue.close(io);
    }
}

const QueueCloseState = struct {
    returned: std.Io.Event = .unset,
    release: std.Io.Event = .unset,
    finished: std.atomic.Value(bool) = .init(false),
};

fn queueUntilClose(
    queue: *std.Io.Queue(u32),
    side: QueueSide,
    state: *QueueCloseState,
    io: std.Io,
) !void {
    const result = switch (side) {
        .put => queue.putOne(io, 22),
        .get => blk: {
            _ = queue.getOne(io) catch |err| break :blk @as(anyerror!void, err);
            break :blk @as(anyerror!void, {});
        },
    };
    state.returned.set(io);
    state.release.waitUncancelable(io);
    state.finished.store(true, .release);
    return result;
}

test "Queue close releases witnessed blocked producers and consumers but does not join them" {
    const io = std.testing.io;
    var watchdog: QueueWatchdog = .{ .io = io };
    const watchdog_thread = try std.Thread.spawn(.{}, QueueWatchdog.run, .{&watchdog});
    defer watchdog_thread.join();
    defer watchdog.done.store(true, .release);

    for ([_]QueueSide{ .put, .get }) |side| {
        var storage: [1]u32 = undefined;
        var queue: std.Io.Queue(u32) = .init(&storage);
        if (side == .put) try queue.putOne(io, 11);
        var state: QueueCloseState = .{};
        var future = try io.concurrent(queueUntilClose, .{ &queue, side, &state, io });
        defer {
            queue.close(io);
            state.release.set(io);
            _ = future.cancel(io) catch {};
        }
        try waitForQueuePending(&queue, side, io);
        queue.close(io);
        queue.close(io);
        try state.returned.wait(io);
        try std.testing.expect(!state.finished.load(.acquire));
        if (side == .put) try std.testing.expectEqual(11, try queue.getOne(io));
        try std.testing.expectError(error.Closed, queue.getOne(io));
        state.release.set(io);
        try std.testing.expectError(error.Closed, future.await(io));
        try std.testing.expect(state.finished.load(.acquire));
        try std.testing.expect(queue.type_erased.putters.first == null);
        try std.testing.expect(queue.type_erased.getters.first == null);
    }
}
