//
//  SummarizationPipeline.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.06.2025.
//

import Foundation
import MLX
import MLXFast
import MLXRandom
import MLXTransformers

public class SummarizationPipeline {
    private let model: Model
    private let tokenizer: Tokenizer
    private let configuration: ModelConfiguration
    
    private var modelId: String { configuration.id }
    
    // Statistics and metrics
    public var lastInferenceTime: TimeInterval = 0
    public var totalTokensGenerated: Int = 0
    public var tokensPerSecond: Double = 0
    
    // Memory tracking
    private var memoryBefore: UInt64 = 0
    private var memoryAfter: UInt64 = 0
    
    /// Creates a new summarization pipeline from a model ID
    /// - Parameter modelId: ID of the model to load
    public init(modelId: String) throws {
        guard let modelConfiguration = SummarizationModel.model(withId: modelId)?.configuration else {
            throw SummarizationError.modelNotFound(modelId)
        }
        
        self.configuration = modelConfiguration
        
        // Get model paths from registry
        let modelInfo = try ModelRegistry.getModelInfo(for: modelId)
        
        // Load tokenizer
        self.tokenizer = try Tokenizer(modelInfo.tokenizerPath)
        
        // Load model
        self.model = try Model.load(modelInfo.modelPath)
        
        print("✅ Loaded model: \(modelId)")
        print("📝 Model directory: \(modelInfo.modelPath.deletingLastPathComponent().path)")
    }
    
    /// Generates a summary for the given text
    /// - Parameters:
    ///   - text: The text to summarize
    ///   - maxTokens: Maximum number of tokens to generate (overrides model config if provided)
    ///   - temperature: Temperature for generation (overrides model config if provided)
    /// - Returns: The generated summary
    public func summarize(
        text: String,
        maxTokens: Int? = nil,
        temperature: Float? = nil
    ) throws -> SummarizationResult {
        // Capture starting memory usage
        memoryBefore = memoryUsage()
        
        let prompt = configuration.createPrompt(for: text)
        
        // Parameters for generation
        let maxLen = maxTokens ?? configuration.maxTokens
        let temp = temperature ?? configuration.temperature
        
        // Tokenize the prompt
        var tokens = try tokenizer.encode(prompt)
        
        // Start timing
        let startTime = Date()
        
        // Generate tokens
        let generatedTokens = model.generate(
            input: tokens,
            maxLength: maxLen,
            temperature: Tensor(temp),
            extraEosTokens: configuration.extraEOSTokens.compactMap({ UInt32(tokenizer.encodeSingleToken($0)) }),
            topK: nil,
            topP: nil
        )
        
        // Calculate inference time
        lastInferenceTime = -startTime.timeIntervalSinceNow
        
        // Decode generated tokens
        let generatedText = try tokenizer.decode(generatedTokens)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Calculate tokens per second
        totalTokensGenerated = generatedTokens.count
        tokensPerSecond = Double(totalTokensGenerated) / lastInferenceTime
        
        // Capture ending memory usage
        memoryAfter = memoryUsage()
        
        return SummarizationResult(
            originalText: text,
            summary: generatedText,
            modelId: modelId,
            inferenceTime: lastInferenceTime,
            tokensPerSecond: tokensPerSecond,
            tokensGenerated: totalTokensGenerated,
            memoryUsed: Double(memoryAfter - memoryBefore) / (1024 * 1024) // MB
        )
    }
    
    /// Returns the current memory usage of the process
    private func memoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
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

/// Errors that can occur during summarization
public enum SummarizationError: Error, LocalizedError {
    case modelNotFound(String)
    case failedToLoadModel(String)
    case invalidInput(String)
    case generationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .modelNotFound(let modelId):
            return "Model not found: \(modelId)"
        case .failedToLoadModel(let reason):
            return "Failed to load model: \(reason)"
        case .invalidInput(let reason):
            return "Invalid input: \(reason)"
        case .generationFailed(let reason):
            return "Generation failed: \(reason)"
        }
    }
}

/// Result of a summarization operation
public struct SummarizationResult {
    public let originalText: String
    public let summary: String
    public let modelId: String
    public let inferenceTime: TimeInterval
    public let tokensPerSecond: Double
    public let tokensGenerated: Int
    public let memoryUsed: Double // in MB
    
    public var compressionRatio: Double {
        guard !originalText.isEmpty else { return 0 }
        return Double(summary.count) / Double(originalText.count)
    }
}

// MARK: - Memory Usage Helper
import Darwin
fileprivate struct mach_task_basic_info {
    var virtual_size: UInt64 = 0
    var resident_size: UInt64 = 0
    var resident_size_max: UInt64 = 0
    var user_time: TimeInterval = 0
    var system_time: TimeInterval = 0
    var policy: Int32 = 0
    var suspend_count: Int32 = 0
}
