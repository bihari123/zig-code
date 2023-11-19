const std = @import("std");
const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    var bigList = std.ArrayList(u8).init(std.heap.page_allocator);
    defer bigList.deinit();

    var index: u32 = 1;
    while (index < 1000001) : (index += 1) {
        if ((@mod(index, 7) == 0) or @mod(index, 10) == 7) {
            try bigList.writer().print("SMACK\n", .{});
        } else {
            try bigList.writer().print("{d}\n", .{index});
        }
    }

    try prinList(&bigList);
}
fn prinList(list: *std.ArrayList(u8)) !void {
    var iter = std.mem.split(u8, list.items, "\n");
    while (iter.next()) |item| {
        try stdout.print("{s}\n", .{item});
    }
}
