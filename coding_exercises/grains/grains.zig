const std = @import("std");
const math = std.math;
pub const ChessboardError = error{
    IndexOutOfBounds,
    InvalidIndex,
};

pub fn square(index: usize) ChessboardError!u64 {
    if (index <= 0 or index > 64) return ChessboardError.IndexOutOfBounds;

    if (index == 1) return 1;

    var i: i32 = 1;
    var count: u64 = 1;
    while (i <= index) : (i += 1) {
        if (i == 1) continue;
        count *= 2;
    }

    // @compileError("please implement the square function");
    return count;
}

pub fn total() u64 {
    // @compileError("please implement the total function");

    var index: usize = 1;
    var sum: u64 = 0;
    while (index <= 64) : (index += 1) {
        sum += square(index) catch {
            break;
        };
    }
    return sum;
}
