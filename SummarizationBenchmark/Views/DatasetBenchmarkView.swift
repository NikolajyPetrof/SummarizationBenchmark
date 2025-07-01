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
    
    // View for when no dataset is selected
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
    
    // Benchmark configuration view
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
    
    // Benchmark progress view
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
    
    // Benchmark results view
    @State private var copiedSummary: String? = nil
    
    private var resultsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Results")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    copyAllResults()
                }) {
                    Label(copiedSummary == "all" ? "Copied!" : "Copy Summary", 
                          systemImage: copiedSummary == "all" ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.bordered)
            }
            
            // Average Performance Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Average Performance")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: {
                        copyAveragePerformance()
                    }) {
                        Image(systemName: copiedSummary == "avg" ? "checkmark" : "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
                
                let avgTime = results.reduce(0) { $0 + $1.inferenceTime } / Double(results.count)
                let avgTokensPerSec = results.reduce(0) { $0 + $1.tokensPerSecond } / Double(results.count)
                let avgMemory = results.reduce(0) { $0 + $1.memoryUsage } / Double(results.count)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    MetricItem(title: "Avg Time", value: String(format: "%.2fs", avgTime))
                    MetricItem(title: "Avg Speed", value: String(format: "%.1f t/s", avgTokensPerSec))
                    MetricItem(title: "Avg Memory", value: String(format: "%.1f MB", avgMemory))
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
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
                        // Action for viewing result details can be added here
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.vertical, 4)
            }
            .frame(height: 300)
            

        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // Run benchmark
    private func runBenchmark() {
        guard let dataset = datasetManager.selectedDataset, let model = benchmarkVM.selectedModel else {
            errorMessage = "Please select a dataset and model"
            return
        }
        
        isRunningBenchmark = true
        results = []
        currentEntryIndex = 0
        progress = 0
        
        // Determine number of entries for benchmark
        let entriesCount = min(selectedSampleSize, dataset.entries.count)
        
        // Get random sample from dataset
        let selectedEntries = dataset.entries.shuffled().prefix(entriesCount).enumerated().map { (index, entry) in
            return (index, entry)
        }
        
        // Run benchmark asynchronously
        Task {
            for (i, (_, entry)) in selectedEntries.enumerated() {
                if !isRunningBenchmark {
                    break // Exit if benchmark was cancelled
                }
                
                currentEntryIndex = i
                progress = Double(i) / Double(entriesCount)
                
                // Use entry from selected sample
                
                do {
                    // Run benchmark for current entry
                    try await benchmarkVM.runBenchmark(text: entry.text, model: model)
                    
                    if let result = benchmarkVM.currentResult {
                        // Create result for dataset entry
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
                        
                        // Add result to list
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
            
            // Complete benchmark
            await MainActor.run {
                isRunningBenchmark = false
                progress = 1.0
            }
        }
    }
    
    // Copy functions
    private func copyAllResults() {
        let avgTime = results.reduce(0) { $0 + $1.inferenceTime } / Double(results.count)
        let avgTokensPerSec = results.reduce(0) { $0 + $1.tokensPerSecond } / Double(results.count)
        let avgMemory = results.reduce(0) { $0 + $1.memoryUsage } / Double(results.count)
        
        let summary = """
        Dataset Benchmark Results Summary:
        
        Average Performance:
        - Inference Time: \(String(format: "%.2f", avgTime))s
        - Tokens/Second: \(String(format: "%.1f", avgTokensPerSec))
        - Memory Usage: \(String(format: "%.1f", avgMemory))MB
        
        Total Entries: \(results.count)
        
        Detailed Results:
        \(results.enumerated().map { index, result in
            "Entry \(index + 1): \(String(format: "%.2f", result.inferenceTime))s, \(String(format: "%.1f", result.tokensPerSecond)) t/s, \(String(format: "%.1f", result.memoryUsage))MB"
        }.joined(separator: "\n"))
        """
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(summary, forType: .string)
        copiedSummary = "all"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedSummary = nil
        }
    }
    
    private func copyAveragePerformance() {
        let avgTime = results.reduce(0) { $0 + $1.inferenceTime } / Double(results.count)
        let avgTokensPerSec = results.reduce(0) { $0 + $1.tokensPerSecond } / Double(results.count)
        let avgMemory = results.reduce(0) { $0 + $1.memoryUsage } / Double(results.count)
        
        let avgPerformance = """
        Average Performance:
        Inference Time: \(String(format: "%.2f", avgTime))s
        Tokens/Second: \(String(format: "%.1f", avgTokensPerSec))
        Memory Usage: \(String(format: "%.1f", avgMemory))MB
        """
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(avgPerformance, forType: .string)
        copiedSummary = "avg"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedSummary = nil
        }
    }

}

// Structure for storing dataset benchmark results
struct DatasetBenchmarkResult: Identifiable, Codable {
    var id = UUID()
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
    
    // Computed properties for quality metrics
    var rougeScore: Double? {
        // ROUGE metric calculation can be added here
        // между generatedSummary и referenceSummary
        return nil
    }
    
    var bleuScore: Double? {
        // BLEU metric calculation can be added here
        // между generatedSummary и referenceSummary
        return nil
    }
}

// MARK: - Metric Item Component
struct MetricItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(6)
    }
}
