//
//  BenchmarkResult.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.06.2025.
//

import Foundation

// MARK: - Benchmark Result
struct BenchmarkResult: Identifiable, Codable {
    var id = UUID()
    let timestamp: Date
    let modelName: String
    let modelId: String
    let inputText: String
    let generatedSummary: String
    let metrics: PerformanceMetrics
    
    struct PerformanceMetrics: Codable {
        let loadTime: Double          // Время загрузки модели (сек)
        let inferenceTime: Double     // Время генерации (сек)
        let tokensPerSecond: Double   // Скорость генерации
        let memoryUsed: Double        // Использованная память (MB)
        let summaryLength: Int        // Длина саммари (символы)
        let compressionRatio: Double  // Коэффициент сжатия (0.0 - 1.0)
        let inputLength: Int          // Длина входного текста
        let tokensGenerated: Int      // Количество сгенерированных токенов
        
        // Computed properties
        var wordsPerSecond: Double {
            let wordCount = Double(tokensGenerated)
            return wordCount / inferenceTime
        }
        
        var charactersPerSecond: Double {
            let charCount = Double(summaryLength)
            return charCount / inferenceTime
        }
        
        var memoryEfficiencyScore: Double {
            // Оценка эффективности памяти (токены/МБ)
            guard memoryUsed > 0 else { return 0 }
            return Double(tokensGenerated) / memoryUsed
        }
    }
    
    // MARK: - Computed Properties
    
    /// Оценка качества на основе сжатия
    var qualityScore: Double {
        let idealCompression = 0.3 // 30% от исходного текста считается оптимальным
        let compressionDifference = abs(metrics.compressionRatio - idealCompression)
        return max(0, 1.0 - (compressionDifference / idealCompression))
    }
    
    /// Оценка производительности на основе скорости
    var performanceScore: Double {
        let baselineSpeed = 10.0 // токенов в секунду как baseline
        return min(1.0, metrics.tokensPerSecond / baselineSpeed)
    }
    
    /// Общая оценка эффективности (0.0 - 1.0)
    var overallScore: Double {
        return (qualityScore + performanceScore) / 2.0
    }
    
    /// Категория производительности
    var performanceCategory: PerformanceCategory {
        switch metrics.tokensPerSecond {
        case 0..<5:
            return .slow
        case 5..<15:
            return .medium
        case 15..<30:
            return .fast
        default:
            return .veryFast
        }
    }
    
    /// Категория использования памяти
    var memoryCategory: MemoryCategory {
        switch metrics.memoryUsed {
        case 0..<1000:
            return .low
        case 1000..<3000:
            return .medium
        case 3000..<6000:
            return .high
        default:
            return .veryHigh
        }
    }
}

// MARK: - Performance Categories
enum PerformanceCategory: String, CaseIterable {
    case slow = "Slow"
    case medium = "Medium"
    case fast = "Fast"
    case veryFast = "Very Fast"
    
    var emoji: String {
        switch self {
        case .slow: return "🐌"
        case .medium: return "🚶"
        case .fast: return "🏃"
        case .veryFast: return "🚀"
        }
    }
    
    var color: String {
        switch self {
        case .slow: return "red"
        case .medium: return "orange"
        case .fast: return "green"
        case .veryFast: return "blue"
        }
    }
}

enum MemoryCategory: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case veryHigh = "Very High"
    
    var emoji: String {
        switch self {
        case .low: return "🟢"
        case .medium: return "🟡"
        case .high: return "🟠"
        case .veryHigh: return "🔴"
        }
    }
}

// MARK: - Benchmark Session
struct BenchmarkSession: Identifiable, Codable {
    var id = UUID()
    let name: String
    let timestamp: Date
    var results: [BenchmarkResult]
    let sessionType: SessionType
    
    enum SessionType: String, Codable, CaseIterable {
        case quick = "Quick Test"
        case comprehensive = "Comprehensive"
        case comparison = "Model Comparison"
        case custom = "Custom"
        
        var description: String {
            switch self {
            case .quick:
                return "Quick performance test with sample texts"
            case .comprehensive:
                return "Detailed testing across multiple scenarios"
            case .comparison:
                return "Side-by-side model comparison"
            case .custom:
                return "Custom testing session"
            }
        }
    }
    
    init(name: String, type: SessionType = .custom, results: [BenchmarkResult] = []) {
        self.id = UUID()
        self.name = name
        self.timestamp = Date()
        self.results = results
        self.sessionType = type
    }
    
    // MARK: - Session Statistics
    
    var totalTests: Int {
        results.count
    }
    
    var averageInferenceTime: Double {
        guard !results.isEmpty else { return 0 }
        return results.map(\.metrics.inferenceTime).reduce(0, +) / Double(results.count)
    }
    
    var averageTokensPerSecond: Double {
        guard !results.isEmpty else { return 0 }
        return results.map(\.metrics.tokensPerSecond).reduce(0, +) / Double(results.count)
    }
    
