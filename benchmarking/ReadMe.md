# SPMC Queue Benchmark Comparison

This repository contains benchmarking results for Single Producer Multiple Consumer (SPMC) Queue implementations across different programming languages. The benchmark tests were conducted with 4 consumers processing 1,000,000 items.

## Overview

The benchmark compares SPMC Queue implementations in:

- Pure C++
- Pure Rust
- Pure Zig
- Zig with C++ header

## Results Summary

| Implementation | Avg Throughput (items/sec) | Avg Latency (μs) | Best Run Throughput |
| -------------- | -------------------------- | ---------------- | ------------------- |
| Pure Zig       | 3,051,487                  | 1.26             | 3,397,651           |
| Pure C++       | 2,289,632                  | 0.00             | 2,623,797           |
| Zig with C++   | 2,269,000                  | 0.00             | 2,577,831           |
| Pure Rust      | 1,674,059                  | 0.00             | 1,867,162           |

## Key Findings

1. **Best Performance**: Pure Zig implementation showed the highest throughput, averaging ~3.05M items/second
2. **Runner-up**: Pure C++ implementation achieved ~2.29M items/second
3. **Interesting Note**: Zig with C++ header performed similarly to Pure C++
4. **Latency Measurements**: Only Pure Zig reported non-zero average latency measurements

## Detailed Results

### Pure Zig Performance

- Average Throughput: 3,051,487 items/second
- Average Latency: 1.26 microseconds
- Min Latency: ~0.02 microseconds
- Max Latency: Range of 300-420 microseconds

### Pure C++ Performance

- Average Throughput: 2,289,632 items/second
- Average Latency: ~0.00 microseconds
- Min Latency: 0.00 microseconds
- Max Latency: Range of 11-80 microseconds

### Zig with C++ Header Performance

- Average Throughput: 2,269,000 items/second
- Average Latency: ~0.00 microseconds
- Min Latency: 0.00 microseconds
- Max Latency: Range of 13-93 microseconds

### Pure Rust Performance

- Average Throughput: 1,674,059 items/second
- Average Latency: ~0.00 microseconds
- Min Latency: 0.00 microseconds
- Max Latency: Range of 5-107 microseconds

## Benchmark Configuration

- Number of Consumers: 4
- Total Items: 1,000,000
- Runs per Implementation: 5

## Notes

1. All implementations were tested under the same conditions with identical workloads
2. Results show the average across 5 consecutive runs to account for system variations
3. Latency reporting methodology may vary between implementations, particularly notable in the Zig implementation's more detailed latency measurements

## Future Work

Potential areas for investigation:

- Impact of different consumer counts
- Varying workload sizes
- Memory usage analysis
- CPU utilization patterns
- Impact of different hardware configurations
