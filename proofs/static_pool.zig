const std = @import("std");

const Order = struct {
    id: u64,
};

const capacity = 4;

const Pool = struct {
    const Slot = union(enum) {
        reserved: void,
        active: Order,
    };

    slots: [capacity]Slot = @splat(.{ .reserved = {} }),
    active_count: u32 = 0,

    fn acquire(pool: *Pool, order: Order) ?u32 {
        for (&pool.slots, 0..) |*slot, index| switch (slot.*) {
            .reserved => {
                slot.* = .{ .active = order };
                pool.active_count += 1;
                std.debug.assert(pool.active_count <= capacity);
                return @intCast(index);
            },
            .active => {},
        };

        std.debug.assert(pool.active_count == capacity);
        return null;
    }

    fn release(pool: *Pool, index: u32) Order {
        std.debug.assert(index < pool.slots.len);
        const slot = &pool.slots[index];
        const order = switch (slot.*) {
            .reserved => unreachable,
            .active => |order| order,
        };
        slot.* = .{ .reserved = {} };
        std.debug.assert(pool.active_count > 0);
        pool.active_count -= 1;
        return order;
    }

    fn visitEverySlot(pool: *const Pool) usize {
        var visited: usize = 0;
        for (pool.slots) |_| visited += 1;
        std.debug.assert(visited == capacity);
        return visited;
    }
};

test "fixed pool rejects excess work and conserves its slots" {
    var pool: Pool = .{};

    for (0..capacity) |id| {
        try std.testing.expectEqual(@as(u32, @intCast(id)), pool.acquire(.{ .id = id }));
    }
    try std.testing.expectEqual(capacity, pool.visitEverySlot());
    try std.testing.expectEqual(@as(?u32, null), pool.acquire(.{ .id = 99 }));

    const released = pool.release(2);
    try std.testing.expectEqual(@as(u64, 2), released.id);
    try std.testing.expectEqual(@as(u32, 2), pool.acquire(.{ .id = 100 }));
    try std.testing.expectEqual(@as(u32, capacity), pool.active_count);
}
