const std = @import("std");

const Io = std.Io;

const StrictClockGuard = struct {
    last: Io.Timestamp,

    /// Pure mechanics proof for an application-owned, single-owner guard.
    /// A shared guard would additionally require synchronization and an
    /// explicit overflow policy.
    fn observe(guard: *StrictClockGuard, raw: Io.Timestamp) Io.Timestamp {
        const next: Io.Timestamp = .fromNanoseconds(@max(
            raw.toNanoseconds(),
            guard.last.toNanoseconds() + 1,
        ));
        std.debug.assert(next.toNanoseconds() > guard.last.toNanoseconds());
        std.debug.assert(next.toNanoseconds() >= raw.toNanoseconds());
        guard.last = next;
        return next;
    }
};

test "Duration constructors, conversions, and formatting use explicit units" {
    const duration = Io.Duration.fromMilliseconds(1_500);
    try std.testing.expectEqual(@as(i96, 1_500_000_000), duration.toNanoseconds());
    try std.testing.expectEqual(@as(i64, 1_500_000), duration.toMicroseconds());
    try std.testing.expectEqual(@as(i64, 1_500), duration.toMilliseconds());
    try std.testing.expectEqual(@as(i64, 1), duration.toSeconds());

    var output: [16]u8 = undefined;
    var writer: Io.Writer = .fixed(&output);
    try writer.print("{f}", .{duration});
    try std.testing.expectEqualStrings("1.5s", writer.buffered());
}

test "clock-tagged arithmetic and Timeout conversions retain their clock" {
    const budget: Io.Clock.Duration = .{
        .raw = .fromMilliseconds(25),
        .clock = .awake,
    };
    const started: Io.Clock.Timestamp = .{
        .raw = .fromNanoseconds(1_000),
        .clock = .awake,
    };
    const deadline = started.addDuration(budget);

    try std.testing.expectEqual(Io.Clock.awake, deadline.clock);
    try std.testing.expectEqual(budget.raw, started.durationTo(deadline).raw);
    try std.testing.expect(deadline.compare(.gt, started));

    const relative: Io.Timeout = .{ .duration = budget };
    const relative_again = relative.toDurationFromNow(std.testing.io).?;
    try std.testing.expectEqual(budget, relative_again);
    switch (relative.toDeadline(std.testing.io)) {
        .deadline => |captured| try std.testing.expectEqual(Io.Clock.awake, captured.clock),
        else => unreachable,
    }

    const absolute: Io.Timeout = .{ .deadline = deadline };
    try std.testing.expectEqual(deadline, absolute.toTimestamp(std.testing.io).?);
    try std.testing.expectEqual(absolute, absolute.toDeadline(std.testing.io));
    const no_timeout: Io.Timeout = .none;
    try std.testing.expectEqual(
        @as(?Io.Clock.Timestamp, null),
        no_timeout.toTimestamp(std.testing.io),
    );
    try no_timeout.sleep(std.testing.io);
}

test "one monotonic deadline survives elapsed work" {
    const io = std.testing.io;
    const clock: Io.Clock = .awake;
    const resolution = try clock.resolution(io);
    try std.testing.expect(resolution.toNanoseconds() >= 0);

    const budget: Io.Clock.Duration = .{
        .raw = .fromMilliseconds(2),
        .clock = clock,
    };
    const deadline = Io.Clock.Timestamp.fromNow(io, budget);
    try deadline.wait(io);

    const finished = Io.Clock.Timestamp.now(io, clock);
    try std.testing.expect(finished.compare(.gte, deadline));
    try std.testing.expect(deadline.durationFromNow(io).raw.toNanoseconds() <= 0);
}

fn longSleep(io: Io) Io.Cancelable!void {
    const duration: Io.Clock.Duration = .{
        .raw = .fromSeconds(30),
        .clock = .awake,
    };
    try duration.sleep(io);
}

test "Threaded sleep is a cancellation point" {
    var threaded: Io.Threaded = .init(std.testing.allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    var future = try io.concurrent(longSleep, .{io});
    try std.testing.expectError(error.Canceled, future.cancel(io));
}

test "a strictly monotonic guard distinguishes repeated raw observations" {
    var guard: StrictClockGuard = .{ .last = .zero };

    const first = guard.observe(.zero);
    const second = guard.observe(.zero);
    const third = guard.observe(.fromNanoseconds(10));
    const fourth = guard.observe(.fromNanoseconds(9));

    try std.testing.expectEqual(@as(i96, 1), first.toNanoseconds());
    try std.testing.expectEqual(@as(i96, 2), second.toNanoseconds());
    try std.testing.expectEqual(@as(i96, 10), third.toNanoseconds());
    try std.testing.expectEqual(@as(i96, 11), fourth.toNanoseconds());
}
