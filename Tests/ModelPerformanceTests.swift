//
//  ModelPerformanceTests.swift
//  Tests
//
//  Created by Nikolay Petrov on 11.06.2025.
//

import XCTest
@testable import SummarizationBenchmark
import MLX
import MLXLLM
import MLXLMCommon
import Darwin

/// Performance benchmark tests for summarization models
class ModelPerformanceTests: XCTestCase {
    
    // Test samples
    let samples = DatasetLoader.predefinedSamples()
    
    // MARK: - Model Loading Performance
    
    func testModelLoadingPerformance() {
        print("\n📊 MODEL LOADING PERFORMANCE")
        
        // Models to test
        let modelIds = [
            "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B",
            "mlx-community/Qwen2.5-1.5B-Instruct-4bit",
            "mlx-community/Meta-Llama-3-8B-Instruct-4bit"
        ]
        
        for modelId in modelIds {
            guard ModelRegistry.isModelAvailable(modelId) else {
                print("⚠️ Model not available: \(modelId)")
                continue
            }
            
            // Measure model loading time
            let startTime = Date()
            do {
                _ = try SummarizationPipeline(modelId: modelId)
                let loadTime = -startTime.timeIntervalSinceNow
                
                let model = SummarizationModel.model(withId: modelId)!
                print("✅ \(model.name) (\(model.size.rawValue)): Loaded in \(String(format: "%.2f", loadTime))s")
            } catch {
                print("❌ Failed to load \(modelId): \(error)")
            }
        }
    }
    
    // MARK: - Token Generation Performance
    
    func testTokenGenerationSpeed() throws {
        print("\n⚡️ TOKEN GENERATION SPEED")
        
        // Use a smaller model for testing
        let modelId = "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B"
        
        guard ModelRegistry.isModelAvailable(modelId) else {
            print("⚠️ Model not available: \(modelId)")
            return
        }
        
        let pipeline = try SummarizationPipeline(modelId: modelId)
        
        // Test with a consistent sample
        let sample = samples[0]
        
        // Run multiple times for better measurement
        let runs = 3
        var totalTokensPerSecond: Double = 0
        
        for i in 1...runs {
            print("Run \(i)/\(runs)...")
            let result = try pipeline.summarize(text: sample.text)
            totalTokensPerSecond += result.tokensPerSecond
            
            print("- Generated \(result.tokensGenerated) tokens in \(String(format: "%.2f", result.inferenceTime))s")
            print("- Speed: \(String(format: "%.1f", result.tokensPerSecond)) tokens/sec")
        }
        
        let averageTokensPerSecond = totalTokensPerSecond / Double(runs)
        print("Average speed: \(String(format: "%.1f", averageTokensPerSecond)) tokens/sec")
    }
    
    // MARK: - Memory Usage Tests
    
    func testMemoryUsage() throws {
        print("\n💾 PEAK MEMORY USAGE TEST")
        
        // Test memory usage for different model sizes
        let modelIds = [
            "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B",  // 1.5B
            "mlx-community/Meta-Llama-3-8B-Instruct-4bit"   // 8B
        ]
        
        for modelId in modelIds {
            guard ModelRegistry.isModelAvailable(modelId) else {
                print("⚠️ Model not available: \(modelId)")
                continue
            }
            
            let model = SummarizationModel.model(withId: modelId)!
            print("Testing \(model.name) (\(model.size.rawValue))...")
            
            // Reset GPU memory statistics
            MLX.GPU.resetPeakMemory()
            
            // Get baseline memory usage
            let memoryBefore = getCurrentMemoryUsage()
            print("Memory before loading: \(String(format: "%.1f", Double(memoryBefore) / 1024 / 1024)) MB")
            
            do {
                // Load model and run inference
                let pipeline = try SummarizationPipeline(modelId: modelId)
                let memoryAfterLoad = getCurrentMemoryUsage()
                
                // Get peak GPU memory after loading
                let peakGPUMemoryLoad = MLX.GPU.peakMemory
                
                print("Memory after loading: \(String(format: "%.1f", Double(memoryAfterLoad) / 1024 / 1024)) MB")
                print("Peak GPU memory during load: \(String(format: "%.1f", Double(peakGPUMemoryLoad) / 1024 / 1024)) MB")
                print("Memory increase: \(String(format: "%.1f", Double(memoryAfterLoad - memoryBefore) / 1024 / 1024)) MB")
                
                // Reset GPU stats for inference
                MLX.GPU.resetPeakMemory()
                
                // Run inference
                let sample = samples[0]
                let result = try pipeline.summarize(text: sample.text)
                
                // Get peak GPU memory after inference
                let peakGPUMemoryInference = MLX.GPU.peakMemory
                
                print("Memory used during inference: \(String(format: "%.1f", result.memoryUsed)) MB")
                print("Peak GPU memory during inference: \(String(format: "%.1f", Double(peakGPUMemoryInference) / 1024 / 1024)) MB")
            } catch {
                print("❌ Error: \(error)")
            }
        }
    }
    
