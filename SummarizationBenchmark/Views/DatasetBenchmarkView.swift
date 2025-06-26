//
//  DatasetBenchmarkView.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 27.06.2025.
//

import SwiftUI

struct DatasetBenchmarkView: View {
    @ObservedObject var benchmarkVM: BenchmarkViewModel
    @ObservedObject var datasetManager: DatasetManager
    
    @State private var isRunningBenchmark = false
    @State private var currentEntryIndex = 0
    @State private var results: [DatasetBenchmarkResult] = []
    @State private var progress: Double = 0
    @State private var errorMessage: String?
    @State private var selectedSampleSize = 5
    
    private let sampleSizes = [5, 10, 20]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Dataset Benchmark")
                    .font(.title)
                    .bold()
                
                Spacer()
                
                if let dataset = datasetManager.selectedDataset {
                    Text(dataset.name)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            if datasetManager.selectedDataset == nil {
                noDatasetSelectedView
            } else {
                configurationView
                
                if isRunningBenchmark {
                    runningBenchmarkView
                } else if !results.isEmpty {
                    resultsView
                }
            }
        }
        .padding()
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    // Представление для случая, когда датасет не выбран
    private var noDatasetSelectedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 72))
                .foregroundColor(.secondary)
            
            Text("No Dataset Selected")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Please select a dataset from the sidebar to run benchmark tests")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Представление для конфигурации бенчмарка
    private var configurationView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Configuration")
                .font(.headline)
            
            HStack {
                Text("Sample size:")
                
                Picker("Sample size", selection: $selectedSampleSize) {
                    ForEach(sampleSizes, id: \.self) { size in
                        Text("\(size) entries").tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(isRunningBenchmark)
                
                Spacer()
                
                if let model = benchmarkVM.selectedModel {
                    HStack {
                        Text("Selected model:")
                        Text(model.name)
                            .fontWeight(.medium)
                    }
                }
            }
            
            Button(action: runBenchmark) {
                if isRunningBenchmark {
                    Text("Running benchmark...")
                } else {
                    Text("Run Benchmark")
                }
            }
            .disabled(isRunningBenchmark || benchmarkVM.selectedModel == nil)
            .buttonStyle(.borderedProminent)
            
            if let dataset = datasetManager.selectedDataset {
                Text("Dataset: \(dataset.name) (\(dataset.entries.count) entries)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // Представление для отображения прогресса бенчмарка
    private var runningBenchmarkView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Running benchmark...")
                .font(.headline)
            
            ProgressView(value: progress)
                .progressViewStyle(.linear)
            
            if let dataset = datasetManager.selectedDataset {
                Text("Processing entry \(currentEntryIndex + 1) of \(min(selectedSampleSize, dataset.entries.count))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button("Cancel") {
                isRunningBenchmark = false
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // Представление для отображения результатов бенчмарка
    private var resultsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Results")
                .font(.headline)
            
            HStack {
                Text("Average Performance:")
                    .fontWeight(.medium)
                
                Spacer()
                
                let avgTime = results.reduce(0) { $0 + $1.inferenceTime } / Double(results.count)
                let avgTokensPerSec = results.reduce(0) { $0 + $1.tokensPerSecond } / Double(results.count)
                
                Text(String(format: "%.2f sec / %.2f tokens/sec", avgTime, avgTokensPerSec))
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("Memory Usage:")
                    .fontWeight(.medium)
                
                Spacer()
                
                let avgMemory = results.reduce(0) { $0 + $1.memoryUsage } / Double(results.count)
                Text(String(format: "%.2f MB", avgMemory))
                    .fontWeight(.medium)
            }
            
            Divider()
            
            Text("Detailed Results")
                .font(.headline)
            
            List(results) { result in
                VStack(alignment: .leading, spacing: 8) {
                    Text("Entry \(result.entryIndex + 1)")
                        .font(.headline)
                    
                    HStack {
                        Text("Time:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.2f sec", result.inferenceTime))
                    }
                    
                    HStack {
                        Text("Speed:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.2f tokens/sec", result.tokensPerSecond))
                    }
                    
                    HStack {
                        Text("Memory:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.2f MB", result.memoryUsage))
                    }
                    
                    Button("View Details") {
                        // Здесь можно добавить действие для просмотра деталей результата
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.vertical, 4)
            }
            .frame(height: 300)
            
            Button("Export Results") {
                exportResults()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // Запуск бенчмарка
    private func runBenchmark() {
        guard let dataset = datasetManager.selectedDataset, let model = benchmarkVM.selectedModel else {
            errorMessage = "Please select a dataset and model"
            return
        }
        
        isRunningBenchmark = true
        results = []
        currentEntryIndex = 0
        progress = 0
        
        // Определяем количество записей для бенчмарка
        let entriesCount = min(selectedSampleSize, dataset.entries.count)
        
        // Запускаем бенчмарк асинхронно
        Task {
            for i in 0..<entriesCount {
                if !isRunningBenchmark {
                    break // Прерываем, если бенчмарк был отменен
                }
                
                currentEntryIndex = i
                progress = Double(i) / Double(entriesCount)
                
                let entry = dataset.entries[i]
                
                do {
                    // Запускаем бенчмарк для текущей записи
                    try await benchmarkVM.runBenchmark(text: entry.text, model: model)
                    
                    if let result = benchmarkVM.currentResult {
                        // Создаем результат для записи датасета
                        let datasetResult = DatasetBenchmarkResult(
                            entryIndex: i,
                            entryId: entry.id,
                            modelId: model.modelId,
                            modelName: model.name,
                            inferenceTime: result.metrics.inferenceTime,
                            tokensPerSecond: result.metrics.tokensPerSecond,
                            memoryUsage: result.metrics.memoryUsed,
                            inputText: entry.text,
                            generatedSummary: result.generatedSummary,
                            referenceSummary: entry.referenceSummary
                        )
                        
                        // Добавляем результат в список
                        await MainActor.run {
                            results.append(datasetResult)
                        }
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = "Error running benchmark: \(error.localizedDescription)"
                        isRunningBenchmark = false
                    }
                    return
                }
            }
            
            // Завершаем бенчмарк
            await MainActor.run {
                isRunningBenchmark = false
                progress = 1.0
            }
        }
    }
    
    // Экспорт результатов
    private func exportResults() {
        guard !results.isEmpty else {
            errorMessage = "No results to export"
            return
        }
        
        // Здесь можно добавить логику экспорта результатов в JSON или CSV
        // Например, сохранение в файл или отправка по email
    }
}

// Структура для хранения результатов бенчмарка на датасете
struct DatasetBenchmarkResult: Identifiable, Codable {
    let id = UUID()
    let entryIndex: Int
    let entryId: UUID
    let modelId: String
    let modelName: String
    let inferenceTime: Double
    let tokensPerSecond: Double
    let memoryUsage: Double
    let inputText: String
    let generatedSummary: String
    let referenceSummary: String?
    
    // Вычисляемые свойства для метрик качества
    var rougeScore: Double? {
        // Здесь можно добавить вычисление ROUGE метрики
        // между generatedSummary и referenceSummary
        return nil
    }
    
    var bleuScore: Double? {
        // Здесь можно добавить вычисление BLEU метрики
        // между generatedSummary и referenceSummary
        return nil
    }
}
