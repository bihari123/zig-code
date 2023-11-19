const std = @import("std");
const ascii = std.ascii;
const print = std.debug.print;
pub fn isValidIsbn10(s: []const u8) bool {
    if (s.len < 10) return false;

    var sum: usize = 0;
    var i: usize = 10;
    for (s) |c| switch (c) {
        '0'...'9' => {
            const num = std.fmt.parseInt(usize, &[_]u8{c}, 10) catch unreachable;
            sum += num * i;
            if (i == 0) return false;
            i -= 1;
        },
        'X' => sum += 10,
        '-' => {},
        else => return false,
    };
    return sum % 11 == 0;
}
