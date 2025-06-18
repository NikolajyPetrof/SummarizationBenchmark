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
import MLXLLM
import MLXLMCommon

public class SummarizationPipeline {
    private var modelContainer: ModelContainer?
    private let configuration: ModelConfiguration
    
    private var modelId: String { configuration.id }
    
    // Statistics and metrics
    public var lastInferenceTime: TimeInterval = 0
    public var totalTokensGenerated: Int = 0
    public var tokensPerSecond: Double = 0
    
    // Memory tracking
    private var memoryBefore: UInt64 = 0
    private var memoryAfter: UInt64 = 0
    
    enum LoadState {
        case idle
        case loaded(ModelContainer)
    }
    
    private var loadState = LoadState.idle
    
    /// Creates a new summarization pipeline from a model ID
    /// - Parameter modelId: ID of the model to load
    public init(modelId: String) throws {
        guard let modelConfiguration = SummarizationModel.model(withId: modelId)?.configuration else {
            throw SummarizationError.modelNotFound(modelId)
        }
        
        self.configuration = modelConfiguration
        print("🔧 Initialized pipeline for model: \(modelId)")
    }
    
    /// Load and return the model -- can be called multiple times
    private func load() async throws -> ModelContainer {
        switch loadState {
        case .idle:
            // Limit the buffer cache
            MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)
            
            // Use a pre-defined model configuration based on our model ID
            let modelConfiguration: MLXLMCommon.ModelConfiguration
            
            // Map our model IDs to LLMRegistry configurations
            switch configuration.id {
            case "microsoft/Phi-3.5-mini-instruct-4bit":
                modelConfiguration = LLMRegistry.phi3_5_4bit
            case "Qwen/Qwen2.5-1.5B-Instruct-4bit":
                modelConfiguration = LLMRegistry.qwen2_5_1_5b
            case "Qwen/Qwen2.5-7B-Instruct-4bit":
                modelConfiguration = LLMRegistry.qwen2_5_7b
            case "microsoft/Phi-3-mini-4k-instruct-4bit":
                modelConfiguration = LLMRegistry.phi4bit
            default:
                // Create a custom configuration for unknown models
                modelConfiguration = MLXLMCommon.ModelConfiguration(
                    id: configuration.id,
                    defaultPrompt: configuration.defaultPrompt
                )
            }
            
            let modelContainer = try await LLMModelFactory.shared.loadContainer(
                configuration: modelConfiguration
            ) { progress in
                Task { @MainActor in 
                    print("📥 Downloading \(self.configuration.id): \(Int(progress.fractionCompleted * 100))%")
                }
            }
            
            let numParams = await modelContainer.perform { context in
                context.model.numParameters()
            }
            
            print("✅ Loaded \(configuration.id). Weights: \(numParams / (1024*1024))M")
            loadState = .loaded(modelContainer)
            return modelContainer
            
        case .loaded(let modelContainer):
            return modelContainer
        }
    }
    
    /// Generates a summary for the given text
    /// - Parameters:
    ///   - text: Input text to summarize
    ///   - maxTokens: Optional maximum tokens to generate
    ///   - temperature: Optional temperature for generation
    /// - Returns: Summary result with performance metrics
    public func summarize(
        text: String,
        maxTokens: Int? = nil,
        temperature: Float? = nil
    ) async throws -> SummarizationResult {
        // Capture starting memory usage
        memoryBefore = memoryUsage()
        
        let prompt = configuration.createPrompt(for: text)
        
        // Parameters for generation
        let maxLen = maxTokens ?? configuration.maxTokens
        let temp = temperature ?? configuration.temperature
        
        // Load model
        let modelContainer = try await load()
        
        // Start timing
        let startTime = Date()
        
        // Set random seed for reproducible generation
        MLXRandom.seed(UInt64(Date.timeIntervalSinceReferenceDate * 1000))
        
        let (generatedText, tokenCount) = try await modelContainer.perform { (context: ModelContext) -> (String, Int) in
            let lmInput = try await context.processor.prepare(input: UserInput(chat: [
                .system("You are a helpful assistant that provides concise summaries."),
                .user(prompt)
            ]))
            
            let generateParameters = GenerateParameters(
                maxTokens: maxLen, 
                temperature: temp,
                topP: 0.9
            )
            
            let stream = try MLXLMCommon.generate(
                input: lmInput, parameters: generateParameters, context: context)
            
            var localGeneratedText = ""
            var localTokenCount = 0
            
            for await generation in stream {
                if let chunk = generation.chunk {
                    localGeneratedText += chunk
                    localTokenCount += 1
                }
            }
            
            return (localGeneratedText, localTokenCount)
        }
        
        // Calculate inference time
        lastInferenceTime = Date().timeIntervalSince(startTime)
        
        // Clean up generated text
        let cleanedGeneratedText = generatedText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Calculate tokens per second
        totalTokensGenerated = tokenCount
        tokensPerSecond = Double(totalTokensGenerated) / lastInferenceTime
        
        // Capture ending memory usage
        memoryAfter = memoryUsage()
        
        return SummarizationResult(
            originalText: text,
            summary: cleanedGeneratedText,
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
