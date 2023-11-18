pub fn isLeapYear(year: u32) bool {

    // @compileError("please implement the isLeapYear function");

    const intType = @TypeOf(year);
    if (@typeInfo(intType) != .Int) {
        @compileError("non-integer type used on leap year: " ++ @typeName(year));
    }
    return (if (@mod(year, @as(intType, 100)) == 0) {
        return @mod(year, @as(intType, 400)) == 0;
    } else {
        return @mod(year, @as(intType, 4)) == 0;
    });
}
