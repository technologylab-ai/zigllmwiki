const std = @import("std");
const builtin = @import("builtin");

test "Zig 0.16 Windows std.Io surface maps to NT status blocks, not IOCP" {
    if (builtin.os.tag == .windows) {
        try checkWindowsMapping();
    } else {
        return error.SkipZigTest;
    }
}

fn checkWindowsMapping() !void {
    const windows = std.os.windows;

    comptime {
        std.debug.assert(std.Io.Evented == void);
        std.debug.assert(std.Io.Operation.DeviceIoControl.Result == windows.IO_STATUS_BLOCK);

        std.debug.assert(@hasDecl(windows.ntdll, "NtReadFile"));
        std.debug.assert(@hasDecl(windows.ntdll, "NtWriteFile"));
        std.debug.assert(@hasDecl(windows.ntdll, "NtDeviceIoControlFile"));
        std.debug.assert(@hasDecl(windows.ntdll, "NtCancelIoFileEx"));
        std.debug.assert(@hasDecl(windows.ntdll, "NtCancelSynchronousIoFile"));
        std.debug.assert(@hasDecl(std.Io.Threaded, "waitForApcOrAlert"));

        // Zig 0.16's std.os.windows surface does not provide the Win32 IOCP
        // and OVERLAPPED declarations. An IOCP adapter therefore needs its own
        // bindings; std.Io.Threaded is not that adapter.
        std.debug.assert(!@hasDecl(windows, "OVERLAPPED"));
        std.debug.assert(!@hasDecl(windows.kernel32, "CreateIoCompletionPort"));
        std.debug.assert(!@hasDecl(windows.kernel32, "GetQueuedCompletionStatusEx"));
        std.debug.assert(!@hasDecl(windows.kernel32, "CancelIoEx"));
    }

    var bytes: [32]u8 = undefined;
    var vectors = [_][]u8{&bytes};
    const async_handle: std.Io.File = .{
        .handle = undefined,
        .flags = .{ .nonblocking = true },
    };
    const operation: std.Io.Operation = .{ .file_read_streaming = .{
        .file = async_handle,
        .data = &vectors,
    } };

    var operation_storage: [1]std.Io.Operation.Storage = undefined;
    var batch: std.Io.Batch = .init(&operation_storage);
    batch.addAt(0, operation);

    try std.testing.expectEqual(@as(u32, 0), batch.submitted.head.toIndex());
    try std.testing.expect(batch.pending.head == .none);
    try std.testing.expect(batch.completed.head == .none);
}
