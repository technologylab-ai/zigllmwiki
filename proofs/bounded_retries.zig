const std = @import("std");

const Io = std.Io;

const ActionError = error{
    Busy,
    ConnectionReset,
    InvalidRequest,
};

const RetryError = ActionError || error{
    InvalidAttemptLimit,
    Timeout,
};

const Step = union(enum) {
    success: u32,
    failure: ActionError,
};

const Script = struct {
    steps: []const Step,
    step_index: usize = 0,
    pause_count: u8 = 0,

    fn run(script: *Script) ActionError!u32 {
        std.debug.assert(script.step_index < script.steps.len);
        const step = script.steps[script.step_index];
        script.step_index += 1;
        return switch (step) {
            .success => |value| value,
            .failure => |err| err,
        };
    }

    fn pause(script: *Script, io: Io, deadline: Io.Clock.Timestamp) error{Timeout}!void {
        const now = Io.Clock.Timestamp.now(io, deadline.clock);
        if (!now.compare(.lt, deadline)) return error.Timeout;
        script.pause_count += 1;
    }
};

fn isTransient(err: ActionError) bool {
    return switch (err) {
        error.Busy, error.ConnectionReset => true,
        error.InvalidRequest => false,
    };
}

fn runWithRetries(
    script: *Script,
    io: Io,
    attempt_limit: u8,
    deadline: Io.Clock.Timestamp,
) RetryError!u32 {
    const attempt_limit_max = 8;
    if (attempt_limit == 0 or attempt_limit > attempt_limit_max) {
        return error.InvalidAttemptLimit;
    }
    if (script.steps.len < attempt_limit) return error.InvalidAttemptLimit;

    for (0..attempt_limit) |attempt_index| {
        return script.run() catch |err| {
            if (!isTransient(err)) return err;
            const attempts_remaining = attempt_limit - attempt_index - 1;
            if (attempts_remaining == 0) return err;
            try script.pause(io, deadline);
            continue;
        };
    }
    unreachable;
}

fn futureDeadline(io: Io) Io.Clock.Timestamp {
    return .fromNow(io, .{
        .raw = .fromSeconds(5),
        .clock = .awake,
    });
}

test "transient failures retry without a useless final pause" {
    const io = std.testing.io;
    const steps = [_]Step{
        .{ .failure = error.Busy },
        .{ .failure = error.ConnectionReset },
        .{ .success = 42 },
    };
    var script: Script = .{ .steps = &steps };

    try std.testing.expectEqual(
        42,
        try runWithRetries(&script, io, 3, futureDeadline(io)),
    );
    try std.testing.expectEqual(3, script.step_index);
    try std.testing.expectEqual(2, script.pause_count);
}

test "attempt exhaustion preserves the last transient error" {
    const io = std.testing.io;
    const steps = [_]Step{
        .{ .failure = error.Busy },
        .{ .failure = error.ConnectionReset },
    };
    var script: Script = .{ .steps = &steps };

    try std.testing.expectError(
        error.ConnectionReset,
        runWithRetries(&script, io, 2, futureDeadline(io)),
    );
    try std.testing.expectEqual(2, script.step_index);
    try std.testing.expectEqual(1, script.pause_count);
}

test "fatal errors and expired deadlines stop immediately" {
    const io = std.testing.io;
    const fatal_steps = [_]Step{.{ .failure = error.InvalidRequest }};
    var fatal_script: Script = .{ .steps = &fatal_steps };
    try std.testing.expectError(
        error.InvalidRequest,
        runWithRetries(&fatal_script, io, 1, futureDeadline(io)),
    );
    try std.testing.expectEqual(0, fatal_script.pause_count);

    const retry_steps = [_]Step{
        .{ .failure = error.Busy },
        .{ .success = 1 },
    };
    var expired_script: Script = .{ .steps = &retry_steps };
    const expired: Io.Clock.Timestamp = .{
        .raw = .zero,
        .clock = .awake,
    };
    try std.testing.expectError(
        error.Timeout,
        runWithRetries(&expired_script, io, 2, expired),
    );
    try std.testing.expectEqual(1, expired_script.step_index);
    try std.testing.expectEqual(0, expired_script.pause_count);
}

test "attempt bounds reject zero and configured excess" {
    const io = std.testing.io;
    const steps = [_]Step{.{ .success = 1 }};
    var script: Script = .{ .steps = &steps };

    try std.testing.expectError(
        error.InvalidAttemptLimit,
        runWithRetries(&script, io, 0, futureDeadline(io)),
    );
    try std.testing.expectError(
        error.InvalidAttemptLimit,
        runWithRetries(&script, io, 9, futureDeadline(io)),
    );
    try std.testing.expectEqual(0, script.step_index);
}
