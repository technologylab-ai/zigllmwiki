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
