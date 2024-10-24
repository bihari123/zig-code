const std = @import("std");
const print = std.debug.print;

const BenchmarkResult = extern struct {
    total_time: f64,
    mean_latency: f64,
    min_latency: f64,
    max_latency: f64,
    throughput: f64,
    items_processed: c_int,
};

extern "c" fn benchmark_cpp(num_consumers: c_int, num_items: c_int, batch_size: c_int) BenchmarkResult;

pub fn main() !void {
    const NUM_CONSUMERS: c_int = 4;
    const NUM_ITEMS: c_int = 1_000_000;
    const BATCH_SIZE: c_int = 1_000;
    const NUM_RUNS: usize = 5;

    print("Running benchmarks with {d} consumers and {d} items...\n", .{ NUM_CONSUMERS, NUM_ITEMS });

    var results = std.ArrayList(BenchmarkResult).init(std.heap.c_allocator);
    defer results.deinit();

    for (0..NUM_RUNS) |i| {
        print("\nRun {d}/{d}:\n\n", .{ i + 1, NUM_RUNS });
        print("C++ SPMC Queue Benchmark Results:\n", .{});

        const result = benchmark_cpp(NUM_CONSUMERS, NUM_ITEMS, BATCH_SIZE);
        try results.append(result);

        print("Total time: {d:.0} microseconds\n", .{result.total_time});
        print("Mean latency: {d:.2} microseconds\n", .{result.mean_latency});
        print("Min latency: {d:.2} microseconds\n", .{result.min_latency});
        print("Max latency: {d:.2} microseconds\n", .{result.max_latency});
        print("Throughput: {d:.2} items/second\n", .{result.throughput});
        print("Items processed: {d}\n", .{result.items_processed});

        std.time.sleep(1 * std.time.ns_per_s);
    }

    var total_throughput: f64 = 0;
    var total_latency: f64 = 0;

    for (results.items) |result| {
        total_throughput += result.throughput;
        total_latency += result.mean_latency;
    }

    const avg_throughput = total_throughput / @as(f64, @floatFromInt(NUM_RUNS));
    const avg_latency = total_latency / @as(f64, @floatFromInt(NUM_RUNS));

    print("\nFinal averaged results across {d} runs:\n", .{NUM_RUNS});
    print("Average throughput: {d:.2} items/second\n", .{avg_throughput});
    print("Average latency: {d:.2} microseconds\n", .{avg_latency});
}
