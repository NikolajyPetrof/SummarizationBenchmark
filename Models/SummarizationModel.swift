//
//  SummarizationModel.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.06.2025.
//

import Foundation
import MLXLLM

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
    }
}

extension SummarizationModel {
    static let availableModels: [SummarizationModel] = [
        SummarizationModel(
            name: "DeepSeek-R1-Qwen-1.5B",
            modelId: "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B",
            size: .small,
            configuration: ModelConfiguration(
                id: "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B",
                defaultPrompt: "Summarize the following text step by step:",
                extraEOSTokens: ["<|end|>"]
            )
        ),
        SummarizationModel(
            name: "Qwen2.5-1.5B-Instruct",
            modelId: "mlx-community/Qwen2.5-1.5B-Instruct-4bit",
            size: .small,
            configuration: ModelConfiguration(
                id: "mlx-community/Qwen2.5-1.5B-Instruct-4bit",
                defaultPrompt: "Please provide a concise summary:"
            )
        ),
        SummarizationModel(
            name: "DeepSeek-R1-Qwen3-8B",
            modelId: "lmstudio-community/DeepSeek-R1-0528-Qwen3-8B-MLX-4bit",
            size: .large,
            configuration: ModelConfiguration(
                id: "lmstudio-community/DeepSeek-R1-0528-Qwen3-8B-MLX-4bit",
                defaultPrompt: "Think step by step and provide a comprehensive summary:",
                extraEOSTokens: ["<|end|>"]
            )
        ),
        SummarizationModel(
            name: "Meta-Llama-3-8B",
            modelId: "mlx-community/Meta-Llama-3-8B-Instruct-4bit",
            size: .large,
            configuration: ModelConfiguration(
                id: "mlx-community/Meta-Llama-3-8B-Instruct-4bit",
                defaultPrompt: "Summarize the following text:"
            )
        )
    ]
}
