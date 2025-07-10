//
//  MainContentView.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.06.2025.
//

import MLX
import SwiftUI
import AppKit

// Class for managing application state
@MainActor
class AppState: ObservableObject {
    let modelManager: ModelManager
    let benchmarkVM: BenchmarkViewModel
    let datasetManager = DatasetManager()
    
    // Selected tab (0 - Benchmark, 1 - Datasets)
    @Published var selectedTab: Int = 0
    
    init() {
        print("AppState: Creating AppState and ModelManager")
        
        // First create ModelManager without reference to AppState
        modelManager = ModelManager()
        
        // Create BenchmarkViewModel
        benchmarkVM = BenchmarkViewModel(modelManager: modelManager)
        
        // Now set the reference to AppState in ModelManager
        modelManager.appState = self
        
        // Initialize datasets
        Task {
             datasetManager.loadDatasets()
        }
    }
}

struct ContentView: View {
    // Use StateObject to create and store AppState
    @StateObject private var appState = AppState()
    
    var body: some View {
        HSplitView {
            SidebarView(benchmarkVM: appState.benchmarkVM, modelManager: appState.modelManager, datasetManager: appState.datasetManager, appState: appState)
            
            if appState.selectedTab == 0 {
                MainBenchmarkView(benchmarkVM: appState.benchmarkVM, modelManager: appState.modelManager, datasetManager: appState.datasetManager)
            } else {
                DatasetsView(datasetManager: appState.datasetManager)
            }
        }
        .frame(minWidth: 1200, minHeight: 800)
    }
}
