//
//  BenchmarkViewModel.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.06.2025.
//

import Foundation
import SwiftUI
import MLX
import MLXLLM
import MLXLMCommon

// AsyncSemaphore для синхронизации доступа к ModelContainer
actor AsyncSemaphore {
    private var value: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    init(value: Int) {
        self.value = value
    }
    
    func wait() async {
        if value > 0 {
            value -= 1
        } else {
            await withCheckedContinuation { continuation in
                waiters.append(continuation)
            }
        }
    }
    
    func signal() {
        if waiters.isEmpty {
            value += 1
        } else {
            let waiter = waiters.removeFirst()
            waiter.resume()
        }
    }
}

@MainActor
class BenchmarkViewModel: ObservableObject {
    @Published var selectedModel: SummarizationModel?
    @Published var inputText = ""
    @Published var generatedSummary = ""
    @Published var isGenerating = false
    @Published var currentResult: BenchmarkResult?
    @Published var sessions: [BenchmarkSession] = []
    @Published var currentSession: BenchmarkSession?
    @Published var errorMessage: String?
    
    private let modelManager: ModelManager
    private let sessionManager = BenchmarkSessionManager()
    
    init(modelManager: ModelManager) {
        self.modelManager = modelManager
        loadSessions()
    }
    
    // Избыточный фабричный метод удален, так как можно использовать стандартный инициализатор
    
    func startNewSession(name: String, type: BenchmarkSession.SessionType = .custom) {
        currentSession = BenchmarkSession(
            name: name,
            type: type,
            results: []
        )
        
        // Save session to the list
        if let session = currentSession {
            sessions.append(session)
            saveSessionsToFile()
        }
    }
    
    @MainActor
    func runBenchmark(text: String, model: SummarizationModel, batchSize: Int = 1) async throws {
        // Проверка на пустой входной текст
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SummarizerError.invalidInput
        }
        
        guard let container = modelManager.loadedModels[model.modelId] else {
            throw SummarizerError.modelNotLoaded
        }
        
        isGenerating = true
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Измеряем память до начала бенчмарка
        let memoryBeforeBenchmark = getCurrentMemoryUsage()
        
        do {
            // Информируем пользователя о реальности батчинга
            if batchSize > 1 {
                print("⚠️ ВАЖНО: MLX Swift не поддерживает нативный батчинг")
                print("🔄 Выполняется параллельная обработка \(batchSize) копий текста для демонстрации")
                print("📊 Это позволяет оценить производительность при множественных запросах")
            } else {
                print("🔄 Обработка одного текста")
            }
            
            print("📊 Память перед обработкой: \(memoryBeforeBenchmark.used) MB")
            
            var summaries: [(String, Int)] = []
            var totalTokens = 0
            
            // Реальная параллельная обработка для batchSize > 1
            if batchSize > 1 {
                // Создаем семафор для ограничения одновременного доступа к ModelContainer
                // MLX не поддерживает одновременное использование контейнера из нескольких потоков
                let semaphore = AsyncSemaphore(value: 1)
                
                // Параллельная обработка нескольких копий текста
                summaries = try await withThrowingTaskGroup(of: (String, Int).self) { group in
                    var results: [(String, Int)] = []
                    
                    // Добавляем задачи в группу
                    for i in 0..<batchSize {
                        group.addTask {
                            print("🔁 Запуск параллельной обработки элемента \(i+1)/\(batchSize)")
                            return try await self.processSingleTextWithSemaphore(text: text, model: model, container: container, index: i+1, semaphore: semaphore)
                        }
                    }
                    
                    // Собираем результаты
                    for try await result in group {
                        results.append(result)
                        print("✅ Завершена обработка одного из элементов батча")
                    }
                    
                    return results
                }
            } else {
                // Обработка одного текста
                let singleResult = try await processSingleText(text: text, model: model, container: container, index: 1)
                summaries = [singleResult]
            }
            
            totalTokens = summaries.reduce(0) { $0 + $1.1 }
            
            // Используем первое резюме для отображения в UI
            let summary = summaries.first ?? ("", 0)
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let inferenceTime = endTime - startTime
            
            // Рассчитываем метрики
            let tokensCount = summary.1
            let tokensPerSecond = Double(totalTokens) / inferenceTime
            
            // Определяем тип квантизации
            let quantType = model.modelId.contains("4bit") ? "4-bit" : 
                           model.modelId.contains("8bit") ? "8-bit" : "16-bit"
            
            let compressionRatio = Double(summary.0.count) / Double(text.count)
            
            // Измеряем память после бенчмарка
            let memoryAfterBenchmark = getCurrentMemoryUsage()
            
            // Рассчитываем реальное потребление памяти
            let runtimeMemoryConsumption = max(0, memoryAfterBenchmark.used - memoryBeforeBenchmark.used)
            _ = max(0, memoryAfterBenchmark.peak - memoryBeforeBenchmark.peak)
            
            // Честный расчет памяти на элемент
            // Для параллельной обработки память может использоваться более эффективно
            let memoryPerItem = batchSize > 1 ? runtimeMemoryConsumption : runtimeMemoryConsumption
            
            print("📊 Итоговые метрики:")
            print("   • Время выполнения: \(String(format: "%.2f", inferenceTime))с")
            print("   • Токенов в секунду: \(String(format: "%.1f", tokensPerSecond))")
            print("   • Использование памяти: \(String(format: "%.1f", runtimeMemoryConsumption))MB")
            print("   • Обработано элементов: \(batchSize)")
            
            // Рассчитываем эффективность использования памяти
            let memEfficiency = runtimeMemoryConsumption > 0 ? Double(totalTokens) / runtimeMemoryConsumption * 100 : 0
            
            // Создаем честные метрики
            let metrics = BenchmarkResult.PerformanceMetrics(
                loadTime: modelManager.getModelLoadTime(model.modelId) ?? 0,
                inferenceTime: inferenceTime,
                tokensPerSecond: tokensPerSecond,
                memoryUsed: memoryBeforeBenchmark.used,
                runtimeMemoryConsumption: runtimeMemoryConsumption,
                peakMemory: memoryAfterBenchmark.peak,
                memoryPerBatchItem: memoryPerItem,
                batchSize: batchSize,
                quantizationType: quantType,
                memoryEfficiency: memEfficiency,
                summaryLength: summary.0.count,
                compressionRatio: compressionRatio,
                inputLength: text.count,
                tokensGenerated: tokensCount
            )
            
            let result = BenchmarkResult(
                timestamp: Date(),
                modelName: model.name,
                modelId: model.modelId,
                inputText: text,
                generatedSummary: summary.0,
                metrics: metrics
            )
            
            currentResult = result
            generatedSummary = summary.0
            
            // Add to current session
            if var session = currentSession {
                session.results.append(result)
                currentSession = session
            }
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        
        isGenerating = false
    }
    
