const std = @import("std");
const builtin = @import("builtin");
const print = std.debug.print;
const Mutex = std.Thread.Mutex;
const Condition = std.Thread.Condition;

comptime {
    @setRuntimeSafety(false);
}

pub fn SPMCQueue(comptime T: type) type {
    return struct {
        const Self = @This();

        queue: std.fifo.LinearFifo(T, .Dynamic),
        mutex: Mutex,
        not_empty: Condition,
        done: std.atomic.Value(bool),
        max_size: usize,

        pub fn init(allocator: std.mem.Allocator, max_size: usize) !Self {
            var fifo = std.fifo.LinearFifo(T, .Dynamic).init(allocator);
            try fifo.ensureTotalCapacity(max_size);

            return Self{
                .queue = fifo,
                .mutex = .{},
                .not_empty = .{},
                .done = std.atomic.Value(bool).init(false),
                .max_size = max_size,
            };
        }

        pub fn deinit(self: *Self) void {
            self.queue.deinit();
        }

        pub inline fn push(self: *Self, value: T) !void {
            self.mutex.lock();
            defer {
                self.mutex.unlock();
                self.not_empty.signal();
            }

            while (self.queue.count >= self.max_size) {
                self.not_empty.wait(&self.mutex);
            }
            try self.queue.writeItem(value);
        }

        pub inline fn pop(self: *Self) ?T {
            self.mutex.lock();
            defer {
                self.mutex.unlock();
                self.not_empty.signal();
            }

            while (true) {
                if (self.queue.readItem()) |value| {
                    return value;
                }

                if (self.done.load(.acquire)) {
                    if (self.queue.count == 0) {
                        return null;
                    }
                }
                self.not_empty.wait(&self.mutex);
            }
        }

        pub fn setDone(self: *Self) void {
            _ = self.done.store(true, .release);
            self.not_empty.broadcast();
        }
    };
}

const BenchmarkStats = struct {
    mean_latency: f64,
    min_latency: f64,
    max_latency: f64,
    throughput: f64,
    latencies: []f64,

    pub fn deinit(self: *BenchmarkStats, allocator: std.mem.Allocator) void {
        allocator.free(self.latencies);
    }
};

fn benchmarkZig(
    allocator: std.mem.Allocator,
    num_consumers: usize,
    num_items: usize,
    batch_size: usize,
) !BenchmarkStats {
    var queue = try SPMCQueue(i32).init(allocator, batch_size);
    defer queue.deinit();

    var items_processed = std.atomic.Value(usize).init(0);
    var latencies = std.ArrayList(f64).init(allocator);
    defer latencies.deinit();

    var latencies_mutex = Mutex{};

    const start_time = std.time.nanoTimestamp();

    // Start consumers
    var consumers = std.ArrayList(std.Thread).init(allocator);
    defer consumers.deinit();

    const Consumer = struct {
        fn run(
            q: *SPMCQueue(i32),
            processed: *std.atomic.Value(usize),
            global_lats: *std.ArrayList(f64),
            lats_mutex: *Mutex,
        ) !void {
            var local_latencies = std.ArrayList(f64).init(global_lats.allocator);
            defer local_latencies.deinit();

            while (true) {
                const process_start = std.time.nanoTimestamp();
                _ = q.pop() orelse break;
                _ = processed.fetchAdd(1, .monotonic);
                const process_end = std.time.nanoTimestamp();
                const latency = @as(f64, @floatFromInt(process_end - process_start)) / std.time.ns_per_us;
                try local_latencies.append(latency);
            }

            // Merge local latencies into global
            lats_mutex.lock();
            defer lats_mutex.unlock();
            try global_lats.appendSlice(local_latencies.items);
        }
    };

    // Start consumer threads
    var i: usize = 0;
    while (i < num_consumers) : (i += 1) {
        const thread = try std.Thread.spawn(
            .{},
            Consumer.run,
            .{ &queue, &items_processed, &latencies, &latencies_mutex },
        );
        try consumers.append(thread);
    }

    // Producer with batch timing
    {
        var batch_idx: usize = 0;
        while (batch_idx < num_items) : (batch_idx += batch_size) {
            const batch_start = std.time.nanoTimestamp();
            const items_to_push = @min(batch_size, num_items - batch_idx);

            var j: usize = 0;
            while (j < items_to_push) : (j += 1) {
                try queue.push(@intCast(batch_idx + j));
            }

            const batch_end = std.time.nanoTimestamp();
            const batch_time = @as(f64, @floatFromInt(batch_end - batch_start)) / std.time.ns_per_us;
            try latencies.append(batch_time / @as(f64, @floatFromInt(items_to_push)));
        }
    }

    queue.setDone();

    // Wait for consumers
    for (consumers.items) |thread| {
        thread.join();
    }

    const end_time = std.time.nanoTimestamp();
    const total_time_us = @divFloor(@as(u64, @intCast(end_time - start_time)), std.time.ns_per_us);

    print("Total time: {d:.2} microseconds\n", .{total_time_us});
    print("Items processed: {d}\n", .{items_processed.load(.monotonic)});

    var sum: f64 = 0;
    var min_latency: f64 = std.math.inf(f64);
    var max_latency: f64 = -std.math.inf(f64);

    for (latencies.items) |latency| {
        sum += latency;
        min_latency = @min(min_latency, latency);
        max_latency = @max(max_latency, latency);
    }

    const mean_latency = sum / @as(f64, @floatFromInt(latencies.items.len));
    const throughput = (@as(f64, @floatFromInt(num_items)) * std.time.us_per_s) / @as(f64, @floatFromInt(total_time_us));

    return BenchmarkStats{
        .mean_latency = mean_latency,
        .min_latency = min_latency,
        .max_latency = max_latency,
        .throughput = throughput,
        .latencies = try latencies.toOwnedSlice(),
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const NUM_CONSUMERS: usize = 4;
    const NUM_ITEMS: usize = 1_000_000;
    const BATCH_SIZE: usize = 1_000;
    const NUM_RUNS: usize = 5;

    print("Running benchmarks with {d} consumers and {d} items...\n", .{ NUM_CONSUMERS, NUM_ITEMS });

    var results = std.ArrayList(BenchmarkStats).init(allocator);
    defer {
        for (results.items) |*result| {
            result.deinit(allocator);
        }
        results.deinit();
    }

    for (0..NUM_RUNS) |run| {
        print("\nRun {d}/{d}:\n", .{ run + 1, NUM_RUNS });

        const result = try benchmarkZig(allocator, NUM_CONSUMERS, NUM_ITEMS, BATCH_SIZE);
        try results.append(result);

        print("Mean latency: {d:.2} microseconds\n", .{result.mean_latency});
        print("Min latency: {d:.2} microseconds\n", .{result.min_latency});
        print("Max latency: {d:.2} microseconds\n", .{result.max_latency});
        print("Throughput: {d:.2} items/second\n", .{result.throughput});

        std.time.sleep(1 * std.time.ns_per_s); // Cool down between runs
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
