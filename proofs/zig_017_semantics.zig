const std = @import("std");

test "logical array bits and native object bytes are distinct contracts" {
    const address = [4]u8{ 127, 0, 0, 1 };
    const logical: u32 = @bitCast(address);
    try std.testing.expectEqual(@as(u32, 0x0100_007f), logical);

    // A sockaddr field needs these bytes in memory on either endian.
    const native = std.mem.readInt(u32, &address, std.lang.Endian.native);
    try std.testing.expectEqualSlices(u8, &address, std.mem.asBytes(&native));
    const expected_native: u32 = switch (std.lang.Endian.native) {
        .little => 0x0100_007f,
        .big => 0x7f00_0001,
    };
    try std.testing.expectEqual(expected_native, native);
}

test "logical boolean vector bits retain every lane and competing match" {
    for (0..16) |first| {
        for (first..16) |second| {
            var values: [16]bool = @splat(false);
            values[first] = true;
            values[second] = true;
            const lanes: @Vector(16, bool) = values;
            const mask: u16 = @bitCast(lanes);
            const expected = (@as(u16, 1) << @intCast(first)) |
                (@as(u16, 1) << @intCast(second));
            try std.testing.expectEqual(expected, mask);
            try std.testing.expectEqual(first, @as(usize, @ctz(mask)));
        }
    }
}

test "reflection associates original field indices and distinguishes null defaults" {
    const Options = struct {
        required: u16,
        present_null: ?u16 = null,
        enabled: bool = false,
    };
    const info = @typeInfo(Options).@"struct";
    inline for (
        info.field_names,
        info.field_types,
        info.field_attrs,
        0..,
    ) |name, FieldType, attrs, index| {
        if (index == 0) {
            try std.testing.expectEqualStrings("required", name);
            try std.testing.expect(attrs.defaultValue(FieldType) == null);
        } else if (index == 1) {
            try std.testing.expectEqualStrings("present_null", name);
            const default: ??u16 = attrs.defaultValue(FieldType);
            try std.testing.expect(default != null);
            try std.testing.expect(default.? == null);
        } else {
            try std.testing.expectEqualStrings("enabled", name);
            try std.testing.expectEqual(@as(?bool, false), attrs.defaultValue(FieldType));
        }
    }

    // Filtering by type must keep the physical index into the attribute column.
    var optional_fields: usize = 0;
    inline for (info.field_names, info.field_types, 0..) |name, FieldType, index| {
        if (FieldType == ?u16) {
            optional_fields += 1;
            try std.testing.expectEqual(@as(usize, 1), index);
            try std.testing.expectEqualStrings("present_null", name);
            try std.testing.expect(info.field_attrs[index].defaultValue(FieldType).? == null);
        }
    }
    try std.testing.expectEqual(@as(usize, 1), optional_fields);
}

test "same-file declaration discovery requires a public cleanup hook" {
    const Hooks = struct {
        pub fn deinit() void {}
        fn privateCleanup() void {}
    };
    try std.testing.expect(@hasDecl(Hooks, "deinit"));
    try std.testing.expect(!@hasDecl(Hooks, "privateCleanup"));
    const declarations = @typeInfo(Hooks).@"struct".decl_names;
    try std.testing.expectEqual(@as(usize, 1), declarations.len);
    try std.testing.expectEqualStrings("deinit", declarations[0]);
}

test "typed byte repetition retains a borrowed sentinel string" {
    const word = "abc";
    const repeated: [9:0]u8 = bytes: {
        var result: [9:0]u8 = @splat(0);
        for (0..3) |copy| @memcpy(result[copy * word.len ..][0..word.len], word);
        break :bytes result;
    };
    const borrowed: *const [9:0]u8 = &repeated;
    const text: [:0]const u8 = borrowed;
    try std.testing.expectEqualStrings("abcabcabc", text);
    try std.testing.expectEqual(@as(u8, 0), text[text.len]);
    try std.testing.expect(@typeInfo(@TypeOf(borrowed)).pointer.attrs.@"const");
    try std.testing.expectEqual(@as(?u8, 0), @typeInfo(@TypeOf(text)).pointer.sentinel());
}
