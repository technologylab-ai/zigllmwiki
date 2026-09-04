const std = @import("std");
const builtin = @import("builtin");
const windows = std.os.windows;
const ws = windows.ws2_32;

// One loopback TCP pair, one overlapped file, four stable records, no
// steady-state allocator. Control-plane setup is deliberately synchronous.
// Default IOCP notification policy: even immediate success retires via a packet.
const slot_limit = 4;
const payload_bytes = 1024;
const receive_chunk = 127;
const rounds = 32;
const cycle_limit_ns = 5 * std.time.ns_per_s;
const pending_error = 997;
const incomplete_error = 996;
const aborted_error = 995;
const not_found_error = 1168;
const timeout_error = 258;
const stop_key = std.math.maxInt(usize);
const invalid_socket = std.math.maxInt(usize);

const Overlapped = extern struct {
    internal: usize = 0,
    internal_high: usize = 0,
    offset: u32 = 0,
    offset_high: u32 = 0,
    event: ?windows.HANDLE = null,
};

const Entry = extern struct {
    key: usize,
    overlapped: ?*Overlapped,
    internal_reserved: usize,
    bytes: u32,
};

const Buffer = extern struct { len: u32, ptr: [*]u8 };
// Layout from the exact Zig 0.16 bundled psdk_inc/_wsadata.h.
const WsaData = if (@sizeOf(usize) == 8) extern struct {
    version: u16,
    high_version: u16,
    max_sockets: u16,
    max_udp: u16,
    vendor: ?[*]u8,
    description: [257]u8,
    system_status: [129]u8,
} else extern struct {
    version: u16,
    high_version: u16,
    description: [257]u8,
    system_status: [129]u8,
    max_sockets: u16,
    max_udp: u16,
    vendor: ?[*]u8,
};

const win32 = struct {
    extern "kernel32" fn CreateIoCompletionPort(
        windows.HANDLE,
        ?windows.HANDLE,
        usize,
        u32,
    ) callconv(.winapi) ?windows.HANDLE;
    extern "kernel32" fn GetQueuedCompletionStatusEx(
        windows.HANDLE,
        [*]Entry,
        u32,
        *u32,
        u32,
        i32,
    ) callconv(.winapi) i32;
    extern "kernel32" fn PostQueuedCompletionStatus(
        windows.HANDLE,
        u32,
        usize,
        ?*Overlapped,
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
        *Overlapped,
    ) callconv(.winapi) i32;
    extern "kernel32" fn GetOverlappedResult(
        windows.HANDLE,
        *Overlapped,
        *u32,
        i32,
    ) callconv(.winapi) i32;
    extern "kernel32" fn FlushFileBuffers(windows.HANDLE) callconv(.winapi) i32;
    extern "kernel32" fn CancelIoEx(windows.HANDLE, *Overlapped) callconv(.winapi) i32;
    extern "kernel32" fn GetLastError() callconv(.winapi) u32;
    extern "kernel32" fn GetTickCount64() callconv(.winapi) u64;
    extern "kernel32" fn QueryPerformanceCounter(*i64) callconv(.winapi) i32;
    extern "kernel32" fn QueryPerformanceFrequency(*i64) callconv(.winapi) i32;
    extern "kernel32" fn Sleep(u32) callconv(.winapi) void;
    extern "kernel32" fn GetCurrentProcess() callconv(.winapi) windows.HANDLE;
    extern "kernel32" fn TerminateProcess(windows.HANDLE, u32) callconv(.winapi) i32;
    extern "ws2_32" fn WSAStartup(u16, *WsaData) callconv(.winapi) i32;
    extern "ws2_32" fn WSACleanup() callconv(.winapi) i32;
    extern "ws2_32" fn WSAGetLastError() callconv(.winapi) i32;
    extern "ws2_32" fn WSASocketW(i32, i32, i32, ?*anyopaque, u32, u32) callconv(.winapi) usize;
    extern "ws2_32" fn bind(usize, *const ws.sockaddr, i32) callconv(.winapi) i32;
    extern "ws2_32" fn listen(usize, i32) callconv(.winapi) i32;
    extern "ws2_32" fn getsockname(usize, *ws.sockaddr, *i32) callconv(.winapi) i32;
    extern "ws2_32" fn connect(usize, *const ws.sockaddr, i32) callconv(.winapi) i32;
    extern "ws2_32" fn accept(usize, ?*ws.sockaddr, ?*i32) callconv(.winapi) usize;
    extern "ws2_32" fn closesocket(usize) callconv(.winapi) i32;
    extern "ws2_32" fn shutdown(usize, i32) callconv(.winapi) i32;
    extern "ws2_32" fn WSARecv(
        usize,
        *Buffer,
        u32,
        ?*u32,
        *u32,
        *Overlapped,
        ?*anyopaque,
    ) callconv(.winapi) i32;
    extern "ws2_32" fn WSASend(
        usize,
        *Buffer,
        u32,
        ?*u32,
        u32,
        *Overlapped,
        ?*anyopaque,
    ) callconv(.winapi) i32;
    extern "ws2_32" fn WSAGetOverlappedResult(
        usize,
        *Overlapped,
        *u32,
        i32,
        *u32,
    ) callconv(.winapi) i32;
};

