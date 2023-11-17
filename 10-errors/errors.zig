const std = @import("std");

const print = std.debug.print;
const expect = std.testing.expect;
const FileOpenError = error{
    AccessDenied,
    OutOfMemory,
    FileNotFound,
};

// Error unions
// An error set type and another type can be combined with the ! operator to form an error union type. Values of these types may be an error value or a value of the other type.

const maybe_error: FileOpenError!u16 = 10;

const no_error = maybe_error catch 0; // Here catch is used, which is followed by an expression which is evaluated when the value before it is an error. The catch here is used to provide a fallback value, but could instead be a noreturn - the type of return, while (true) and others.

fn failingFunction() error{Oops}!void {
    return error.Oops;
}

pub fn main() !void {
    //Functions often return error unions. Here’s one using a catch, where the |err| syntax receives the value of the error. This is called payload capturing, and is used similarly in many places. We’ll talk about it in more detail later in the chapter. Side note: some languages use similar syntax for lambdas - this is not true for Zig.

    failingFunction() catch |err| {
        try expect(err == error.Oops);
        return;
    };
}
//try x is a shortcut for x catch |err| return err, and is commonly used where handling an error isn’t appropriate. Zig’s try and catch are unrelated to try-catch in other languages.

fn failFn() error{Oops}!i32 {
    try failingFunction();
    return 12;
}
//errdefer works like defer, but only executing when the function is returned from with an error inside of the errdefer’s block.

var problems: u32 = 98;

fn failFnCounter() error{Oops}!void {
    errdefer problems += 1;
    try failingFunction();
}
test "errDefer" {
    failFnCounter() catch |err| {
        try expect(err == error.Oops);
        try expect(problems == 99);
        return;
    };
}
//Error unions returned from a function can have their error sets inferred by not having an explicit error set. This inferred error set contains all possible errors that the function may return.

fn createFile() !void {
    return error.AccessDenied;
}
test "inferred error set" {
    //type coercion successfully takes place
    const x: error{AccessDenied}!void = createFile();
    //Zig does not let us ignore error unions via _ = x;
    //we must unwrap it with "try", "catch", or "if" by any means
    _ = x catch {};
}
// Error set can be merged
const A = error{ NotDir, PathNptFound };
const B = error{ OutOfMemory, PathNotFound };
const C = A || B;
// anyerror is the global error set, which due to being the superset of all error sets, can have an error from any set coerced to it. Its usage should be generally avoided.
