//
//  BenchmarkSessionManager.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.06.2025.
//

import Foundation

/// Класс для работы с файловой системой при сохранении/загрузке сессий бенчмаркинга
class BenchmarkSessionManager {
    private let documentsDirectory: URL
    private let sessionsFileName = "benchmark_sessions.json"
    
    init() {
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var sessionsURL: URL {
        documentsDirectory.appendingPathComponent(sessionsFileName)
    }
    
    /// Сохраняет все сессии в JSON файл
    func saveSessions(_ sessions: [BenchmarkSession]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        guard let data = try? encoder.encode(sessions) else {
            print("❌ Failed to encode sessions")
            return
        }
        
        do {
            try data.write(to: sessionsURL)
            print("✅ Sessions saved to \(sessionsURL.path)")
        } catch {
            print("❌ Failed to save sessions: \(error)")
        }
    }
    
    /// Загружает сессии из JSON файла
    func loadSessions() -> [BenchmarkSession] {
        guard FileManager.default.fileExists(atPath: sessionsURL.path) else {
            print("🔍 No sessions file found, returning empty array")
            return []
        }
        
        do {
            let data = try Data(contentsOf: sessionsURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let sessions = try decoder.decode([BenchmarkSession].self, from: data)
            print("✅ Loaded \(sessions.count) sessions")
            return sessions
        } catch {
            print("❌ Failed to load sessions: \(error)")
            return []
        }
    }
    
    /// Экспортирует сессию в CSV формате
    func exportSessionAsCSV(_ session: BenchmarkSession) -> URL? {
        var csv = "Model,Model ID,Inference Time (s),Tokens/Second,Memory Used (MB),Summary Length,Input Length,Compression Ratio,Timestamp\n"
        
        for result in session.results {
            let metrics = result.metrics
            csv += "\"\(result.modelName)\",\"\(result.modelId)\",\(metrics.inferenceTime),\(metrics.tokensPerSecond),\(metrics.memoryUsed),\(metrics.summaryLength),\(metrics.inputLength),\(metrics.compressionRatio),\"\(result.timestamp)\"\n"
        }
        
        let fileName = "benchmark_\(session.name)_\(formattedDate(session.timestamp)).csv"
        let exportURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try csv.write(to: exportURL, atomically: true, encoding: .utf8)
            print("✅ Exported session to \(exportURL.path)")
            return exportURL
        } catch {
            print("❌ Failed to export session: \(error)")
            return nil
        }
    }
    
    /// Экспортирует сессию в JSON формате
    func exportSessionAsJSON(_ session: BenchmarkSession) -> URL? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        guard let data = try? encoder.encode(session) else { 
            return nil 
        }
        
        let fileName = "benchmark_\(session.name)_\(formattedDate(session.timestamp)).json"
        let exportURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: exportURL)
            print("✅ Exported session to \(exportURL.path)")
            return exportURL
        } catch {
            print("❌ Failed to export session: \(error)")
            return nil
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        return formatter.string(from: date)
    }
}
