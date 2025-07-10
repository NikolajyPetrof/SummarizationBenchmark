//
//  BenchmarkControlsView.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.07.2025.
//

import SwiftUI

struct BenchmarkControlsView: View {
    @ObservedObject var benchmarkVM: BenchmarkViewModel
    @ObservedObject var modelManager: ModelManager
    let inputText: String
    @State private var selectedBatchSize = 1
    
    private let availableBatchSizes = [1, 2, 4, 8]
    
    var canRunBenchmark: Bool {
        guard let selectedModel = benchmarkVM.selectedModel else { return false }
        guard modelManager.loadedModels[selectedModel.modelId] != nil else { return false }
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard !benchmarkVM.isGenerating else { return false }
        return true
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Selected Model Info
            if let selectedModel = benchmarkVM.selectedModel {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Selected Model:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(selectedModel.name)
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        // Model status indicator
                        Circle()
                            .fill(modelManager.loadedModels[selectedModel.modelId] != nil ? Color.green : Color.orange)
                            .frame(width: 10, height: 10)
                    }
                    
                    // Batch Size Control
                    HStack(alignment: .center) {
                        Text("Batch Size:")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Picker("Batch Size", selection: $selectedBatchSize) {
                            ForEach(availableBatchSizes, id: \.self) { size in
                                Text("\(size)").tag(size)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                    }
                    .padding(.top, 4)
                }
                .padding()
                .background(Color(NSColor.controlColor))
                .cornerRadius(8)
            }
            
            // Кнопка суммаризации удалена
            
            // Run Benchmark Button
            Button(action: {
                Task {
                    guard let model = benchmarkVM.selectedModel else { return }
                    do {
                        try await benchmarkVM.runBenchmark(text: inputText, model: model, batchSize: selectedBatchSize)
                    } catch {
                        benchmarkVM.errorMessage = error.localizedDescription
                    }
                }
            }) {
                HStack {
                    if benchmarkVM.isGenerating {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "play.fill")
                    }
                    
                    Text(benchmarkVM.isGenerating ? "Generating Summary..." : "Run Benchmark")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canRunBenchmark)
            
            // Error Message
            if let errorMessage = modelManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
}
