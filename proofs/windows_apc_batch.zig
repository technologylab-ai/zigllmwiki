const std = @import("std");
const builtin = @import("builtin");
const windows = std.os.windows;
const Io = std.Io;

// NPFS only: two pipe handles per fixture, 4096-byte requested quota, one or two
// stable operation slots, at most one Threaded task plus one watchdog thread.
// The watchdog exits the process instead of unwinding live kernel references.
const quota = 4096;
const watchdog_ticks = 2000;

const Watchdog = struct {
    done: std.atomic.Value(bool) = .init(false),

    fn run(self: *Watchdog) void {
        for (0..watchdog_ticks) |_| {
            if (self.done.load(.acquire)) return;
            delay(10);
        }
        abortProcess(124);
    }
};

fn abortProcess(code: u32) noreturn {
    _ = win32.TerminateProcess(windows.GetCurrentProcess(), code);
    unreachable;
}

fn delay(milliseconds: i64) void {
    const interval: windows.LARGE_INTEGER = -milliseconds * 10_000;
    _ = windows.ntdll.NtDelayExecution(.FALSE, &interval);
}

const Pipe = struct {
    reader: Io.File,
    writer: Io.File,

    fn init(threaded: *Io.Threaded) !Pipe {
        const handles = try threaded.windowsCreatePipe(.{
            .server = .{ .mode = .{ .IO = .ASYNCHRONOUS } },
            .client = .{ .mode = .{ .IO = .ASYNCHRONOUS } },
            .inbound = true,
            .quota = quota,
        });
        return .{
            .reader = .{ .handle = handles[0], .flags = .{ .nonblocking = true } },
            .writer = .{ .handle = handles[1], .flags = .{ .nonblocking = true } },
        };
    }

    fn close(self: Pipe, io: Io) void {
        self.writer.close(io);
        self.reader.close(io);
    }
};

const RawOperation = struct {
    status: windows.IO_STATUS_BLOCK = undefined,
    completed: bool = false,
    submitted: bool = false,
    handle: windows.HANDLE,

    fn apc(
        context: ?*anyopaque,
        _: *windows.IO_STATUS_BLOCK,
        _: windows.ULONG,
    ) align(Io.Threaded.apc_align) callconv(.winapi) void {
        const self: *RawOperation = @ptrCast(@alignCast(context));
        std.debug.assert(!self.completed);
        self.completed = true;
    }

    fn accept(self: *RawOperation, status: windows.NTSTATUS) !void {
        switch (status) {
            .SUCCESS, .PENDING => self.submitted = true,
            else => return error.UnexpectedSubmissionStatus,
        }
    }

    fn wait(self: *RawOperation) void {
        while (!self.completed) Io.Threaded.waitForApcOrAlert();
    }

    fn cleanup(self: *RawOperation) void {
        if (!self.submitted or self.completed) return;
        var cancel_status: windows.IO_STATUS_BLOCK = undefined;
        _ = windows.ntdll.NtCancelIoFileEx(self.handle, &self.status, &cancel_status);
        self.wait();
    }
};

fn rawRead(pipe: Pipe, operation: *RawOperation, bytes: []u8) windows.NTSTATUS {
    return windows.ntdll.NtReadFile(
        pipe.reader.handle,
        null,
        RawOperation.apc,
        operation,
        &operation.status,
        bytes.ptr,
        @intCast(bytes.len),
        null,
        null,
    );
}

fn rawWrite(pipe: Pipe, operation: *RawOperation, bytes: []const u8) windows.NTSTATUS {
    return windows.ntdll.NtWriteFile(
        pipe.writer.handle,
        null,
        RawOperation.apc,
        operation,
        &operation.status,
        bytes.ptr,
        @intCast(bytes.len),
        null,
        null,
    );
}

