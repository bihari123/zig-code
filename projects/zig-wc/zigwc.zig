const std = @import("std");
const fs = std.fs;
const os = std.os;
const print = std.debug.print;
pub fn main() !void {
    const filePath = "/media/tarun/6D7F-B6EF/GitHub/zig-code/projects/zig-wc/test.txt";

    if (isFileExists(filePath)) {
        print("File {s} Exists\n", .{filePath});
    } else {
        print("File {s} NOT Exists\n", .{filePath});
    }
}

fn isFileExists(filePath: []const u8) bool {
    const file = fs.openFileAbsolute(filePath, .{}) catch |err| switch (err) {
        fs.File.OpenError.FileNotFound => {
            print("File {s} Not Found\n", .{filePath});
            return false;
        },
        else => {
            print("File {s} Not Accessed: \n", .{filePath});
            return false;
        },
    };

    _ = file;
    return true;
}
