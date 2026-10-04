const builtin = @import("builtin");
const std = @import("std");

const NativeChannel = opaque {};

extern fn zigllm_dispatch_io_open_random(
    absolute_path: [*:0]const u8,
) ?*NativeChannel;
extern fn zigllm_dispatch_io_read(
    channel: *NativeChannel,
    offset: i64,
    buffer: [*]u8,
    length: usize,
    bytes_read: *usize,
) c_int;
extern fn zigllm_dispatch_io_close(channel: *NativeChannel) void;

/// Minimal Zig ownership adapter for the proof. It intentionally does not
/// claim to be a complete std.Io backend: the C boundary synchronously joins
/// one asynchronous Dispatch I/O read, keeping the caller buffer borrowed
/// until the terminal handler.
const DispatchFile = struct {
    channel: *NativeChannel,

    const ReadError = error{
        DispatchIoFailure,
    };

    fn open(absolute_path: [:0]const u8) error{SystemResources}!DispatchFile {
        return .{
            .channel = zigllm_dispatch_io_open_random(absolute_path.ptr) orelse
                return error.SystemResources,
        };
    }

    fn close(file: *DispatchFile) void {
        zigllm_dispatch_io_close(file.channel);
        file.* = undefined;
    }

    fn read(
        file: *DispatchFile,
        buffer: []u8,
        offset: i64,
    ) ReadError!usize {
        var bytes_read: usize = undefined;
        const error_code = zigllm_dispatch_io_read(
            file.channel,
            offset,
            buffer.ptr,
            buffer.len,
            &bytes_read,
        );
        if (error_code != 0) return error.DispatchIoFailure;
        return bytes_read;
    }
};

fn benchmarkStdIo(
    clock_io: std.Io,
    operation_io: std.Io,
    file: std.Io.File,
    buffer: []u8,
    iterations: usize,
) !std.Io.Duration {
    _ = try file.readPositionalAll(operation_io, buffer, 0);
    const started = std.Io.Timestamp.now(clock_io, .awake);
    for (0..iterations) |_| {
        const bytes_read = try file.readPositionalAll(operation_io, buffer, 0);
        if (bytes_read != buffer.len) return error.ShortRead;
        std.mem.doNotOptimizeAway(buffer[bytes_read - 1]);
    }
    return started.durationTo(std.Io.Timestamp.now(clock_io, .awake));
}

fn benchmarkDispatchIo(
    clock_io: std.Io,
    file: *DispatchFile,
    buffer: []u8,
    iterations: usize,
) !std.Io.Duration {
    _ = try file.read(buffer, 0);
    const started = std.Io.Timestamp.now(clock_io, .awake);
    for (0..iterations) |_| {
        const bytes_read = try file.read(buffer, 0);
        if (bytes_read != buffer.len) return error.ShortRead;
        std.mem.doNotOptimizeAway(buffer[bytes_read - 1]);
    }
    return started.durationTo(std.Io.Timestamp.now(clock_io, .awake));
}

/// Deliberate, local hot-cache comparison. It measures synchronous joins of
/// equal-size positional reads; it is not evidence about cold storage,
/// concurrent queue depth, tail latency, writes, or durability.
pub fn main(init: std.process.Init) !void {
    if (builtin.mode != .safe) return error.PerformanceRequiresReleaseSafe;
    if (builtin.os.tag != .macos) return error.UnsupportedPlatform;

    const file_size = 1024 * 1024;
    const iterations = 64;
    const payload = try init.gpa.alloc(u8, file_size);
    defer init.gpa.free(payload);
    for (payload, 0..) |*byte, index| byte.* = @truncate(index);
    const buffer = try init.gpa.alloc(u8, file_size);
    defer init.gpa.free(buffer);

    var path_buffer: [256]u8 = undefined;
    const path = try std.fmt.bufPrintZ(
        &path_buffer,
        "/tmp/zigllmwiki-macos-io-{d}",
        .{std.c.getpid()},
    );
    std.Io.Dir.deleteFileAbsolute(init.io, path) catch {};
    defer std.Io.Dir.deleteFileAbsolute(init.io, path) catch {};
    try std.Io.Dir.cwd().writeFile(init.io, .{
        .sub_path = path,
        .data = payload,
        .flags = .{ .exclusive = true },
    });

    var threaded_file = try std.Io.Dir.openFileAbsolute(init.io, path, .{});
    defer threaded_file.close(init.io);

    var native_dispatch = try DispatchFile.open(path);
    defer native_dispatch.close();

    const threaded_elapsed = try benchmarkStdIo(
        init.io,
        init.io,
        threaded_file,
        buffer,
        iterations,
    );
    const native_elapsed = try benchmarkDispatchIo(
        init.io,
        &native_dispatch,
        buffer,
        iterations,
    );

    std.debug.print(
        "hot-cache positional read: {d} x {d} bytes\n" ++
            "std.Io.Threaded: {d} ns\n" ++
            "Apple Dispatch I/O joined by shim: {d} ns\n",
        .{
            iterations,
            file_size,
            threaded_elapsed.toNanoseconds(),
            native_elapsed.toNanoseconds(),
        },
    );
}

test "Zig 0.17 reads a regular file through Apple Dispatch I/O" {
    if (builtin.os.tag != .macos) return error.SkipZigTest;

    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();

    const expected = "dispatch I/O keeps this buffer alive through completion";
    try temporary.dir.writeFile(std.testing.io, .{
        .sub_path = "payload",
        .data = expected,
    });
    const absolute_path = try temporary.dir.realPathFileAlloc(
        std.testing.io,
        "payload",
        std.testing.allocator,
    );
    defer std.testing.allocator.free(absolute_path);

    var file = try DispatchFile.open(absolute_path);
    defer file.close();

    var buffer: [expected.len]u8 = undefined;
    const bytes_read = try file.read(&buffer, 0);
    try std.testing.expectEqual(expected.len, bytes_read);
    try std.testing.expectEqualStrings(expected, &buffer);
}

test "Zig 0.17 macOS Evented selects the source-blocked Dispatch type" {
    if (builtin.os.tag != .macos) return error.SkipZigTest;
    comptime {
        std.debug.assert(std.Io.Evented == std.Io.Dispatch);
        std.debug.assert(@hasDecl(std.Io.Dispatch, "init"));
        std.debug.assert(@hasDecl(std.Io.Dispatch, "deinit"));
        std.debug.assert(@hasDecl(std.Io.Dispatch, "io"));
        const init_type = @typeInfo(@TypeOf(std.Io.Dispatch.init)).@"fn";
        std.debug.assert(init_type.param_types[0].? == *std.Io.Dispatch);
        std.debug.assert(init_type.param_types[1].? == std.mem.Allocator);
        std.debug.assert(init_type.param_types[2].? == std.Io.Dispatch.InitOptions);
        const io_type = @typeInfo(@TypeOf(std.Io.Dispatch.io)).@"fn";
        std.debug.assert(io_type.param_types[0].? == *std.Io.Dispatch);
        std.debug.assert(io_type.return_type.? == std.Io);
        const deinit_type = @typeInfo(@TypeOf(std.Io.Dispatch.deinit)).@"fn";
        std.debug.assert(deinit_type.param_types[0].? == *std.Io.Dispatch);
        std.debug.assert(deinit_type.return_type.? == void);
    }
    // Function signatures do not prove their lazily analyzed bodies compile.
    // The separate negative witness invokes both init() and io().
}
