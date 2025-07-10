//
//  MemoryInfoView.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.07.2025.
//

import SwiftUI
import MLX

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
        // Сразу обновляем информацию о памяти
        updateMemoryInfo()
        
        // Запускаем таймер для периодического обновления
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateMemoryInfo()
        }
    }
    
    private func updateMemoryInfo() {
        let used = MLX.GPU.peakMemory  // Используем пиковое значение памяти вместо cacheMemory
        let total = MLX.GPU.memoryLimit // Максимальный размер кэша
        memoryInfo = (used: used, total: total)
    }
}
