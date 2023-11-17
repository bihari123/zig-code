const std = @import("std");
const print = std.debug.print;
const expect = std.testing.expect;

// Zig's enums allow you to define types with restricted set of named values

const Directions = enum { north, south, east, west };

//Enums types may have specified (integer) tag types.

const Value = enum(u2) { zero, one, two };
// we can override the values

const Value2 = enum(u32) {
    hundred = 100,
    thousand = 1000,
    million = 1000,
};
test "set enum ordinal value" {
    try expect(@intFromEnum(Value2.hundred) == 100);
    try expect(@intFromEnum(Value2.thousand) == 1000);
    try expect(@intFromEnum(Value2.million) == 1000000);
    try expect(@intFromEnum(Value2.next) == 1000001);
}

// methods can be given to the enums. These act as namespaced functions that can be called with dot syntax.

const Suit = enum {
    clubs,
    spades,
    diamonds,
    hearts,
    pub fn isClubs(self: Suit) bool {
        return self == Suit.clubs;
    }
};

test "enum method" {
    try expect(Suit.spades.isClubs()) == Suit.isClubs(.spades);
}

// Enums can also be given var and const declarations. these act as namaspaced globals and their values are unrelated and unattached to instances of the enum type.

const Mode = enum {
    var count: u32 = 0;
    on,
    off,
};

test "hmm" {
    Mode.count += 1;
    try expect(Mode.count == 1);
}
