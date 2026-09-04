const std = @import("std");

const batch_size_limit: u16 = 256;
const request_count_limit: u32 = 100_000_000;
const sample_count_limit: u8 = 32;

const WorkloadOptions = struct {
    request_count: u32 = 1_000_000,
    batch_size: u16 = 256,
    sample_count: u8 = 5,

    fn validate(options: WorkloadOptions) !void {
        if (options.request_count == 0 or
            options.request_count > request_count_limit)
        {
            return error.InvalidRequestCount;
        }
        if (options.batch_size == 0 or options.batch_size > batch_size_limit) {
            return error.InvalidBatchSize;
        }
        if (options.sample_count == 0 or
            options.sample_count > sample_count_limit)
        {
            return error.InvalidSampleCount;
        }
    }
};

const WorkloadStats = struct {
    request_count: u32,
    batch_count: u32,
    digest: u64,
};

/// The data plane receives dense slices, has no allocator or I/O capability,
/// and contains the regular hot loop. The digest makes all processed values
/// observable to the caller.
fn process_batch(keys: []const u32, values: []const u64) u64 {
    std.debug.assert(keys.len == values.len);
    std.debug.assert(keys.len <= batch_size_limit);

    var digest: u64 = 0;
    for (keys, values) |key, value| {
        const mixed = (@as(u64, key) *% 0x9e3779b185ebca87) ^ value;
        digest +%= mixed;
    }
    return digest;
}

/// The control plane owns admission, finite storage, flush decisions, and the
/// final partial batch. The timed harness calls this with runtime parameters.
fn run_workload(options: WorkloadOptions) !WorkloadStats {
    try options.validate();

    var keys: [batch_size_limit]u32 = undefined;
    var values: [batch_size_limit]u64 = undefined;
    var count: u16 = 0;
    var batch_count: u32 = 0;
    var digest: u64 = 0;

    var request_index: u32 = 0;
    while (request_index < options.request_count) : (request_index += 1) {
        std.debug.assert(count < options.batch_size);
        keys[count] = request_index;
        values[count] = @as(u64, request_index) * 17 + 3;
        count += 1;

        if (count == options.batch_size) {
            digest +%= process_batch(keys[0..count], values[0..count]);
            batch_count += 1;
            count = 0;
        }
    }

    if (count > 0) {
        digest +%= process_batch(keys[0..count], values[0..count]);
        batch_count += 1;
    }

    std.debug.assert(batch_count == divide_round_up(
        options.request_count,
        options.batch_size,
    ));
    return .{
        .request_count = options.request_count,
        .batch_count = batch_count,
        .digest = digest,
    };
}

fn divide_round_up(numerator: u32, denominator: u16) u32 {
    std.debug.assert(denominator > 0);
    return (numerator + denominator - 1) / denominator;
}

