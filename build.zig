const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lint_command = b.addSystemCommand(&.{
        "python3",
        "tools/lint_wiki.py",
    });
    const graph_command = b.addSystemCommand(&.{
        "python3",
        "tools/lint_wiki.py",
        "--graph-report",
    });
    const fmt_command = b.addSystemCommand(&.{
        "zig",
        "fmt",
        "--check",
        "build.zig",
        "proofs",
    });

    const test_step = b.step("test", "Run executable knowledge proofs");
    const lint_step = b.step("lint", "Check wiki schema, links, and version");
    lint_step.dependOn(&lint_command.step);
    lint_step.dependOn(&fmt_command.step);

    const graph_step = b.step("graph", "Emit JSON graph and backlink health");
    graph_step.dependOn(&graph_command.step);

    const verify_step = b.step("verify", "Verify wiki and all Zig proofs");
    verify_step.dependOn(&lint_command.step);
    verify_step.dependOn(&fmt_command.step);

    const generated_code_command = b.addSystemCommand(&.{
        "python3",
        "tools/inspect_generated_code.py",
        "--source",
        "proofs/error_path_catalog.zig",
        "--symbol",
        "bounded_sum_u32",
        "--output-dir",
        ".zig-cache/generated-code",
        "--optimize",
        "ReleaseSafe",
    });
    verify_step.dependOn(&generated_code_command.step);

    const proof_sources = [_][]const u8{
        "proofs/async_vs_concurrent.zig",
        "proofs/bounded_retries.zig",
        "proofs/cancellation.zig",
        "proofs/control_flow_shape.zig",
        "proofs/diagnostics_factory.zig",
        "proofs/error_path_catalog.zig",
        "proofs/error_context.zig",
        "proofs/files_and_atomic_persistence.zig",
        "proofs/fmt_steering.zig",
        "proofs/integer_boundaries.zig",
        "proofs/invariants.zig",
        "proofs/io_sync_primitives.zig",
        "proofs/io_time.zig",
        "proofs/linux_io_uring.zig",
        "proofs/network_process_entropy.zig",
        "proofs/newtype_index.zig",
        "proofs/performance_sketch.zig",
        "proofs/persistence_assertion_pair.zig",
        "proofs/process_init_capabilities.zig",
        "proofs/select_and_batch.zig",
        "proofs/static_pool.zig",
        "proofs/state_lifetime_and_arithmetic.zig",
        "proofs/testing_io_modes.zig",
        "proofs/threaded_blocked_read_cancel_linux.zig",
        "proofs/threaded_blocked_read_cancel_macos.zig",
        "proofs/threaded_blocked_read_cancel_windows.zig",
        "proofs/windows_io_mapping.zig",
        "proofs/windows_apc_batch.zig",
        "proofs/windows_iocp_lifecycle.zig",
        "proofs/windows_iocp_tcp_file.zig",
    };
    for (proof_sources) |proof_source| {
        const proof_module = b.createModule(.{
            .root_source_file = b.path(proof_source),
            .target = target,
            .optimize = optimize,
        });
        const proof_tests = b.addTest(.{ .root_module = proof_module });
        const run_proof_tests = b.addRunArtifact(proof_tests);
        test_step.dependOn(&run_proof_tests.step);
        verify_step.dependOn(&run_proof_tests.step);
    }

    const windows_architectures = [_]std.Target.Cpu.Arch{
        .x86,
        .x86_64,
        .aarch64,
    };
    const windows_proof_sources = [_][]const u8{
        "proofs/windows_io_mapping.zig",
        "proofs/threaded_blocked_read_cancel_windows.zig",
        "proofs/windows_apc_batch.zig",
        "proofs/windows_iocp_lifecycle.zig",
        "proofs/windows_iocp_tcp_file.zig",
    };
    for (windows_architectures) |architecture| {
        for (windows_proof_sources) |proof_source| {
            const windows_module = b.createModule(.{
                .root_source_file = b.path(proof_source),
                .target = b.resolveTargetQuery(.{
                    .cpu_arch = architecture,
                    .os_tag = .windows,
                }),
                .optimize = optimize,
            });
            const windows_tests = b.addTest(.{ .root_module = windows_module });
            verify_step.dependOn(&windows_tests.step);
        }
    }

    const single_threaded_testing_module = b.createModule(.{
        .root_source_file = b.path("proofs/testing_io_modes.zig"),
        .target = target,
        .optimize = optimize,
        .single_threaded = true,
    });
    const single_threaded_testing_tests = b.addTest(.{
        .root_module = single_threaded_testing_module,
    });
    const run_single_threaded_testing_tests = b.addRunArtifact(single_threaded_testing_tests);
    test_step.dependOn(&run_single_threaded_testing_tests.step);
    verify_step.dependOn(&run_single_threaded_testing_tests.step);

    const macos_dispatch_module = b.createModule(.{
        .root_source_file = b.path("proofs/macos_dispatch_io.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = target.result.os.tag == .macos,
    });
    if (target.result.os.tag == .macos) {
        macos_dispatch_module.addCSourceFile(.{
            .file = b.path("proofs/macos_dispatch_io_shim.c"),
            .flags = &.{ "-fblocks", "-Wall", "-Wextra", "-Werror" },
        });
    }
    const macos_dispatch_tests = b.addTest(.{
        .root_module = macos_dispatch_module,
    });
    const run_macos_dispatch_tests = b.addRunArtifact(macos_dispatch_tests);
    test_step.dependOn(&run_macos_dispatch_tests.step);
    verify_step.dependOn(&run_macos_dispatch_tests.step);

    const performance_module = b.createModule(.{
        .root_source_file = b.path("proofs/performance_sketch.zig"),
        .target = target,
        .optimize = optimize,
    });
    const performance_executable = b.addExecutable(.{
        .name = "performance-sketch",
        .root_module = performance_module,
    });
    const run_performance_executable = b.addRunArtifact(performance_executable);
    run_performance_executable.addArgs(&.{
        "--request-count",
        "100000",
        "--batch-size",
        "256",
        "--sample-count",
        "2",
    });
    verify_step.dependOn(&run_performance_executable.step);

    const process_init_module = b.createModule(.{
        .root_source_file = b.path("proofs/process_init_capabilities.zig"),
        .target = target,
        .optimize = optimize,
    });
    const process_init_executable = b.addExecutable(.{
        .name = "process-init-capabilities",
        .root_module = process_init_module,
    });
    const run_process_init = b.addRunArtifact(process_init_executable);
    verify_step.dependOn(&run_process_init.step);
}
