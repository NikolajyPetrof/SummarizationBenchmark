//
//  BenchmarkResultsPanel.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.07.2025.
//

import SwiftUI

struct BenchmarkResultsPanel: View {
    @ObservedObject var benchmarkVM: BenchmarkViewModel
    @State private var selectedTab = 0 // 0 - Summary, 1 - Benchmark
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Results")
                .font(.title2)
                .bold()
            
            if let result = benchmarkVM.currentResult {
                // Model info
                HStack {
                    VStack(alignment: .leading) {
                        Text("Model: \(result.modelName)")
                            .font(.headline)
                        Text("Generated on: \(result.timestamp.formatted())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                
                // Tab selector
                Picker("Results View", selection: $selectedTab) {
                    Text("Summary").tag(0)
                    Text("Benchmark").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                if selectedTab == 0 {
                    // Summary Output
                    SummaryOutputView(result: result)
                } else {
                    // Benchmark Results
                    PerformanceMetricsView(metrics: result.metrics)
                }
            } else if benchmarkVM.isGenerating {
                VStack {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Generating summary...")
                            .font(.headline)
                        Text("This may take a few seconds")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No results yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Click 'Run Benchmark' to see results")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }
}
