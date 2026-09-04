const std = @import("std");
const builtin = @import("builtin");
const windows = std.os.windows;

// A deliberately small custom Win32 adapter, outside std.Io.Threaded. Four
// slots bound submitted I/O AND terminal results awaiting dispatch. The port's
// concurrency value does not impose this bound. No operation storage moves
// between submission and reconciliation; each buffer belongs to its slot.
const slot_limit = 4;
const transfer_bytes = 64;
const load_rounds = 256;
const race_rounds = 16;
const stop_key = std.math.maxInt(usize);
const stop_bytes = 0x53544f50;
const pending_error = 997;
const aborted_error = 995;
const not_found_error = 1168;
const timeout_error = 258;

// The SDK OVERLAPPED union's offset variant is sufficient for these fixtures.
const Overlapped = extern struct {
    internal: usize = 0,
    internal_high: usize = 0,
    offset: u32 = 0,
    offset_high: u32 = 0,
    event: ?windows.HANDLE = null,
};

const win32 = struct {
    extern "kernel32" fn CreateIoCompletionPort(
        windows.HANDLE,
        ?windows.HANDLE,
        usize,
        u32,
    ) callconv(.winapi) ?windows.HANDLE;
    extern "kernel32" fn GetQueuedCompletionStatus(
        windows.HANDLE,
        *u32,
        *usize,
        *?*Overlapped,
        u32,
    ) callconv(.winapi) i32;
    extern "kernel32" fn PostQueuedCompletionStatus(
        windows.HANDLE,
        u32,
        usize,
        ?*Overlapped,
    ) callconv(.winapi) i32;
    extern "kernel32" fn SetFileCompletionNotificationModes(
        windows.HANDLE,
        u8,
    ) callconv(.winapi) i32;
    extern "kernel32" fn ReadFile(
        windows.HANDLE,
        [*]u8,
        u32,
        ?*u32,
        *Overlapped,
    ) callconv(.winapi) i32;
    extern "kernel32" fn WriteFile(
        windows.HANDLE,
        [*]const u8,
        u32,
        ?*u32,
        ?*Overlapped,
    ) callconv(.winapi) i32;
    extern "kernel32" fn CancelIoEx(windows.HANDLE, ?*Overlapped) callconv(.winapi) i32;
    extern "kernel32" fn GetOverlappedResult(
        windows.HANDLE,
        *Overlapped,
        *u32,
        i32,
    ) callconv(.winapi) i32;
    extern "kernel32" fn GetLastError() callconv(.winapi) u32;
    extern "kernel32" fn GetTickCount64() callconv(.winapi) u64;
    extern "kernel32" fn QueryPerformanceCounter(*i64) callconv(.winapi) i32;
    extern "kernel32" fn QueryPerformanceFrequency(*i64) callconv(.winapi) i32;
    extern "kernel32" fn Sleep(u32) callconv(.winapi) void;
    extern "kernel32" fn GetCurrentProcess() callconv(.winapi) windows.HANDLE;
    extern "kernel32" fn TerminateProcess(windows.HANDLE, u32) callconv(.winapi) i32;
};

fn failFast(code: u32) noreturn {
    // Terminating this test process avoids DLL detach callbacks and releasing
    // live kernel-owned buffers. The hosted job also has an outer time limit:
    // no userspace watchdog promises an OS/driver-independent hard deadline.
    if (win32.TerminateProcess(win32.GetCurrentProcess(), code) == 0) @trap();
    unreachable;
}

const Watchdog = struct {
    done: std.atomic.Value(bool) = .init(false),

    fn run(self: *Watchdog) void {
        const deadline = win32.GetTickCount64() + 30_000;
        while (!self.done.load(.acquire)) {
            if (win32.GetTickCount64() >= deadline) {
                // Terminate the test process rather than unwind live kernel
                // buffers, close handles under I/O, or hang the hosted job.
                failFast(77);
            }
            win32.Sleep(10);
        }
    }
};

const Slot = struct {
    overlapped: Overlapped = .{},
    buffer: [transfer_bytes]u8 = @splat(0xcc),
    handle: ?windows.HANDLE = null,
    writer: ?windows.HANDLE = null,
    state: enum { free, submitted } = .free,
    generation: u32 = 0,
    retired_generation: u32 = 0,
    expected_byte: u8 = 0,
    allow_abort: bool = false,
    last_aborted: bool = false,
};