fn failFast(code: u32) noreturn {
    // Do not unwind stack records while kernel ownership may remain. The
    // hosted job timeout is still required for a stuck OS/driver termination.
    if (win32.TerminateProcess(win32.GetCurrentProcess(), code) == 0) @trap();
    unreachable;
}

const Watchdog = struct {
    done: std.atomic.Value(bool) = .init(false),

    fn run(self: *Watchdog) void {
        const deadline = win32.GetTickCount64() + 60_000;
        while (!self.done.load(.acquire)) {
            if (win32.GetTickCount64() >= deadline) failFast(81);
            win32.Sleep(10);
        }
    }
};

const Kind = enum { receive, send, read, write };
const Result = struct { bytes: u32 = 0, code: u32 = 0 };
const Slot = struct {
    overlapped: Overlapped = .{},
    buffer: [payload_bytes]u8 = @splat(0xcc),
    handle: ?windows.HANDLE = null,
    key: usize = 0,
    kind: Kind = .receive,
    submitted: bool = false,
    flags: u32 = 0,
    generation: u32 = 0,
    retired_generation: u32 = 0,
    length: u32 = 0,
    result: Result = .{},
};

const Metrics = struct {
    submitted: u32 = 0,
    immediate: [4]u32 = @splat(0),
    pending: [4]u32 = @splat(0),
    initiation_failed: u32 = 0,
    packets: u32 = 0,
    successful: u32 = 0,
    canceled: u32 = 0,
    other_failures: u32 = 0,
    cancel_accepted: u32 = 0,
    cancel_not_found: u32 = 0,
    dequeue_calls: u32 = 0,
    max_batch: u32 = 0,
    peak_owned: u32 = 0,
    short_receives: u32 = 0,
};

