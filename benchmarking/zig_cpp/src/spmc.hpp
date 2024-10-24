#pragma once

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  double total_time;
  double mean_latency;
  double min_latency;
  double max_latency;
  double throughput;
  int items_processed;
} BenchmarkResult;

BenchmarkResult benchmark_cpp(int num_consumers, int num_items, int batch_size);

#ifdef __cplusplus
}
#endif
