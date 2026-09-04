const std = @import("std");

const RequestIndex = enum(u32) { _ };
const ItemCount = enum(u32) { _ };
const ByteCount = enum(u32) { _ };

const WireFlags = packed struct(u16) {
    urgent: bool,
    compressed: bool,
    kind: u2,
    reserved: u12 = 0,
};

const WireRecord = struct {
    request_index: RequestIndex,
    item_count: ItemCount,
    payload_bytes: ByteCount,
    flags: WireFlags,
};

const request_index_offset = 0;
const item_count_offset = request_index_offset + @sizeOf(u32);
const payload_bytes_offset = item_count_offset + @sizeOf(u32);
const flags_offset = payload_bytes_offset + @sizeOf(u32);
const wire_record_size = flags_offset + @sizeOf(u16);

comptime {
    std.debug.assert(@sizeOf(RequestIndex) == @sizeOf(u32));
    std.debug.assert(@sizeOf(ItemCount) == @sizeOf(u32));
    std.debug.assert(@sizeOf(ByteCount) == @sizeOf(u32));
    std.debug.assert(@bitSizeOf(WireFlags) == 16);
    std.debug.assert(@sizeOf(WireFlags) == @sizeOf(u16));
    std.debug.assert(wire_record_size == 14);
}

const BoundaryError = error{
    IntegerOutOfRange,
    InvalidLength,
    ReservedBitsSet,
};

fn byteCountFromUsize(value: usize) BoundaryError!ByteCount {
    const narrowed = std.math.cast(u32, value) orelse
        return error.IntegerOutOfRange;
    return @enumFromInt(narrowed);
}

fn totalWireBytes(payload_bytes: ByteCount) BoundaryError!u32 {
    return std.math.add(
        u32,
        @intCast(wire_record_size),
        @intFromEnum(payload_bytes),
    ) catch error.IntegerOutOfRange;
}

fn encode(record: WireRecord) [wire_record_size]u8 {
    std.debug.assert(record.flags.reserved == 0);

    var bytes: [wire_record_size]u8 = undefined;
    std.mem.writeInt(
        u32,
        bytes[request_index_offset..item_count_offset],
        @intFromEnum(record.request_index),
        .little,
    );
    std.mem.writeInt(
        u32,
        bytes[item_count_offset..payload_bytes_offset],
        @intFromEnum(record.item_count),
        .little,
    );
    std.mem.writeInt(
        u32,
        bytes[payload_bytes_offset..flags_offset],
        @intFromEnum(record.payload_bytes),
        .little,
    );
    std.mem.writeInt(
        u16,
        bytes[flags_offset..wire_record_size],
        @bitCast(record.flags),
        .little,
    );
    return bytes;
}

fn decode(bytes: []const u8) BoundaryError!WireRecord {
    if (bytes.len != wire_record_size) return error.InvalidLength;

    const flags: WireFlags = @bitCast(std.mem.readInt(
        u16,
        bytes[flags_offset..wire_record_size],
        .little,
    ));
    if (flags.reserved != 0) return error.ReservedBitsSet;

    return .{
        .request_index = @enumFromInt(std.mem.readInt(
            u32,
            bytes[request_index_offset..item_count_offset],
            .little,
        )),
        .item_count = @enumFromInt(std.mem.readInt(
            u32,
            bytes[item_count_offset..payload_bytes_offset],
            .little,
        )),
        .payload_bytes = @enumFromInt(std.mem.readInt(
            u32,
            bytes[payload_bytes_offset..flags_offset],
            .little,
        )),
        .flags = flags,
    };
}

test "domain integers stay distinct and narrowing is checked" {
    const count: ItemCount = @enumFromInt(7);
    const bytes: ByteCount = try byteCountFromUsize(7);

    try std.testing.expect(@TypeOf(count) != @TypeOf(bytes));
    try std.testing.expectEqual(@as(u32, 7), @intFromEnum(bytes));

    if (@bitSizeOf(usize) > @bitSizeOf(u32)) {
        try std.testing.expectError(
            error.IntegerOutOfRange,
            byteCountFromUsize(@as(usize, std.math.maxInt(u32)) + 1),
        );
    }

    const maximum_payload: ByteCount = @enumFromInt(std.math.maxInt(u32));
    try std.testing.expectError(
        error.IntegerOutOfRange,
        totalWireBytes(maximum_payload),
    );
}

test "wire representation has explicit widths and little endian order" {
    const record: WireRecord = .{
        .request_index = @enumFromInt(0x0102_0304),
        .item_count = @enumFromInt(0x0506_0708),
        .payload_bytes = @enumFromInt(0x090a_0b0c),
        .flags = .{ .urgent = true, .compressed = false, .kind = 2 },
    };

    const bytes = encode(record);
    try std.testing.expectEqualSlices(u8, &.{
        0x04, 0x03, 0x02, 0x01,
        0x08, 0x07, 0x06, 0x05,
        0x0c, 0x0b, 0x0a, 0x09,
        0x09, 0x00,
    }, &bytes);

    const decoded = try decode(&bytes);
    try std.testing.expectEqual(
        @intFromEnum(record.request_index),
        @intFromEnum(decoded.request_index),
    );
    try std.testing.expectEqual(
        @intFromEnum(record.item_count),
        @intFromEnum(decoded.item_count),
    );
    try std.testing.expectEqual(
        @intFromEnum(record.payload_bytes),
        @intFromEnum(decoded.payload_bytes),
    );
    try std.testing.expectEqual(record.flags, decoded.flags);
}

test "wire decoder rejects size and reserved-bit violations" {
    try std.testing.expectError(error.InvalidLength, decode(&.{0}));

    var bytes = encode(.{
        .request_index = @enumFromInt(0),
        .item_count = @enumFromInt(0),
        .payload_bytes = @enumFromInt(0),
        .flags = .{ .urgent = false, .compressed = false, .kind = 0 },
    });
    bytes[wire_record_size - 1] = 0x80;
    try std.testing.expectError(error.ReservedBitsSet, decode(&bytes));
}
