const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    // Slices are special kind of pointer that reference a continuous subset of elemetns on a sequesnce
    // slices can be thought of as a pair of [*]T (multi item pointer) and a usize(the element count). Their syntax is []T, with T being child type. Slices are used heavily throughout Zig for when you need to operate on arbitrary amounts of data. Slices have the same attributes as pointers, meaning that there also exists const slices. For loops also operate over slices. String literals in Zig coerce to []const u8.

    var array = [5]i32{ 1, 2, 3, 4, 5 };
    var end: usize = 4;
    var slice = array[1..end];
    print("len: {}\n", .{slice.len});
    print("first: {}\n", .{slice[0]});
    for (slice) |elem| {
        print("elem: {}\n", .{elem});
    }

    // All slices must have a runtime-known length. If, instead, their lengths are compile-time known, the compiler will convert the slice into a single-item array pointer for us.

    var ptr: *[3]i32 = array[1..4];
    print("len: {}\n", .{ptr.len});
    print("first: {}\n", .{ptr[0]});
    for (ptr) |elem| {
        print("elem: {}\n", .{elem});
    }
    //In practice, single-item array pointers are just like slices. The only real difference is that with array pointers, bounds checking occurs at compile-time.
}
