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
    
    /// Доступные модели
    @Published var availableModels: [PythonModel] = [
        PythonModel(id: "mlx-community/SmolLM3-3B-4bit", name: "SmolLM3 3B 4bit", description: ""),
        PythonModel(id: "mlx-community/gemma-3-4b-it-4bit", name: "gemma-3-4b-it-4bit", description: ""),
    ]
    
    /// Выбранная модель
    @Published var selectedModel: PythonModel!
    
    /// Максимальное количество токенов для генерации
    @Published var maxTokens: Int = 256
    
    /// Температура для генерации (0.0-1.0)
    @Published var temperature: Double = 0.3
    
    /// Top-p для генерации (0.0-1.0)
    @Published var topP: Double = 0.8
    
    /// Зависимости установлены
    @Published var dependenciesInstalled: Bool = false
    
    // MARK: - Private Properties
    
    /// Сервис для работы с Python-моделями
    private let pythonModelService = PythonModelService()
    
    /// Отмена задачи
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Выбираем первую модель по умолчанию
        self.selectedModel = availableModels.first!
        
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
        
        do {
            let result = try await pythonModelService.summarizeText(
                text,
                modelPath: selectedModel.id,
                maxTokens: maxTokens,
                temperature: temperature,
                topP: topP
            )
            
            await MainActor.run {
                self.summary = result
                self.errorMessage = ""
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Ошибка суммаризации: \(error.localizedDescription)"
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
            }
        }
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
}
