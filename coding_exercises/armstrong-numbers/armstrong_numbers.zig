const std = @import("std");
const math = std.math;
pub fn isArmstrongNumber(num: u128) bool {
    // @compileError("please implement the isArmstrongNumber function");

    if ((num == 0) or (num / 10 == 0)) return true;

    if (num / 100 == 0) return false;

    var sum: u128 = 0;
    var len: usize = 0;
    var arr: [128]u128 = undefined;

    var num2: u128 = num;
    while (num2 > 0) : (num2 = @divFloor(num2, @as(u128, 10))) {
        arr[len] = @mod(num2, @as(u128, 10));

        len += 1;
    }
    var cur = num;
    while (cur != 0) {
        sum += std.math.pow(u128, @mod(cur, 10), len);
        cur = @divFloor(cur, 10);
    }

    return sum == num;
}
pub fn main() !void {
    _ = isArmstrongNumber(153);
}