fn checkRawApc(threaded: *Io.Threaded) !void {
    const io = threaded.io();
    const pipe = try Pipe.init(threaded);
    defer pipe.close(io);
    var byte: [1]u8 = undefined;
    var empty_read: RawOperation = .{ .handle = pipe.reader.handle };
    defer empty_read.cleanup();
    const pending_read = rawRead(pipe, &empty_read, &byte);
    try empty_read.accept(pending_read);
    try std.testing.expectEqual(windows.NTSTATUS.PENDING, pending_read);
    try pipe.writer.writeStreamingAll(io, "R");
    empty_read.wait();
    try std.testing.expectEqual(windows.NTSTATUS.SUCCESS, empty_read.status.u.Status);
    try std.testing.expectEqualSlices(u8, "R", &byte);

    try pipe.writer.writeStreamingAll(io, "I");
    var ready_read: RawOperation = .{ .handle = pipe.reader.handle };
    defer ready_read.cleanup();
    const ready_status = rawRead(pipe, &ready_read, &byte);
    try ready_read.accept(ready_status);
    ready_read.wait();
    try std.testing.expectEqual(windows.NTSTATUS.SUCCESS, ready_read.status.u.Status);
    try std.testing.expectEqualSlices(u8, "I", &byte);

    var small_write: RawOperation = .{ .handle = pipe.writer.handle };
    defer small_write.cleanup();
    const small_status = rawWrite(pipe, &small_write, "W");
    try small_write.accept(small_status);
    small_write.wait();
    try std.testing.expectEqual(windows.NTSTATUS.SUCCESS, small_write.status.u.Status);
    try std.testing.expectEqual(1, try pipe.reader.readStreaming(io, &.{&byte}));
    try std.testing.expectEqualSlices(u8, "W", &byte);

    const payload: [quota * 2]u8 = @splat(0x5a);
    var large_write: RawOperation = .{ .handle = pipe.writer.handle };
    defer large_write.cleanup();
    const large_status = rawWrite(pipe, &large_write, &payload);
    try large_write.accept(large_status);
    // The measured return status is recorded, rather than assuming every
    // Windows release implements NPFS quota accounting identically.
    var received: [quota * 2]u8 = undefined;
    var used: usize = 0;
    for (0..payload.len) |_| {
        if (used == received.len) break;
        const n = try pipe.reader.readStreaming(io, &.{received[used..]});
        try std.testing.expect(n > 0);
        used += n;
    }
    large_write.wait();
    try std.testing.expectEqual(payload.len, large_write.status.Information);
    try std.testing.expectEqualSlices(u8, &payload, received[0..used]);
    std.debug.print(
        "APC raw: empty_read={s} ready_read={s} small_write={s} quota_write={s}; " ++
            "bytes=1,1,1,8192; callbacks=4\n",
        .{
            @tagName(pending_read),
            @tagName(ready_status),
            @tagName(small_status),
            @tagName(large_status),
        },
    );
}

fn readTask(file: Io.File, io: Io, entered: *Io.Event) !usize {
    var byte: [1]u8 = undefined;
    entered.set(io);
    return file.readStreaming(io, &.{&byte});
}

fn writeTask(file: Io.File, io: Io, entered: *Io.Event) !usize {
    const bytes: [quota * 2]u8 = @splat(0x57);
    entered.set(io);
    return file.writeStreaming(io, &.{}, &.{&bytes}, 1);
}

fn checkDirectCancel(threaded: *Io.Threaded) !void {
    const io = threaded.io();
    inline for (.{ readTask, writeTask }, 0..) |task, index| {
        const pipe = try Pipe.init(threaded);
        defer pipe.close(io);
        var entered: Io.Event = .unset;
        const file = if (index == 0) pipe.reader else pipe.writer;
        var future = try io.concurrent(task, .{ file, io, &entered });
        defer _ = future.cancel(io) catch {};
        try entered.wait(io);
        delay(20);
        try std.testing.expectError(error.Canceled, future.cancel(io));
    }
    std.debug.print(
        "APC Threaded task cancel: empty read + 8192-byte write; " ++
            "20ms submission allowance, no direct NT submission witness\n",
        .{},
    );
}

// Zig 0.16 Threaded.batchCancel first waits indefinitely for an APC/alert,
// before requesting cancellation. This test-only NT wake makes that initial
// wait progress. It is not a std.Io interface feature or production adapter.
fn cancelWithAlert(batch: *Io.Batch, io: Io) void {
    if (batch.pending.head != .none) {
        const status = windows.ntdll.NtAlertThread(windows.GetCurrentThread());
        if (status != .SUCCESS) abortProcess(125);
    }
    batch.cancel(io);
}

