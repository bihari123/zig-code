const std = @import("std");
const print = std.debug.print;
const expect = std.testing.expect;

// Zig's unions allow you to define types which store one value of many possible typed fields; only one field may be active at one time.

const Result = union {
    int: i64,
    float: f64,
    bool: bool,
};

test "simple union" {
    var result = Result{ .int = 1234 };
    result.float = 12.34; // will give error as float and bool field of result is not active. Only int is active.
}

// to find out the active field, we can use tagged unions. We perform payload capturing on the union to get the value of the field.

const Tagged = union(enum) { a: u8, b: f32, c: bool };

test "switch on tagged unions" {
    var value = Tagged{ .b = 1.5 };
    switch (value) {
        .a => |*byte| byte.* += 1,
        .b => |*float| float.* *= 2,
        .c => |*c| c.* = !c.*,
    }
    try expect(value.b == 3);
}
//void member types can have their type omitted from the syntax. Here, none is of type void.
const Tagged2 = union(enum) { a: u8, b: f32, c: bool, none };
