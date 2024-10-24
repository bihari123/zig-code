const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Build options
    const options = b.addOptions();
    options.addOption(bool, "enable_thread_local_storage", true);
    options.addOption(bool, "enable_prefetch", true);

    // Main executable
    const exe = b.addExecutable(.{
        .name = "spmc-benchmark",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add build options to executable
    exe.root_module.addOptions("build_options", options);

    // Install the executable
    b.installArtifact(exe);

    // Create run command
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // Add standard run step
    const run_step = b.step("run", "Run the benchmark");
    run_step.dependOn(&run_cmd.step);

    // Add optimized benchmark step
    const bench_cmd = b.addRunArtifact(exe);
    bench_cmd.step.dependOn(b.getInstallStep());

    // Configure benchmark-specific settings
    bench_cmd.has_side_effects = true;

    const bench_step = b.step("bench", "Run optimized benchmark");
    bench_step.dependOn(&bench_cmd.step);

    // Unit tests
    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
