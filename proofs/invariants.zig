const std = @import("std");

fn is_sorted(items: []const u32) bool {
    if (items.len < 2) return true;

    for (1..items.len) |index| {
        if (items[index - 1] > items[index]) return false;
    }
    return true;
}

fn insertion_partition_holds(
    items: []const u32,
    target: u32,
    low: usize,
    high: usize,
) bool {
    if (low > high) return false;
    if (high > items.len) return false;

    for (items[0..low]) |item| {
        if (item >= target) return false;
    }
    for (items[high..]) |item| {
        if (item < target) return false;
    }
    return true;
}

fn insertion_point(items: []const u32, target: u32) usize {
    std.debug.assert(is_sorted(items));

    var low: usize = 0;
    var high: usize = items.len;
    var progress_budget: usize = items.len + 1;

    std.debug.assert(insertion_partition_holds(items, target, low, high));

    while (low < high) {
        std.debug.assert(progress_budget > 0);
        progress_budget -= 1;

        const width_before = high - low;
        const middle = low + width_before / 2;
        std.debug.assert(middle >= low);
        std.debug.assert(middle < high);

        if (items[middle] < target) {
            low = middle + 1;
        } else {
            high = middle;
        }

        std.debug.assert(insertion_partition_holds(items, target, low, high));
        std.debug.assert(high - low < width_before);
    }

    std.debug.assert(low == high);
    std.debug.assert(insertion_partition_holds(items, target, low, low));
    return low;
}

fn check_all_targets(items: []const u32, target_limit: u32) !void {
    var target: u32 = 0;
    while (target < target_limit) : (target += 1) {
        const answer = insertion_point(items, target);

        for (0..items.len + 1) |candidate| {
            try std.testing.expectEqual(
                candidate == answer,
                insertion_partition_holds(items, target, candidate, candidate),
            );
        }
    }
}

test "insertion point preserves its partition and has one valid result" {
    try check_all_targets(&.{}, 7);
    try check_all_targets(&.{0}, 7);
    try check_all_targets(&.{ 0, 0, 0 }, 7);
    try check_all_targets(&.{ 0, 1, 2, 3, 4, 5 }, 7);
    try check_all_targets(&.{ 0, 2, 2, 2, 5 }, 7);
}
