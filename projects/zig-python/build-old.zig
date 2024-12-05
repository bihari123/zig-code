const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create a static library for the Python wrapper
    const lib = b.addStaticLibrary(.{
        .name = "emotion_analyzer_lib",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add Python dependencies to the library
    const python_path = b.option(
        []const u8,
        "python-path",
        "Path to Python installation",
    ) orelse "/usr/include/python3.12";

    lib.addIncludePath(.{ .cwd_relative = python_path });
    lib.linkSystemLibrary("python3.12");
    lib.linkLibC();

    b.installArtifact(lib);

    // Create the executable
    const exe = b.addExecutable(.{
        .name = "emotion-analyzer",
        .root_source_file = b.path("src/emotion_wrapper.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Link the executable with our library and Python
    exe.linkLibrary(lib);
    exe.addIncludePath(.{ .cwd_relative = python_path });
    exe.linkSystemLibrary("python3.12");
    exe.linkLibC();

    // Run setup script for Python dependencies if on Unix-like systems
    if (builtin.os.tag != .windows) {
        const setup_cmd = b.addSystemCommand(&[_][]const u8{
            "/bin/sh",
            "-c",
            "python3 -m venv .venv && . .venv/bin/activate && pip install -r requirements.txt",
        });
        b.getInstallStep().dependOn(&setup_cmd.step);
    }

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the emotion analyzer");
    run_step.dependOn(&run_cmd.step);

    // Add unit tests
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/emotion_wrapper.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}
