const std = @import("std");
const fs = std.fs;
const os = std.os;
const print = std.debug.print;

const fileInfo = union(enum) { exists: bool, bytes: usize, lines: usize, err: fs.File.OpenError };

fn getFileInfo(filePath: []const u8) fileInfo {
    const file = fs.openFileAbsolute(filePath, .{}) catch |err| switch (err) {
        fs.File.OpenError.FileNotFound => {
            return fileInfo{ .exists = false };
        },
        else => {
            return fileInfo{ .err = err };
        },
    };
    defer file.close();
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const fileContent = file.readToEndAlloc(allocator, comptime std.math.maxInt(usize)) catch {
        return fileInfo{ .err = fs.File.OpenError.Unexpected };
    };
    defer allocator.free(fileContent);
    return fileInfo{ .bytes = fileContent.len };
}
pub fn main() !void {
    const filePath = "/media/tarun/6D7F-B6EF/GitHub/zig-code/projects/zig-wc/test.txt";

    const fileInfoValues = getFileInfo(filePath);
    switch (fileInfoValues) {
        .err => print("Error accessing the file: {s}.  \n", .{filePath}),
        .exists => |*exists| if (!exists.*) {
            print("File {s} Not Exists\n", .{filePath});
        },
        .bytes => |*bytes| print("The bytes are {}\n", .{bytes.*}),
        .lines => {},
    }
}