const Metrics = struct {
    submitted: u32 = 0,
    immediate: u32 = 0,
    pending: u32 = 0,
    direct: u32 = 0,
    packets: u32 = 0,
    canceled: u32 = 0,
    canceled_bytes_reported: u64 = 0,
    canceled_buffer_changes: u32 = 0,
    successful: u32 = 0,
    cancel_accepted: u32 = 0,
    cancel_not_found: u32 = 0,
    peak_owned: u32 = 0,
    checksum: u64 = 0,
};

const Harness = struct {
    slots: [slot_limit]Slot = @splat(.{}),
    port: ?windows.HANDLE = null,
    skip_success: bool,
    accepting: bool = true,
    stop_seen: bool = false,
    shutdown_finished: bool = false,
    owned: u32 = 0,
    metrics: Metrics = .{},

    fn initPort(self: *Harness) !void {
        const invalid: windows.HANDLE = @ptrFromInt(std.math.maxInt(usize));
        self.port = win32.CreateIoCompletionPort(invalid, null, 0, 1) orelse
            return error.CreatePortFailed;
    }

    fn associate(self: *Harness, index: usize) !void {
        const handle = self.slots[index].handle.?;
        const associated = win32.CreateIoCompletionPort(handle, self.port, index + 1, 0);
        try std.testing.expectEqual(self.port, associated);
        if (self.skip_success) {
            // FILE_SKIP_COMPLETION_PORT_ON_SUCCESS: direct ownership applies
            // only to TRUE ReadFile returns, never ERROR_IO_PENDING.
            if (win32.SetFileCompletionNotificationModes(handle, 1) == 0)
                return error.SetNotificationModeFailed;
        }
    }

    fn initPipes(self: *Harness, threaded: *std.Io.Threaded) !void {
        try self.initPort();
        for (0..slot_limit) |index| try self.replacePipe(threaded, index);
    }

    fn replacePipe(self: *Harness, threaded: *std.Io.Threaded, index: usize) !void {
        const slot = &self.slots[index];
        try std.testing.expectEqual(.free, slot.state);
        // No operation can still reference these handles. Close before
        // creating the replacement to retain the four-pair resource bound.
        if (slot.writer) |handle| windows.CloseHandle(handle);
        if (slot.handle) |handle| windows.CloseHandle(handle);
        slot.writer = null;
        slot.handle = null;
        const pair = try threaded.windowsCreatePipe(.{
            .server = .{ .mode = .{ .IO = .ASYNCHRONOUS } },
            .client = .{ .mode = .{ .IO = .SYNCHRONOUS_NONALERT } },
            .inbound = true,
            .quota = 4096,
        });
        slot.handle = pair[0];
        slot.writer = pair[1];
        try self.associate(index);
    }

    fn initFiles(self: *Harness, dir: std.Io.Dir) !void {
        try self.initPort();
        for (&self.slots, 0..) |*slot, index| {
            // Select the actual NT handle mode explicitly. Zig 0.16's
            // dirOpenFileWtf16 no-follow path chooses ASYNCHRONOUS but still
            // reports File.flags.nonblocking=false, so do not use that
            // wrapper's metadata as an asynchronous fixture witness.
            const name_w = std.unicode.utf8ToUtf16LeStringLiteral("iocp");
            var name = windows.UNICODE_STRING.init(name_w);
            var status_block: windows.IO_STATUS_BLOCK = undefined;
            var handle: windows.HANDLE = undefined;
            const status = windows.ntdll.NtOpenFile(
                &handle,
                .{ .STANDARD = .{ .SYNCHRONIZE = true }, .GENERIC = .{ .READ = true } },
                &.{ .RootDirectory = dir.handle, .ObjectName = &name },
                &status_block,
                .{ .READ = true },
                .{ .IO = .ASYNCHRONOUS, .NON_DIRECTORY_FILE = true },
            );
            if (status == .PENDING) {
                // This local fixture requires completed open setup. Do not
                // unwind a potentially kernel-owned setup status block.
                failFast(79);
            }
            if (status != .SUCCESS) {
                std.debug.print("IOCP NtOpenFile setup failed: {s}\n", .{@tagName(status)});
                return error.FileFixtureOpenFailed;
            }
            slot.handle = handle;
            try self.associate(index);
        }
    }

    fn submit(
        self: *Harness,
        index: usize,
        expected_byte: u8,
        offset: u32,
        allow_abort: bool,
    ) !void {
        if (!self.accepting) return error.AdmissionClosed;
        const slot = &self.slots[index];
        if (slot.state != .free) return error.CapacityExhausted;
        try std.testing.expect(self.owned < slot_limit);
        try std.testing.expectEqual(slot.generation, slot.retired_generation);
        slot.generation += 1;
        slot.overlapped = .{ .offset = offset };
        @memset(&slot.buffer, 0xcc);
        slot.expected_byte = expected_byte;
        slot.allow_abort = allow_abort;
        slot.state = .submitted;
        self.owned += 1;
        self.metrics.submitted += 1;
        self.metrics.peak_owned = @max(self.metrics.peak_owned, self.owned);
        const succeeded = win32.ReadFile(
            slot.handle.?,
            &slot.buffer,
            transfer_bytes,
            null,
            &slot.overlapped,
        );
        if (succeeded != 0) {
            self.metrics.immediate += 1;
            if (self.skip_success) {
                var bytes: u32 = 0;
                if (win32.GetOverlappedResult(slot.handle.?, &slot.overlapped, &bytes, 0) == 0)
                    return error.ImmediateResultFailed;
                self.metrics.direct += 1;
                try self.retire(index, bytes, 0);
            }
            // Default mode owns no direct completion, even on TRUE.
        } else {
            const code = win32.GetLastError();
            if (code != pending_error) {
                // A failed submission has no packet to drain. No kernel
                // ownership remains, but fail this narrow expected workload.
                slot.state = .free;
                slot.retired_generation = slot.generation;
                self.owned -= 1;
                std.debug.print("IOCP ReadFile submission failed: {d}\n", .{code});
                return error.ReadSubmissionFailed;
            }
            self.metrics.pending += 1;
        }
    }

    fn retire(self: *Harness, index: usize, bytes: u32, code: u32) !void {
        const slot = &self.slots[index];
        try std.testing.expectEqual(.submitted, slot.state);
        try std.testing.expectEqual(slot.retired_generation + 1, slot.generation);
        // Reclaim only after the terminal result is ours. Even a failed
        // correctness assertion below must not leave a nonexistent request
        // marked pending for error-path shutdown to cancel a second time.
        slot.retired_generation = slot.generation;
        slot.state = .free;
        self.owned -= 1;
        slot.last_aborted = code == aborted_error;
        if (slot.last_aborted) {
            self.metrics.canceled += 1;
            try std.testing.expect(slot.allow_abort);
            self.metrics.canceled_bytes_reported += bytes;
            for (slot.buffer) |byte| {
                if (byte != 0xcc) self.metrics.canceled_buffer_changes += 1;
            }
            // Aborted does not promise an untouched buffer or no consumed
            // input. Observed bytes are metrics, not rollback guarantees.
        } else {
            self.metrics.successful += 1;
            try std.testing.expectEqual(0, code);
            try std.testing.expectEqual(transfer_bytes, bytes);
            for (slot.buffer) |byte| {
                try std.testing.expectEqual(slot.expected_byte, byte);
                self.metrics.checksum += byte;
            }
        }
    }

    fn cancel(self: *Harness, index: usize) !void {
        const slot = &self.slots[index];
        try std.testing.expectEqual(.submitted, slot.state);
        if (win32.CancelIoEx(slot.handle.?, &slot.overlapped) != 0) {
            self.metrics.cancel_accepted += 1;
        } else {
            const code = win32.GetLastError();
            try std.testing.expectEqual(not_found_error, code);
            self.metrics.cancel_not_found += 1;
        }
        // Neither outcome releases the slot or its buffer.
        try std.testing.expectEqual(.submitted, slot.state);
    }

    fn dequeue(self: *Harness, timeout_ms: u32) !bool {
        var bytes: u32 = 0;
        var key: usize = 0;
        var overlapped: ?*Overlapped = null;
        const succeeded = win32.GetQueuedCompletionStatus(
            self.port.?,
            &bytes,
            &key,
            &overlapped,
            timeout_ms,
        );
        const code = if (succeeded == 0) win32.GetLastError() else 0;
        if (overlapped == null) {
            if (succeeded == 0) {
                try std.testing.expectEqual(timeout_error, code);
                return false;
            }
            try std.testing.expect(!self.accepting);
            try std.testing.expect(!self.stop_seen);
            try std.testing.expectEqual(stop_key, key);
            try std.testing.expectEqual(stop_bytes, bytes);
            self.stop_seen = true;
            return true;
        }
        // A failed dequeue WITH an OVERLAPPED is a terminal I/O failure,
        // unlike a timeout/port failure without one.
        try std.testing.expect(key >= 1 and key <= slot_limit);
        const index = key - 1;
        try std.testing.expectEqual(&self.slots[index].overlapped, overlapped.?);
        self.metrics.packets += 1;
        try self.retire(index, bytes, code);
        return true;
    }

    fn drain(self: *Harness) !void {
        const deadline = win32.GetTickCount64() + 3000;
        while (self.owned != 0 or (!self.accepting and !self.stop_seen)) {
            if (win32.GetTickCount64() >= deadline) return error.DrainWatchdog;
            _ = try self.dequeue(25);
        }
        // All kernel-owned requests are terminal; an extra packet would be
        // an ownership bug. This also catches double handling immediate I/O.
        try std.testing.expect(!try self.dequeue(0));
    }

    fn shutdown(self: *Harness) !void {
        if (self.port == null or self.shutdown_finished) return;
        self.accepting = false;
        if (win32.PostQueuedCompletionStatus(self.port.?, stop_bytes, stop_key, null) == 0)
            return error.PostStopFailed;
        for (&self.slots, 0..) |*slot, index| {
            if (slot.state == .submitted) {
                slot.allow_abort = true;
                try self.cancel(index);
            }
        }
        try self.drain();
        try std.testing.expect(self.stop_seen);
        try std.testing.expectEqual(
            self.metrics.submitted,
            self.metrics.successful + self.metrics.canceled,
        );
        try std.testing.expectEqual(
            self.metrics.submitted,
            self.metrics.direct + self.metrics.packets,
        );
        self.shutdown_finished = true;
    }

    fn deinit(self: *Harness) void {
        self.shutdown() catch |err| {
            // A missing terminal completion cannot be made memory safe by
            // returning and freeing slots. Bound the failure at process scope.
            std.debug.print("IOCP shutdown failed: {s}\n", .{@errorName(err)});
            failFast(78);
        };
        for (&self.slots) |*slot| {
            if (slot.writer) |handle| windows.CloseHandle(handle);
            if (slot.handle) |handle| windows.CloseHandle(handle);
        }
        if (self.port) |port| windows.CloseHandle(port);
    }

    fn reportLoad(
        self: *const Harness,
        fixture: []const u8,
        before: Metrics,
        samples: *[load_rounds]i64,
        elapsed: i64,
    ) void {
        std.mem.sort(i64, samples, {}, std.sort.asc(i64));
        const measured = .{
            .slots = slot_limit,
            .transfer_bytes = transfer_bytes,
            .rounds = load_rounds,
            .bytes = load_rounds * slot_limit * transfer_bytes,
            .elapsed_ns = toNanoseconds(elapsed),
            .bytes_per_s = @divTrunc(
                @as(i128, load_rounds * slot_limit * transfer_bytes) * std.time.ns_per_s,
                @max(1, toNanoseconds(elapsed)),
            ),
            // Nearest-rank percentiles of four-operation cycle latency,
            // including submission, producer writes for pipes, and draining.
            .cycle_p50_ns = toNanoseconds(samples[127]),
            .cycle_p99_ns = toNanoseconds(samples[253]),
            .cycle_max_ns = toNanoseconds(samples[255]),
            .immediate = self.metrics.immediate - before.immediate,
            .pending = self.metrics.pending - before.pending,
            .direct = self.metrics.direct - before.direct,
            .packets = self.metrics.packets - before.packets,
            .checksum = self.metrics.checksum - before.checksum,
        };
        std.debug.print(
            "IOCP {s}: mode={s} build={s} {any}\n",
            .{
                fixture,
                if (self.skip_success) "skip-success" else "default",
                @tagName(builtin.mode),
                measured,
            },
        );
    }
};

