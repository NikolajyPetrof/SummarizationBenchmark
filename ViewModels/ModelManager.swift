//
//  ModelManager.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.06.2025.
//

import Foundation
import MLX
import MLXLLM
import MLXLMCommon

@MainActor
class ModelManager: ObservableObject {
    @Published var loadedModels: [String: LLMModelContainer] = [:]
    @Published var isLoading = false
    @Published var loadingProgress: Double = 0.0
    @Published var loadingStatus = ""
    @Published var errorMessage: String?
    
    func loadModel(_ model: SummarizationModel) async throws {
        guard loadedModels[model.modelId] == nil else {
            return // Уже загружена
        }
        
        isLoading = true
        loadingStatus = "Loading \(model.name)..."
        errorMessage = nil
        
        do {
            // Настройка памяти GPU
            let memoryLimit = Int(model.size.expectedMemory * 1024 * 1024 * 1024)
            MLX.GPU.set(cacheLimit: memoryLimit)
            
            let container = try await LLMModelFactory.shared.loadContainer(
                configuration: model.configuration
            ) { progress in
                Task { @MainActor in
                    self.loadingProgress = progress.fractionCompleted
                    self.loadingStatus = "Downloading: \(Int(progress.fractionCompleted * 100))%"
                }
            }
            
            loadedModels[model.modelId] = container
            loadingStatus = "\(model.name) loaded successfully"
            
        } catch {
            errorMessage = "Failed to load \(model.name): \(error.localizedDescription)"
            throw error
        }
        
        isLoading = false
    }
    
    func unloadModel(_ modelId: String) {
        loadedModels.removeValue(forKey: modelId)
        MLX.GPU.clearCache()
    }
    
    func unloadAllModels() {
        loadedModels.removeAll()
        MLX.GPU.clearCache()
    }
}
