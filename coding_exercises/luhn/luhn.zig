const std = @import("std");
const ascii = std.ascii;
pub fn isValid(s: []const u8) bool {
    var sum: usize = 0;
    var index: usize = 0;
    var lenght: usize = s.len - 1;

    for (s) |elem| {
        if (ascii.isWhitespace(elem)) lenght -= 1 else continue;
    }

    if (lenght <= 0) return false;

    for (s) |char| {
        if (ascii.isWhitespace(char)) continue;
        if (!ascii.isDigit(char)) return false;

        var digit: usize = undefined;
        if (@mod(lenght - index, 2) != 0) {
            digit = 2 * (@as(usize, char - '0'));
            if (digit > 9) {
                digit -= 9;
            }
        } else {
            digit = @as(usize, char - '0');
        }

        sum += digit;

        index += 1;
    }
    return @mod(sum, 10) == 0;
}
pub fn main() !void {
    std.debug.print("the input is valid: {any}", .{isValid("59")});
}
