pub const ComputationError = error{IllegalArgument};
pub fn steps(number: usize) ComputationError!usize {
    // _ = number;
    // @compileError("please implement the steps function");

    if (number == 0) {
        return ComputationError.IllegalArgument;
    }

    var count: usize = 0;
    if (number == 1) {
        return count;
    } else if (@mod(number, 2) == 0) {
        count += 1;
        return count + (steps(number / 2) catch |err| {
            return err;
        });
    } else {
        count += 1;
        return count + (steps((3 * number) + 1) catch |err| {
            return err;
        });
    }
}