fn writePayload(handle: windows.HANDLE, byte: u8) !void {
    const payload: [transfer_bytes]u8 = @splat(byte);
    var written: u32 = 0;
    if (win32.WriteFile(handle, &payload, transfer_bytes, &written, null) == 0)
        return error.WriteFailed;
    try std.testing.expectEqual(transfer_bytes, written);
}

const RacingWriter = struct {
    handle: windows.HANDLE,
    byte: u8,
    failure: ?anyerror = null,

    fn run(self: *RacingWriter) void {
        writePayload(self.handle, self.byte) catch |err| {
            self.failure = err;
        };
    }
};

fn counter() i64 {
    var ticks: i64 = 0;
    std.debug.assert(win32.QueryPerformanceCounter(&ticks) != 0);
    return ticks;
}

fn toNanoseconds(ticks: i64) i128 {
    var frequency: i64 = 0;
    std.debug.assert(win32.QueryPerformanceFrequency(&frequency) != 0);
    return @divTrunc(@as(i128, ticks) * std.time.ns_per_s, frequency);
}

fn exercisePipes(skip_success: bool, threaded: *std.Io.Threaded) !void {
    var harness: Harness = .{ .skip_success = skip_success };
    defer harness.deinit();
    try harness.initPipes(threaded);

    // Prefilled pipe: require actual immediate successes in both policies.
    for (0..slot_limit) |index| {
        try writePayload(harness.slots[index].writer.?, 0x31);
        try harness.submit(index, 0x31, 0, false);
    }
    try harness.drain();
    try std.testing.expect(harness.metrics.immediate > 0);
    if (skip_success) try std.testing.expect(harness.metrics.direct > 0);

    // Submit before writing: pending is required for this empty-pipe fixture.
    for (0..slot_limit) |index| try harness.submit(index, 0x42, 0, false);
    try std.testing.expectEqual(slot_limit, harness.owned);
    try std.testing.expectError(error.CapacityExhausted, harness.submit(0, 0, 0, false));
    for (&harness.slots) |*slot| try writePayload(slot.writer.?, 0x42);
    try harness.drain();

    // Empty pipe cancellation has no normal-success competitor.
    try harness.submit(0, 0, 0, true);
    try harness.cancel(0);
    try harness.drain();
    try std.testing.expect(harness.slots[0].last_aborted);

    // Default policy's TRUE result proves normal completion before cancel,
    // while its packet still owns retirement. Do not infer terminal read
    // status from writer completion or poll the IOCP-deferred status block.
    if (!skip_success) {
        try writePayload(harness.slots[0].writer.?, 0x53);
        const before_immediate = harness.metrics.immediate;
        try harness.submit(0, 0x53, 0, false);
        try std.testing.expectEqual(before_immediate + 1, harness.metrics.immediate);
        try harness.cancel(0);
        try harness.drain();
        try std.testing.expect(!harness.slots[0].last_aborted);
    }

    // Actual competing writer/canceler scheduling. Either outcome is legal;
    // do not require the scheduler to exhibit both. After both actors are
    // terminal, replace this pipe: aborted reads need not leave input intact.
    var raced_success: u32 = 0;
    var raced_cancel: u32 = 0;
    for (0..race_rounds) |round| {
        const byte: u8 = @intCast(round + 0x60);
        try harness.submit(0, byte, 0, true);
        var writer: RacingWriter = .{ .handle = harness.slots[0].writer.?, .byte = byte };
        const thread = try std.Thread.spawn(.{}, RacingWriter.run, .{&writer});
        const canceled = harness.cancel(0);
        thread.join();
        try canceled;
        if (writer.failure) |err| return err;
        try harness.drain();
        if (harness.slots[0].last_aborted) {
            raced_cancel += 1;
        } else {
            raced_success += 1;
        }
        try harness.replacePipe(threaded, 0);
    }
    std.debug.print(
        "IOCP competing races: success={d} canceled={d} attempts={d}\n",
        .{ raced_success, raced_cancel, race_rounds },
    );

    // A bounded workload, not a device throughput ranking. All four empty
    // pipes are pending before 64-byte writes. The outstanding-record count
    // bounds possible undrained data packets; it does not measure kernel depth.
    const before = harness.metrics;
    var samples: [load_rounds]i64 = undefined;
    var expected_checksum: u64 = 0;
    const start = counter();
    for (0..load_rounds) |round| {
        const cycle_start = counter();
        for (0..slot_limit) |index| {
            const byte: u8 = @intCast((round + index) % 251);
            expected_checksum += @as(u64, byte) * transfer_bytes;
            try harness.submit(index, byte, 0, false);
        }
        for (&harness.slots) |*slot| try writePayload(slot.writer.?, slot.expected_byte);
        try harness.drain();
        samples[round] = counter() - cycle_start;
    }
    const elapsed = counter() - start;
    try std.testing.expectEqual(slot_limit, harness.metrics.peak_owned);
    try std.testing.expectEqual(expected_checksum, harness.metrics.checksum - before.checksum);
    harness.reportLoad("named-pipe-load", before, &samples, elapsed);

    // Shutdown starts with genuinely pending reads and posts one distinct
    // control packet. Seeing that packet is not permission to exit the drain.
    for (0..slot_limit) |index| try harness.submit(index, 0, 0, true);
    harness.accepting = false;
    try std.testing.expectError(error.AdmissionClosed, harness.submit(0, 0, 0, false));
    try harness.shutdown();
    std.debug.print(
        "IOCP pipe lifecycle including shutdown: skip_success={} {any}\n",
        .{ skip_success, harness.metrics },
    );
    // deinit closes handles only after the explicit shutdown above completed.
}

