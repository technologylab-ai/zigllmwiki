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

    const proof_sources = [_][]const u8{
        "proofs/async_vs_concurrent.zig",
        "proofs/cancellation.zig",
        "proofs/diagnostics_factory.zig",
        "proofs/error_context.zig",
        "proofs/fmt_steering.zig",
        "proofs/invariants.zig",
        "proofs/io_sync_primitives.zig",
        "proofs/newtype_index.zig",
        "proofs/process_init_capabilities.zig",
        "proofs/select_and_batch.zig",
        "proofs/static_pool.zig",
        "proofs/threaded_blocked_read_cancel_macos.zig",
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
