//
//  MainContentView.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.06.2025.
//

import MLX
import SwiftUI
import AppKit

// Класс для управления состоянием приложения
@MainActor
class AppState: ObservableObject {
    let modelManager = ModelManager()
    let benchmarkVM: BenchmarkViewModel
    
    init() {
        print("AppState: Создание AppState и ModelManager")
        benchmarkVM = BenchmarkViewModel(modelManager: modelManager)
    }
}

struct ContentView: View {
    // Используем StateObject для создания и хранения AppState
    @StateObject private var appState = AppState()
    
    var body: some View {
        return NavigationView {
            SidebarView(benchmarkVM: appState.benchmarkVM, modelManager: appState.modelManager)
            MainBenchmarkView(benchmarkVM: appState.benchmarkVM, modelManager: appState.modelManager)
        }
        .frame(minWidth: 1200, minHeight: 800)
        .navigationTitle("Summarization Benchmark")
        .navigationTitle("Summarization Benchmark")
        .navigationTitle("Summarization Benchmark")
        .navigationTitle("Summarization Benchmark")
    }
}

// MARK: - Sidebar для выбора моделей
struct SidebarView: View {
    @ObservedObject var benchmarkVM: BenchmarkViewModel
    @ObservedObject var modelManager: ModelManager
    
