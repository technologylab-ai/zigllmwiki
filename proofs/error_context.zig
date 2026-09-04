const std = @import("std");

const Diagnostics = struct {
    operation: ?[]const u8 = null,
    path: ?[]const u8 = null,
};

fn readRecord(diagnostics: *Diagnostics) !void {
    errdefer diagnostics.operation = "read-record";
    return error.InvalidRecord;
}

fn loadFile(diagnostics: *Diagnostics, path: []const u8) !void {
    errdefer diagnostics.path = path;
    try readRecord(diagnostics);
}

test "errdefer captures telescoping context without changing the error" {
    var diagnostics: Diagnostics = .{};

    try std.testing.expectError(
        error.InvalidRecord,
        loadFile(&diagnostics, "accounts.dat"),
    );
    try std.testing.expectEqualStrings("read-record", diagnostics.operation.?);
    try std.testing.expectEqualStrings("accounts.dat", diagnostics.path.?);
}
