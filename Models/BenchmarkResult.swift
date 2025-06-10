//
//  BenchmarkResult.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.06.2025.
//

import Foundation

struct BenchmarkResult: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let modelName: String
    let inputText: String
    let generatedSummary: String
    let metrics: PerformanceMetrics
    
    struct PerformanceMetrics: Codable {
        let loadTime: Double          // Время загрузки модели (сек)
        let inferenceTime: Double     // Время генерации (сек)
        let tokensPerSecond: Double   // Скорость генерации
        let memoryUsed: Double        // Использованная память (MB)
        let summaryLength: Int        // Длина саммари (символы)
        let compressionRatio: Double  // Коэффициент сжатия
    }
}

struct BenchmarkSession: Identifiable, Codable {
    let id = UUID()
    let name: String
    let timestamp: Date
    let results: [BenchmarkResult]
    
    var averageInferenceTime: Double {
        results.map(\.metrics.inferenceTime).reduce(0, +) / Double(results.count)
    }
    
    var averageTokensPerSecond: Double {
        results.map(\.metrics.tokensPerSecond).reduce(0, +) / Double(results.count)
    }
}
