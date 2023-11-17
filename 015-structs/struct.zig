const std = @import("std");
const print = std.debug.print;
const expect = std.testing.expect;

const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,
};

test "struct usage" {
    const my_vector = Vec3{
        .x = 0, // all fields must be given a value
        .y = 100,
        .z = 1000,
    };
    _ = my_vector;
}
// fields may be given a defaults

const Vec4 = struct {
    x: f32,
    y: f32,
    z: f32 = 0,
    w: f32 = undefined,
};

test "struct with default" {
    const my_vector = Vec4{ .x = 3, .y = 4 };
    _ = my_vector;
}
//Structs have the unique property that when given a pointer to a struct, one level of dereferencing is done automatically when accessing fields. Notice how, in this example, self.x and self.y are accessed in the swap function without needing to dereference the self pointer.
const Stuff = struct {
    x: i32,
    y: i32,
    fn swap(self: *Stuff) void {
        const tmp = self.x;
        self.x = self.y;
        self.y = tmp;
    }
};

test "automatic dereference" {
    var thing = Stuff{ .x = 10, .y = 20 };
    thing.swap();
    try expect(thing.x == 20);
    try expect(thing.y == 10);
}
