#include "spmc.hpp"
#include <algorithm>
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

extern "C" BenchmarkResult benchmark_cpp(int num_consumers, int num_items,
                                         int batch_size) {
  SPMCQueue<int> queue(batch_size);
  std::vector<std::thread> consumers;
  std::atomic<int> items_processed{0};
  std::vector<double> latencies;
  std::mutex latencies_mutex;

  auto start_time = std::chrono::high_resolution_clock::now();

  // Start consumers
  for (int i = 0; i < num_consumers; i++) {
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

  for (auto &consumer : consumers) {
    consumer.join();
  }

  auto end_time = std::chrono::high_resolution_clock::now();
  auto total_time = std::chrono::duration_cast<std::chrono::microseconds>(
                        end_time - start_time)
                        .count();

  BenchmarkResult result;
  result.total_time = total_time;
  result.mean_latency =
      std::accumulate(latencies.begin(), latencies.end(), 0.0) /
      latencies.size();
  result.min_latency = *std::min_element(latencies.begin(), latencies.end());
  result.max_latency = *std::max_element(latencies.begin(), latencies.end());
  result.throughput = (num_items * 1000000.0) / total_time;
  result.items_processed = items_processed.load();

  return result;
}
