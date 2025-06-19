//
//  SummarizationModel.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.06.2025.
//

import Foundation

struct SummarizationModel: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let modelId: String
    let size: ModelSize
    let configuration: ModelConfiguration
    
    enum ModelSize: String, CaseIterable {
        case small = "1.5B"
        case large = "8B"
        
        var expectedMemory: Double {
            switch self {
            case .small: return 2.0  // GB
            case .large: return 8.0  // GB
            }
        }
        
        var color: String {
            switch self {
            case .small: return "green"
            case .large: return "orange"
            }
        }
    }
    
    // MARK: - Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(modelId) // Используем modelId для уникальности
    }
    
    static func == (lhs: SummarizationModel, rhs: SummarizationModel) -> Bool {
        lhs.modelId == rhs.modelId
    }
    
    // MARK: - Utility methods
    var displayName: String {
        return "\(name) (\(size.rawValue))"
    }
    
    var memoryRequirement: String {
        return "~\(String(format: "%.1f", size.expectedMemory))GB"
    }
    
    var isLargeModel: Bool {
        return size == .large
    }
}

extension SummarizationModel {
    static let availableModels: [SummarizationModel] = [
        
        SummarizationModel(
                name: "DeepSeek R1 Distill Qwen 1.5B",
                modelId: "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B",
                size: .small,
                configuration: ModelConfiguration(
                    id: "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B",
                    defaultPrompt: "",
                    extraEOSTokens: ["<|end|>"],
                    temperature: 0.6,
                    maxTokens: 200,
                    additionalMetadata: [
                        "type": "decoder-only",
                        "quantization": "4bit",
                        "engine": "mlx"
                    ]
                )
            ),

            // 8B Models
            SummarizationModel(
                name: "DeepSeek R1 Distill Llama 8B",
                modelId: "mlx-community/DeepSeek-R1-Distill-Llama-8B",
                size: .large,
                configuration: ModelConfiguration(
                    id: "mlx-community/DeepSeek-R1-Distill-Llama-8B",
                    defaultPrompt: "",
                    temperature: 0.7,
                    maxTokens: 150,
                    additionalMetadata: [
                        "type": "decoder-only",
                        "quantization": "4bit",
                        "engine": "mlx"
                    ]
                )
            ),

            SummarizationModel(
                name: "BART Large CNN",
                modelId: "facebook/bart-large-cnn",
                size: .large,
                configuration: ModelConfiguration(
                    id: "facebook/bart-large-cnn",
                    defaultPrompt: "",
                    extraEOSTokens: ["</s>"],
                    temperature: 0.6,
                    maxTokens: 250,
                    additionalMetadata: [
                        "type": "encoder-decoder",
                        "quantization": "none",
                        "engine": "transformers"
                    ]
                )
            ),

            SummarizationModel(
                name: "DeepSeek R1‑0528 Qwen3 8B 4bit DWQ",
                modelId: "mlx-community/DeepSeek-R1-0528-Qwen3-8B-4bit-DWQ",
                size: .large,
                configuration: ModelConfiguration(
                    id: "mlx-community/DeepSeek-R1-0528-Qwen3-8B-4bit-DWQ",
                    defaultPrompt: "",
                    temperature: 0.7,
                    maxTokens: 200,
                    additionalMetadata: [
                        "type": "decoder-only",
                        "quantization": "4bit",
                        "engine": "mlx"
                    ]
                )
            ),

            SummarizationModel(
                name: "ModernBERT base",
                modelId: "answerdotai/ModernBERT-base",
                size: .large,
                configuration: ModelConfiguration(
                    id: "answerdotai/ModernBERT-base",
                    defaultPrompt: "",
                    temperature: 0.7,
                    maxTokens: 200,
                    additionalMetadata: [
                        "type": "encoder-only",
                        "quantization": "none",
                        "engine": "transformers"
                    ]
                )
            ),

            SummarizationModel(
                name: "ModernBERT large",
                modelId: "answerdotai/ModernBERT-large",
                size: .large,
                configuration: ModelConfiguration(
                    id: "answerdotai/ModernBERT-large",
                    defaultPrompt: "",
                    temperature: 0.7,
                    maxTokens: 200,
                    additionalMetadata: [
                        "type": "encoder-only",
                        "quantization": "none",
                        "engine": "transformers"
                    ]
                )
            ),

            SummarizationModel(
                name: "Llama 3.2 3B Instruct",
                modelId: "mlx-community/Llama-3.2-3B-Instruct-4bit",
                size: .large,
                configuration: ModelConfiguration(
                    id: "mlx-community/Llama-3.2-3B-Instruct-4bit",
                    defaultPrompt: "",
                    temperature: 0.7,
                    maxTokens: 200,
                    additionalMetadata: [
                        "type": "decoder-only",
                        "quantization": "4bit",
                        "engine": "mlx"
                    ]
                )
            ),

            SummarizationModel(
                name: "Qwen2.5 1.5B Instruct",
                modelId: "mlx-community/Qwen2.5-1.5B-Instruct-4bit",
                size: .small,
                configuration: ModelConfiguration(
                    id: "mlx-community/Qwen2.5-1.5B-Instruct-4bit",
                    defaultPrompt: "",
                    temperature: 0.7,
                    maxTokens: 200,
                    additionalMetadata: [
                        "type": "decoder-only",
                        "quantization": "4bit",
                        "engine": "mlx"
                    ]
                )
            ),

            SummarizationModel(
                name: "Meta Llama 3 8B Instruct 4bit",
                modelId: "mlx-community/Meta-Llama-3-8B-Instruct-4bit",
                size: .large,
                configuration: ModelConfiguration(
                    id: "mlx-community/Meta-Llama-3-8B-Instruct-4bit",
                    defaultPrompt: "",
                    temperature: 0.7,
                    maxTokens: 200,
                    additionalMetadata: [
                        "type": "decoder-only",
                        "quantization": "4bit",
                        "engine": "mlx"
                    ]
                )
            )
        
        
    ]
}

// MARK: - Static Helper Methods
extension SummarizationModel {
    /// Get the default prompt for all models
    static var defaultPrompt: String {
        return ModelConfiguration.defaultSummarizationPrompt
    }
    
    /// Получить модель по ID
    static func model(withId id: String) -> SummarizationModel? {
        return availableModels.first { $0.modelId == id }
    }
    
    /// Модели определенного размера
    static func models(ofSize size: ModelSize) -> [SummarizationModel] {
        return availableModels.filter { $0.size == size }
    }
    
    /// Только небольшие модели (1.5B)
    static var smallModels: [SummarizationModel] {
        return models(ofSize: .small)
    }
    
    /// Только большие модели (8B)
    static var largeModels: [SummarizationModel] {
        return models(ofSize: .large)
    }
    
    /// Модели с reasoning способностями
    static var reasoningModels: [SummarizationModel] {
        return availableModels.filter {
            $0.configuration.additionalMetadata["type"] == "reasoning"
        }
    }
    
    /// Стандартные инструкционные модели
    static var instructModels: [SummarizationModel] {
        return availableModels.filter {
            $0.configuration.additionalMetadata["type"] == "instruct"
        }
    }
    
    /// Количество доступных моделей
    static var totalCount: Int {
        return availableModels.count
    }
    
    /// Общие требования к памяти для всех моделей
    static var totalMemoryRequirement: Double {
        return availableModels.map { $0.size.expectedMemory }.reduce(0, +)
    }
}
