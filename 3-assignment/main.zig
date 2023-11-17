const std = @import("std");

pub fn main() void {
    //In Zig, values can be assigned to constants or variables.
    const c: bool = true; //Here, we assign the value true to the bool constant c. Constants are immutable, so the value of c cannot change.
    var v: bool = false; //Here, we assign the value false to the bool variable v. Variables are mutable, so the value of v can change.
    v = true;

    const inferred = true; //Note that the compiler can often infer types for you.

    var u: bool = undefined; //To create an uninitialized constant or variable, assign undefined to it. Using undefined values will result in either a crash or undefined behavior, so be careful!
    u = true;

    _ = c;
    _ = inferred; //Assignments can also be used to ignore expressions.
}
