pub const DnaError = error{
    EmptyDnaStrands,
    UnequalDnaStrands,
};

pub fn compute(first: []const u8, second: []const u8) DnaError!usize {
    // @compileError("please implement the compute function");

    if ((first.len == 0) or (second.len == 0)) return DnaError.EmptyDnaStrands;

    if (first.len != second.len) return DnaError.UnequalDnaStrands;

    var len: i32 = @intCast(first.len - 1);
    var diff: usize = 0;
    while (len >= 0) : (len -= 1) {
        var point: usize = if (first[@intCast(len)] != second[@intCast(len)]) 1 else 0;
        diff += point;
    }
    return diff;
}
