#include <algorithm> // Added for min_element and max_element
#include <atomic>
#include <chrono>
#include <condition_variable>
#include <iomanip>
#include <iostream>
#include <mutex>
#include <numeric>
#include <queue>
#include <thread>
#include <vector>

template <typename T> class SPMCQueue {
private:
  std::queue<T> queue;
  mutable std::mutex mutex;
  std::condition_variable not_empty;
  std::atomic<bool> done{false};
  const size_t max_size;

public:
  explicit SPMCQueue(size_t size) : max_size(size) {}

  void push(T value) {
    std::unique_lock<std::mutex> lock(mutex);
    while (queue.size() >= max_size) {
      not_empty.wait(lock);
    }
    queue.push(std::move(value));
    lock.unlock();
    not_empty.notify_one();
  }

  bool pop(T &value) {
    std::unique_lock<std::mutex> lock(mutex);
    while (queue.empty()) {
      if (done.load()) {
        return false;
      }
      not_empty.wait(lock);
    }
    value = std::move(queue.front());
    queue.pop();
    lock.unlock();
    not_empty.notify_one();
    return true;
  }

  void set_done() {
    done.store(true);
    not_empty.notify_all();
  }
};

struct BenchmarkStats {
  double mean_latency;
  double min_latency;
  double max_latency;
  double throughput;
  std::vector<double> latencies;
};

BenchmarkStats benchmark_cpp(int num_consumers, int num_items,
                             int batch_size = 1000) {
  SPMCQueue<int> queue(batch_size);
  std::vector<std::thread> consumers;
  std::atomic<int> items_processed{0};
  std::vector<double> latencies;
  std::mutex latencies_mutex;

  auto start_time = std::chrono::high_resolution_clock::now();

  // Start consumers
  for (int i = 0; i < num_consumers; i++) { // Fixed typo here (was a0)
    consumers.emplace_back([&queue, &items_processed, &latencies,
                            &latencies_mutex] {
      std::vector<double> local_latencies;
      int value;
      while (queue.pop(value)) {
        auto process_start = std::chrono::high_resolution_clock::now();
        items_processed.fetch_add(1);
        auto process_end = std::chrono::high_resolution_clock::now();
        auto latency = std::chrono::duration_cast<std::chrono::microseconds>(
                           process_end - process_start)
                           .count();
        local_latencies.push_back(latency);
      }
      // Merge local latencies into global
      std::lock_guard<std::mutex> lock(latencies_mutex);
      latencies.insert(latencies.end(), local_latencies.begin(),
                       local_latencies.end());
    });
  }

  // Producer with batch timing
  for (int i = 0; i < num_items; i += batch_size) {
    auto batch_start = std::chrono::high_resolution_clock::now();
    for (int j = 0; j < batch_size && (i + j) < num_items; ++j) {
      queue.push(i + j);
    }
    auto batch_end = std::chrono::high_resolution_clock::now();
    auto batch_time = std::chrono::duration_cast<std::chrono::microseconds>(
                          batch_end - batch_start)
                          .count();
    latencies.push_back(static_cast<double>(batch_time) / batch_size);
  }

  queue.set_done();

  // Wait for consumers
  for (auto &consumer : consumers) {
    consumer.join();
  }

  auto end_time = std::chrono::high_resolution_clock::now();
  auto total_time = std::chrono::duration_cast<std::chrono::microseconds>(
                        end_time - start_time)
                        .count();

  // Calculate statistics
  BenchmarkStats stats;
  stats.latencies = latencies;
  stats.mean_latency =
      std::accumulate(latencies.begin(), latencies.end(), 0.0) /
      latencies.size();
  stats.min_latency = *std::min_element(latencies.begin(), latencies.end());
  stats.max_latency = *std::max_element(latencies.begin(), latencies.end());
  stats.throughput = (num_items * 1000000.0) / total_time; // items per second

  std::cout << "\nC++ SPMC Queue Benchmark Results:\n";
  std::cout << std::fixed << std::setprecision(2);
  std::cout << "Total time: " << total_time << " microseconds\n";
  std::cout << "Mean latency: " << stats.mean_latency << " microseconds\n";
  std::cout << "Min latency: " << stats.min_latency << " microseconds\n";
  std::cout << "Max latency: " << stats.max_latency << " microseconds\n";
  std::cout << "Throughput: " << stats.throughput << " items/second\n";
  std::cout << "Items processed: " << items_processed << "\n";

  return stats;
}

int main() {
  const int NUM_CONSUMERS = 4;
  const int NUM_ITEMS = 1000000;
  const int BATCH_SIZE = 1000;

  // Run multiple iterations to get stable results
  std::cout << "Running benchmarks with " << NUM_CONSUMERS << " consumers and "
            << NUM_ITEMS << " items...\n";

  std::vector<BenchmarkStats> results;
  const int NUM_RUNS = 5;

  for (int i = 0; i < NUM_RUNS; i++) {
    std::cout << "\nRun " << (i + 1) << "/" << NUM_RUNS << ":\n";
    results.push_back(benchmark_cpp(NUM_CONSUMERS, NUM_ITEMS, BATCH_SIZE));
    std::this_thread::sleep_for(
        std::chrono::seconds(1)); // Cool down between runs
  }

  // Calculate average across runs
  double avg_throughput = 0;
  double avg_latency = 0;
  for (const auto &result : results) {
    avg_throughput += result.throughput;
    avg_latency += result.mean_latency;
  }
  avg_throughput /= NUM_RUNS;
  avg_latency /= NUM_RUNS;

  std::cout << "\nFinal averaged results across " << NUM_RUNS << " runs:\n";
  std::cout << "Average throughput: " << std::fixed << std::setprecision(2)
            << avg_throughput << " items/second\n";
  std::cout << "Average latency: " << avg_latency << " microseconds\n";

  return 0;
}