const Harness = struct {
    slots: [slot_limit]Slot = @splat(.{}),
    port: ?windows.HANDLE = null,
    owned: u32 = 0,
    accepting: bool = true,
    stop_posted: bool = false,
    stop_seen: bool = false,
    metrics: Metrics = .{},

    fn init(self: *Harness) !void {
        const invalid: windows.HANDLE = @ptrFromInt(std.math.maxInt(usize));
        self.port = win32.CreateIoCompletionPort(invalid, null, 0, 1) orelse
            return error.CreatePortFailed;
    }

    fn associate(self: *Harness, handle: windows.HANDLE, key: usize) !void {
        try std.testing.expectEqual(
            self.port,
            win32.CreateIoCompletionPort(handle, self.port, key, 0),
        );
    }

    // Zero means accepted and now owned until dequeue; a nonzero OS code
    // means failed initiation and no packet. Neither is a completed payload.
    fn submit(self: *Harness, index: usize, kind: Kind, length: u32, offset: u32) !u32 {
        if (!self.accepting) return error.AdmissionClosed;
        const slot = &self.slots[index];
        if (slot.submitted) return error.CapacityExhausted;
        try std.testing.expect(length > 0 and length <= payload_bytes);
        try std.testing.expectEqual(slot.generation, slot.retired_generation);
        slot.generation += 1;
        slot.overlapped = .{ .offset = offset };
        slot.kind = kind;
        slot.length = length;
        slot.flags = 0;
        slot.result = .{};
        slot.submitted = true;
        self.owned += 1;
        self.metrics.peak_owned = @max(self.metrics.peak_owned, self.owned);
        var buffer: Buffer = .{ .len = length, .ptr = &slot.buffer };
        const immediate = switch (kind) {
            .receive => win32.WSARecv(
                @intFromPtr(slot.handle.?),
                &buffer,
                1,
                null,
                &slot.flags,
                &slot.overlapped,
                null,
            ) == 0,
            .send => win32.WSASend(
                @intFromPtr(slot.handle.?),
                &buffer,
                1,
                null,
                0,
                &slot.overlapped,
                null,
            ) == 0,
            .read => win32.ReadFile(
                slot.handle.?,
                &slot.buffer,
                length,
                null,
                &slot.overlapped,
            ) != 0,
            .write => win32.WriteFile(
                slot.handle.?,
                &slot.buffer,
                length,
                null,
                &slot.overlapped,
            ) != 0,
        };
        const code: u32 = if (immediate) 0 else switch (kind) {
            .receive, .send => @intCast(win32.WSAGetLastError()),
            .read, .write => win32.GetLastError(),
        };
        if (code != 0 and code != pending_error) {
            slot.submitted = false;
            slot.retired_generation = slot.generation;
            self.owned -= 1;
            self.metrics.initiation_failed += 1;
            return code;
        }
        self.metrics.submitted += 1;
        if (immediate) {
            self.metrics.immediate[@intFromEnum(kind)] += 1;
        } else {
            self.metrics.pending[@intFromEnum(kind)] += 1;
        }
        return 0;
    }

    fn cancel(self: *Harness, index: usize) !void {
        const slot = &self.slots[index];
        try std.testing.expect(slot.submitted);
        if (win32.CancelIoEx(slot.handle.?, &slot.overlapped) != 0) {
            self.metrics.cancel_accepted += 1;
        } else {
            try std.testing.expectEqual(not_found_error, win32.GetLastError());
            self.metrics.cancel_not_found += 1;
        }
        try std.testing.expect(slot.submitted);
    }

    fn retire(self: *Harness, entry: Entry) !void {
        const overlapped = entry.overlapped orelse {
            try std.testing.expect(self.stop_posted and !self.stop_seen);
            try std.testing.expectEqual(stop_key, entry.key);
            try std.testing.expectEqual(0, entry.bytes);
            self.stop_seen = true;
            return;
        };
        var matched: ?*Slot = null;
        for (&self.slots) |*slot| {
            if (&slot.overlapped == overlapped) matched = slot;
        }
        const slot = matched orelse return error.UnknownCompletion;
        try std.testing.expect(slot.submitted);
        try std.testing.expectEqual(slot.key, entry.key);
        // GQCSEx success is batch success, not operation success. Internal is
        // reserved. Ask the documented API for EACH operation's terminal code.
        var bytes: u32 = 0;
        var flags: u32 = 0;
        const success = switch (slot.kind) {
            .receive, .send => win32.WSAGetOverlappedResult(
                @intFromPtr(slot.handle.?),
                &slot.overlapped,
                &bytes,
                0,
                &flags,
            ) != 0,
            .read, .write => win32.GetOverlappedResult(
                slot.handle.?,
                &slot.overlapped,
                &bytes,
                0,
            ) != 0,
        };
        const code: u32 = if (success) 0 else switch (slot.kind) {
            .receive, .send => @intCast(win32.WSAGetLastError()),
            .read, .write => win32.GetLastError(),
        };
        if (code == incomplete_error) failFast(82);
        slot.result = .{ .bytes = if (success) bytes else 0, .code = code };
        slot.submitted = false;
        self.owned -= 1;
        slot.retired_generation = slot.generation;
        self.metrics.packets += 1;
        if (success) {
            self.metrics.successful += 1;
            try std.testing.expectEqual(entry.bytes, bytes);
            try std.testing.expect(bytes <= slot.length);
            if (slot.kind == .receive and bytes > 0 and bytes < slot.length)
                self.metrics.short_receives += 1;
        } else if (code == aborted_error) {
            self.metrics.canceled += 1;
        } else {
            self.metrics.other_failures += 1;
        }
        // Error byte outputs are not treated as transferred/rolled-back data.
    }

    fn dequeue(self: *Harness, timeout: u32) !u32 {
        var entries: [slot_limit]Entry = undefined;
        var count: u32 = 0;
        self.metrics.dequeue_calls += 1;
        if (win32.GetQueuedCompletionStatusEx(
            self.port.?,
            &entries,
            slot_limit,
            &count,
            timeout,
            0,
        ) == 0) {
            try std.testing.expectEqual(timeout_error, win32.GetLastError());
            return 0;
        }
        try std.testing.expect(count > 0 and count <= slot_limit);
        self.metrics.max_batch = @max(self.metrics.max_batch, count);
        for (entries[0..count]) |entry| try self.retire(entry);
        return count;
    }

    fn drain(self: *Harness) !void {
        const deadline = win32.GetTickCount64() + 5000;
        while (self.owned != 0 or (self.stop_posted and !self.stop_seen)) {
            if (win32.GetTickCount64() >= deadline) return error.DrainDeadline;
            _ = try self.dequeue(25);
        }
        try std.testing.expectEqual(0, try self.dequeue(0));
    }

    fn shutdown(self: *Harness) !void {
        if (self.port == null or (self.stop_seen and self.owned == 0)) return;
        self.accepting = false;
        if (!self.stop_posted) {
            if (win32.PostQueuedCompletionStatus(self.port.?, 0, stop_key, null) == 0)
                return error.PostStopFailed;
            self.stop_posted = true;
        }
        for (&self.slots, 0..) |*slot, index| {
            if (slot.submitted) try self.cancel(index);
        }
        try self.drain();
        try std.testing.expectEqual(self.metrics.submitted, self.metrics.packets);
        try std.testing.expectEqual(
            self.metrics.packets,
            self.metrics.successful + self.metrics.canceled + self.metrics.other_failures,
        );
    }

    fn deinit(self: *Harness) void {
        self.shutdown() catch |err| {
            std.debug.print("TCP/file shutdown failed: {s}\n", .{@errorName(err)});
            failFast(83);
        };
        if (self.port) |port| windows.CloseHandle(port);
    }
};

