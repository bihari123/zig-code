const std = @import("std");
const print = std.debug.print;
pub fn main() !void {
    var x: i8 = 1;
    // simple switch
    switch (x) {
        -1...1 => {
            x = -x;
        },
        10, 100 => {
            x = @divExact(x, 10);
        },
        else => {},
    }
    // switch expressions

    x = switch (x) {
        -1...1 => -x,
        10, 100 => @divExact(x, 10),
        else => x,
    };
}