/// A worked durable-command-server sketch. Capacity figures are explicit
/// design assumptions, not measurements of the machine running this proof.
const ServerSketch = struct {
    requests_per_second_target: u32 = 20_000,
    request_bytes_max: u32 = 1_024,
    response_bytes_max: u32 = 256,
    journal_bytes_per_request: u32 = 512,
    memory_bytes_touched_per_request: u32 = 2_816,
    batch_size_max: u16 = batch_size_limit,
    batches_in_flight_max: u16 = 16,

    network_bytes_per_second_assumed: u64 = 1_250_000_000,
    disk_bytes_per_second_assumed: u64 = 500_000_000,
    memory_bytes_per_second_assumed: u64 = 20_000_000_000,
    durability_latency_ns_assumed: u64 = 1_000_000,
    cpu_frequency_hz_assumed: u64 = 3_000_000_000,
    cpu_utilization_ppm_max: u32 = 700_000,
    resource_utilization_ppm_max: u32 = 100_000,

    fn calculate(sketch: ServerSketch) Calculated {
        const requests_per_second = @as(u64, sketch.requests_per_second_target);
        const batches_per_second = divide_round_up(
            sketch.requests_per_second_target,
            sketch.batch_size_max,
        );
        const network_bytes_per_second = requests_per_second *
            (sketch.request_bytes_max + sketch.response_bytes_max);
        const disk_bytes_per_second = requests_per_second *
            sketch.journal_bytes_per_request;
        const memory_bytes_per_second = requests_per_second *
            sketch.memory_bytes_touched_per_request;
        const requests_in_flight_max = @as(u64, sketch.batch_size_max) *
            sketch.batches_in_flight_max;

        return .{
            .batches_per_second = batches_per_second,
            .requests_in_flight_max = requests_in_flight_max,
            .reserved_bytes = requests_in_flight_max *
                (sketch.request_bytes_max +
                    sketch.response_bytes_max +
                    sketch.journal_bytes_per_request),
            .network_bytes_per_second = network_bytes_per_second,
            .disk_bytes_per_second = disk_bytes_per_second,
            .memory_bytes_per_second = memory_bytes_per_second,
            .network_utilization_ppm = utilization_ppm(
                network_bytes_per_second,
                sketch.network_bytes_per_second_assumed,
            ),
            .disk_bandwidth_utilization_ppm = utilization_ppm(
                disk_bytes_per_second,
                sketch.disk_bytes_per_second_assumed,
            ),
            .memory_bandwidth_utilization_ppm = utilization_ppm(
                memory_bytes_per_second,
                sketch.memory_bytes_per_second_assumed,
            ),
            .durability_occupancy_ppm = @intCast(
                @as(u64, batches_per_second) *
                    sketch.durability_latency_ns_assumed *
                    1_000_000 /
                    std.time.ns_per_s,
            ),
            .cpu_cycles_per_request_budget = sketch.cpu_frequency_hz_assumed *
                sketch.cpu_utilization_ppm_max /
                1_000_000 /
                requests_per_second,
            .full_batch_fill_ns = @as(u64, sketch.batch_size_max) *
                std.time.ns_per_s /
                requests_per_second,
        };
    }

    fn validate_headroom(sketch: ServerSketch) !void {
        const calculated = sketch.calculate();
        if (calculated.network_utilization_ppm >
            sketch.resource_utilization_ppm_max or
            calculated.disk_bandwidth_utilization_ppm >
                sketch.resource_utilization_ppm_max or
            calculated.memory_bandwidth_utilization_ppm >
                sketch.resource_utilization_ppm_max or
            calculated.durability_occupancy_ppm >
                sketch.resource_utilization_ppm_max)
        {
            return error.InsufficientResourceHeadroom;
        }
    }

    const Calculated = struct {
        batches_per_second: u32,
        requests_in_flight_max: u64,
        reserved_bytes: u64,
        network_bytes_per_second: u64,
        disk_bytes_per_second: u64,
        memory_bytes_per_second: u64,
        network_utilization_ppm: u32,
        disk_bandwidth_utilization_ppm: u32,
        memory_bandwidth_utilization_ppm: u32,
        durability_occupancy_ppm: u32,
        cpu_cycles_per_request_budget: u64,
        full_batch_fill_ns: u64,
    };
};

fn utilization_ppm(demand: u64, capacity: u64) u32 {
    std.debug.assert(capacity > 0);
    return @intCast(demand * 1_000_000 / capacity);
}

fn parse_options(init: std.process.Init) !WorkloadOptions {
    var options: WorkloadOptions = .{};
    var arguments = try std.process.Args.Iterator.initAllocator(
        init.minimal.args,
        init.gpa,
    );
    defer arguments.deinit();

    if (!arguments.skip()) return error.MissingExecutableName;
    while (arguments.next()) |argument| {
        if (std.mem.eql(u8, argument, "--request-count")) {
            const value = arguments.next() orelse return error.MissingArgumentValue;
            options.request_count = try std.fmt.parseInt(u32, value, 10);
        } else if (std.mem.eql(u8, argument, "--batch-size")) {
            const value = arguments.next() orelse return error.MissingArgumentValue;
            options.batch_size = try std.fmt.parseInt(u16, value, 10);
        } else if (std.mem.eql(u8, argument, "--sample-count")) {
            const value = arguments.next() orelse return error.MissingArgumentValue;
            options.sample_count = try std.fmt.parseInt(u8, value, 10);
        } else {
            return error.UnknownArgument;
        }
    }
    try options.validate();
    return options;
}

