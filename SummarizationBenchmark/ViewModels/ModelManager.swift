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
    // Ссылка на AppState для доступа к другим менеджерам
    weak var appState: AppState?
    
    @Published var loadedModels: [String: ModelContainer] = [:]
    @Published var isLoading = false
    @Published var loadingProgress: Double = 0.0
    @Published var loadingStatus = ""
    @Published var errorMessage: String?
    
    // Добавляем индивидуальный прогресс для каждой модели
    @Published var modelLoadingProgress: [String: Double] = [:]
    @Published var modelLoadingStatus: [String: String] = [:]
    @Published var modelErrors: [String: String] = [:]
    
    private var loadingTasks: [String: Task<Void, Never>] = [:]
    
    // Ограничение на количество одновременных загрузок
    private let maxConcurrentLoads = 2
    private var loadingQueue: [String] = []
    
    init(appState: AppState? = nil) {
        self.appState = appState
    }
    
    func loadModel(_ model: SummarizationModel) async throws {
        print("ModelManager: Попытка загрузить модель: \(model.name) (\(model.modelId))")
        
        // Проверяем, не загружена ли уже модель
        guard loadedModels[model.modelId] == nil else {
            print("ModelManager: Модель \(model.name) уже загружена")
            return // Уже загружена
        }
        
        // Проверяем, не загружается ли уже
        guard loadingTasks[model.modelId] == nil else {
            print("ModelManager: Модель \(model.name) уже в процессе загрузки")
            return // Уже загружается
        }
        
        print("ModelManager: Начинаем загрузку модели \(model.name)")
        isLoading = true
        loadingStatus = "Loading \(model.name)..."
        errorMessage = nil
        loadingProgress = 0.0
        modelLoadingProgress[model.modelId] = 0.0
        modelLoadingStatus[model.modelId] = "Loading..."
        // Очищаем предыдущие ошибки
        modelErrors[model.modelId] = nil
        
        // Добавляем модель в очередь загрузки
        loadingQueue.append(model.modelId)
        
        // Проверяем, можно ли начать загрузку
        if loadingQueue.count > maxConcurrentLoads {
            print("ModelManager: Ожидаем освобождения слота для загрузки \(model.name)")
            await waitForSlot()
        }
        
        let task = Task { @MainActor in
            // Попытки загрузки с повторами
            var attempts = 0
            // Увеличиваем количество попыток для моделей Gemma
            let maxAttempts = model.modelId.contains("gemma") ? 5 : 3
            print("ModelManager: Максимальное количество попыток для \(model.name): \(maxAttempts)")
            var lastError: Error?
            
            while attempts < maxAttempts {
                attempts += 1
                print("ModelManager: Попытка загрузки \(attempts)/\(maxAttempts) для \(model.name)")
                
                do {
                    // Настройка памяти GPU в зависимости от размера модели
                    let baseMemoryRequirement = Double(model.memoryRequirement) ?? 0
                    
                    // Увеличиваем выделение памяти для моделей Gemma
                    let scaleFactor = model.modelId.contains("gemma") ? 10 : 0.8
                    print("ModelManager: Используем коэффициент масштабирования памяти: \(scaleFactor) для \(model.name)")
                    
                    let scaledMemoryRequirement = baseMemoryRequirement * scaleFactor
                    let memoryRequirementMB = scaledMemoryRequirement * 1024 * 1024
                    let memoryLimit = Int(memoryRequirementMB)
                    print("ModelManager: Выделяем \(scaledMemoryRequirement)GB памяти для \(model.name)")
                    MLX.GPU.set(cacheLimit: memoryLimit)
                    
                    // Создаем LLM конфигурацию
                    let llmConfig = MLXLMCommon.ModelConfiguration(
                        id: model.modelId,
                        defaultPrompt: model.configuration.defaultPrompt
                    )
                    
                    print("ModelManager: Начинаем загрузку контейнера для \(model.name)")
                    let container = try await LLMModelFactory.shared.loadContainer(
                        configuration: llmConfig
                    ) { [weak self] progress in
                        Task { @MainActor in
                            let clampedProgress = min(max(progress.fractionCompleted, 0.0), 1.0)
                            print("ModelManager: Прогресс загрузки \(model.name): \(Int(clampedProgress * 100))%")
                            self?.loadingProgress = clampedProgress
                            self?.modelLoadingProgress[model.modelId] = clampedProgress
                        }
                    }
                    
                    print("ModelManager: Контейнер для \(model.name) успешно загружен")
                    print("ModelManager: Модель \(model.name) успешно загружена")
                    self.loadedModels[model.modelId] = container
                    self.loadingProgress = 1.0
                    self.modelLoadingProgress[model.modelId] = 1.0
                    self.loadingStatus = "\(model.name) loaded successfully"
                    self.modelLoadingStatus[model.modelId] = "Loaded"
                    print("ModelManager: Текущие загруженные модели: \(self.loadedModels.keys)")
                    
                    // Успешная загрузка, выходим из цикла
                    break
                    
                } catch {
                    lastError = error
                    print("ModelManager: Ошибка при попытке \(attempts): \(error)")
                    
                    // Если это не последняя попытка и ошибка связана с сетью, ждем перед повтором
                    if attempts < maxAttempts {
                        // Расширенная обработка сетевых ошибок
                        if let urlError = error as? URLError {
                            // Разные задержки в зависимости от типа ошибки
                            var waitTime = 5
                            
                            switch urlError.code {
                            case .timedOut:
                                waitTime = 8
                                print("ModelManager: Ошибка таймаута, ждем \(waitTime) секунд...")
                            case .notConnectedToInternet, .networkConnectionLost:
                                waitTime = 10
                                print("ModelManager: Проблема с сетью, ждем \(waitTime) секунд...")
                            default:
                                waitTime = 5
                                print("ModelManager: Сетевая ошибка \(urlError.code), ждем \(waitTime) секунд...")
                            }
                            
                            self.modelLoadingStatus[model.modelId] = "Retrying in \(waitTime)s..."
                            try? await Task.sleep(nanoseconds: UInt64(waitTime) * 1_000_000_000)
                        } else if model.modelId.contains("gemma") {
                            // Для моделей Gemma повторяем даже при других ошибках
                            print("ModelManager: Особая обработка для Gemma, повторяем через 10 секунд...")
                            self.modelLoadingStatus[model.modelId] = "Retrying in 10s..."
                            try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 секунд
                        } else {
                            // Для других ошибок не повторяем
                            break
                        }
                    }
                }
            }
            
            // Если все попытки неудачны, обрабатываем ошибку
            if let error = lastError {
                // Улучшенная обработка сетевых ошибок
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet:
                        self.errorMessage = "Отсутствует подключение к интернету. Проверьте соединение и попробуйте снова."
                        self.modelErrors[model.modelId] = "Отсутствует подключение к интернету"
                    case .cannotFindHost, .cannotConnectToHost:
                        self.errorMessage = "Не удалось подключиться к серверу Hugging Face. Проверьте соединение или попробуйте позже."
                        self.modelErrors[model.modelId] = "Не удалось подключиться к серверу"
                    case .timedOut:
                        self.errorMessage = "Превышено время ожидания ответа от сервера после \(maxAttempts) попыток. Проверьте скорость соединения."
                        self.modelErrors[model.modelId] = "Превышено время ожидания после \(maxAttempts) попыток"
                    default:
                        self.errorMessage = "Сетевая ошибка: \(urlError.localizedDescription)"
                        self.modelErrors[model.modelId] = "Сетевая ошибка: \(urlError.localizedDescription)"
                    }
                } else {
                    self.errorMessage = "Ошибка загрузки модели: \(error.localizedDescription)"
                    self.modelErrors[model.modelId] = "Ошибка загрузки: \(error.localizedDescription)"
                }
                
                // Сбрасываем статус загрузки
                self.loadingProgress = 0
                self.modelLoadingProgress[model.modelId] = 0
                self.loadingStatus = "Ошибка загрузки"
                self.modelLoadingStatus[model.modelId] = "Error"
                
                print("ModelManager: Ошибка загрузки модели \(model.name): \(error)")
                print("ModelManager: Тип ошибки: \(type(of: error))")
            }
            
            // Очищаем задачу загрузки
            self.loadingTasks[model.modelId] = nil
            
            // Обновляем общее состояние загрузки
            if self.loadingTasks.isEmpty {
                self.isLoading = false
            }
            
            // Удаляем модель из очереди загрузки
            if let index = self.loadingQueue.firstIndex(of: model.modelId) {
                self.loadingQueue.remove(at: index)
            }
        }
        
        loadingTasks[model.modelId] = task
        await task.value
    }
    
    // Ожидание освобождения слота для загрузки
    private func waitForSlot() async {
        while loadingQueue.count >= maxConcurrentLoads {
            await Task.yield()
        }
    }
    
    func unloadModel(_ modelId: String) {
        // Отменяем загрузку, если идет
        loadingTasks[modelId]?.cancel()
        loadingTasks[modelId] = nil
        
        // Удаляем модель из загруженных
        loadedModels[modelId] = nil
        
        // Очищаем индивидуальные состояния модели
        modelLoadingProgress[modelId] = nil
        modelLoadingStatus[modelId] = nil
        modelErrors[modelId] = nil
        
        // Удаляем из очереди загрузки
        if let index = loadingQueue.firstIndex(of: modelId) {
            loadingQueue.remove(at: index)
        }
        
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
        
        // Очищаем все индивидуальные состояния
        modelLoadingProgress.removeAll()
        modelLoadingStatus.removeAll()
        modelErrors.removeAll()
        
        // Очищаем очередь загрузки
        loadingQueue.removeAll()
        
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
    
    // Получение индивидуального прогресса модели
    func getModelProgress(_ modelId: String) -> Double {
        return modelLoadingProgress[modelId] ?? 0.0
    }
    
    // Получение индивидуального статуса модели
    func getModelStatus(_ modelId: String) -> String {
        return modelLoadingStatus[modelId] ?? ""
    }
    
    // Получение индивидуальной ошибки модели
    func getModelError(_ modelId: String) -> String? {
        return modelErrors[modelId]
    }
    
    // Проверка наличия ошибки у модели
    func hasModelError(_ modelId: String) -> Bool {
        return modelErrors[modelId] != nil
    }
    
    // Получение информации о памяти
    func getMemoryInfo() -> (used: Int, total: Int) {
        // Используем MLX GPU API для получения реальных значений
        let total = MLX.GPU.memoryLimit
        let used = MLX.GPU.peakMemory
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
