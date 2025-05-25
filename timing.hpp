#pragma once

#include <iostream>
#include <chrono>
#include <functional>

double measureAverageExecutionTime(double durationInSeconds, const std::function<void()>& func) {
  using namespace std::chrono;

  auto startTime = high_resolution_clock::now();
  auto endTime = startTime + duration<double>(durationInSeconds);

  size_t iterations = 0;
  auto currentTime = startTime;

  // Run the function repeatedly until the duration has passed
  while (currentTime < endTime) {
    func();
    ++iterations;
    currentTime = high_resolution_clock::now();
  }

  auto totalDuration = duration_cast<duration<double>>(currentTime - startTime).count(); // in seconds
  if (iterations == 0) return 0.0;

  double averageDurationPerCall = (totalDuration / iterations) * 1'000'000.0; // Convert seconds to microseconds
  return averageDurationPerCall;
}
