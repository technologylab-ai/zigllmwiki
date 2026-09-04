const std = @import("std");

const State = struct {
    sequence: u64,
    credits: u64,
    debits: u64,

    fn invariant(state: State) bool {
        return state.sequence > 0 and state.debits <= state.credits;
    }
};

const magic = "PAIR";
const version: u16 = 1;
const magic_offset = 0;
const version_offset = magic_offset + magic.len;
const reserved_offset = version_offset + @sizeOf(u16);
const sequence_offset = reserved_offset + @sizeOf(u16);
const credits_offset = sequence_offset + @sizeOf(u64);
const debits_offset = credits_offset + @sizeOf(u64);
const checksum_offset = debits_offset + @sizeOf(u64);
const encoded_size = checksum_offset + @sizeOf(u32);

comptime {
    std.debug.assert(encoded_size == 36);
}

const DecodeError = error{
    InvalidLength,
    InvalidMagic,
    UnsupportedVersion,
    ReservedBitsSet,
    ChecksumMismatch,
    InvalidState,
};

fn checksum(bytes: []const u8) u32 {
    var result: u32 = 2_166_136_261;
    for (bytes) |byte| {
        result ^= byte;
        result *%= 16_777_619;
    }
    return result;
}

fn refreshChecksum(bytes: *[encoded_size]u8) void {
    std.mem.writeInt(
        u32,
        bytes[checksum_offset..encoded_size],
        checksum(bytes[0..checksum_offset]),
        .little,
    );
}

fn encode(state: State) [encoded_size]u8 {
    // Producer-side assertion: logical state must be valid before persistence.
    std.debug.assert(state.invariant());

    var bytes: [encoded_size]u8 = @splat(0);
    @memcpy(bytes[magic_offset..version_offset], magic);
    std.mem.writeInt(u16, bytes[version_offset..reserved_offset], version, .little);
    std.mem.writeInt(u64, bytes[sequence_offset..credits_offset], state.sequence, .little);
    std.mem.writeInt(u64, bytes[credits_offset..debits_offset], state.credits, .little);
    std.mem.writeInt(u64, bytes[debits_offset..checksum_offset], state.debits, .little);
    refreshChecksum(&bytes);
    return bytes;
}

fn decode(bytes: []const u8) DecodeError!State {
    if (bytes.len != encoded_size) return error.InvalidLength;
    if (!std.mem.eql(u8, bytes[magic_offset..version_offset], magic)) {
        return error.InvalidMagic;
    }
    if (std.mem.readInt(u16, bytes[version_offset..reserved_offset], .little) != version) {
        return error.UnsupportedVersion;
    }
    if (std.mem.readInt(u16, bytes[reserved_offset..sequence_offset], .little) != 0) {
        return error.ReservedBitsSet;
    }
    if (std.mem.readInt(u32, bytes[checksum_offset..encoded_size], .little) !=
        checksum(bytes[0..checksum_offset]))
    {
        return error.ChecksumMismatch;
    }

    const state: State = .{
        .sequence = std.mem.readInt(
            u64,
            bytes[sequence_offset..credits_offset],
            .little,
        ),
        .credits = std.mem.readInt(
            u64,
            bytes[credits_offset..debits_offset],
            .little,
        ),
        .debits = std.mem.readInt(
            u64,
            bytes[debits_offset..checksum_offset],
            .little,
        ),
    };
    if (!state.invariant()) return error.InvalidState;

    // Consumer-side assertion: re-establish the same property independently.
    std.debug.assert(state.invariant());
    return state;
}

test "producer and consumer independently enforce the persisted invariant" {
    const expected: State = .{ .sequence = 7, .credits = 100, .debits = 40 };
    const bytes = encode(expected);
    const actual = try decode(&bytes);
    try std.testing.expectEqualDeep(expected, actual);
}

test "decoder rejects structural corruption before forming trusted state" {
    var bytes = encode(.{ .sequence = 1, .credits = 10, .debits = 5 });

    try std.testing.expectError(error.InvalidLength, decode(bytes[0 .. encoded_size - 1]));

    bytes[magic_offset] ^= 1;
    try std.testing.expectError(error.InvalidMagic, decode(&bytes));
    bytes[magic_offset] ^= 1;

    std.mem.writeInt(u16, bytes[version_offset..reserved_offset], version + 1, .little);
    refreshChecksum(&bytes);
    try std.testing.expectError(error.UnsupportedVersion, decode(&bytes));
    std.mem.writeInt(u16, bytes[version_offset..reserved_offset], version, .little);

    bytes[reserved_offset] = 1;
    refreshChecksum(&bytes);
    try std.testing.expectError(error.ReservedBitsSet, decode(&bytes));
}

test "decoder rejects semantically invalid state even with a valid checksum" {
    var bytes = encode(.{ .sequence = 1, .credits = 10, .debits = 5 });
    std.mem.writeInt(u64, bytes[debits_offset..checksum_offset], 11, .little);
    refreshChecksum(&bytes);

    try std.testing.expectError(error.InvalidState, decode(&bytes));
}

test "decoder detects mutation with a stale checksum" {
    var bytes = encode(.{ .sequence = 1, .credits = 10, .debits = 5 });
    bytes[credits_offset] ^= 1;

    try std.testing.expectError(error.ChecksumMismatch, decode(&bytes));
}