    // MARK: - Model Comparison Tests
    
    func testModelComparison() throws {
        print("\n📊 MODEL COMPARISON")
        
        let modelIds = [
            "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B",
            "mlx-community/Qwen2.5-1.5B-Instruct-4bit",
            "mlx-community/Meta-Llama-3-8B-Instruct-4bit" 
        ]
        
        let sample = samples[0]
        
        print("| Model | Size | Tokens/sec | Time (s) | Memory (MB) |")
        print("| ----- | ---- | ---------- | -------- | ----------- |")
        
        for modelId in modelIds {
            guard ModelRegistry.isModelAvailable(modelId) else {
                continue
            }
            
            let model = SummarizationModel.model(withId: modelId)!
            
            do {
                let pipeline = try SummarizationPipeline(modelId: modelId)
                let result = try pipeline.summarize(text: sample.text)
                
                print("| \(model.name) | \(model.size.rawValue) | \(String(format: "%.1f", result.tokensPerSecond)) | \(String(format: "%.2f", result.inferenceTime)) | \(String(format: "%.1f", result.memoryUsed)) |")
            } catch {
                print("| \(model.name) | \(model.size.rawValue) | Failed | Failed | Failed |")
            }
        }
    }
    
    // MARK: - Batch Size Memory Test
    
    func testMemoryUsageWithBatchSizes() throws {
        print("\n💾 BATCH SIZE MEMORY TEST")
        
        // Choose a model for batch size testing
        let modelId = "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B"
        
        // Skip test if model is not available
        guard ModelRegistry.isModelAvailable(modelId) else {
            print("⚠️ Model not available: \(modelId)")
            return
        }
        
        let model = SummarizationModel.model(withId: modelId)!
        print("Testing \(model.name) with different batch sizes...")
        
        // Use the first few samples as test data
        let testData = Array(samples.prefix(8))
        
        // Test different batch sizes
        let batchSizes = [1, 2, 4, 8]
        var memoryResults: [Int: Double] = [:]
        
        do {
            // Load the model once
            let pipeline = try SummarizationPipeline(modelId: modelId)
            
            print("| Batch Size | Memory Used (MB) | Per-item Memory (MB) |")
            print("| ---------- | --------------- | ------------------- |")
            
            for batchSize in batchSizes {
                // Skip batch sizes larger than available samples
                guard batchSize <= testData.count else {
                    print("⚠️ Skipping batch size \(batchSize): not enough test samples")
                    continue
                }
                
                // Reset peak memory
                MLX.GPU.resetPeakMemory()
                
                // Process batch
                let batch = Array(testData.prefix(batchSize))
                let startTime = Date()
                
                // Process each item in batch and measure memory
                var summaries: [String] = []
                for sample in batch {
                    let result = try pipeline.summarize(text: sample.text)
                    summaries.append(result.summary)
                }
                
                // Measure peak memory
                let peakMemory = Double(MLX.GPU.peakMemory) / 1024 / 1024 // MB
                let timeElapsed = -startTime.timeIntervalSinceNow
                let perItemMemory = peakMemory / Double(batchSize)
                
                memoryResults[batchSize] = peakMemory
                
                print("| \(batchSize) | \(String(format: "%.1f", peakMemory)) | \(String(format: "%.1f", perItemMemory)) |")
                print("  Time: \(String(format: "%.2f", timeElapsed))s")
            }
            
            // Report scaling efficiency
            if let baselineMemory = memoryResults[1], memoryResults.count > 1 {
                print("\nMemory scaling efficiency:")
                for (batchSize, memory) in memoryResults.sorted(by: { $0.key < $1.key }) {
                    if batchSize > 1 {
                        let theoreticalMemory = baselineMemory * Double(batchSize)
                        let efficiency = (theoreticalMemory / memory) * 100
                        print("Batch size \(batchSize): \(String(format: "%.1f", efficiency))% efficiency")
                    }
                }
            }
            
        } catch {
            print("❌ Error: \(error)")
        }
    }
    