fn createSocket() !usize {
    const socket = win32.WSASocketW(ws.AF.INET, ws.SOCK.STREAM, ws.IPPROTO.TCP, null, 0, 1);
    if (socket == invalid_socket) return error.CreateSocketFailed;
    return socket;
}

const Pair = struct {
    client: usize,
    server: usize,

    fn init() !Pair {
        const listener = try createSocket();
        defer _ = win32.closesocket(listener);
        var address: ws.sockaddr.in = .{
            .port = 0,
            .addr = std.mem.nativeToBig(u32, 0x7f000001),
        };
        if (win32.bind(listener, @ptrCast(&address), @sizeOf(@TypeOf(address))) != 0)
            return error.BindFailed;
        if (win32.listen(listener, 1) != 0) return error.ListenFailed;
        var size: i32 = @sizeOf(@TypeOf(address));
        if (win32.getsockname(listener, @ptrCast(&address), &size) != 0)
            return error.SocketNameFailed;
        const client = try createSocket();
        errdefer _ = win32.closesocket(client);
        if (win32.connect(client, @ptrCast(&address), size) != 0) return error.ConnectFailed;
        const server = win32.accept(listener, null, null);
        if (server == invalid_socket) return error.AcceptFailed;
        return .{ .client = client, .server = server };
    }

    fn deinit(self: Pair) void {
        _ = win32.closesocket(self.server);
        _ = win32.closesocket(self.client);
    }
};

