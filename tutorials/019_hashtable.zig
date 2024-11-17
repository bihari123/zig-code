const std = @import("std");
const AutoHashMap = std.hash_map.AutoHashMap;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var hash_table = AutoHashMap(u32, u16).init(allocator);
    defer hash_table.deinit();

    try hash_table.put(1233, 1);
    try hash_table.put(123244, 4);
    if (hash_table.remove(1233)) {
        std.debug.print("value {any} is removed", .{1233});
    }

    var it = hash_table.iterator();

    while (it.next()) |kv| {
        std.debug.print("\nkey {d}\t value {d}", .{ kv.key_ptr.*, kv.value_ptr.* });
    }
}
