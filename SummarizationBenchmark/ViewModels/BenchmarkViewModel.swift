//
//  BenchmarkViewModel.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.06.2025.
//

import Foundation
import MLX
import MLXLLM
import MLXLMCommon

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
    
    // Фабричный метод для создания экземпляра BenchmarkViewModel
    static func create(with modelManager: ModelManager) -> BenchmarkViewModel {
        return BenchmarkViewModel(modelManager: modelManager)
    }
    
    func startNewSession(name: String, type: BenchmarkSession.SessionType = .custom) {
        currentSession = BenchmarkSession(
            name: name,
            type: type,
            results: []
        )
        
        // Сохраняем сессию в список
        if let session = currentSession {
            sessions.append(session)
            saveSessionsToFile()
        }
    }
    
    func runBenchmark(text: String, model: SummarizationModel) async throws {
        guard let container = modelManager.loadedModels[model.modelId] else {
            throw SummarizerError.modelNotLoaded
        }
        
        isGenerating = true
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Сбрасываем пиковое значение памяти перед началом измерения
        MLX.GPU.resetPeakMemory()
        
        do {
            let prompt = model.configuration.createPrompt(for: text)
            let summary = try await container.perform { context in
                let input = try await context.processor.prepare(input: .init(prompt: prompt))
                
                let generateStream = try MLXLMCommon.generate(
                    input: input,
                    parameters: GenerateParameters(
                        maxTokens: 200,
                        temperature: 0.7,
                        topP: 0.9,
                        repetitionPenalty: 1.1
                    ),
                    context: context
                )
                
                var localGeneratedText = ""
                var localTokenCount = 0
                
                for await generation in generateStream {
                    if let chunk = generation.chunk {
                        localGeneratedText += chunk
                        localTokenCount += 1
                    }
                }
                
                return (localGeneratedText, localTokenCount)
            }
            
            let endTime = CFAbsoluteTimeGetCurrent()
            
            // Получаем пиковое значение памяти после инференса
            let memoryUsed = getCurrentMemoryUsage()
            
            let inferenceTime = endTime - startTime
            let tokensCount = summary.1
            let tokensPerSecond = Double(tokensCount) / inferenceTime
            let compressionRatio = Double(summary.0.count) / Double(text.count)
            
            let metrics = BenchmarkResult.PerformanceMetrics(
                loadTime: 0, // Будем измерять отдельно
                inferenceTime: inferenceTime,
                tokensPerSecond: tokensPerSecond,
                memoryUsed: memoryUsed,
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
            
            // Добавляем в текущую сессию
            if var session = currentSession {
                session.results.append(result)
                currentSession = session
            }
            
        } catch {
            throw error
        }
        
        isGenerating = false
    }
    
    private func getCurrentMemoryUsage() -> Double {
        let memoryInfo = modelManager.getMemoryInfo()
        let usedMB = Double(memoryInfo.used) / (1024 * 1024) // Конвертируем в MB
        return usedMB
    }
    
    func saveSession() {
        guard let session = currentSession else { return }
        sessions.append(session)
        
        // Сохранение в UserDefaults или файл
        saveSessionsToFile()
    }
    
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