    private func modelCardView(for model: SummarizationModel) -> some View {
        let isCurrentModel = benchmarkVM.currentResult?.modelId == model.modelId
        let isLoaded = modelManager.loadedModels[model.modelId] != nil
        let isLoading = modelManager.isModelLoading(model.modelId)
        let isSelected = benchmarkVM.selectedModel?.modelId == model.modelId
        let loadingProgress = modelManager.getModelProgress(model.modelId)
        let hasError = modelManager.hasModelError(model.modelId)
        
        let metrics: (time: Double, tokensPerSecond: Double, compressionRatio: Double)?
        
        if isCurrentModel, let result = benchmarkVM.currentResult {
            metrics = (
                time: result.metrics.inferenceTime,
                tokensPerSecond: result.metrics.tokensPerSecond,
                compressionRatio: result.metrics.compressionRatio
            )
        } else {
            metrics = nil
        }
        
        return ModelCardView(
            model: model,
            isLoaded: isLoaded,
            isSelected: isSelected,
            isLoading: isLoading,
            loadingProgress: loadingProgress,
            hasError: hasError,
            errorMessage: modelManager.getModelError(model.modelId),
            generatedSummary: isCurrentModel ? benchmarkVM.currentResult?.generatedSummary : nil,
            metrics: metrics,
            onSelect: { benchmarkVM.selectedModel = model },
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
                        modelCardView(for: model)
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

// MARK: - Memory Info View
struct MemoryInfoView: View {
    @State private var memoryInfo = (used: 0, total: MLX.GPU.cacheLimit)
    @State private var timer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GPU Memory")
                .font(.headline)
            
            // Безопасно вычисляем значения для отображения
            let safeTotal = max(Double(memoryInfo.total), 1.0) // Избегаем деления на ноль
            let safeUsed = max(min(Double(memoryInfo.used), safeTotal), 0.0) // Ограничиваем значение
            
            let usedGB = safeUsed / (1024 * 1024 * 1024)
            let totalGB = safeTotal / (1024 * 1024 * 1024)
            let usagePercentage = min(safeUsed / safeTotal, 1.0) // Ограничиваем значением 1.0
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Used:")
                    Spacer()
                    Text("\(String(format: "%.1f", usedGB))GB / \(String(format: "%.1f", totalGB))GB")
                }
                .font(.caption)
                
                ProgressView(value: usagePercentage)
                    .progressViewStyle(LinearProgressViewStyle())
                
                // Используем безопасное преобразование в Int
                let usagePercent = Int(usagePercentage * 100)
                Text("\(usagePercent)% used")
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
            memoryInfo = (used: MLX.GPU.memoryLimit, total: MLX.GPU.cacheLimit)
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
                .frame(minWidth: 400, idealWidth: 500, maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)
            
            // Results Panel
            BenchmarkResultsPanel(benchmarkVM: benchmarkVM)
                .frame(minWidth: 400, idealWidth: 500, maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        .frame(minHeight: 300, maxHeight: .infinity, alignment: .topLeading)
                        .frame(maxWidth: .infinity)
                    
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
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                    }
                    .frame(minHeight: 300, maxHeight: .infinity)
                    .frame(maxWidth: .infinity)
                    
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
                    
                    // Model status indicator
                    Circle()
                        .fill(modelManager.loadedModels[selectedModel.modelId] != nil ? Color.green : Color.orange)
                        .frame(width: 10, height: 10)
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
                        try await benchmarkVM.runBenchmark(text: inputText, model: model)
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

// MARK: - Benchmark Results Panel
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
struct SummaryOutputView: View {
    let result: BenchmarkResult
    @State private var isExpanded = true
    @State private var copiedToClipboard = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Generated Summary")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(result.generatedSummary, forType: .string)
                    copiedToClipboard = true
                    
                    // Reset the copied state after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copiedToClipboard = false
                    }
                }) {
                    Label(copiedToClipboard ? "Copied!" : "Copy", systemImage: copiedToClipboard ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.bordered)
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                }
                .buttonStyle(.plain)
            }
            
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
    case gun = "gun"
    case penguin = "penguin"
    
    var title: String {
        switch self {
        case .climate: return "Climate Change"
        case .ai: return "Artificial Intelligence"
        case .brain: return "Human Brain"
        case .economics: return "Global Economics"
        case .space: return "Space Exploration"
        case .gun: return "Зимнее утро"
        case .penguin: return "Penguin"
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
        case .gun:
            return """
                Мороз и солнце; день чудесный!
                Еще ты дремлешь, друг прелестный —
                Пора, красавица, проснись:
                Открой сомкнуты негой взоры
                Навстречу северной Авроры,
                Звездою севера явись!
                Вечор, ты помнишь, вьюга злилась,
                На мутном небе мгла носилась;
                Луна, как бледное пятно,
                Сквозь тучи мрачные желтела,
                И ты печальная сидела —
                А нынче… погляди в окно:
                Под голубыми небесами
                Великолепными коврами,
                Блестя на солнце, снег лежит;
                Прозрачный лес один чернеет,
                И ель сквозь иней зеленеет,
                И речка подо льдом блестит.
                Вся комната янтарным блеском
                Озарена. Веселым треском
                Трещит затопленная печь.
                Приятно думать у лежанки.
                Но знаешь: не велеть ли в санки
                Кобылку бурую запречь?
                Скользя по утреннему снегу,
                Друг милый, предадимся бегу
                Нетерпеливого коня
                И навестим поля пустые,
                Леса, недавно столь густые,
                И берег, милый для меня.
                """
        case .penguin:
            return """
                Пингвин — птица, которая не летает. Зато все 18 видов этого семейства отлично плавают и ныряют — благодаря обтекаемой форме тела и устройству костей крыльев.

                Императорских пингвинов в Антарктиде живет так много, что их колонии видны из космоса! Это помогает ученым изучать птиц, считать их, следить за передвиженями.

                «Эффектом пингвина» называют такое поведение, когда ни один человек (или пингвин!) на берегу не хочет первым заходить в воду. Может быть, потому, что она холодная, или просто нет настроения. Но пингвины делают именно так: подталкивают друг друга, отходят как бы нерешительно, снова приближаются к воде — до тех пор, пока кто-то из них не спрыгнет в воду первым. Такое поведение — природный механизм, ведь в естественных условиях жизни пингвин, первым прыгнувший в воду, рискует быть съеденным хищником.

                Пингвины пьют морскую воду (или глотают ее во время охоты за рыбой). Для них это безопасно, потому что с помощью особой надглазной железы соль отфильтровывается из организма птицы. Соленая вода потом выделяется через клюв во время чихания.

                Пингвины питаются морепродуктами. Рыбу, кальмаров и креветок они ловят во время ныряния, но пищу не жуют — зубов у пингвина нет, он же птица! Зато у него в пасти особые шипы, которые помогают еде отправляться прямо в глотку.

                Раз в год пингвины линяют. Линька происходит обычно весной: «зимнее», старое оперение пингвин меняет на новое, сбрасывая практически все перья! От трёх до четырёх недель, пока новое оперение отрастает, пингвин выглядит как пушистый серо-коричневый шарик. У нового пуха еще некоторое время нет водоотталкивающих свойств, поэтому плавать пингвин в это время не может.
                """
        }
    }
    
    var wordCount: Int {
        content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
}
