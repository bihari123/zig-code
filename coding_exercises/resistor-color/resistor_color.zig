const std = @import("std");
pub const ColorBand = enum(usize) {
    black = 0,
    brown = 1,
    red = 2,
    orange = 3,
    yellow = 4,
    green = 5,
    blue = 6,
    violet = 7,
    grey = 8,
    white = 9,

    pub fn getVal(self: ColorBand) usize {
        return @intFromEnum(self);
    }
};

pub fn colorCode(color: ColorBand) usize {
    // @compileError("determine the value of a colorband on a resistor");

    return color.getVal();
}

pub fn colors() []const ColorBand {
    // @compileError("refer to a collection of all resistor colorbands");
    return std.enums.values(ColorBand);
}