const IdleCancel = struct {
    io: Io,
    file: Io.File,
    entered: std.atomic.Value(bool) = .init(false),
    done: std.atomic.Value(bool) = .init(false),
    failure: ?anyerror = null,

    fn run(self: *IdleCancel) void {
        self.check() catch |err| {
            self.failure = err;
        };
        self.done.store(true, .release);
    }

    fn check(self: *IdleCancel) !void {
        var byte: [1]u8 = undefined;
        var vectors = [_][]u8{&byte};
        var storage: [1]Io.Operation.Storage = undefined;
        var batch: Io.Batch = .init(&storage);
        defer cancelWithAlert(&batch, self.io);
        batch.addAt(0, .{ .file_read_streaming = .{ .file = self.file, .data = &vectors } });
        try std.testing.expectError(error.Timeout, batch.awaitConcurrent(self.io, .{
            .duration = .{ .raw = .fromMilliseconds(1), .clock = .awake },
        }));
        self.entered.store(true, .release);
        batch.cancel(self.io);
        try std.testing.expect(batch.pending.head == .none);
        try std.testing.expect(batch.next() == null);
    }
};

fn checkIdleCancel(threaded: *Io.Threaded) !void {
    const io = threaded.io();
    const pipe = try Pipe.init(threaded);
    defer pipe.close(io);
    var state: IdleCancel = .{ .io = io, .file = pipe.reader };
    const thread = try std.Thread.spawn(.{}, IdleCancel.run, .{&state});
    // This join cannot outlive the process watchdog even if the runtime fails.
    defer thread.join();
    for (0..1000) |_| {
        if (state.entered.load(.acquire) or state.done.load(.acquire)) break;
        delay(1);
    }
    delay(100);
    const finished_without_alert = state.done.load(.acquire);
    for (0..100) |_| {
        if (state.done.load(.acquire)) break;
        _ = windows.ntdll.NtAlertThread(thread.getHandle());
        delay(10);
    }
    if (!state.done.load(.acquire)) abortProcess(126);
    if (state.failure) |err| return err;
    try std.testing.expect(state.entered.load(.acquire));
    std.debug.print(
        "APC Batch.cancel idle witness: finished_in_100ms_before_alert={}; " ++
            "after_explicit_NtAlertThread=true; canceled_result_absent=true\n",
        .{finished_without_alert},
    );
}

fn checkBatch(threaded: *Io.Threaded) !void {
    const io = threaded.io();
    const success_pipe = try Pipe.init(threaded);
    defer success_pipe.close(io);
    const cancel_pipe = try Pipe.init(threaded);
    defer cancel_pipe.close(io);
    try success_pipe.writer.writeStreamingAll(io, "S");
    var bytes: [2][1]u8 = undefined;
    var success_vectors = [_][]u8{&bytes[0]};
    var cancel_vectors = [_][]u8{&bytes[1]};
    var storage: [2]Io.Operation.Storage = undefined;
    var batch: Io.Batch = .init(&storage);
    defer cancelWithAlert(&batch, io);
    batch.addAt(0, .{ .file_read_streaming = .{
        .file = success_pipe.reader,
        .data = &success_vectors,
    } });
    batch.addAt(1, .{ .file_read_streaming = .{
        .file = cancel_pipe.reader,
        .data = &cancel_vectors,
    } });
    try batch.awaitConcurrent(io, .{
        .duration = .{ .raw = .fromSeconds(1), .clock = .awake },
    });
    cancelWithAlert(&batch, io);
    const completion = batch.next() orelse return error.MissingSuccess;
    try std.testing.expectEqual(0, completion.index);
    try std.testing.expectEqual(1, try completion.result.file_read_streaming);
    try std.testing.expectEqualSlices(u8, "S", &bytes[0]);
    try std.testing.expect(batch.next() == null);
    try std.testing.expect(batch.pending.head == .none);

    // A submitted write may win before cancellation. The public contract
    // requires preserving its result, not forcing the cancellation to win.
    batch.addAt(0, .{ .file_write_streaming = .{
        .file = success_pipe.writer,
        .data = &.{"B"},
    } });
    try batch.awaitConcurrent(io, .{
        .duration = .{ .raw = .fromSeconds(1), .clock = .awake },
    });
    cancelWithAlert(&batch, io);
    const write_completion = batch.next() orelse return error.MissingSuccess;
    try std.testing.expectEqual(1, try write_completion.result.file_write_streaming);
    try std.testing.expect(batch.next() == null);
    std.debug.print("APC Batch: capacity=2; success retained=2; pending read canceled=1\n", .{});
}

