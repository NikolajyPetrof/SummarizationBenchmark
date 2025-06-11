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
    
    private let modelManager = ModelManager()
    private let sessionManager = BenchmarkSessionManager()
    
    init() {
        loadSessions()
    }
    
    func startNewSession(name: String, type: BenchmarkSession.SessionType = .custom) {
        currentSession = BenchmarkSession(
            name: name,
            timestamp: Date(),
            results: [],
            sessionType: type
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
        let memoryBefore = getCurrentMemoryUsage()
        
        do {
            let prompt = "\(model.configuration.defaultPrompt)\n\n\(text)\n\nSummary:"
            
            let summary = try await container.perform { context in
                let input = try await context.processor.prepare(input: .init(prompt: prompt))
                
                return try MLXLMCommon.generate(
                    input: input,
                    parameters: GenerateParameters(
                        temperature: 0.7,
                        topP: 0.9,
                        repetitionPenalty: 1.1,
                        maxTokens: 200
                    ),
                    context: context
                ) { tokens in
                    // Можно добавить callback для отображения прогресса
                    return .more
                }
            }
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let memoryAfter = getCurrentMemoryUsage()
            
            let inferenceTime = endTime - startTime
            let tokensCount = summary.split(separator: " ").count
            let tokensPerSecond = Double(tokensCount) / inferenceTime
            let memoryUsed = memoryAfter - memoryBefore
            let compressionRatio = Double(summary.count) / Double(text.count)
            
            let metrics = BenchmarkResult.PerformanceMetrics(
                loadTime: 0, // Будем измерять отдельно
                inferenceTime: inferenceTime,
                tokensPerSecond: tokensPerSecond,
                memoryUsed: memoryUsed,
                summaryLength: summary.count,
                compressionRatio: compressionRatio
            )
            
            let result = BenchmarkResult(
                timestamp: Date(),
                modelName: model.name,
                inputText: text,
                generatedSummary: summary,
                metrics: metrics
            )
            
            currentResult = result
            generatedSummary = summary
            
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
        let memoryInfo = MLX.GPU.memoryInfo()
        return Double(memoryInfo.used) / (1024 * 1024) // MB
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
    
    /// Получает текущее использование памяти GPU в мегабайтах
    private func getCurrentMemoryUsage() -> Double {
        return Double(modelManager.getMemoryInfo().used) / (1024 * 1024) // Конвертируем в MB
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
