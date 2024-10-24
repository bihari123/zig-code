#include <atomic>
#include <chrono>
#include <iostream>
#include <thread>
#include <vector>

template <typename T, size_t N> class SPMCQueue {
private:
  struct Node {
    T data;
    std::atomic<bool> available{false};
  };

  Node buffer[N];
  std::atomic<size_t> write_idx{0};
  std::atomic<size_t> read_idx{0};
  const size_t capacity = N;

public:
  bool push(const T &item) {
    size_t current = write_idx.load(std::memory_order_relaxed);
    if (current - read_idx.load(std::memory_order_acquire) >= capacity) {
      return false; // Queue is full
    }

    buffer[current % capacity].data = item;
    buffer[current % capacity].available.store(true, std::memory_order_release);
    write_idx.store(current + 1, std::memory_order_release);
    return true;
  }

  bool pop(T &item) {
    while (true) {
      size_t current = read_idx.load(std::memory_order_relaxed);
      if (current >= write_idx.load(std::memory_order_acquire)) {
        return false; // Queue is empty
      }

      if (buffer[current % capacity].available.load(
              std::memory_order_acquire)) {
        if (read_idx.compare_exchange_weak(current, current + 1,
                                           std::memory_order_release,
                                           std::memory_order_relaxed)) {
          item = buffer[current % capacity].data;
          buffer[current % capacity].available.store(false,
                                                     std::memory_order_release);
          return true;
        }
      }
      std::this_thread::yield();
    }
  }
};

// Benchmark code
void benchmark() {
  const size_t QUEUE_SIZE = 1024;
  const size_t NUM_CONSUMERS = 4;
  const size_t ITEMS_PER_PRODUCER = 1000000;

  SPMCQueue<int, QUEUE_SIZE> queue;
  std::atomic<size_t> total_consumed{0};
  std::atomic<bool> producer_done{false};

  auto producer = [&]() {
    auto start = std::chrono::high_resolution_clock::now();

    for (size_t i = 0; i < ITEMS_PER_PRODUCER; ++i) {
      while (!queue.push(i)) {
        std::this_thread::yield();
      }
    }

    producer_done.store(true, std::memory_order_release);
    auto end = std::chrono::high_resolution_clock::now();
    auto duration =
        std::chrono::duration_cast<std::chrono::microseconds>(end - start);
    std::cout << "Producer took: " << duration.count() << " microseconds\n";
  };

  auto consumer = [&]() {
    size_t items_consumed = 0;
    int item;

    while (true) {
      if (queue.pop(item)) {
        items_consumed++;
      } else if (producer_done.load(std::memory_order_acquire) &&
                 !queue.pop(item)) {
        break;
      } else {
        std::this_thread::yield();
      }
    }

    total_consumed += items_consumed;
  };

  std::vector<std::thread> consumers;
  auto start = std::chrono::high_resolution_clock::now();

  std::thread prod(producer);
  for (size_t i = 0; i < NUM_CONSUMERS; ++i) {
    consumers.emplace_back(consumer);
  }

  prod.join();
  for (auto &c : consumers) {
    c.join();
  }

  auto end = std::chrono::high_resolution_clock::now();
  auto duration =
      std::chrono::duration_cast<std::chrono::microseconds>(end - start);

  std::cout << "Total items consumed: " << total_consumed << "\n";
  std::cout << "Total time: " << duration.count() << " microseconds\n";
  std::cout << "Throughput: "
            << (ITEMS_PER_PRODUCER * 1000000.0 / duration.count())
            << " items/second\n";
}

int main() {
  benchmark();
  return 0;
}