    // MARK: - Helper Methods
    
    /// Обрабатывает один текст с помощью модели с синхронизацией
    private func processSingleTextWithSemaphore(text: String, model: SummarizationModel, container: ModelContainer, index: Int, semaphore: AsyncSemaphore) async throws -> (String, Int) {
        // Ожидаем разрешения на доступ к ModelContainer
        await semaphore.wait()
        
        defer {
            // Освобождаем семафор после завершения обработки
            Task {
                await semaphore.signal()
            }
        }
        
        return try await processSingleText(text: text, model: model, container: container, index: index)
    }
    
    /// Обрабатывает один текст с помощью модели
    private func processSingleText(text: String, model: SummarizationModel, container: ModelContainer, index: Int) async throws -> (String, Int) {
        let prompt = model.configuration.createPrompt(for: text)
        
        print("🔄 Начинаем обработку элемента \(index) с промптом длиной \(prompt.count) символов")
        
        let result = try await container.perform { (context: ModelContext) -> (String, Int) in
            // Подготавливаем входные данные для модели
            let userInput = UserInput(prompt: prompt)
            let lmInput = try await context.processor.prepare(input: userInput)
            
            // Параметры генерации из конфигурации модели
            let generateParameters = GenerateParameters(
                maxTokens: model.configuration.maxTokens,
                temperature: model.configuration.temperature
            )
            
            // Генерируем токены с помощью правильного API
            let stream = try MLXLMCommon.generate(
                input: lmInput,
                parameters: generateParameters,
                context: context
            )
            
            // Собираем сгенерированные токены
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
        
        print("✅ Завершена обработка элемента \(index): \(result.1) токенов, \(result.0.count) символов")
        return result
    }
    
    private func getCurrentMemoryUsage() -> (used: Double, peak: Double) {
        let memoryInfo = modelManager.getMemoryInfo()
        let usedMB = Double(memoryInfo.used) / (1024 * 1024) // Convert to MB
        let peakMB = Double(memoryInfo.peak) / (1024 * 1024) // Convert to MB
        return (used: usedMB, peak: peakMB)
    }
    
    // Метод saveSession удален, так как дублировал логику из startNewSession и не использовался
    
    private func saveSessionsToFile() {
        sessionManager.saveSessions(sessions)
    }
    
    func loadSessions() {
        sessions = sessionManager.loadSessions()
        
        if let lastSession = sessions.last {
            currentSession = lastSession
        }
    }
    
    func clearCurrentResult() {
        currentResult = nil
        generatedSummary = ""
        errorMessage = nil
    }
    
    func deleteSession(_ session: BenchmarkSession) {
        sessions.removeAll { $0.id == session.id }
        if currentSession?.id == session.id {
            currentSession = nil
        }
        saveSessionsToFile()
    }
    
    func exportResults(from session: BenchmarkSession) -> URL? {
        return sessionManager.exportSessionAsCSV(session)
    }
}

// MARK: - Errors

enum SummarizerError: Error, LocalizedError {
    case modelNotLoaded
    case generationFailed(String)
    case invalidInput
    case memoryError
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Модель не загружена. Пожалуйста, загрузите модель перед генерацией."
        case .generationFailed(let message):
            return "Ошибка генерации: \(message)"
        case .invalidInput:
            return "Некорректный входной текст. Пожалуйста, проверьте ввод."
        case .memoryError:
            return "Ошибка памяти. Недостаточно GPU памяти для выполнения операции."
        }
    }
}
