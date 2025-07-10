//
//  MainBenchmarkView.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.07.2025.
//

import SwiftUI

struct MainBenchmarkView: View {
    @ObservedObject var benchmarkVM: BenchmarkViewModel
    @ObservedObject var modelManager: ModelManager
    @ObservedObject var datasetManager: DatasetManager
    @State private var selectedBenchmarkMode: BenchmarkMode = .singleText
    
    enum BenchmarkMode: String, CaseIterable {
        case singleText = "Single Text"
        case dataset = "Dataset"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Mode Selector
            Picker("Benchmark Mode", selection: $selectedBenchmarkMode) {
                ForEach(BenchmarkMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content based on selected mode
            if selectedBenchmarkMode == .singleText {
                HSplitView {
                    // Input Panel
                    TextInputPanel(benchmarkVM: benchmarkVM, modelManager: modelManager)
                        .frame(minWidth: 400, idealWidth: 500, maxWidth: .infinity, maxHeight: .infinity)
                        .layoutPriority(1)
                    
                    // Results Panel
                    BenchmarkResultsPanel(benchmarkVM: benchmarkVM)
                        .frame(minWidth: 400, idealWidth: 500, maxWidth: .infinity, maxHeight: .infinity)
                        .layoutPriority(1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                DatasetBenchmarkView(benchmarkVM: benchmarkVM, datasetManager: datasetManager)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
