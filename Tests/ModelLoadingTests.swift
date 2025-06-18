//
//  ModelLoadingTests.swift
//  Tests
//
//  Created by Nikolay Petrov on 11.06.2025.
//

import XCTest
@testable import SummarizationBenchmark
import MLX
import MLXLLM
import MLXLMCommon

/// Tests for model loading and basic generation functionality
class ModelLoadingTests: XCTestCase {
    
    // MARK: - Model Loading Tests
    
    func testModelRegistryConfiguration() {
        // Test that the model registry is properly configured
        let modelsDir = ModelRegistry.modelsDirectory
        XCTAssertNotNil(modelsDir, "Model directory should be configured")
        
        // Test setting custom directory
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("TestModels")
        ModelRegistry.setCustomModelDirectory(tempDir)
        XCTAssertEqual(ModelRegistry.modelsDirectory.path, tempDir.path, "Custom model directory should be set correctly")
    }
    
    func testModelAvailability() {
        // Check if the required models are registered
        let allModels = SummarizationModel.availableModels
        
        // Verify we have the required models in the registry
        let requiredModelIds = [
            "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B",
            "mlx-community/DeepSeek-R1-Distill-Llama-8B",
            "mlx-community/Meta-Llama-3-8B-Instruct-4bit",
            "mlx-community/Qwen2.5-1.5B-Instruct-4bit"
        ]
        
        for modelId in requiredModelIds {
            XCTAssertNotNil(
                SummarizationModel.model(withId: modelId),
                "Model \(modelId) should be registered"
            )
        }
        
        // Print availability status
        print("\nModel Availability Status:")
        for modelId in requiredModelIds {
            let isAvailable = ModelRegistry.isModelAvailable(modelId)
            print("- \(modelId): \(isAvailable ? "Available" : "Not downloaded")")
        }
    }
    
    // MARK: - Basic Generation Tests
    
    func testBasicSummarization() throws {
        // Choose a small model for quick testing
        let modelId = "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B"
        
        // Skip test if model is not available
        guard ModelRegistry.isModelAvailable(modelId) else {
            print("⚠️ Skipping test: Model \(modelId) is not downloaded")
            return
        }
        
        // Create pipeline
        measure {
            do {
                let pipeline = try SummarizationPipeline(modelId: modelId)
                
                // Short text for quick test
                let text = "Artificial intelligence (AI) has evolved significantly over the past decade. Machine learning models, particularly deep neural networks, have revolutionized fields like computer vision, natural language processing, and reinforcement learning."
                
                // Generate summary
                let result = try pipeline.summarize(text: text, maxTokens: 50)
                
                // Verify result has content
                XCTAssertFalse(result.summary.isEmpty, "Summary should not be empty")
                XCTAssertGreaterThan(result.tokensGenerated, 0, "Should generate tokens")
                XCTAssertGreaterThan(result.tokensPerSecond, 0, "Tokens per second should be positive")
                
                print("\nGenerated summary: \(result.summary)")
                print("Time: \(result.inferenceTime)s, Tokens/sec: \(result.tokensPerSecond)")
            } catch {
                XCTFail("Failed to run summarization: \(error)")
            }
        }
    }
    
    /// Test if all required models can be loaded
    func testModelLoading() {
        let smallModelId = "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B"
        let largeModelId = "mlx-community/Meta-Llama-3-8B-Instruct-4bit"
        
        var results = [String: (success: Bool, loadTime: TimeInterval, error: Error?)]()
        
        // Test small model
        let smallModelStart = Date()
        do {
            _ = try SummarizationPipeline(modelId: smallModelId)
            results[smallModelId] = (true, -smallModelStart.timeIntervalSinceNow, nil)
        } catch {
            results[smallModelId] = (false, -smallModelStart.timeIntervalSinceNow, error)
        }
        
        // Test large model
        let largeModelStart = Date()
        do {
            _ = try SummarizationPipeline(modelId: largeModelId)
            results[largeModelId] = (true, -largeModelStart.timeIntervalSinceNow, nil)
        } catch {
            results[largeModelId] = (false, -largeModelStart.timeIntervalSinceNow, error)
        }
        
        // Report results
        print("\nModel Loading Test Results:")
        for (modelId, result) in results {
            if result.success {
                print("✅ \(modelId): Loaded successfully in \(String(format: "%.2f", result.loadTime))s")
            } else {
                print("❌ \(modelId): Failed to load (\(result.error?.localizedDescription ?? "unknown error"))")
            }
        }
    }
}
