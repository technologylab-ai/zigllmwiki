const std = @import("std");

const Configuration = struct {
    limits: [8]u32,
    generation: u64,
};

comptime {
    std.debug.assert(@sizeOf(Configuration) > 16);
}

fn configuration_checksum(configuration: *const Configuration) u64 {
    var checksum: u64 = configuration.generation;
    for (configuration.limits) |limit| checksum +%= limit;
    return checksum;
}

const StableTable = struct {
    entries: [4]u64,
    address: usize,

    fn init(table: *StableTable) void {
        table.* = .{
            .entries = @splat(0),
            .address = @intFromPtr(table),
        };
        table.assert_stable();
    }

    fn assert_stable(table: *const StableTable) void {
        std.debug.assert(table.address == @intFromPtr(table));
    }
};

const Service = struct {
    table: StableTable,
    generation: u64,

    fn init(service: *Service, generation: u64) void {
        service.generation = generation;
        StableTable.init(&service.table);
        service.table.assert_stable();
    }
};

const Encoded = struct {
    bytes: [16]u8,
    len: u8,
};

fn encode_bounded(payload: []const u8) error{PayloadTooLarge}!Encoded {
    if (payload.len > 16) return error.PayloadTooLarge;
    var encoded: Encoded = .{
        .bytes = @splat(0),
        .len = @intCast(payload.len),
    };
    @memcpy(encoded.bytes[0..payload.len], payload);
    return encoded;
}

const DivideError = error{
    DivisionByZero,
    NotExact,
};

fn divide_exact(numerator: u32, denominator: u32) DivideError!u32 {
    if (denominator == 0) return error.DivisionByZero;
    if (numerator % denominator != 0) return error.NotExact;
    return @divExact(numerator, denominator);
}

fn divide_floor(numerator: i32, denominator: i32) error{DivisionByZero}!i32 {
    if (denominator == 0) return error.DivisionByZero;
    return @divFloor(numerator, denominator);
}

fn divide_ceil(numerator: i32, denominator: i32) !i32 {
    return std.math.divCeil(i32, numerator, denominator);
}

test "large read-only values are borrowed and stable fields initialize in place" {
    const configuration: Configuration = .{
        .limits = .{ 1, 2, 3, 4, 5, 6, 7, 8 },
        .generation = 9,
    };
    try std.testing.expectEqual(45, configuration_checksum(&configuration));

    var service: Service = undefined;
    Service.init(&service, 7);
    service.table.entries[0] = 11;
    service.table.assert_stable();
    try std.testing.expectEqual(7, service.generation);
    try std.testing.expectEqual(11, service.table.entries[0]);
}

test "encoded output initializes unused capacity and clears reused storage" {
    var encoded = try encode_bounded("secret");
    try std.testing.expectEqualSlices(u8, "secret", encoded.bytes[0..encoded.len]);
    try std.testing.expectEqualSlices(
        u8,
        &@as([10]u8, @splat(0)),
        encoded.bytes[encoded.len..],
    );

    @memset(&encoded.bytes, 0);
    encoded.len = 0;
    try std.testing.expectEqualSlices(u8, &@as([16]u8, @splat(0)), &encoded.bytes);
}

test "division operations expose exact floor and ceiling intent" {
    try std.testing.expectEqual(4, try divide_exact(12, 3));
    try std.testing.expectError(error.NotExact, divide_exact(13, 3));
    try std.testing.expectError(error.DivisionByZero, divide_exact(1, 0));

    try std.testing.expectEqual(-3, try divide_floor(-5, 2));
    try std.testing.expectEqual(-2, try divide_ceil(-5, 2));
    try std.testing.expectEqual(3, try divide_ceil(5, 2));
    try std.testing.expectError(error.DivisionByZero, divide_ceil(1, 0));
}