fn racingWriter(file: Io.File, io: Io, start: *Io.Event) !void {
    try start.wait(io);
    try file.writeStreamingAll(io, "R");
}

fn checkBatchRaces(threaded: *Io.Threaded) !void {
    const io = threaded.io();
    var succeeded: usize = 0;
    var canceled: usize = 0;
    for (0..32) |_| {
        const pipe = try Pipe.init(threaded);
        defer pipe.close(io);
        var byte: [1]u8 = undefined;
        var vectors = [_][]u8{&byte};
        var storage: [1]Io.Operation.Storage = undefined;
        var batch: Io.Batch = .init(&storage);
        defer cancelWithAlert(&batch, io);
        batch.addAt(0, .{ .file_read_streaming = .{ .file = pipe.reader, .data = &vectors } });
        try std.testing.expectError(error.Timeout, batch.awaitConcurrent(io, .{
            .duration = .{ .raw = .fromMilliseconds(1), .clock = .awake },
        }));
        var start: Io.Event = .unset;
        var future = try io.concurrent(racingWriter, .{ pipe.writer, io, &start });
        defer future.cancel(io) catch {};
        start.set(io);
        cancelWithAlert(&batch, io);
        try future.await(io);
        if (batch.next()) |completion| {
            try std.testing.expectEqual(0, completion.index);
            try std.testing.expectEqual(1, try completion.result.file_read_streaming);
            try std.testing.expectEqualSlices(u8, "R", &byte);
            succeeded += 1;
        } else {
            // A canceled result does not certify absence of side effects.
            // Close this round's pipe only after the target and writer have
            // terminated; do not assume whether its byte remains unread.
            canceled += 1;
        }
        try std.testing.expect(batch.next() == null);
        try std.testing.expect(batch.pending.head == .none);
    }
    try std.testing.expectEqual(32, succeeded + canceled);
    std.debug.print(
        "APC Batch cancel/write race: rounds=32; success={d}; canceled={d}; " ++
            "each operation reconciled once; no required winning distribution\n",
        .{ succeeded, canceled },
    );
}

const win32 = struct {
    extern "kernel32" fn TerminateProcess(
        process: windows.HANDLE,
        code: u32,
    ) callconv(.winapi) windows.BOOL;
    extern "kernel32" fn SetNamedPipeHandleState(
        pipe: windows.HANDLE,
        mode: ?*const u32,
        max_collection: ?*const u32,
        collection_timeout: ?*const u32,
    ) callconv(.winapi) windows.BOOL;
    extern "kernel32" fn CreateNamedPipeW(
        name: [*:0]const u16,
        open_mode: u32,
        pipe_mode: u32,
        max_instances: u32,
        out_buffer: u32,
        in_buffer: u32,
        default_timeout: u32,
        security_attributes: ?*anyopaque,
    ) callconv(.winapi) windows.HANDLE;
    extern "kernel32" fn CreateFileW(
        name: [*:0]const u16,
        access: u32,
        share: u32,
        security_attributes: ?*anyopaque,
        creation: u32,
        flags: u32,
        template: ?windows.HANDLE,
    ) callconv(.winapi) windows.HANDLE;
};

fn messagePipe() !Pipe {
    var name_bytes: [96]u8 = undefined;
    const name = try std.fmt.bufPrint(&name_bytes, "\\\\.\\pipe\\zig-wiki-apc-{d}", .{
        windows.GetCurrentProcessId(),
    });
    var wide: [96:0]u16 = @splat(0);
    const name_len = try std.unicode.utf8ToUtf16Le(&wide, name);
    wide[name_len] = 0;
    // PIPE_ACCESS_DUPLEX | FILE_FLAG_OVERLAPPED | FILE_FLAG_FIRST_PIPE_INSTANCE;
    // PIPE_TYPE_MESSAGE | PIPE_READMODE_MESSAGE, one local instance.
    const server = win32.CreateNamedPipeW(&wide, 0x40080003, 0x6, 1, quota, quota, 1000, null);
    if (server == windows.INVALID_HANDLE_VALUE) return error.CreateNamedPipeFailed;
    errdefer windows.CloseHandle(server);
    // GENERIC_READ | GENERIC_WRITE; OPEN_EXISTING; FILE_FLAG_OVERLAPPED.
    const client = win32.CreateFileW(&wide, 0xc0000000, 0, null, 3, 0x40000000, null);
    if (client == windows.INVALID_HANDLE_VALUE) return error.OpenNamedPipeFailed;
    errdefer windows.CloseHandle(client);
    const message_mode: u32 = 2;
    if (win32.SetNamedPipeHandleState(client, &message_mode, null, null) == .FALSE)
        return error.SetMessageModeFailed;
    return .{
        .reader = .{ .handle = server, .flags = .{ .nonblocking = true } },
        .writer = .{ .handle = client, .flags = .{ .nonblocking = true } },
    };
}