fn exerciseFiles(skip_success: bool, dir: std.Io.Dir) !void {
    var harness: Harness = .{ .skip_success = skip_success };
    defer harness.deinit();
    try harness.initFiles(dir);
    const before = harness.metrics;
    var samples: [load_rounds]i64 = undefined;
    var expected_checksum: u64 = 0;
    const start = counter();
    for (0..load_rounds) |round| {
        const cycle_start = counter();
        for (0..slot_limit) |index| {
            const block = (round + index) % slot_limit;
            expected_checksum += (block + 0x20) * transfer_bytes;
            try harness.submit(
                index,
                @intCast(block + 0x20),
                @intCast(block * transfer_bytes),
                false,
            );
        }
        try harness.drain();
        samples[round] = counter() - cycle_start;
    }
    const elapsed = counter() - start;
    try std.testing.expectEqual(expected_checksum, harness.metrics.checksum - before.checksum);
    harness.reportLoad("hot-regular-file-offsets", before, &samples, elapsed);
    // ReadFile may return either immediate success or pending for regular
    // files. The counters state what happened; neither path is fabricated.
    try std.testing.expectEqual(load_rounds * slot_limit, harness.metrics.successful);
    try std.testing.expectEqual(0, harness.metrics.canceled);
}

fn runWindowsProof() !void {
    comptime {
        std.debug.assert(@sizeOf(Overlapped) == if (@sizeOf(usize) == 8) 32 else 20);
        std.debug.assert(@offsetOf(Overlapped, "event") == 2 * @sizeOf(usize) + 8);
    }
    var watchdog: Watchdog = .{};
    const watchdog_thread = try std.Thread.spawn(.{}, Watchdog.run, .{&watchdog});
    defer watchdog_thread.join();
    defer watchdog.done.store(true, .release);

    var threaded: std.Io.Threaded = .init(std.testing.allocator, .{});
    defer threaded.deinit();
    try exercisePipes(false, &threaded);
    try exercisePipes(true, &threaded);

    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    var contents: [slot_limit * transfer_bytes]u8 = undefined;
    for (0..slot_limit) |block| {
        @memset(contents[block * transfer_bytes ..][0..transfer_bytes], @intCast(block + 0x20));
    }
    try temporary.dir.writeFile(std.testing.io, .{ .sub_path = "iocp", .data = &contents });
    try exerciseFiles(false, temporary.dir);
    try exerciseFiles(true, temporary.dir);
}

test "custom IOCP owns immediate, pending, canceled, and shutdown completions within fixed limits" {
    if (builtin.os.tag == .windows) {
        try runWindowsProof();
    } else {
        return error.SkipZigTest;
    }
}
