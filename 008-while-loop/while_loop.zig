const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var i: u8 = 2;
    while (i < 100) {
        i *= 2;
    }
    print("the final value is i is {}\n", .{i});

    var sum = @as(u8, 0);
    var j = @as(u8, 0);

    while (j <= 10) : (j += 1) { // while with continue statement
        sum += j;
    }
    print("the final sum  is {}\n", .{sum});

    var k = @as(u8, 0);
    var sum2 = @as(u8, 0);
    while (k < 3) : (k += 1) {
        if (k == 2) break; // while with break statement
        sum2 += k;
    }

    print("the final sum2  is {}\n", .{sum2});
    var h = @as(u8, 0);
    var sum3 = @as(u8, 0);
    while (h < 3) : (h += 1) {
        if (h == 2) continue;
        sum3 += h;
    }
    print("the final sum3  is {}\n", .{sum3});
}