    // MARK: - Quantization Memory Test
    
    func testQuantizationEffectOnMemory() throws {
        print("\n💾 QUANTIZATION MEMORY COMPARISON")
        
        // Define models with different quantization to test
        let modelComparisons = [
            // 4-bit vs 8-bit pair for comparison (if available)
            ("mlx-community/DeepSeek-R1-Distill-Qwen-1.5B", "INT4"),
            // Use model IDs that match the quantization type in your registry
            // For testing, we'll simulate having different quantizations with the same model
            ("mlx-community/Meta-Llama-3-8B-Instruct-4bit", "INT4")
        ]
        
        print("| Model | Quantization | Memory (MB) | Load Time (s) | Inference Speed (tokens/s) |")
        print("| ----- | ------------ | ----------- | ------------- | -------------------------- |")
        
        for (modelId, quantType) in modelComparisons {
            guard ModelRegistry.isModelAvailable(modelId) else {
                print("⚠️ Model not available: \(modelId)")
                continue
            }
            
            let model = SummarizationModel.model(withId: modelId)!
            
            // Reset peak memory
            MLX.GPU.resetPeakMemory()
            
            do {
                // Measure load time
                let loadStart = Date()
                let pipeline = try SummarizationPipeline(modelId: modelId)
                let loadTime = -loadStart.timeIntervalSinceNow
                
                // Measure memory after loading
                let memoryAfterLoad = Double(MLX.GPU.peakMemory) / 1024 / 1024 // MB
                
                // Reset for inference
                MLX.GPU.resetPeakMemory()
                
                // Run inference
                let sample = samples[0]
                let inferenceStart = Date()
                let result = try pipeline.summarize(text: sample.text)
                let inferenceTime = -inferenceStart.timeIntervalSinceNow
                
                // Measure memory during inference
                let memoryDuringInference = Double(MLX.GPU.peakMemory) / 1024 / 1024 // MB
                
                // Print results in table format
                print("| \(model.name) | \(quantType) | \(String(format: "%.1f", memoryAfterLoad)) | \(String(format: "%.2f", loadTime)) | \(String(format: "%.1f", result.tokensPerSecond)) |")
                print("Inference memory: \(String(format: "%.1f", memoryDuringInference)) MB")
                
            } catch {
                print("❌ Failed to test \(model.name): \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get current memory usage in bytes
    private func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / 4)
        
        let _ = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { pointer in
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    pointer,
                    &count
                )
            }
        }
        
        return info.resident_size
    }
}

// MARK: - Memory Usage Helper
fileprivate struct mach_task_basic_info {
    var virtual_size: UInt64 = 0
    var resident_size: UInt64 = 0
    var resident_size_max: UInt64 = 0
    var user_time: TimeInterval = 0
    var system_time: TimeInterval = 0
    var policy: Int32 = 0
    var suspend_count: Int32 = 0
}
