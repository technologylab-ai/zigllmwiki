const std = @import("std");

pub fn read_sector(
    audit: *ReadSectorAudit,
    sector_id: SectorID,
    options: ReadSectorOptions,
    completion: *ReadSectorCompletion,
    callback: ReadSectorCallback,
) void {
    std.debug.assert(options.size_bytes > 0);

    audit.attempts_count += 1;
    completion.* = .{
        .sector_id = sector_id,
        .offset_bytes = options.offset_bytes,
        .size_bytes = options.size_bytes,
        .checksum_actual = 0,
    };
    if (options.checksum_expected) |checksum_expected| {
        completion.checksum_actual = checksum_expected;
    } else {
        completion.checksum_actual = 0;
    }
    callback(completion);
}

const coordinates = [_]u8{
    1, 2, 3,
    4, 5, 6,
    7, 8, 9,
};

const command = [_][]const u8{ "aws", "s3", "sync", "source", "target" } ++ [_][]const u8{
    "--include",       "*.html",
    "--include",       "*.xml",
    "--cache-control", "max-age=0",
};

const SectorID = enum(u64) { _ };

const ReadSectorOptions = struct {
    offset_bytes: u64,
    size_bytes: u64,
    checksum_expected: ?u64,
};

const ReadSectorAudit = struct {
    attempts_count: u32 = 0,
};

const ReadSectorCompletion = struct {
    sector_id: SectorID = @enumFromInt(0),
    offset_bytes: u64 = 0,
    size_bytes: u64 = 0,
    checksum_actual: u64 = 0,
    finished: bool = false,

    const Self = @This();

    fn finish(self: *Self) void {
        std.debug.assert(!self.finished);
        self.finished = true;
    }
};

const ReadSectorCallback = *const fn (completion: *ReadSectorCompletion) void;

fn read_sector_callback(completion: *ReadSectorCompletion) void {
    completion.finish();
}

// This test checks the values; formatting is enforced separately by `zig fmt --check`.
test "formatter-directed arrays retain their values" {
    try std.testing.expectEqual(@as(usize, 9), coordinates.len);
    try std.testing.expectEqual(@as(usize, 11), command.len);
}

// This test makes every confusable option visible, then observes the callback's final state.
test "explicit options preserve call-site meaning and callback order" {
    var audit: ReadSectorAudit = .{};
    var completion: ReadSectorCompletion = .{};

    read_sector(
        &audit,
        @enumFromInt(7),
        .{
            .offset_bytes = 4_096,
            .size_bytes = 512,
            .checksum_expected = null,
        },
        &completion,
        read_sector_callback,
    );

    try std.testing.expectEqual(@as(u32, 1), audit.attempts_count);
    try std.testing.expectEqual(@as(SectorID, @enumFromInt(7)), completion.sector_id);
    try std.testing.expectEqual(@as(u64, 4_096), completion.offset_bytes);
    try std.testing.expectEqual(@as(u64, 512), completion.size_bytes);
    try std.testing.expectEqual(@as(u64, 0), completion.checksum_actual);
    try std.testing.expect(completion.finished);
}
