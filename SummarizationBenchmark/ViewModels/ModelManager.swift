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
    
    private var loadingTasks: [String: Task<Void, Never>] = [:]
    
    func loadModel(_ model: SummarizationModel) async throws {
        // Проверяем, не загружена ли уже модель
        guard loadedModels[model.modelId] == nil else {
            return // Уже загружена
        }
        
        // Проверяем, не загружается ли уже
        guard loadingTasks[model.modelId] == nil else {
            return // Уже загружается
        }
        
        isLoading = true
        loadingStatus = "Loading \(model.name)..."
        errorMessage = nil
        loadingProgress = 0.0
        
        let task = Task { @MainActor in
            do {
                // Настройка памяти GPU в зависимости от размера модели
                let memoryLimit = Int(Double(model.memoryRequirement) * 0.8 * 1024 * 1024) // 80% от ожидаемого в MB
                MLX.Device.setCacheLimit(memoryLimit)
                
                // Создаем MLX конфигурацию
                let mlxConfig = MLXLLM.ModelConfiguration(id: model.modelId)
                
                let container = try await LLMModelFactory.shared.loadContainer(
                    configuration: mlxConfig
                ) { [weak self] progress in
                    Task { @MainActor in
                        self?.loadingProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                    }
                }
                
                self.loadedModels[model.modelId] = container
                self.loadingProgress = 1.0
                self.loadingStatus = "\(model.name) loaded successfully"
            } catch {
                self.errorMessage = "Failed to load model: \(error.localizedDescription)"
            }
            
            self.loadingTasks[model.modelId] = nil
            
            if self.loadingTasks.isEmpty {
                self.isLoading = false
            }
        }
        
        loadingTasks[model.modelId] = task
    }
    
    func unloadModel(_ modelId: String) {
        // Отменяем загрузку, если идет
        loadingTasks[modelId]?.cancel()
        loadingTasks[modelId] = nil
        
        // Удаляем модель из загруженных
        loadedModels[modelId] = nil
        
        // Обновляем состояние загрузки
        if loadingTasks.isEmpty {
            isLoading = false
        }
        
        // Очищаем память GPU
        MLX.Device.defaultDevice.resetMemory()
    }
    
    func unloadAllModels() {
        // Отменяем все загрузки
        loadingTasks.values.forEach { $0.cancel() }
        loadingTasks.removeAll()
        
        // Удаляем все модели из загруженных
        loadedModels.removeAll()
        
        // Обновляем состояние загрузки
        isLoading = false
        
        // Очищаем память GPU
        MLX.Device.defaultDevice.resetMemory()
    }
    
    func isModelLoaded(_ modelId: String) -> Bool {
        return loadedModels[modelId] != nil
    }
    
    func isModelLoading(_ modelId: String) -> Bool {
        return loadingTasks[modelId] != nil
    }
    
    // Получение информации о памяти
    func getMemoryInfo() -> (used: Int, total: Int) {
        // В MLX Swift API пока нет прямого метода memoryInfo(),
        // поэтому будем использовать приближенные значения
        let device = MLX.Device.defaultDevice
        let total = device.cacheLimit
        
        // Использованная память - это приблизительно 80% от кэша для загруженных моделей
        let used = loadedModelIds.reduce(0) { sum, modelId in
            if let model = SummarizationModel.model(withId: modelId) {
                return sum + Int(Double(model.memoryRequirement) * 0.8 * 1024 * 1024) // MB -> bytes
            }
            return sum
        }
        
        return (used: used, total: total)
    }
    
    // Получение списка загруженных моделей
    var loadedModelIds: [String] {
        Array(loadedModels.keys)
    }
    
    // Общий размер загруженных моделей (приблизительно)
    var estimatedMemoryUsage: Double {
        let loadedModelSizes = loadedModelIds.compactMap { modelId in
            SummarizationModel.model(withId: modelId)?.memoryRequirement
        }
        return loadedModelSizes.reduce(0, +)
    }
}
