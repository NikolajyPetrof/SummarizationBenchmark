//
//  ContentView.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.06.2025.
//

import MLX
import SwiftUI

struct ContentView: View {
    @StateObject private var benchmarkVM = BenchmarkViewModel()
    @StateObject private var modelManager = ModelManager()
    
    var body: some View {
        NavigationView {
            SidebarView(benchmarkVM: benchmarkVM, modelManager: modelManager)
            MainBenchmarkView(benchmarkVM: benchmarkVM, modelManager: modelManager)
        }
        .frame(minWidth: 1200, minHeight: 800)
        .navigationTitle("Summarization Benchmark")
    }
}

// MARK: - Sidebar для выбора моделей
struct SidebarView: View {
    @ObservedObject var benchmarkVM: BenchmarkViewModel
    @ObservedObject var modelManager: ModelManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("Models")
                .font(.title2)
                .bold()
                .padding()
            
            Divider()
            
            // Models List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(SummarizationModel.availableModels) { model in
                        ModelCardView(
                            model: model,
                            isLoaded: modelManager.loadedModels[model.modelId] != nil,
                            isSelected: benchmarkVM.selectedModel?.id == model.id,
                            isLoading: modelManager.isLoading && modelManager.loadingStatus.contains(model.name),
                            loadingProgress: modelManager.loadingProgress,
                            onSelect: {
                                benchmarkVM.selectedModel = model
                            },
                            onLoad: {
                                Task {
                                    try await modelManager.loadModel(model)
                                }
                            },
                            onUnload: {
                                modelManager.unloadModel(model.modelId)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Memory Info
            MemoryInfoView()
                .padding()
        }
        .frame(minWidth: 300, maxWidth: 350)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Model Card для каждой модели
struct ModelCardView: View {
    let model: SummarizationModel
    let isLoaded: Bool
    let isSelected: Bool
    let isLoading: Bool
    let loadingProgress: Double
    let onSelect: () -> Void
    let onLoad: () -> Void
    let onUnload: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Model Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.name)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    HStack {
                        Text(model.size.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(model.size == .small ? Color.green : Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                        
                        Text("~\(String(format: "%.1f", model.size.expectedMemory))GB")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status Indicator
                Circle()
                    .fill(isLoaded ? Color.green : Color.gray)
                    .frame(width: 12, height: 12)
            }
            
            // Loading Progress
            if isLoading {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: loadingProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                    Text("\(Int(loadingProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Action Buttons
            HStack {
                if isLoaded {
                    Button("Unload") {
                        onUnload()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                } else {
                    Button("Load") {
                        onLoad()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)
                }
                
                Spacer()
                
                if isLoaded {
                    Button("Select") {
                        onSelect()
                    }
                    .buttonStyle(isSelected ? .borderedProminent : .bordered)
                    .disabled(isSelected)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor : Color(NSColor.controlColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isLoaded ? Color.green : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Memory Info View
struct MemoryInfoView: View {
    @State private var memoryInfo = MLX.GPU.memoryInfo()
    @State private var timer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GPU Memory")
                .font(.headline)
            
            let usedGB = Double(memoryInfo.used) / (1024 * 1024 * 1024)
            let totalGB = Double(memoryInfo.total) / (1024 * 1024 * 1024)
            let usagePercentage = Double(memoryInfo.used) / Double(memoryInfo.total)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Used:")
                    Spacer()
                    Text("\(String(format: "%.1f", usedGB))GB / \(String(format: "%.1f", totalGB))GB")
                }
                .font(.caption)
                
                ProgressView(value: usagePercentage)
                    .progressViewStyle(LinearProgressViewStyle())
                
                Text("\(Int(usagePercentage * 100))% used")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlColor))
        .cornerRadius(8)
        .onAppear {
            startMemoryMonitoring()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startMemoryMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            memoryInfo = MLX.GPU.memoryInfo()
        }
    }
}

// MARK: - Main Benchmark View
struct MainBenchmarkView: View {
    @ObservedObject var benchmarkVM: BenchmarkViewModel
    @ObservedObject var modelManager: ModelManager
    
    var body: some View {
        HSplitView {
            // Input Panel
            TextInputPanel(benchmarkVM: benchmarkVM, modelManager: modelManager)
                .frame(minWidth: 400)
            
            // Results Panel
            BenchmarkResultsPanel(benchmarkVM: benchmarkVM)
                .frame(minWidth: 400)
        }
    }
}

// MARK: - Text Input Panel
struct TextInputPanel: View {
    @ObservedObject var benchmarkVM: BenchmarkViewModel
    @ObservedObject var modelManager: ModelManager
    @State private var selectedPreset = TextPreset.climate
    @State private var customText = ""
    @State private var useCustomText = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Input Text")
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                // Session Controls
                Button("New Session") {
                    // TODO: Implement new session
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Text Source Toggle
            Picker("Text Source", selection: $useCustomText) {
                Text("Preset Texts").tag(false)
                Text("Custom Text").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            if useCustomText {
                // Custom Text Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter your text:")
                        .font(.headline)
                    
                    TextEditor(text: $customText)
                        .font(.system(.body, design: .monospaced))
                        .border(Color.gray.opacity(0.5), width: 1)
                        .frame(minHeight: 300)
                    
                    HStack {
                        Text("Characters: \(customText.count)")
                        Spacer()
                        Text("Words: \(customText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            } else {
                // Preset Text Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select preset text:")
                        .font(.headline)
                    
                    Picker("Preset", selection: $selectedPreset) {
                        ForEach(TextPreset.allCases, id: \.self) { preset in
                            Text(preset.title).tag(preset)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    // Preview
                    ScrollView {
                        Text(selectedPreset.content)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 250)
                    
                    HStack {
                        Text("Characters: \(selectedPreset.content.count)")
                        Spacer()
                        Text("Words: \(selectedPreset.wordCount)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Benchmark Controls
            BenchmarkControlsView(
                benchmarkVM: benchmarkVM,
                modelManager: modelManager,
                inputText: useCustomText ? customText : selectedPreset.content
            )
        }
        .padding()
    }
}

// MARK: - Benchmark Controls
struct BenchmarkControlsView: View {
    @ObservedObject var benchmarkVM: BenchmarkViewModel
    @ObservedObject var modelManager: ModelManager
    let inputText: String
    
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
                HStack {
                    VStack(alignment: .leading) {
                        Text("Selected Model:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(selectedModel.name)
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    let isLoaded = modelManager.loadedModels[selectedModel.modelId] != nil
                    Text(isLoaded ? "✅ Loaded" : "❌ Not Loaded")
                        .font(.caption)
                        .foregroundColor(isLoaded ? .green : .red)
                }
                .padding()
                .background(Color(NSColor.controlColor))
                .cornerRadius(8)
            } else {
                Text("No model selected")
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(NSColor.controlColor))
                    .cornerRadius(8)
            }
            
            // Run Benchmark Button
            Button(action: {
                Task {
                    guard let model = benchmarkVM.selectedModel else { return }
                    try await benchmarkVM.runBenchmark(text: inputText, model: model)
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

// MARK: - Benchmark Results Panel
struct BenchmarkResultsPanel: View {
    @ObservedObject var benchmarkVM: BenchmarkViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Benchmark Results")
                .font(.title2)
                .bold()
            
            if let result = benchmarkVM.currentResult {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Summary Output
                        SummaryOutputView(result: result)
                        
                        // Performance Metrics
                        PerformanceMetricsView(metrics: result.metrics)
                        
                        // Model Info
                        ModelInfoView(result: result)
                    }
                    .padding()
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
                        Text("Run a benchmark to see results")
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

// MARK: - Summary Output View
struct SummaryOutputView: View {
    let result: BenchmarkResult
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text("Generated Summary")
                        .font(.headline)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                ScrollView {
                    Text(result.generatedSummary)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.textBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                .frame(maxHeight: 200)
                
                HStack {
                    Text("Length: \(result.generatedSummary.count) characters")
                    Spacer()
                    Button("Copy") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(result.generatedSummary, forType: .string)
                    }
                    .buttonStyle(.bordered)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Performance Metrics View
struct PerformanceMetricsView: View {
    let metrics: BenchmarkResult.PerformanceMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Metrics")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetricCard(
                    title: "Inference Time",
                    value: "\(String(format: "%.2f", metrics.inferenceTime))s",
                    icon: "clock",
                    color: .blue
                )
                
                MetricCard(
                    title: "Tokens/Second",
                    value: "\(String(format: "%.1f", metrics.tokensPerSecond))",
                    icon: "speedometer",
                    color: .green
                )
                
                MetricCard(
                    title: "Memory Used",
                    value: "\(String(format: "%.1f", metrics.memoryUsed))MB",
                    icon: "memorychip",
                    color: .orange
                )
                
                MetricCard(
                    title: "Compression",
                    value: "\(String(format: "%.1f", metrics.compressionRatio * 100))%",
                    icon: "arrow.down.circle",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .bold()
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Model Info View
struct ModelInfoView: View {
    let result: BenchmarkResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Model Information")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                InfoRow(label: "Model:", value: result.modelName)
                InfoRow(label: "Timestamp:", value: DateFormatter.localizedString(from: result.timestamp, dateStyle: .short, timeStyle: .medium))
                InfoRow(label: "Input Length:", value: "\(result.inputText.count) characters")
                InfoRow(label: "Summary Length:", value: "\(result.metrics.summaryLength) characters")
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
        .font(.caption)
    }
}

// MARK: - Text Presets
enum TextPreset: String, CaseIterable {
    case climate = "climate"
    case ai = "ai"
    case brain = "brain"
    case economics = "economics"
    case space = "space"
    
    var title: String {
        switch self {
        case .climate: return "Climate Change"
        case .ai: return "Artificial Intelligence"
        case .brain: return "Human Brain"
        case .economics: return "Global Economics"
        case .space: return "Space Exploration"
        }
    }
    
    var content: String {
        switch self {
        case .climate:
            return """
            Climate change is one of the most pressing challenges facing humanity today. Rising global temperatures, largely driven by human activities such as burning fossil fuels and deforestation, are causing widespread environmental disruptions. These include melting ice caps, rising sea levels, more frequent extreme weather events, and shifts in precipitation patterns. The impacts are not just environmental but also social and economic, affecting agriculture, water resources, human health, and infrastructure. Scientists worldwide are studying these effects and developing models to predict future scenarios. Addressing climate change requires urgent global action, including transitioning to renewable energy sources, improving energy efficiency, protecting and restoring forests, and implementing policies that reduce greenhouse gas emissions. International cooperation through agreements like the Paris Climate Accord is essential for coordinating efforts across nations.
            """
        case .ai:
            return """
            Artificial intelligence has revolutionized numerous industries and aspects of daily life. From healthcare diagnostics to autonomous vehicles, from personalized recommendations to smart home systems, AI technologies are becoming increasingly integrated into our world. Machine learning algorithms can now process vast amounts of data to identify patterns and make predictions that would be impossible for humans to achieve manually. Deep learning networks have achieved remarkable breakthroughs in image recognition, natural language processing, and game playing. However, this rapid advancement also raises important questions about privacy, job displacement, algorithmic bias, and the need for responsible AI development. As we continue to advance these technologies, it's crucial to balance innovation with ethical considerations and ensure that AI benefits all of humanity while minimizing potential risks and negative consequences.
            """
        case .brain:
            return """
            The human brain is one of the most complex structures in the known universe, containing approximately 86 billion neurons interconnected through trillions of synapses. This intricate network enables consciousness, memory, learning, and all cognitive functions that define human experience. Recent advances in neuroscience have revealed fascinating insights into how the brain processes information, forms memories, and adapts through neuroplasticity. Researchers are using cutting-edge technologies like functional MRI, optogenetics, and brain-computer interfaces to unlock the mysteries of neural function. Studies have shown that the brain continues to change and adapt throughout life, challenging previous assumptions about fixed neural pathways. Understanding the brain better has profound implications for treating neurological disorders, developing artificial intelligence, and potentially enhancing human cognitive abilities through various interventions and technologies.
            """
        case .economics:
            return """
            The global economy is a complex interconnected system that affects billions of people worldwide. Economic policies, trade relationships, and market dynamics influence everything from employment rates to the cost of everyday goods. In recent years, we've seen significant shifts due to technological advancement, changing demographics, and global events. Digital currencies and blockchain technology are challenging traditional financial systems, while automation is transforming labor markets. Income inequality has become a major concern in many developed nations, leading to discussions about universal basic income and progressive taxation. International trade agreements and tariffs continue to shape global commerce, while emerging markets play increasingly important roles in the world economy. Understanding these economic forces is crucial for governments, businesses, and individuals making financial decisions in an interconnected world.
            """
        case .space:
            return """
            Space exploration represents humanity's greatest adventure and scientific endeavor. From the first human steps on the Moon to robotic missions exploring Mars and the outer planets, space exploration has expanded our understanding of the universe and our place within it. Modern space programs involve international cooperation, with the International Space Station serving as a symbol of what nations can achieve together. Private companies like SpaceX and Blue Origin are revolutionizing space travel with reusable rockets and ambitious plans for Mars colonization. Scientific discoveries from space missions have led to countless technological innovations that benefit life on Earth, from satellite communications to medical imaging technologies. As we look to the future, missions to Mars, asteroid mining, and the search for extraterrestrial life promise to open new frontiers for human civilization and scientific discovery.
            """
        }
    }
    
    var wordCount: Int {
        content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
}