    var averageMemoryUsage: Double {
        guard !results.isEmpty else { return 0 }
        return results.map(\.metrics.memoryUsed).reduce(0, +) / Double(results.count)
    }
    
    var averageCompressionRatio: Double {
        guard !results.isEmpty else { return 0 }
        return results.map(\.metrics.compressionRatio).reduce(0, +) / Double(results.count)
    }
    
    var averageQualityScore: Double {
        guard !results.isEmpty else { return 0 }
        return results.map(\.qualityScore).reduce(0, +) / Double(results.count)
    }
    
    var averagePerformanceScore: Double {
        guard !results.isEmpty else { return 0 }
        return results.map(\.performanceScore).reduce(0, +) / Double(results.count)
    }
    
    // MARK: - Best Results
    
    var fastestResult: BenchmarkResult? {
        results.max { $0.metrics.tokensPerSecond < $1.metrics.tokensPerSecond }
    }
    
    var mostMemoryEfficientResult: BenchmarkResult? {
        results.min { $0.metrics.memoryUsed < $1.metrics.memoryUsed }
    }
    
    var bestQualityResult: BenchmarkResult? {
        results.max { $0.qualityScore < $1.qualityScore }
    }
    
    var bestOverallResult: BenchmarkResult? {
        results.max { $0.overallScore < $1.overallScore }
    }
    
    // MARK: - Model Analysis
    
    var uniqueModels: Set<String> {
        Set(results.map(\.modelName))
    }
    
    var modelBreakdown: [String: [BenchmarkResult]] {
        Dictionary(grouping: results, by: \.modelName)
    }
    
    var modelAverages: [String: ModelAverages] {
        var averages: [String: ModelAverages] = [:]
        
        for (modelName, modelResults) in modelBreakdown {
            let avgInferenceTime = modelResults.map(\.metrics.inferenceTime).reduce(0, +) / Double(modelResults.count)
            let avgTokensPerSecond = modelResults.map(\.metrics.tokensPerSecond).reduce(0, +) / Double(modelResults.count)
            let avgMemoryUsed = modelResults.map(\.metrics.memoryUsed).reduce(0, +) / Double(modelResults.count)
            let avgQualityScore = modelResults.map(\.qualityScore).reduce(0, +) / Double(modelResults.count)
            
            averages[modelName] = ModelAverages(
                inferenceTime: avgInferenceTime,
                tokensPerSecond: avgTokensPerSecond,
                memoryUsed: avgMemoryUsed,
                qualityScore: avgQualityScore,
                testCount: modelResults.count
            )
        }
        
        return averages
    }
    
    // MARK: - Session Summary
    
    var sessionSummary: SessionSummary {
        SessionSummary(
            totalTests: totalTests,
            uniqueModels: uniqueModels.count,
            averageInferenceTime: averageInferenceTime,
            averageTokensPerSecond: averageTokensPerSecond,
            averageMemoryUsage: averageMemoryUsage,
            averageQualityScore: averageQualityScore,
            bestPerformingModel: fastestResult?.modelName,
            mostEfficientModel: mostMemoryEfficientResult?.modelName,
            sessionDuration: calculateSessionDuration()
        )
    }
    
    private func calculateSessionDuration() -> TimeInterval {
        guard let firstResult = results.first,
              let lastResult = results.last else {
            return 0
        }
        return lastResult.timestamp.timeIntervalSince(firstResult.timestamp)
    }
}

// MARK: - Supporting Structures

struct ModelAverages {
    let inferenceTime: Double
    let tokensPerSecond: Double
    let memoryUsed: Double
    let qualityScore: Double
    let testCount: Int
}

struct SessionSummary {
    let totalTests: Int
    let uniqueModels: Int
    let averageInferenceTime: Double
    let averageTokensPerSecond: Double
    let averageMemoryUsage: Double
    let averageQualityScore: Double
    let bestPerformingModel: String?
    let mostEfficientModel: String?
    let sessionDuration: TimeInterval
    
    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: sessionDuration) ?? "0s"
    }
}

// MARK: - Error Types
enum BenchmarkError: Error, LocalizedError {
    case modelNotLoaded
    case generationFailed
    case invalidInput
    case sessionNotFound
    case insufficientMemory
    case modelLoadingTimeout
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Model is not loaded. Please load the model first."
        case .generationFailed:
            return "Text generation failed. Please try again."
        case .invalidInput:
            return "Invalid input text. Please provide valid text to summarize."
        case .sessionNotFound:
            return "Benchmark session not found."
        case .insufficientMemory:
            return "Insufficient memory to load this model."
        case .modelLoadingTimeout:
            return "Model loading timed out. Please try again."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .modelNotLoaded:
            return "Load the model from the sidebar before running benchmarks."
        case .generationFailed:
            return "Check your internet connection and try again."
        case .invalidInput:
            return "Enter some text to summarize."
        case .sessionNotFound:
            return "Create a new session to start benchmarking."
        case .insufficientMemory:
            return "Try unloading other models or use a smaller model."
        case .modelLoadingTimeout:
            return "Check your internet connection and try loading again."
        }
    }
}
