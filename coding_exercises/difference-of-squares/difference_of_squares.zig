const std = @import("std");
const math = std.math;
pub fn squareOfSum(number: usize) usize {
    // @compileError("compute the sum of i from 0 to n then square it");
    return math.pow(usize, (@divExact((number * (number + 1)), 2)), 2);
}

pub fn sumOfSquares(number: usize) usize {
    // @compileError("compute the sum of i^2 from 0 to n");

    const numerator = number * (number + 1) * ((2 * number) + 1);
    return @divExact(numerator, 6);
}

pub fn differenceOfSquares(number: usize) usize {

    // @compileError("compute the difference between the square of sum and sum of squares");

    return (squareOfSum(number) - sumOfSquares(number));
}