fn openFile(dir: std.Io.Dir, write: bool) !windows.HANDLE {
    var name = windows.UNICODE_STRING.init(std.unicode.utf8ToUtf16LeStringLiteral("tcp-file"));
    var block: windows.IO_STATUS_BLOCK = undefined;
    var handle: windows.HANDLE = undefined;
    const status = windows.ntdll.NtOpenFile(
        &handle,
        .{ .STANDARD = .{ .SYNCHRONIZE = true }, .GENERIC = .{ .READ = true, .WRITE = write } },
        &.{ .RootDirectory = dir.handle, .ObjectName = &name },
        &block,
        .{ .READ = true, .WRITE = true },
        .{ .IO = .ASYNCHRONOUS, .NON_DIRECTORY_FILE = true },
    );
    if (status == .PENDING) failFast(84);
    if (status != .SUCCESS) return error.FileOpenFailed;
    return handle;
}

fn accepted(harness: *Harness, index: usize, kind: Kind, length: u32, offset: u32) !void {
    const code = try harness.submit(index, kind, length, offset);
    if (code != 0) {
        std.debug.print("TCP/file {s} initiation error: {d}\n", .{ @tagName(kind), code });
        return error.UnexpectedInitiationFailure;
    }
}

fn successful(slot: *const Slot) !u32 {
    try std.testing.expect(!slot.submitted);
    try std.testing.expectEqual(0, slot.result.code);
    return slot.result.bytes;
}

fn byteAt(round: usize, offset: usize) u8 {
    return @intCast((round * 17 + offset) % 251);
}

fn tcpTransfer(harness: *Harness, round: usize) !void {
    var sent: u32 = 0;
    var received: u32 = 0;
    var submissions: u32 = 0;
    while (received < payload_bytes or sent < payload_bytes) {
        // Positive partial completions make progress; <= 2*payload_bytes
        // submissions suffice even if every completion transfers one byte.
        try std.testing.expect(submissions < 2 * payload_bytes);
        const sending = sent < payload_bytes;
        const receiving = received < payload_bytes;
        if (receiving) {
            try accepted(harness, 0, .receive, @min(receive_chunk, payload_bytes - received), 0);
            submissions += 1;
        }
        if (sending) {
            for (harness.slots[1].buffer[0 .. payload_bytes - sent], 0..) |*byte, i|
                byte.* = byteAt(round, sent + i);
            try accepted(harness, 1, .send, payload_bytes - sent, 0);
            submissions += 1;
        }
        try harness.drain();
        if (sending) {
            const count = try successful(&harness.slots[1]);
            try std.testing.expect(count > 0);
            sent += count;
        }
        if (receiving) {
            const count = try successful(&harness.slots[0]);
            try std.testing.expect(count > 0);
            for (harness.slots[0].buffer[0..count], 0..) |byte, i|
                try std.testing.expectEqual(byteAt(round, received + i), byte);
            @memcpy(
                harness.slots[2].buffer[received..][0..count],
                harness.slots[0].buffer[0..count],
            );
            received += count;
        }
    }
    try std.testing.expectEqual(payload_bytes, sent);
    try std.testing.expectEqual(payload_bytes, received);
}

fn fileTransfer(harness: *Harness, round: usize, checksum: *u64) !void {
    const base: u32 = @intCast(round * payload_bytes);
    var written: u32 = 0;
    while (written < payload_bytes) {
        const remaining = payload_bytes - written;
        // First write uses bytes received from TCP. After a short write, shift
        // the unconsumed tail only after its terminal packet has been drained.
        try accepted(harness, 2, .write, remaining, base + written);
        try harness.drain();
        const count = try successful(&harness.slots[2]);
        try std.testing.expect(count > 0);
        written += count;
        std.mem.copyForwards(u8, &harness.slots[2].buffer, harness.slots[2].buffer[count..]);
    }
    if (win32.FlushFileBuffers(harness.slots[2].handle.?) == 0) return error.FlushFailed;
    var read: u32 = 0;
    while (read < payload_bytes) {
        @memset(&harness.slots[2].buffer, 0xcc);
        try accepted(harness, 2, .read, payload_bytes - read, base + read);
        try harness.drain();
        const count = try successful(&harness.slots[2]);
        try std.testing.expect(count > 0);
        for (harness.slots[2].buffer[0..count], 0..) |byte, i| {
            try std.testing.expectEqual(byteAt(round, read + i), byte);
            checksum.* += byte;
        }
        read += count;
    }
}

