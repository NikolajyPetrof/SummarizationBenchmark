# SummarizationBenchmark Tests

This directory contains test files for evaluating the MLX-based summarization pipeline performance and functionality.

## Test Files Overview

### 1. ModelLoadingTests.swift
Tests basic model loading and configuration functionality:
- Model registry configuration
- Model availability checking
- Basic summarization functionality
- Model loading time measurements

### 2. SummarizationPipelineTests.swift
Tests summarization quality and behavior:
- Pipeline creation with different models
- Output quality evaluation (compression ratio, content preservation)
- Testing different temperature settings
- Testing different max token settings

### 3. ModelPerformanceTests.swift
Benchmarks performance metrics across models:
- Model loading time
- Token generation speed (tokens/second)
- Memory usage during loading and inference
- Comparative analysis between different model sizes

## Running the Tests

You can run the tests individually or as a test suite using either Xcode or the Swift CLI.

### Using Xcode:
1. Open the project in Xcode
2. Select the Test Navigator
3. Run individual tests or the entire test suite

### Using Swift CLI:
```bash
# Run all tests
swift test

# Run a specific test file
swift test --filter ModelLoadingTests

# Run a specific test case
swift test --filter ModelLoadingTests/testModelAvailability
```

## Model Requirements

The tests expect the following models to be available locally:
- `DeepSeek-R1-Distill-Qwen-1.5B` (1.5B parameters)
- `Qwen2.5-1.5B-Instruct-4bit` (1.5B parameters)
- `DeepSeek-R1-Distill-Llama-8B` (8B parameters)
- `Meta-Llama-3-8B-Instruct-4bit` (8B parameters)

Models should be placed in the default model directory as specified in `ModelRegistry+Custom.swift` or set using the `SUMMARIZATION_MODEL_DIR` environment variable.

## Test Outputs

Tests will output:
- Performance metrics (loading time, tokens/sec, memory usage)
- Summary quality evaluation
- Comparison tables between different models

## Notes

- Some tests will be skipped if models are not downloaded
- Memory usage tests require macOS (using Darwin APIs)
- Long-running tests are marked with appropriate comments
