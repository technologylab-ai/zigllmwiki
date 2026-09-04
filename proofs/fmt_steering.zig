const std = @import("std");

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

test "formatter-directed arrays retain their values" {
    try std.testing.expectEqual(@as(usize, 9), coordinates.len);
    try std.testing.expectEqual(@as(usize, 11), command.len);
}