/// Reproducible benchmark-style entry point. It deliberately has no timing
/// threshold: compare distributions only on a controlled runner. The timed
/// region excludes argument parsing, warm-up, and reporting.
pub fn main(init: std.process.Init) !void {
    const options = try parse_options(init);
    const warmup_options: WorkloadOptions = .{
        .request_count = @min(options.request_count, 10_000),
        .batch_size = options.batch_size,
        .sample_count = 1,
    };
    const warmup = try run_workload(warmup_options);
    std.mem.doNotOptimizeAway(warmup.digest);

    var expected_digest: ?u64 = null;
    for (0..options.sample_count) |sample_index| {
        const started = std.Io.Timestamp.now(init.io, .awake);
        const stats = try run_workload(options);
        const elapsed = started.durationTo(std.Io.Timestamp.now(init.io, .awake));
        std.mem.doNotOptimizeAway(stats.digest);

        if (expected_digest) |digest| {
            std.debug.assert(stats.digest == digest);
        } else {
            expected_digest = stats.digest;
        }
        std.debug.assert(elapsed.toNanoseconds() >= 0);
        const elapsed_ns: u128 = @intCast(elapsed.toNanoseconds());
        const requests_per_second: u128 = if (elapsed_ns == 0)
            0
        else
            @as(u128, stats.request_count) * std.time.ns_per_s / elapsed_ns;

        std.debug.print(
            "sample={d} requests={d} batch_size={d} batches={d} " ++
                "elapsed_ns={d} requests_per_second={d} digest={x}\n",
            .{
                sample_index,
                stats.request_count,
                options.batch_size,
                stats.batch_count,
                elapsed_ns,
                requests_per_second,
                stats.digest,
            },
        );
    }
}

test "batching changes control-plane frequency without changing the witness" {
    const unbatched = try run_workload(.{
        .request_count = 1_000,
        .batch_size = 1,
        .sample_count = 1,
    });
    const batched = try run_workload(.{
        .request_count = 1_000,
        .batch_size = 128,
        .sample_count = 1,
    });

    try std.testing.expectEqual(@as(u32, 1_000), unbatched.batch_count);
    try std.testing.expectEqual(@as(u32, 8), batched.batch_count);
    try std.testing.expectEqual(unbatched.digest, batched.digest);
    try std.testing.expectEqual(@as(u64, 18_012_382_155_497_441_768), batched.digest);
}

test "the quantified sketch exposes limits, utilization, and latency" {
    const sketch: ServerSketch = .{};
    const calculated = sketch.calculate();

    try std.testing.expectEqual(@as(u32, 79), calculated.batches_per_second);
    try std.testing.expectEqual(@as(u64, 4_096), calculated.requests_in_flight_max);
    try std.testing.expectEqual(@as(u64, 7_340_032), calculated.reserved_bytes);
    try std.testing.expectEqual(@as(u64, 25_600_000), calculated.network_bytes_per_second);
    try std.testing.expectEqual(@as(u64, 10_240_000), calculated.disk_bytes_per_second);
    try std.testing.expectEqual(@as(u64, 56_320_000), calculated.memory_bytes_per_second);
    try std.testing.expectEqual(@as(u32, 20_480), calculated.network_utilization_ppm);
    try std.testing.expectEqual(@as(u32, 20_480), calculated.disk_bandwidth_utilization_ppm);
    try std.testing.expectEqual(@as(u32, 2_816), calculated.memory_bandwidth_utilization_ppm);
    try std.testing.expectEqual(@as(u32, 79_000), calculated.durability_occupancy_ppm);
    try std.testing.expectEqual(@as(u64, 105_000), calculated.cpu_cycles_per_request_budget);
    try std.testing.expectEqual(@as(u64, 12_800_000), calculated.full_batch_fill_ns);
    try sketch.validate_headroom();
}

test "the same fixed batch limit rejects an overcommitted durability sketch" {
    const sketch: ServerSketch = .{
        .requests_per_second_target = 100_000,
    };
    const calculated = sketch.calculate();

    try std.testing.expectEqual(@as(u32, 391_000), calculated.durability_occupancy_ppm);
    try std.testing.expectError(
        error.InsufficientResourceHeadroom,
        sketch.validate_headroom(),
    );
}
