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
    @Published var loadedModels: [String: ModelContainer] = [:]
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
                // Break up complex expression into simpler sub-expressions
                let baseMemoryRequirement = Double(model.memoryRequirement) ?? 0
                let scaledMemoryRequirement = baseMemoryRequirement * 0.8
                let memoryRequirementMB = scaledMemoryRequirement * 1024 * 1024
                let memoryLimit = Int(memoryRequirementMB) // 80% от ожидаемого в MB
                MLX.GPU.set(cacheLimit: memoryLimit)
                
                // Создаем LLM конфигурацию
                let llmConfig = MLXLMCommon.ModelConfiguration(
                    id: model.modelId,
                    defaultPrompt: model.configuration.defaultPrompt
                )
                
                let container = try await LLMModelFactory.shared.loadContainer(
                    configuration: llmConfig
                ) { [weak self] progress in
                    Task { @MainActor in
                        // Ограничиваем значение прогресса в диапазоне от 0 до 1
                        let clampedProgress = min(max(progress.fractionCompleted, 0.0), 1.0)
                        self?.loadingProgress = clampedProgress
                    }
                }
                
                self.loadedModels[model.modelId] = container
                self.loadingProgress = 1.0
                self.loadingStatus = "\(model.name) loaded successfully"
            } catch {
                // Улучшенная обработка сетевых ошибок
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet:
                        self.errorMessage = "Отсутствует подключение к интернету. Проверьте соединение и попробуйте снова."
                    case .cannotFindHost, .cannotConnectToHost:
                        self.errorMessage = "Не удалось подключиться к серверу Hugging Face. Проверьте соединение или попробуйте позже."
                    case .timedOut:
                        self.errorMessage = "Превышено время ожидания ответа от сервера. Проверьте скорость соединения."
                    default:
                        self.errorMessage = "Сетевая ошибка: \(urlError.localizedDescription)"
                    }
                } else {
                    self.errorMessage = "Ошибка загрузки модели: \(error.localizedDescription)"
                }
                
                // Сбрасываем статус загрузки
                self.loadingProgress = 0
                self.loadingStatus = "Ошибка загрузки"
                
                print("Ошибка загрузки модели: \(error)")
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
        MLX.GPU.resetPeakMemory()
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
        MLX.GPU.resetPeakMemory()
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
        let device = MLX.GPU.self
        let total = max(device.cacheLimit, 1) // Гарантируем, что total не равен 0
        
        // Использованная память - это приблизительно 80% от кэша для загруженных моделей
        var used = 0
        
        for modelId in loadedModelIds {
            if let model = SummarizationModel.model(withId: modelId),
               let baseRequirement = Double(model.memoryRequirement),
               baseRequirement.isFinite { // Проверяем, что значение конечное
                let scaledRequirement = baseRequirement * 0.8
                let bytesRequirement = scaledRequirement * 1024 * 1024 // MB -> bytes
                used += Int(bytesRequirement)
            }
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
            if let model = SummarizationModel.model(withId: modelId),
               let memoryReq = Double(model.memoryRequirement) {
                return memoryReq
            }
            return nil
        }
        return loadedModelSizes.reduce(0) { sum, value in
            return sum + value
        }
    }
}
