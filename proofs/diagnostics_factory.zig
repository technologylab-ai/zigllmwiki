const std = @import("std");

const Diagnostic = struct {
    code: Code,
    file_id: u32,
    offset: u32,

    const Code = enum {
        banned_item,
        long_line,
    };
};

const Diagnostics = struct {
    const capacity = 4;

    entries: [capacity]Diagnostic = undefined,
    len: u8 = 0,
    dropped: u32 = 0,

    fn addBanned(diagnostics: *Diagnostics, file_id: u32, offset: u32) void {
        diagnostics.add(.{
            .code = .banned_item,
            .file_id = file_id,
            .offset = offset,
        });
    }

    fn addLongLine(diagnostics: *Diagnostics, file_id: u32, offset: u32) void {
        diagnostics.add(.{
            .code = .long_line,
            .file_id = file_id,
            .offset = offset,
        });
    }

    fn add(diagnostics: *Diagnostics, item: Diagnostic) void {
        if (diagnostics.len == capacity) {
            diagnostics.dropped += 1;
            return;
        }
        diagnostics.entries[diagnostics.len] = item;
        diagnostics.len += 1;
    }
};

fn checkSource(diagnostics: ?*Diagnostics) error{InvalidSource}!void {
    if (diagnostics) |sink| {
        sink.addBanned(7, 11);
        sink.addLongLine(7, 42);
    }
    return error.InvalidSource;
}

test "error code is independent of bounded diagnostics representation" {
    try std.testing.expectError(error.InvalidSource, checkSource(null));

    var diagnostics: Diagnostics = .{};
    try std.testing.expectError(error.InvalidSource, checkSource(&diagnostics));
    try std.testing.expectEqual(@as(u8, 2), diagnostics.len);
    try std.testing.expectEqual(Diagnostic.Code.banned_item, diagnostics.entries[0].code);
    try std.testing.expectEqual(@as(u32, 42), diagnostics.entries[1].offset);
    try std.testing.expectEqual(@as(u32, 0), diagnostics.dropped);
}

test "diagnostic capacity fails explicitly without allocating" {
    var diagnostics: Diagnostics = .{};
    for (0..Diagnostics.capacity + 1) |offset| {
        diagnostics.addLongLine(1, @intCast(offset));
    }

    try std.testing.expectEqual(@as(u8, Diagnostics.capacity), diagnostics.len);
    try std.testing.expectEqual(@as(u32, 1), diagnostics.dropped);
}
