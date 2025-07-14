//
//  SidebarView.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.07.2025.
//

import SwiftUI


struct SidebarView: View {
    @ObservedObject var benchmarkVM: BenchmarkViewModel
    @ObservedObject var modelManager: ModelManager
    @ObservedObject var datasetManager: DatasetManager
    @ObservedObject var appState: AppState
    
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
            // Navigation Tabs
            VStack(spacing: 0) {
                Button(action: { appState.selectedTab = 0 }) {
                    HStack {
                        Image(systemName: "chart.bar")
                        Text("Benchmark")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(appState.selectedTab == 0 ? Color.accentColor.opacity(0.2) : Color.clear)
                    .foregroundColor(appState.selectedTab == 0 ? .accentColor : .primary)
                }
                
                Button(action: { appState.selectedTab = 1 }) {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("Datasets")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(appState.selectedTab == 1 ? Color.accentColor.opacity(0.2) : Color.clear)
                    .foregroundColor(appState.selectedTab == 1 ? .accentColor : .primary)
                }
            }
            .buttonStyle(.plain)
            
            Divider()
            
            if appState.selectedTab == 0 {
                // Models Section
                VStack(alignment: .leading) {
                    Text("Models")
                        .font(.title2)
                        .bold()
                        .padding()
                    
                    // Models List
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(SummarizationModel.availableModels) { model in
                                modelCardView(for: model)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            } else {
                // Datasets Section
                VStack(alignment: .leading) {
                    Text("Datasets")
                        .font(.title2)
                        .bold()
                        .padding()
                    
                    // Dataset List
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(datasetManager.datasets) { dataset in
                                datasetCardView(dataset)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            Spacer()
            
            // Memory Info
            MemoryInfoView()
                .padding()
        }
        .frame(minWidth: 300, maxWidth: 350)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func datasetCardView(_ dataset: Dataset) -> some View {
        let isSelected = datasetManager.selectedDataset?.id == dataset.id
        
        return Button(action: {
            datasetManager.selectedDataset = dataset
        }) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dataset.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("\(dataset.entries.count) entries")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: sourceIcon(for: dataset.source))
                    Text(dataset.source.rawValue)
                        .font(.caption2)
                    
                    Spacer()
                    
                    Image(systemName: categoryIcon(for: dataset.category))
                    Text(dataset.category.rawValue)
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // Получение иконки для источника датасета
    private func sourceIcon(for source: Dataset.DatasetSource) -> String {
        switch source {
        case .cnnDailyMail:
            return "newspaper"
        case .redditTIFU:
            return "person.2"
        case .scientificAbstracts:
            return "book"
        case .custom:
            return "doc.text"
        case .arxivPapers:
            return "doc.text"
        }
    }
    
    // Получение иконки для категории датасета
    private func categoryIcon(for category: Dataset.DatasetCategory) -> String {
        switch category {
        case .news:
            return "globe"
        case .social:
            return "bubble.left.and.bubble.right"
        case .scientific:
            return "graduationcap"
        case .other:
            return "doc"
        }
    }
}
