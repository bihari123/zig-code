const std = @import("std");
const print = std.debug.print;
const expect = std.testing.expect;

fn increment(num: *u8) void {
    num.* += 1;
}

pub fn main() !void {
    var x: u8 = 1;
    increment(&x);
    print("the value of x is {}\n", .{x});
}
//Trying to set a *T to the value 0 is detectable illegal behaviour.
test "naughty pointer" {
    var x: u16 = 0;
    var y: *u8 = @ptrFromInt(x);
    _ = y;
}
//Zig also has const pointers, which cannot be used to modify the referenced data. Referencing a const variable will yield a const pointer.
test "const pointers" {
    const x: u8 = 1;
    var y = &x;
    y.* += 1;
}
// Pointer sized integers
//  usize and isize are given as unsigned and signed integers which are the same size as pointers
test "usize" {
    try expect(@sizeOf(usize) == @sizeOf(*u8));
    try expect(@sizeOf(isize) == @sizeOf(*u8));
}

// Many item pointers
// Sometimes, you may have a pointer to an unknown amount of elements. [*]T is the solution for this, which works like *T but also supports indexing syntax, pointer arithmetic, and slicing. Unlike *T, it cannot point to a type which does not have a known size. *T coerces to [*]T.

// These many pointers may point to any amount of elements, including 0 and 1.