fn deviceTask(io: Io, file: Io.File) !windows.IO_STATUS_BLOCK {
    var answer: [1]u8 = undefined;
    return (try io.operate(.{ .device_io_control = .{
        .file = file,
        .code = windows.CTL_CODE.PIPE.TRANSCEIVE,
        .in = "Q",
        .out = &answer,
    } })).device_io_control;
}

fn checkDevice(threaded: *Io.Threaded) !void {
    const io = threaded.io();
    const pipe = try messagePipe();
    defer pipe.close(io);
    var future = try io.concurrent(deviceTask, .{ io, pipe.writer });
    defer _ = future.cancel(io) catch {};
    var request: [1]u8 = undefined;
    // Receipt of Q witnesses the transceive is issued; no reply is supplied.
    try std.testing.expectEqual(1, try pipe.reader.readStreaming(io, &.{&request}));
    try std.testing.expectEqualSlices(u8, "Q", &request);
    try std.testing.expectError(error.Canceled, future.cancel(io));

    var answer: [1]u8 = undefined;
    var storage: [1]Io.Operation.Storage = undefined;
    var batch: Io.Batch = .init(&storage);
    defer cancelWithAlert(&batch, io);
    for (0..2) |round| {
        batch.addAt(0, .{ .device_io_control = .{
            .file = pipe.writer,
            .code = windows.CTL_CODE.PIPE.TRANSCEIVE,
            .in = "Q",
            .out = &answer,
        } });
        try std.testing.expectError(error.Timeout, batch.awaitConcurrent(io, .{
            .duration = .{ .raw = .fromMilliseconds(1), .clock = .awake },
        }));
        try std.testing.expectEqual(1, try pipe.reader.readStreaming(io, &.{&request}));
        if (round == 1) {
            try pipe.reader.writeStreamingAll(io, "A");
            try batch.awaitConcurrent(io, .{
                .duration = .{ .raw = .fromSeconds(1), .clock = .awake },
            });
        }
        cancelWithAlert(&batch, io);
        if (round == 0) {
            try std.testing.expect(batch.next() == null);
        } else {
            const result = (batch.next() orelse return error.MissingReply).result.device_io_control;
            try std.testing.expectEqual(windows.NTSTATUS.SUCCESS, result.u.Status);
            try std.testing.expectEqual(1, result.Information);
            try std.testing.expectEqualSlices(u8, "A", &answer);
            try std.testing.expect(batch.next() == null);
        }
    }
    std.debug.print(
        "APC device_io_control: NPFS message TRANSCEIVE via NtFsControlFile; " ++
            "direct canceled=1; batch canceled=1; batch success retained=1; " ++
            "arbitrary drivers/NtDeviceIoControlFile not exercised\n",
        .{},
    );
}

fn runProof() !void {
    var watchdog: Watchdog = .{};
    const watchdog_thread = try std.Thread.spawn(.{}, Watchdog.run, .{&watchdog});
    defer watchdog_thread.join();
    defer watchdog.done.store(true, .release);
    var threaded: Io.Threaded = .init(std.testing.allocator, .{
        .async_limit = .nothing,
        .concurrent_limit = .limited(1),
    });
    defer threaded.deinit();
    try checkRawApc(&threaded);
    try checkDirectCancel(&threaded);
    try checkIdleCancel(&threaded);
    try checkBatch(&threaded);
    try checkBatchRaces(&threaded);
    try checkDevice(&threaded);
}

test "Windows APC read write batch and NPFS control retain ownership through cancellation" {
    if (builtin.os.tag != .windows) return error.SkipZigTest;
    try runProof();
}
