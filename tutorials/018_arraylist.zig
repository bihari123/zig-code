const std=@import("std");
pub fn main() !void {

    var gpa=std.heap.GeneralPurposeAllocator(.{}){};
    const allocator=gpa.allocator();

    var buffer=try std.ArrayList(u8).initCapacity(allocator, 100);

    defer buffer.deinit();
    
    try buffer.append("h");
    try buffer.append("e");
    try buffer.appendSlice(" World");

    _=buffer.orderedRemove(3); // preserving the order of the array
    _=buffer.swapRemove(3); // not preserving the order of the array

    try buffer.insert(4,"3");
    try buffer.insertSlice(5,"My tarun");
    }
