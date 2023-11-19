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

pub fn colorCode(colors: [2]ColorBand) usize {
    return colors[0].getVal() * 10 + colors[1].getVal();
}
