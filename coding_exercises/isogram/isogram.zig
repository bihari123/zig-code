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
