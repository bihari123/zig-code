// Rust Implementation (spmc.rs)
use std::collections::VecDeque;
use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};
use std::sync::{Arc, Condvar, Mutex};
use std::thread;
use std::time::{Duration, Instant};

struct SPMCQueue<T> {
    queue: Mutex<VecDeque<T>>,
    not_empty: Condvar,
    done: AtomicBool,
    max_size: usize,
}

impl<T> SPMCQueue<T> {
    fn new(max_size: usize) -> Self {
        SPMCQueue {
            queue: Mutex::new(VecDeque::with_capacity(max_size)),
            not_empty: Condvar::new(),
            done: AtomicBool::new(false),
            max_size,
        }
    }

    fn push(&self, value: T) {
        let mut queue = self.queue.lock().unwrap();
        while queue.len() >= self.max_size {
            queue = self.not_empty.wait(queue).unwrap();
        }
        queue.push_back(value);
        self.not_empty.notify_one();
    }

    fn pop(&self) -> Option<T> {
        let mut queue = self.queue.lock().unwrap();
        loop {
            if let Some(value) = queue.pop_front() {
                self.not_empty.notify_one();
                return Some(value);
            }
            if self.done.load(Ordering::Relaxed) && queue.is_empty() {
                return None;
            }
            queue = self.not_empty.wait(queue).unwrap();
        }
    }

    fn set_done(&self) {
        self.done.store(true, Ordering::Relaxed);
        self.not_empty.notify_all();
    }
}

#[derive(Debug)]
struct BenchmarkStats {
    mean_latency: f64,
    min_latency: f64,
    max_latency: f64,
    throughput: f64,
    latencies: Vec<f64>,
}

fn benchmark_rust(num_consumers: usize, num_items: usize, batch_size: usize) -> BenchmarkStats {
    let queue = Arc::new(SPMCQueue::new(batch_size));
    let items_processed = Arc::new(AtomicUsize::new(0));
    let latencies = Arc::new(Mutex::new(Vec::new()));

    let start_time = Instant::now();

    // Create consumers
    let mut handles = vec![];
    for _ in 0..num_consumers {
        let queue = Arc::clone(&queue);
        let items_processed = Arc::clone(&items_processed);
        let latencies = Arc::clone(&latencies);

        handles.push(thread::spawn(move || {
            let mut local_latencies = Vec::new();
            while let Some(_) = queue.pop() {
                let process_start = Instant::now();
                items_processed.fetch_add(1, Ordering::Relaxed);
                let process_end = Instant::now();
                let latency = process_end.duration_since(process_start).as_micros() as f64;
                local_latencies.push(latency);
            }
            // Merge local latencies into global
            let mut global_latencies = latencies.lock().unwrap();
            global_latencies.extend(local_latencies);
        }));
    }

    // Producer with batch timing
    for i in (0..num_items).step_by(batch_size) {
        let batch_start = Instant::now();
        for j in 0..batch_size.min(num_items - i) {
            queue.push(i + j);
        }
        let batch_end = Instant::now();
        let batch_time = batch_end.duration_since(batch_start).as_micros() as f64;
        latencies
            .lock()
            .unwrap()
            .push(batch_time / batch_size as f64);
    }

    queue.set_done();

    // Wait for consumers
    for handle in handles {
        handle.join().unwrap();
    }

    let total_time = start_time.elapsed();
    let total_micros = total_time.as_micros() as f64;

    // Calculate statistics
    let latencies = latencies.lock().unwrap();
    let mean_latency = latencies.iter().sum::<f64>() / latencies.len() as f64;
    let min_latency = latencies.iter().fold(f64::INFINITY, |a, &b| a.min(b));
    let max_latency = latencies.iter().fold(f64::NEG_INFINITY, |a, &b| a.max(b));
    let throughput = (num_items as f64 * 1_000_000.0) / total_micros;

    println!("\nRust SPMC Queue Benchmark Results:");
    println!("Total time: {:.2} microseconds", total_micros);
    println!("Mean latency: {:.2} microseconds", mean_latency);
    println!("Min latency: {:.2} microseconds", min_latency);
    println!("Max latency: {:.2} microseconds", max_latency);
    println!("Throughput: {:.2} items/second", throughput);
    println!(
        "Items processed: {}",
        items_processed.load(Ordering::Relaxed)
    );

    BenchmarkStats {
        mean_latency,
        min_latency,
        max_latency,
        throughput,
        latencies: latencies.to_vec(),
    }
}

fn main() {
    const NUM_CONSUMERS: usize = 4;
    const NUM_ITEMS: usize = 1000000;
    const BATCH_SIZE: usize = 1000;
    const NUM_RUNS: usize = 5;

    println!(
        "Running benchmarks with {} consumers and {} items...",
        NUM_CONSUMERS, NUM_ITEMS
    );

    let mut results = Vec::new();

    for i in 0..NUM_RUNS {
        println!("\nRun {}/{}", i + 1, NUM_RUNS);
        results.push(benchmark_rust(NUM_CONSUMERS, NUM_ITEMS, BATCH_SIZE));
        thread::sleep(Duration::from_secs(1)); // Cool down between runs
    }

    // Calculate average across runs
    let avg_throughput = results.iter().map(|r| r.throughput).sum::<f64>() / NUM_RUNS as f64;
    let avg_latency = results.iter().map(|r| r.mean_latency).sum::<f64>() / NUM_RUNS as f64;

    println!("\nFinal averaged results across {} runs:", NUM_RUNS);
    println!("Average throughput: {:.2} items/second", avg_throughput);
    println!("Average latency: {:.2} microseconds", avg_latency);
}

