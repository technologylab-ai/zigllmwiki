const std = @import("std");

const Tree = struct {
    nodes: []const Node.Data,

    const Node = enum(u32) {
        root = 0,
        invalid = std.math.maxInt(u32),
        _,

        const Data = struct {
            parent: Node,
            children: struct {
                index: u32,
                count: u32,
            },

            comptime {
                std.debug.assert(@sizeOf(Data) == 12);
            }
        };
    };

    fn get(tree: *const Tree, node: Node) Node.Data {
        return tree.nodes[@intFromEnum(node)];
    }

    fn parent(tree: *const Tree, node: Node) ?Node {
        const result = tree.get(node).parent;
        return if (result == .invalid) null else result;
    }
};

test "non-exhaustive enum is a compact distinct index type" {
    const OtherIndex = enum(u32) { _ };
    const node: Tree.Node = @enumFromInt(7);
    const other: OtherIndex = @enumFromInt(7);

    try std.testing.expectEqual(@as(u32, 7), @intFromEnum(node));
    try std.testing.expect(@TypeOf(node) != @TypeOf(other));
    try std.testing.expectEqual(@sizeOf(u32), @sizeOf(Tree.Node));
}

test "the owning collection resolves an index" {
    const nodes = [_]Tree.Node.Data{
        .{
            .parent = .invalid,
            .children = .{ .index = 1, .count = 1 },
        },
        .{
            .parent = .root,
            .children = .{ .index = 0, .count = 0 },
        },
    };
    const tree: Tree = .{ .nodes = &nodes };

    try std.testing.expectEqual(@as(?Tree.Node, null), tree.parent(.root));
    try std.testing.expectEqual(Tree.Node.root, tree.parent(@enumFromInt(1)).?);
}
