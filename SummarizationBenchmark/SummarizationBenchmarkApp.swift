//
//  SummarizationBenchmarkApp.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.06.2025.
//

// MARK: - Main App File
import SwiftUI
import Foundation
import MLX
import MLXFast

@main
struct SummarizationBenchmarkApp: App {
    init() {
        // Инициализация MLX при запуске приложения
        setupMLX()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1200, minHeight: 800)
                .onAppear {
                    setupAppearance()
                }
        }
        .defaultSize(width: 1400, height: 900)
        .commands {
            // Добавляем команды меню
            AppCommands()
        }
    }
    
    private func setupMLX() {
            // Устанавливаем разумный лимит кэша (70% от общей памяти)
            MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)
        
    }
    
    private func setupAppearance() {
        // Настройка внешнего вида приложения
        if #available(macOS 14.0, *) {
            // Настройки для macOS 14+
        }
    }
}

// MARK: - App Commands (Menu)
struct AppCommands: Commands {
    var body: some Commands {
        // File Menu
        CommandGroup(replacing: .newItem) {
            Button("New Benchmark Session") {
                // TODO: Implement new session creation
            }
            .keyboardShortcut("n", modifiers: .command)
            
            Button("Export Current Session...") {
                // TODO: Implement export functionality
            }
            .keyboardShortcut("e", modifiers: .command)
        }
        
        // Models Menu
        CommandMenu("Models") {
            Button("Load All Small Models") {
                // TODO: Implement bulk loading
            }
            
            Button("Unload All Models") {
                // TODO: Implement bulk unloading
            }
            .keyboardShortcut("u", modifiers: [.command, .shift])
            
            Divider()
            
            Button("Show GPU Memory Usage") {
                // TODO: Show memory dialog
            }
            .keyboardShortcut("m", modifiers: .command)
        }
        
        // Benchmark Menu
        CommandMenu("Benchmark") {
            Button("Run Quick Test") {
                // TODO: Implement quick test
            }
            .keyboardShortcut("r", modifiers: .command)
            
            Button("Run Full Benchmark Suite") {
                // TODO: Implement full benchmark
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            
            Divider()
            
            Button("Clear Results") {
                // TODO: Clear current results
            }
        }
        
        // Help Menu
        CommandGroup(replacing: .help) {
            Button("Summarization Benchmark Help") {
                // TODO: Show help window
            }
            
            Button("About Models") {
                // TODO: Show model information
            }
            
            Button("Performance Tips") {
                // TODO: Show performance tips
            }
        }
    }
}
