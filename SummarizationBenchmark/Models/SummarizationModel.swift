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
        // 1.5B Models
        SummarizationModel(
            name: "DeepSeek-R1-Qwen-1.5B",
            modelId: "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B",
            size: .small,
            configuration: ModelConfiguration(
                id: "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B",
                defaultPrompt: "Summarize the following text step by step:",
                extraEOSTokens: ["<|end|>"],
                temperature: 0.6,
                maxTokens: 200,
                additionalMetadata: [
                    "type": "reasoning",
                    "quantization": "4bit"
                ]
            )
        ),
        
        SummarizationModel(
            name: "Qwen2.5-1.5B-Instruct",
            modelId: "mlx-community/Qwen2.5-1.5B-Instruct-4bit",
            size: .small,
            configuration: ModelConfiguration(
                id: "mlx-community/Qwen2.5-1.5B-Instruct-4bit",
                defaultPrompt: "Please provide a concise summary:",
                temperature: 0.7,
                maxTokens: 150,
                additionalMetadata: [
                    "type": "instruct",
                    "quantization": "4bit"
                ]
            )
        ),
        
        // 8B Models
        SummarizationModel(
            name: "DeepSeek-R1-Qwen3-8B",
            modelId: "lmstudio-community/DeepSeek-R1-0528-Qwen3-8B-MLX-4bit",
            size: .large,
            configuration: ModelConfiguration(
                id: "lmstudio-community/DeepSeek-R1-0528-Qwen3-8B-MLX-4bit",
                defaultPrompt: "Think step by step and provide a comprehensive summary:",
                extraEOSTokens: ["<|end|>"],
                temperature: 0.6,
                maxTokens: 250,
                additionalMetadata: [
                    "type": "reasoning",
                    "quantization": "4bit",
                    "context_length": "32768"
                ]
            )
        ),
        
        SummarizationModel(
            name: "Meta-Llama-3-8B",
            modelId: "mlx-community/Meta-Llama-3-8B-Instruct-4bit",
            size: .large,
            configuration: ModelConfiguration(
                id: "mlx-community/Meta-Llama-3-8B-Instruct-4bit",
                defaultPrompt: "Summarize the following text:",
                temperature: 0.7,
                maxTokens: 200,
                additionalMetadata: [
                    "type": "instruct",
                    "quantization": "4bit"
                ]
            )
        ),
        
        // Дополнительная модель Llama 3.2 1B для тестирования
        SummarizationModel(
            name: "Llama-3.2-1B",
            modelId: "mlx-community/Llama-3.2-1B-Instruct-4bit",
            size: .small,
            configuration: ModelConfiguration(
                id: "mlx-community/Llama-3.2-1B-Instruct-4bit",
                defaultPrompt: "Summarize:",
                temperature: 0.7,
                maxTokens: 180,
                additionalMetadata: [
                    "type": "instruct",
                    "quantization": "4bit"
                ]
            )
        )
    ]
}

// MARK: - Static Helper Methods
extension SummarizationModel {
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