fn counter() i64 {
    var ticks: i64 = 0;
    std.debug.assert(win32.QueryPerformanceCounter(&ticks) != 0);
    return ticks;
}

fn nanoseconds(ticks: i64) i128 {
    var frequency: i64 = 0;
    std.debug.assert(win32.QueryPerformanceFrequency(&frequency) != 0);
    return @divTrunc(@as(i128, ticks) * std.time.ns_per_s, frequency);
}

fn exercise(harness: *Harness, pair: Pair) !void {
    var samples: [rounds]i64 = undefined;
    var checksum: u64 = 0;
    const started = counter();
    for (0..rounds) |round| {
        const cycle = counter();
        try tcpTransfer(harness, round);
        try fileTransfer(harness, round, &checksum);
        samples[round] = counter() - cycle;
    }
    const elapsed = counter() - started;
    var expected_checksum: u64 = 0;
    for (0..rounds) |round| {
        for (0..payload_bytes) |offset| expected_checksum += byteAt(round, offset);
    }
    try std.testing.expectEqual(expected_checksum, checksum);
    std.mem.sort(i64, &samples, {}, std.sort.asc(i64));
    // This is a generous fixture progress criterion, not a deployment SLO.
    try std.testing.expect(nanoseconds(samples[31]) < cycle_limit_ns);
    std.debug.print("IOCP TCP-to-file: build={s} {any}\n", .{ @tagName(builtin.mode), .{
        .rounds = rounds,
        .payload_bytes = payload_bytes,
        .receive_chunk = receive_chunk,
        .working_set_bytes = rounds * payload_bytes,
        .elapsed_ns = nanoseconds(elapsed),
        .bytes_per_second = @divTrunc(
            @as(i128, rounds * payload_bytes) * std.time.ns_per_s,
            @max(1, nanoseconds(elapsed)),
        ),
        .cycle_p50_ns = nanoseconds(samples[15]),
        .cycle_p99_ns = nanoseconds(samples[31]),
        .cycle_max_ns = nanoseconds(samples[31]),
        .checksum = checksum,
    } });

    // Accepted empty receive proves genuine pending work and a per-entry
    // failed result. This does not use APC alerts or Threaded.batchCancel.
    const before_pending = harness.metrics.pending[@intFromEnum(Kind.receive)];
    try accepted(harness, 0, .receive, 1, 0);
    try std.testing.expectEqual(
        before_pending + 1,
        harness.metrics.pending[@intFromEnum(Kind.receive)],
    );
    try std.testing.expectError(error.CapacityExhausted, harness.submit(0, .receive, 1, 0));
    try harness.cancel(0);
    try harness.drain();
    try std.testing.expectEqual(aborted_error, harness.slots[0].result.code);

    // Real regular-file cancel races; neither immediate returns nor a winning
    // cancellation are required from this filesystem/cache/scheduler.
    var race_success: [2]u32 = @splat(0);
    var race_aborted: [2]u32 = @splat(0);
    for (0..rounds) |_| {
        for ([_]Kind{ .read, .write }, 0..) |kind, i| {
            @memset(&harness.slots[2].buffer, 0x5a);
            const offset: u32 = if (kind == .read) 0 else rounds * payload_bytes;
            try accepted(harness, 2, kind, payload_bytes, offset);
            try harness.cancel(2);
            try harness.drain();
            const result = harness.slots[2].result;
            if (result.code == aborted_error) {
                race_aborted[i] += 1;
            } else {
                try std.testing.expectEqual(0, result.code);
                try std.testing.expectEqual(payload_bytes, result.bytes);
                if (kind == .read) {
                    for (harness.slots[2].buffer, 0..) |byte, byte_offset|
                        try std.testing.expectEqual(byteAt(0, byte_offset), byte);
                }
                race_success[i] += 1;
            }
        }
    }
    std.debug.print("IOCP file cancel races: read/write success={any} aborted={any}\n", .{
        race_success, race_aborted,
    });

    // Read-only file access produces a failed initiation with no packet.
    const before = harness.metrics.packets;
    try std.testing.expectEqual(5, try harness.submit(3, .write, 1, 0));
    try harness.drain();
    try std.testing.expectEqual(before, harness.metrics.packets);

    // EOF is an expected file failure, possibly immediate or in a packet.
    const eof_code = try harness.submit(2, .read, 1, (rounds + 2) * payload_bytes);
    if (eof_code == 0) {
        try harness.drain();
        try std.testing.expectEqual(38, harness.slots[2].result.code);
    } else {
        try std.testing.expectEqual(38, eof_code);
    }
    if (win32.shutdown(pair.client, 1) != 0) return error.SocketShutdownFailed;
    try accepted(harness, 0, .receive, 1, 0);
    try harness.drain();
    try std.testing.expectEqual(0, try successful(&harness.slots[0]));

    // Client's receive direction remains open: stop with TWO pending reads.
    // Retain slots, sockets, file and port until both aborted packets drain;
    // a stop packet arriving first is never permission to free their storage.
    harness.slots[0].handle = @ptrFromInt(pair.client);
    harness.slots[0].key = 2;
    harness.slots[1].handle = @ptrFromInt(pair.client);
    harness.slots[1].key = 2;
    try accepted(harness, 0, .receive, 1, 0);
    try accepted(harness, 1, .receive, 1, 0);
    harness.accepting = false;
    try std.testing.expectError(error.AdmissionClosed, harness.submit(2, .read, 1, 0));
    try harness.shutdown();
    try std.testing.expectEqual(aborted_error, harness.slots[0].result.code);
    try std.testing.expectEqual(aborted_error, harness.slots[1].result.code);
    std.debug.print("IOCP TCP/file lifecycle (kind order receive/send/read/write): {any}\n", .{
        harness.metrics,
    });
}

