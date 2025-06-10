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
    
    private let modelManager = ModelManager()
    
    func startNewSession(name: String) {
        currentSession = BenchmarkSession(
            name: name,
            timestamp: Date(),
            results: []
        )
    }
    
    func runBenchmark(text: String, model: SummarizationModel) async throws {
        guard let container = modelManager.loadedModels[model.modelId] else {
            throw BenchmarkError.modelNotLoaded
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
        // Реализация сохранения
        if let data = try? JSONEncoder().encode(sessions) {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("benchmark_sessions.json")
            try? data.write(to: url)
        }
    }
}

enum BenchmarkError: Error {
    case modelNotLoaded
    case generationFailed
}
