const std = @import("std");
pub fn isPangram(str: []const u8) bool {
    // @compileError("please implement the isPangram function");

    var letters = std.bit_set.IntegerBitSet(26).initEmpty();

    for (str) |c| {
        if (!std.ascii.isAlphabetic(c)) continue;

        letters.set(std.ascii.toLower(c) - 'a');
    }

    return letters.count() == 26;
}