fn runWindowsProof() !void {
    comptime {
        std.debug.assert(@sizeOf(Overlapped) == if (@sizeOf(usize) == 8) 32 else 20);
        std.debug.assert(@sizeOf(Entry) == if (@sizeOf(usize) == 8) 32 else 16);
        std.debug.assert(@sizeOf(WsaData) == if (@sizeOf(usize) == 8) 408 else 400);
    }
    var watchdog: Watchdog = .{};
    const thread = try std.Thread.spawn(.{}, Watchdog.run, .{&watchdog});
    defer thread.join();
    defer watchdog.done.store(true, .release);
    var wsa_data: WsaData = undefined;
    try std.testing.expectEqual(0, win32.WSAStartup(0x0202, &wsa_data));
    defer _ = win32.WSACleanup();
    try std.testing.expectEqual(0x0202, wsa_data.version);

    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    try temporary.dir.writeFile(std.testing.io, .{ .sub_path = "tcp-file", .data = "" });
    const file = try openFile(temporary.dir, true);
    defer windows.CloseHandle(file);
    const read_only = try openFile(temporary.dir, false);
    defer windows.CloseHandle(read_only);
    const pair = try Pair.init();
    defer pair.deinit();
    var harness: Harness = .{};
    // This defer runs BEFORE handle/WSA/temporary cleanup, even on failure.
    defer harness.deinit();
    try harness.init();
    try harness.associate(@ptrFromInt(pair.server), 1);
    try harness.associate(@ptrFromInt(pair.client), 2);
    try harness.associate(file, 3);
    try harness.associate(read_only, 4);
    harness.slots[0].handle = @ptrFromInt(pair.server);
    harness.slots[0].key = 1;
    harness.slots[1].handle = @ptrFromInt(pair.client);
    harness.slots[1].key = 2;
    harness.slots[2].handle = file;
    harness.slots[2].key = 3;
    harness.slots[3].handle = read_only;
    harness.slots[3].key = 4;
    try exercise(&harness, pair);
}

test "bounded IOCP TCP-to-file pipeline reconciles batched results and independent shutdown" {
    if (builtin.os.tag == .windows) {
        try runWindowsProof();
    } else {
        return error.SkipZigTest;
    }
}
