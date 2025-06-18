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
        print("\n💾 MEMORY USAGE TEST")
        
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
            
            // Get baseline memory usage
            let memoryBefore = getCurrentMemoryUsage()
            print("Memory before loading: \(String(format: "%.1f", Double(memoryBefore) / 1024 / 1024)) MB")
            
            do {
                // Load model and run inference
                let pipeline = try SummarizationPipeline(modelId: modelId)
                let memoryAfterLoad = getCurrentMemoryUsage()
                
                print("Memory after loading: \(String(format: "%.1f", Double(memoryAfterLoad) / 1024 / 1024)) MB")
                print("Memory increase: \(String(format: "%.1f", Double(memoryAfterLoad - memoryBefore) / 1024 / 1024)) MB")
                
                // Run inference
                let sample = samples[0]
                let result = try pipeline.summarize(text: sample.text)
                
                print("Memory used during inference: \(String(format: "%.1f", result.memoryUsed)) MB")
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
