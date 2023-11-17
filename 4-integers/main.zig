const std = @import("std");
const print = std.debug.print;

const a: u8 = 1;
const b: u32 = 10;
const c: i64 = 100;
const d: isize = 1_000;
const e: u21 = 10_000; //Integers in Zig can have arbitrary bit-widths.
const f: 42 = 100_000;
const g: comptime_int = 1_000_000; //Here, we define some compile-time known integers. These have no size limit and can be written as either integer literals or Unicode code point literals.
const h = 10_000_000;
const i = '💯';
pub fn main() !void {
    print("integer: {d}\n", .{i});
    print("unicode: {u}\n", .{i});
}
