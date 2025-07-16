//
//  MainContentView.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.06.2025.
//

import MLX
import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// Class for managing application state
@MainActor
class AppState: ObservableObject {
    let modelManager: ModelManager
    let benchmarkVM: BenchmarkViewModel
    let datasetManager = DatasetManager()
    let pythonModelVM = PythonModelViewModel()
    
    // Selected tab (0 - Benchmark, 1 - Datasets, 2 - Python Models)
    @Published var selectedTab: Int = 0
    
    // Показывать ли представление Python-моделей
    @Published var showPythonModelsView: Bool = false
    
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
        
        // Подписываемся на уведомление для показа Python-моделей
        NotificationCenter.default.addObserver(forName: Notification.Name("ShowPythonModelsView"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.showPythonModelsView = true
            }
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
            } else if appState.selectedTab == 1 {
                DatasetsView(datasetManager: appState.datasetManager)
            } else {
                PythonModelView(viewModel: appState.pythonModelVM)
            }
        }
        .frame(minWidth: 1200, minHeight: 800)
        .sheet(isPresented: $appState.showPythonModelsView) {
            PythonModelView(viewModel: appState.pythonModelVM)
                .frame(width: 800, height: 700)
        }
    }
}
