const std = @import("std");
const print = std.debug.print;

fn addFive(x: u32) u32 {
    return x + 5;
}

pub fn main() !void {
    const y = addFive(0);
    print("the functions output is {}\n", .{y});
}
// recursive statement
pub fn fibonacci(n: u16) u16 {
    if (n == 0 or n == 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}
