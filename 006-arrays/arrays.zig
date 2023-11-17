const std = @import("std");
const print = std.debug.print;

const a = [5]u8{ 'h', 'e', 'l', 'l', 'o' };
const b = [_]u8{ 'w', 'o', 'l', 'd' };

pub fn main() !void {
    print("\nThe length of the array b is {}\n", .{b.len});

    print("printing the array a\n", .{});
    for (a, 0..) |character, index| { // starting the index from 0
        print("the index is {} and the character is {u}\n", .{ index, character });
    }
    print("printing the array b\n", .{});
    for (b) |character| {
        print("elem: {u}\n", .{character});
    }
}
