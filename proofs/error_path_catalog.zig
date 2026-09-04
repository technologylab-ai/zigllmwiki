const std = @import("std");

const PipelineFault = enum {
    none,
    acquire,
    decode,
    apply,
    flush,
};

const PipelineError = error{
    AcquireFailed,
    DecodeFailed,
    ApplyFailed,
    FlushFailed,
};

const PipelineState = struct {
    acquired: bool = false,
    released: bool = false,
    applied: bool = false,
    publications: u32 = 0,
};

fn expected_error(fault: PipelineFault) ?PipelineError {
    return switch (fault) {
        .none => null,
        .acquire => error.AcquireFailed,
        .decode => error.DecodeFailed,
        .apply => error.ApplyFailed,
        .flush => error.FlushFailed,
    };
}

fn run_pipeline(state: *PipelineState, fault: PipelineFault) PipelineError!void {
    std.debug.assert(!state.acquired);
    std.debug.assert(!state.released);
    std.debug.assert(state.publications == 0);

    if (fault == .acquire) return error.AcquireFailed;
    state.acquired = true;
    defer {
        std.debug.assert(state.acquired);
        state.acquired = false;
        state.released = true;
    }

    if (fault == .decode) return error.DecodeFailed;
    if (fault == .apply) return error.ApplyFailed;
    state.applied = true;
    if (fault == .flush) return error.FlushFailed;

    state.publications += 1;
    std.debug.assert(state.publications == 1);
}

pub export fn bounded_sum_u32(values: [*]const u32, count: u32) u64 {
    std.debug.assert(count <= 1024);
    const count_usize: usize = @intCast(count);
    var total: u64 = 0;
    for (values[0..count_usize]) |value| total += value;
    return total;
}

test "every catalogued non-fatal path has exact state and ownership evidence" {
    inline for (std.meta.tags(PipelineFault)) |fault| {
        var state: PipelineState = .{};
        const result = run_pipeline(&state, fault);

        if (expected_error(fault)) |fault_error| {
            try std.testing.expectError(fault_error, result);
            try std.testing.expectEqual(@as(u32, 0), state.publications);
        } else {
            try result;
            try std.testing.expectEqual(@as(u32, 1), state.publications);
        }

        try std.testing.expect(!state.acquired);
        try std.testing.expectEqual(fault != .acquire, state.released);
        try std.testing.expectEqual(fault == .none or fault == .flush, state.applied);
    }
}

test "generated-code subject preserves its bounded result contract" {
    const values = [_]u32{ 1, 2, 3, 5, 8 };
    try std.testing.expectEqual(@as(u64, 19), bounded_sum_u32(&values, values.len));
}
