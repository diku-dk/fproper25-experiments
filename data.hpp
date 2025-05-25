// Facilities for reading Futhark data files.

#pragma once

#include <fstream>
#include <iostream>
#include <vector>
#include <cstdint>
#include <stdexcept>
#include <array>
#include <string>
#include <type_traits>

// Map C++ types to Futhark 4-character type strings
template<typename T>
struct FutharkTypeString;

template<> struct FutharkTypeString<int8_t>  { static constexpr const char* value = "  i8"; };
template<> struct FutharkTypeString<int16_t> { static constexpr const char* value = " i16"; };
template<> struct FutharkTypeString<int64_t> { static constexpr const char* value = " i64"; };
template<> struct FutharkTypeString<int32_t> { static constexpr const char* value = " i32"; };
template<> struct FutharkTypeString<float>   { static constexpr const char* value = " f32"; };
template<> struct FutharkTypeString<double>  { static constexpr const char* value = " f64"; };

template<typename T, size_t K>
std::pair<std::vector<T>, std::array<uint64_t, K>> read_futhark_array(const std::string& filename) {
  static_assert(std::is_trivially_copyable_v<T>, "Type must be trivially copyable");
  static_assert(K >= 0, "Rank must be non-negative");

  std::ifstream in(filename, std::ios::binary);
  if (!in) {
    throw std::runtime_error("Failed to open file: " + filename);
  }

  // Read header
  char magic;
  uint8_t version;
  in.read(&magic, 1);
  in.read(reinterpret_cast<char*>(&version), 1);
  if (magic != 'b' || version != 2) {
    throw std::runtime_error("Invalid Futhark binary file: bad magic or version");
  }

  // Read and check rank
  uint8_t num_dims;
  in.read(reinterpret_cast<char*>(&num_dims), 1);
  if (num_dims != K) {
    throw std::runtime_error("Expected rank " + std::to_string(K) + ", got " + std::to_string(num_dims));
  }

  // Read and check element type
  std::array<char, 4> type_buf;
  in.read(type_buf.data(), 4);
  std::string type_str(type_buf.data(), 4);
  if (type_str != FutharkTypeString<T>::value) {
    throw std::runtime_error("Type mismatch. Expected '" +
                             std::string(FutharkTypeString<T>::value) +
                             "', got '" + type_str + "'");
  }

  // Read shape
  std::array<uint64_t, K> shape{};
  for (size_t i = 0; i < K; ++i) {
    in.read(reinterpret_cast<char*>(&shape[i]), sizeof(uint64_t));
  }

  // Compute total number of elements
  uint64_t total_elements = 1;
  for (size_t i = 0; i < K; ++i) {
    total_elements *= shape[i];
  }

  // Read data
  std::vector<T> data(total_elements);
  in.read(reinterpret_cast<char*>(data.data()), total_elements * sizeof(T));
  if (!in) {
    throw std::runtime_error("Failed to read data");
  }

  return {std::move(data), shape};
}
