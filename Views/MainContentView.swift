//
//  MainContentView.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.06.2025.
//

import SwiftUI

struct MainContentView: View {
    @ObservedObject var benchmarkVM: BenchmarkViewModel
    @ObservedObject var modelManager: ModelManager
    @State private var showingNewSessionSheet = false
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("Summarization Benchmark")
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
                
                Button("New Session") {
                    showingNewSessionSheet = true
                }
                .sheet(isPresented: $showingNewSessionSheet) {
                    NewSessionView(benchmarkVM: benchmarkVM)
                }
            }
            .padding()
            
            // Main content
            HSplitView {
                // Input panel
                InputPanel(benchmarkVM: benchmarkVM, modelManager: modelManager)
                    .frame(minWidth: 400)
                
                // Results panel
                ResultsPanel(benchmarkVM: benchmarkVM)
                    .frame(minWidth: 400)
            }
        }
    }
}

struct InputPanel: View {
    @ObservedObject var benchmarkVM: BenchmarkViewModel
    @ObservedObject var modelManager: ModelManager
    @State private var inputText = sampleTexts[0]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Input Text")
                .font(.headline)
            
            // Sample text picker
            Picker("Sample Text", selection: $inputText) {
                ForEach(Array(sampleTexts.enumerated()), id: \.offset) { index, text in
                    Text("Sample \(index + 1)").tag(text)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            // Text editor
            TextEditor(text: $inputText)
                .border(Color.gray, width: 1)
                .frame(minHeight: 200)
            
            // Benchmark button
            Button(action: {
                guard let model = benchmarkVM.selectedModel else { return }
                Task {
                    try await benchmarkVM.runBenchmark(text: inputText, model: model)
                }
            }) {
                HStack {
                    if benchmarkVM.isGenerating {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(benchmarkVM.isGenerating ? "Generating..." : "Run Benchmark")
                }
            }
            .disabled(benchmarkVM.selectedModel == nil ||
                     modelManager.loadedModels[benchmarkVM.selectedModel?.modelId ?? ""] == nil ||
                     benchmarkVM.isGenerating)
            
            Spacer()
        }
        .padding()
    }
}

struct ResultsPanel: View {
    @ObservedObject var benchmarkVM: BenchmarkViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Results")
                .font(.headline)
            
            if let result = benchmarkVM.currentResult {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Summary
                        VStack(alignment: .leading) {
                            Text("Generated Summary")
                                .font(.subheadline)
                                .bold()
                            Text(result.generatedSummary)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        // Metrics
                        MetricsView(metrics: result.metrics)
                    }
                    .padding()
                }
            } else {
                Text("No results yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
    }
}

struct MetricsView: View {
    let metrics: BenchmarkResult.PerformanceMetrics
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Performance Metrics")
                .font(.subheadline)
                .bold()
            
            Grid(alignment: .leading) {
                GridRow {
                    Text("Inference Time:")
                    Text("\(String(format: "%.2f", metrics.inferenceTime))s")
                }
                GridRow {
                    Text("Tokens/Second:")
                    Text("\(String(format: "%.1f", metrics.tokensPerSecond))")
                }
                GridRow {
                    Text("Memory Used:")
                    Text("\(String(format: "%.1f", metrics.memoryUsed))MB")
                }
                GridRow {
                    Text("Summary Length:")
                    Text("\(metrics.summaryLength) chars")
                }
                GridRow {
                    Text("Compression Ratio:")
                    Text("\(String(format: "%.2f", metrics.compressionRatio))")
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// Sample texts for testing
let sampleTexts = [
    """
    Climate change is one of the most pressing challenges facing humanity today. Rising global temperatures, largely driven by human activities such as burning fossil fuels and deforestation, are causing widespread environmental disruptions. These include melting ice caps, rising sea levels, more frequent extreme weather events, and shifts in precipitation patterns. The impacts are not just environmental but also social and economic, affecting agriculture, water resources, human health, and infrastructure. Addressing climate change requires urgent global action, including transitioning to renewable energy sources, improving energy efficiency, protecting and restoring forests, and implementing policies that reduce greenhouse gas emissions.
    """,
    """
    Artificial intelligence has revolutionized numerous industries and aspects of daily life. From healthcare diagnostics to autonomous vehicles, from personalized recommendations to smart home systems, AI technologies are becoming increasingly integrated into our world. Machine learning algorithms can now process vast amounts of data to identify patterns and make predictions that would be impossible for humans to achieve manually. However, this rapid advancement also raises important questions about privacy, job displacement, algorithmic bias, and the need for responsible AI development. As we continue to advance these technologies, it's crucial to balance innovation with ethical considerations and ensure that AI benefits all of humanity.
    """,
    """
    The human brain is one of the most complex structures in the known universe, containing approximately 86 billion neurons interconnected through trillions of synapses. This intricate network enables consciousness, memory, learning, and all cognitive functions that define human experience. Recent advances in neuroscience have revealed fascinating insights into how the brain processes information, forms memories, and adapts through neuroplasticity. Researchers are using cutting-edge technologies like functional MRI, optogenetics, and brain-computer interfaces to unlock the mysteries of neural function. Understanding the brain better has profound implications for treating neurological disorders, developing artificial intelligence, and potentially enhancing human cognitive abilities.
    """
]
