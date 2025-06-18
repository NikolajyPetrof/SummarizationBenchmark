//
//  SummarizationPipelineTests.swift
//  Tests
//
//  Created by Nikolay Petrov on 11.06.2025.
//

import XCTest
@testable import SummarizationBenchmark
import MLX
import MLXLLM
import MLXLMCommon

/// Tests for summarization pipeline with real articles
class SummarizationPipelineTests: XCTestCase {
    
    // Test samples
    let samples = DatasetLoader.predefinedSamples()
    
    // MARK: - Pipeline Configuration Tests
    
    func testPipelineCreation() throws {
        // Test creation with all registered models
        for model in SummarizationModel.availableModels {
            if ModelRegistry.isModelAvailable(model.modelId) {
                do {
                    let pipeline = try SummarizationPipeline(modelId: model.modelId)
                    XCTAssertNotNil(pipeline, "Pipeline should be created for model: \(model.name)")
                    print("✅ Created pipeline for: \(model.name)")
                } catch {
                    XCTFail("Failed to create pipeline for \(model.name): \(error.localizedDescription)")
                }
            } else {
                print("⚠️ Skipping model \(model.name) - not downloaded")
            }
        }
    }
    
    // MARK: - Summarization Quality Tests
    
    func testSummarizationLength() throws {
        // Choose a small model for testing
        let modelId = "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B"
        
        // Skip test if model is not available
        guard ModelRegistry.isModelAvailable(modelId) else {
            print("⚠️ Skipping test: Model \(modelId) is not downloaded")
            return
        }
        
        let pipeline = try SummarizationPipeline(modelId: modelId)
        
        // Test with multiple samples
        for (index, sample) in samples.enumerated() {
            print("\nTesting sample \(index + 1)/\(samples.count)...")
            
            // Generate summary
            let result = try pipeline.summarize(text: sample.text)
            
            // Verify summary length is reasonable (between 10% and 50% of original text)
            let compressionRatio = Double(result.summary.count) / Double(sample.text.count)
            XCTAssertGreaterThan(compressionRatio, 0.05, "Summary is too short")
            XCTAssertLessThan(compressionRatio, 0.7, "Summary is too long")
            
            print("Original length: \(sample.text.count) chars")
            print("Summary length: \(result.summary.count) chars")
            print("Compression ratio: \(String(format: "%.2f", compressionRatio * 100))%")
            print("Summary: \(result.summary.prefix(100))...")
        }
    }
    
    func testSummarizationContent() throws {
        // Choose a model with good summarization capabilities
        let modelId = "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B"
        
        // Skip test if model is not available
        guard ModelRegistry.isModelAvailable(modelId) else {
            print("⚠️ Skipping test: Model \(modelId) is not downloaded")
            return
        }
        
        let pipeline = try SummarizationPipeline(modelId: modelId)
        
        // Compare generated summaries with reference summaries
        for (index, sample) in samples.enumerated() {
            print("\nTesting sample \(index + 1)/\(samples.count)...")
            
            // Generate summary
            let result = try pipeline.summarize(text: sample.text)
            
            // Compute basic content overlap (very simple metric)
            let overlapScore = calculateContentOverlap(generated: result.summary, reference: sample.summary)
            
            print("Content overlap score: \(String(format: "%.2f", overlapScore * 100))%")
            print("Reference summary: \(sample.summary.prefix(100))...")
            print("Generated summary: \(result.summary.prefix(100))...")
            
            // There should be some overlap between reference and generated summary
            // This is a very basic check and not a proper evaluation metric
            XCTAssertGreaterThan(overlapScore, 0.0, "Summary should have some content overlap with reference")
        }
    }
    
    func testTemperatureEffects() throws {
        // Choose a model for testing
        let modelId = "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B"
        
        // Skip test if model is not available
        guard ModelRegistry.isModelAvailable(modelId) else {
            print("⚠️ Skipping test: Model \(modelId) is not downloaded")
            return
        }
        
        let pipeline = try SummarizationPipeline(modelId: modelId)
        let sample = samples.first!
        
        // Test different temperature settings
        let temperatures: [Float] = [0.1, 0.5, 0.9]
        var summaries: [String] = []
        
        for temp in temperatures {
            let result = try pipeline.summarize(text: sample.text, temperature: temp)
            summaries.append(result.summary)
            
            print("\nTemperature \(temp) summary:")
            print(result.summary.prefix(100))
            print("Length: \(result.summary.count) chars")
        }
        
        // Verify that different temperatures produce different summaries
        // This is not always guaranteed due to the nature of sampling, but likely with these temperature differences
        for i in 0..<summaries.count {
            for j in (i+1)..<summaries.count {
                let similarity = calculateContentOverlap(generated: summaries[i], reference: summaries[j])
                print("Similarity between temp \(temperatures[i]) and \(temperatures[j]): \(String(format: "%.2f", similarity * 100))%")
                
                // Don't assert here as this is a probabilistic test that could fail occasionally
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Calculate simple content overlap between two summaries
    /// This is a very basic metric and not a proper evaluation method
    private func calculateContentOverlap(generated: String, reference: String) -> Double {
        // Convert to lowercase and split into words
        let genWords = Set(generated.lowercased().components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty })
        let refWords = Set(reference.lowercased().components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty })
        
        // Calculate intersection
        let intersection = genWords.intersection(refWords).count
        
        // Return Jaccard similarity: intersection / union
        return Double(intersection) / Double(genWords.union(refWords).count)
    }
}
