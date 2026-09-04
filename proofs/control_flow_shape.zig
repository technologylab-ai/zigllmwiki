const std = @import("std");

const Event = union(enum) {
    batch: []const u16,
    close,
};

const Controller = struct {
    total: u32 = 0,
    item_count: u16 = 0,
    closed: bool = false,

    const ApplyError = error{
        Closed,
        BatchTooLarge,
        Overflow,
    };

    /// The parent owns branching and every mutation of Controller state.
    fn apply(controller: *Controller, event: Event) ApplyError!void {
        switch (event) {
            .batch => |items| {
                if (controller.closed) return error.Closed;
                if (items.len <= batch_max) {
                    const delta = try sumBatch(items);
                    const item_count = std.math.cast(u16, items.len) orelse
                        return error.BatchTooLarge;
                    const total_next = std.math.add(u32, controller.total, delta) catch
                        return error.Overflow;
                    const item_count_next = std.math.add(
                        u16,
                        controller.item_count,
                        item_count,
                    ) catch return error.Overflow;

                    controller.total = total_next;
                    controller.item_count = item_count_next;
                } else {
                    return error.BatchTooLarge;
                }
            },
            .close => {
                if (controller.closed) return error.Closed;
                controller.closed = true;
            },
        }
    }
};

const batch_max = 8;

/// The leaf performs repetitive mechanics and returns a value; it does not
/// mutate Controller or decide what the next system state should be.
fn sumBatch(items: []const u16) error{Overflow}!u32 {
    std.debug.assert(items.len <= batch_max);
    var total: u32 = 0;
    for (items) |item| {
        total = std.math.add(u32, total, item) catch return error.Overflow;
    }
    return total;
}

const Admission = enum {
    denied,
    overloaded,
    unavailable,
    admitted,
};

/// Nested positive cases make the complete decision tree visible.
fn classifyAdmission(authorized: bool, has_capacity: bool, service_ready: bool) Admission {
    if (authorized) {
        if (has_capacity) {
            if (service_ready) {
                return .admitted;
            } else {
                return .unavailable;
            }
        } else {
            return .overloaded;
        }
    } else {
        return .denied;
    }
}

const Node = struct {
    first_child: u8,
    child_count: u8,
    value: u16,
};

const WalkError = error{
    InvalidIndex,
    StackCapacityExceeded,
    WorkLimitExceeded,
    Overflow,
};

/// An explicit work stack replaces recursion and exposes both memory and work
/// limits. A cycle cannot overflow the call stack; it exhausts max_visits.
fn sumTree(nodes: []const Node, root: u8, max_visits: u8) WalkError!u32 {
    const stack_capacity = 8;
    var stack: [stack_capacity]u8 = undefined;
    var stack_count: u8 = 1;
    var visit_count: u8 = 0;
    var total: u32 = 0;
    stack[0] = root;

    while (stack_count > 0) {
        if (visit_count == max_visits) return error.WorkLimitExceeded;
        visit_count += 1;

        stack_count -= 1;
        const index = stack[stack_count];
        if (index >= nodes.len) return error.InvalidIndex;
        const node = nodes[index];
        total = std.math.add(u32, total, node.value) catch return error.Overflow;

        for (0..node.child_count) |child_offset| {
            if (stack_count == stack.len) return error.StackCapacityExceeded;
            const child_index = std.math.add(
                u8,
                node.first_child,
                @intCast(child_offset),
            ) catch return error.InvalidIndex;
            stack[stack_count] = child_index;
            stack_count += 1;
        }
    }
    return total;
}

test "the controller centralizes decisions and state mutation" {
    var controller: Controller = .{};
    try controller.apply(.{ .batch = &.{ 2, 3, 5 } });
    try std.testing.expectEqual(10, controller.total);
    try std.testing.expectEqual(3, controller.item_count);

    try controller.apply(.close);
    try std.testing.expect(controller.closed);
    try std.testing.expectError(error.Closed, controller.apply(.{ .batch = &.{1} }));
    try std.testing.expectEqual(10, controller.total);
}

test "the admission tree handles the positive and negative state space" {
    try std.testing.expectEqual(Admission.denied, classifyAdmission(false, false, false));
    try std.testing.expectEqual(Admission.denied, classifyAdmission(false, true, true));
    try std.testing.expectEqual(Admission.overloaded, classifyAdmission(true, false, false));
    try std.testing.expectEqual(Admission.overloaded, classifyAdmission(true, false, true));
    try std.testing.expectEqual(Admission.unavailable, classifyAdmission(true, true, false));
    try std.testing.expectEqual(Admission.admitted, classifyAdmission(true, true, true));
}

test "bounded iterative traversal terminates trees and cycles explicitly" {
    const tree = [_]Node{
        .{ .first_child = 1, .child_count = 2, .value = 1 },
        .{ .first_child = 0, .child_count = 0, .value = 2 },
        .{ .first_child = 0, .child_count = 0, .value = 3 },
    };
    try std.testing.expectEqual(6, try sumTree(&tree, 0, tree.len));

    const cycle = [_]Node{
        .{ .first_child = 0, .child_count = 1, .value = 1 },
    };
    try std.testing.expectError(error.WorkLimitExceeded, sumTree(&cycle, 0, 4));

    const too_wide = [_]Node{
        .{ .first_child = 1, .child_count = 9, .value = 0 },
        .{ .first_child = 0, .child_count = 0, .value = 0 },
        .{ .first_child = 0, .child_count = 0, .value = 0 },
        .{ .first_child = 0, .child_count = 0, .value = 0 },
        .{ .first_child = 0, .child_count = 0, .value = 0 },
        .{ .first_child = 0, .child_count = 0, .value = 0 },
        .{ .first_child = 0, .child_count = 0, .value = 0 },
        .{ .first_child = 0, .child_count = 0, .value = 0 },
        .{ .first_child = 0, .child_count = 0, .value = 0 },
        .{ .first_child = 0, .child_count = 0, .value = 0 },
    };
    try std.testing.expectError(
        error.StackCapacityExceeded,
        sumTree(&too_wide, 0, too_wide.len),
    );
}
