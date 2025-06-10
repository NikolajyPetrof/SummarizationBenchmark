//
//  ContentView.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.06.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var benchmarkVM = BenchmarkViewModel()
    @StateObject private var modelManager = ModelManager()
    
    var body: some View {
        NavigationView {
            Sidebar(benchmarkVM: benchmarkVM, modelManager: modelManager)
            MainContentView(benchmarkVM: benchmarkVM, modelManager: modelManager)
        }
        .frame(minWidth: 1000, minHeight: 700)
        .navigationTitle("Summarization Benchmark")
    }
}

struct Sidebar: View {
    @ObservedObject var benchmarkVM: BenchmarkViewModel
    @ObservedObject var modelManager: ModelManager
    
    var body: some View {
        List {
            Section("Models") {
                ForEach(SummarizationModel.availableModels) { model in
                    ModelRowView(
                        model: model,
                        isLoaded: modelManager.loadedModels[model.modelId] != nil,
                        isSelected: benchmarkVM.selectedModel?.id == model.id,
                        onSelect: { benchmarkVM.selectedModel = model },
                        onLoad: {
                            Task {
                                try await modelManager.loadModel(model)
                            }
                        },
                        onUnload: { modelManager.unloadModel(model.modelId) }
                    )
                }
            }
            
            Section("Sessions") {
                ForEach(benchmarkVM.sessions) { session in
                    NavigationLink(session.name, destination: SessionDetailView(session: session))
                }
            }
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 250)
    }
}

struct ModelRowView: View {
    let model: SummarizationModel
    let isLoaded: Bool
    let isSelected: Bool
    let onSelect: () -> Void
    let onLoad: () -> Void
    let onUnload: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(model.name)
                    .font(.headline)
                Text(model.size.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isLoaded {
                Button("Unload") { onUnload() }
                    .foregroundColor(.red)
            } else {
                Button("Load") { onLoad() }
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .onTapGesture { onSelect() }
    }
}
