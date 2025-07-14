//
//  Dataset.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 27.06.2025.
//

import Foundation

/// Структура для представления датасета для тестирования суммаризации
struct Dataset: Identifiable, Codable, Hashable {
    var id = UUID()
    let name: String
    let description: String
    let source: DatasetSource
    let category: DatasetCategory
    let entries: [DatasetEntry]
    let metadata: [String: String]
    
    /// Источник датасета
    enum DatasetSource: String, Codable, CaseIterable {
        case cnnDailyMail = "CNN/DailyMail"
        case redditTIFU = "Reddit TIFU"
        case scientificAbstracts = "Scientific Abstracts (PubMed)"
        case arxivPapers = "ArXiv Papers"
        case custom = "Custom"
    }
    
    /// Категория датасета
    enum DatasetCategory: String, Codable, CaseIterable {
        case news = "News"
        case social = "Social Media"
        case scientific = "Scientific"
        case other = "Other"
    }
    
    /// Статистика по датасету
    var statistics: DatasetStatistics {
        let totalEntries = entries.count
        let totalTextLength = entries.reduce(0) { $0 + $1.text.count }
        let totalSummaryLength = entries.compactMap { $0.referenceSummary?.count }.reduce(0, +)
        let averageTextLength = totalEntries > 0 ? Double(totalTextLength) / Double(totalEntries) : 0
        let averageSummaryLength = totalEntries > 0 ? Double(totalSummaryLength) / Double(totalEntries) : 0
        
        return DatasetStatistics(
            totalEntries: totalEntries,
            totalTextLength: totalTextLength,
            totalSummaryLength: totalSummaryLength,
            averageTextLength: averageTextLength,
            averageSummaryLength: averageSummaryLength
        )
    }
    
    /// Получить случайную выборку из датасета
    func randomSample(count: Int) -> [DatasetEntry] {
        guard count <= entries.count else { return entries }
        return Array(entries.shuffled().prefix(count))
    }
    
    /// Получить подмножество датасета определенного размера
    func subset(ofSize size: Int) -> Dataset {
        guard size <= entries.count else { return self }
        let subsetEntries = Array(entries.prefix(size))
        
        return Dataset(
            name: "\(name) (Subset \(size))",
            description: "\(description) - Subset of \(size) entries",
            source: source,
            category: category,
            entries: subsetEntries,
            metadata: metadata
        )
    }
}

/// Запись в датасете
struct DatasetEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    let text: String
    let referenceSummary: String?
    let metadata: [String: String]
    
    /// Длина текста в словах
    var wordCount: Int {
        text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
    
    /// Длина текста в символах
    var characterCount: Int {
        text.count
    }
    
    /// Длина эталонного саммари в словах (если есть)
    var summaryWordCount: Int? {
        referenceSummary?.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
    
    /// Коэффициент сжатия (отношение длины саммари к длине текста)
    var compressionRatio: Double? {
        guard let summaryCount = referenceSummary?.count, text.count > 0 else { return nil }
        return Double(summaryCount) / Double(text.count)
    }
}

/// Статистика по датасету
struct DatasetStatistics: Codable {
    let totalEntries: Int
    let totalTextLength: Int
    let totalSummaryLength: Int
    let averageTextLength: Double
    let averageSummaryLength: Double
    
    /// Среднее отношение длины саммари к длине текста
    var averageCompressionRatio: Double {
        guard averageTextLength > 0 else { return 0 }
        return averageSummaryLength / averageTextLength
    }
}
