const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const a = true;
    var x: u16 = 0;

    if (a) {
        x += 1;
    } else {
        x += 2;
    }

    print("the value of x is {}\n", .{x});
    // If statements also work as expressions.

    x += if (a) 1 else 2;
    print("the value of x is {}\n", .{x});
}
