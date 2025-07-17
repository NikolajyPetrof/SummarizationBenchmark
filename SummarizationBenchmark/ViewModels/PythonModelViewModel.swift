import Foundation
import Combine
import SwiftUI

/// ViewModel для работы с Python-моделями
class PythonModelViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Статус выполнения
    @Published var isProcessing: Bool = false
    
    /// Сообщение о статусе
    @Published var statusMessage: String = ""
    
    /// Сообщение об ошибке
    @Published var errorMessage: String = ""
    
    /// Полный текст ошибки с деталями
    @Published var fullErrorText: String = ""
    
    /// Прогресс выполнения (0.0 - 1.0)
    @Published var progress: Double = 0.0
    
    /// Результат суммаризации
    @Published var summary: String = ""
    
    /// Доступные модели (разделены по типам)
    @Published var availableModels: [PythonModel] = [
        // MLX-optimized models for Apple Silicon
        PythonModel(id: "mlx-community/SmolLM3-3B-4bit", name: "SmolLM3 3B (MLX)", description: "Optimized for Apple Silicon", isMLXModel: true),
        PythonModel(id: "mlx-community/gemma-3-4b-it-4bit", name: "Gemma-3 4B (MLX)", description: "Optimized for Apple Silicon", isMLXModel: true),
        PythonModel(id: "mlx-community/Llama-3.2-1B-Instruct-4bit", name: "Llama-3.2 1B (MLX)", description: "Optimized for Apple Silicon", isMLXModel: true),
        PythonModel(id: "mlx-community/Phi-3.5-mini-instruct-4bit", name: "Phi-3.5 Mini (MLX)", description: "Optimized for Apple Silicon", isMLXModel: true),
        
        // Standard Transformers models
        PythonModel(id: "facebook/bart-large-cnn", name: "BART Large CNN", description: "Reliable summarization model", isMLXModel: false),
        PythonModel(id: "google/gemma-2-2b-it", name: "Gemma-2 2B", description: "Standard model", isMLXModel: false),
        PythonModel(id: "HuggingFaceTB/SmolLM3-3B", name: "SmolLM3 3B (Standard)", description: "Standard model", isMLXModel: false),
    ]
    
    /// Выбранная модель
    @Published var selectedModel: PythonModel!
    
    /// Максимальное количество токенов для генерации
    @Published var maxTokens: Int = 256
    
    /// Температура для генерации (0.0-1.0)
    @Published var temperature: Double = 0.3
    
    /// Таймаут для генерации в секундах
    @Published var timeoutSeconds: Int = 300
    
    /// Top-p для генерации (0.0-1.0)
    @Published var topP: Double = 0.8
    
    /// Использовать MLX оптимизацию
    @Published var useMLX: Bool = true
    
    /// Зависимости установлены
    @Published var dependenciesInstalled: Bool = false
    
    /// Является ли устройство Apple Silicon
    @Published var isAppleSilicon: Bool = false
    
    // MARK: - Private Properties
    
    /// Сервис для работы с Python-моделями
    private let pythonModelService = PythonModelService()
    
    /// Отмена задачи
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Проверяем архитектуру устройства
        #if arch(arm64)
        isAppleSilicon = true
        #else
        isAppleSilicon = false
        #endif
        
        // Выбираем подходящую модель по умолчанию
        if isAppleSilicon {
            // Для Apple Silicon выбираем MLX-модель
            self.selectedModel = availableModels.first { $0.isMLXModel } ?? availableModels.first!
        } else {
            // Для Intel выбираем стандартную модель
            self.selectedModel = availableModels.first { !$0.isMLXModel } ?? availableModels.first!
        }
        
        // Подписываемся на изменения в сервисе
        pythonModelService.$isProcessing
            .receive(on: DispatchQueue.main)
            .assign(to: \.isProcessing, on: self)
            .store(in: &cancellables)
        
        pythonModelService.$statusMessage
            .receive(on: DispatchQueue.main)
            .assign(to: \.statusMessage, on: self)
            .store(in: &cancellables)
        
        pythonModelService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
            
        pythonModelService.$fullErrorText
            .receive(on: DispatchQueue.main)
            .assign(to: \.fullErrorText, on: self)
            .store(in: &cancellables)
        
        pythonModelService.$progress
            .receive(on: DispatchQueue.main)
            .assign(to: \.progress, on: self)
            .store(in: &cancellables)
        
        // Проверяем зависимости при инициализации
        Task {
            await checkDependencies()
        }
    }
    
    // MARK: - Computed Properties
    
    /// Доступные MLX модели
    var mlxModels: [PythonModel] {
        availableModels.filter { $0.isMLXModel }
    }
    
    /// Доступные стандартные модели
    var standardModels: [PythonModel] {
        availableModels.filter { !$0.isMLXModel }
    }
    
    /// Рекомендуемые модели для текущего устройства
    var recommendedModels: [PythonModel] {
        if isAppleSilicon {
            return mlxModels
        } else {
            return standardModels
        }
    }
    
    // MARK: - Public Methods
    
    /// Суммаризирует текст с использованием выбранной модели
    /// - Parameter text: Текст для суммаризации
    func summarizeText(_ text: String) async {
        guard !text.isEmpty else {
            await MainActor.run {
                self.errorMessage = "Текст для суммаризации не может быть пустым"
            }
            return
        }
        
        // Автоматически определяем, использовать ли MLX
        let shouldUseMLX = selectedModel.isMLXModel && isAppleSilicon && useMLX
        
        do {
            let result = try await pythonModelService.summarizeText(
                text,
                modelPath: selectedModel.id,
                maxTokens: maxTokens,
                temperature: temperature,
                topP: topP,
                useMLX: shouldUseMLX,
                timeout: timeoutSeconds,
                verbose: true
            )
            
            await MainActor.run {
                self.summary = result
                self.errorMessage = ""
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Ошибка суммаризации: \(error.localizedDescription)"
                
                // Если это ошибка MLX-модели на неподдерживаемом устройстве
                if selectedModel.isMLXModel && !isAppleSilicon {
                    self.errorMessage = "MLX-модели поддерживаются только на Apple Silicon. Выберите стандартную модель."
                }
            }
        }
    }
    
    /// Проверяет наличие необходимых зависимостей
    func checkDependencies() async {
        let result = await pythonModelService.checkDependencies()
        
        await MainActor.run {
            self.dependenciesInstalled = result.success
            if !result.success {
                self.errorMessage = result.message
            }
        }
    }
    
    /// Устанавливает необходимые зависимости
    func installDependencies() async {
        let result = await pythonModelService.installDependencies()
        
        await MainActor.run {
            self.dependenciesInstalled = result.success
            if !result.success {
                self.errorMessage = result.message
            } else {
                self.statusMessage = "Зависимости успешно установлены"
            }
        }
    }
    
    /// Выбирает рекомендуемую модель для текущего устройства
    func selectRecommendedModel() {
        selectedModel = recommendedModels.first ?? availableModels.first!
    }
    
    /// Сбрасывает ошибки
    func clearErrors() {
        errorMessage = ""
        fullErrorText = ""
    }
}

/// Модель для Python-моделей
struct PythonModel: Identifiable, Hashable {
    /// Идентификатор модели (путь или идентификатор на Hugging Face)
    let id: String
    
    /// Название модели
    let name: String
    
    /// Описание модели
    let description: String
    
    /// Является ли модель MLX-оптимизированной
    let isMLXModel: Bool
    
    /// Рекомендуемые параметры для модели
    var recommendedMaxTokens: Int {
        if isMLXModel {
            return 200  // MLX модели быстрее, можем позволить больше токенов
        } else {
            return 150  // Стандартные модели медленнее
        }
    }
    
    var recommendedTemperature: Double {
        if name.contains("SmolLM") {
            return 0.3
        } else if name.contains("Gemma") {
            return 0.2
        } else if name.contains("Llama") {
            return 0.4
        } else {
            return 0.3
        }
    }
}
