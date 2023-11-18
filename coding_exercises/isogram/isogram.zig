const std = @import("std");
pub fn isIsogram(str: []const u8) bool {
    // @compileError("please implement the isIsogram function");

    var bits = std.bit_set.IntegerBitSet(26).initEmpty();

    for (str) |char| {
        if (!std.ascii.isAlphabetic(char)) continue;

        if (bits.isSet(std.ascii.toLower(char) - 'a')) {
            return false;
        }
        bits.set(std.ascii.toLower(char) - 'a');
    }
    return true;
}

// alternate solution
// const ascii = @import("std").ascii;
// pub fn isIsogram(str: []const u8) bool {
// var set: u26 = 0; // std.StaticBitSet also works.
// for (str) |c| {
// if (!ascii.isAlphabetic(c)) continue;
// const mask = @as(u26, 1) << @intCast(u5, ascii.toLower(c) - 'a');
// if (set & mask != 0) return false;
// set |= mask;
// }
// return true;
// }
