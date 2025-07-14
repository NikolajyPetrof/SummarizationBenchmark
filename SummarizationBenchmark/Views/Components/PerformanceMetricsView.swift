//
//  PerformanceMetricsView.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.07.2025.
//

import SwiftUI

struct PerformanceMetricsView: View {
    let metrics: BenchmarkResult.PerformanceMetrics
    @State private var copiedMetric: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Performance Metrics")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    copyAllMetrics()
                }) {
                    Label(copiedMetric == "all" ? "Copied!" : "Copy All",
                          systemImage: copiedMetric == "all" ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.bordered)
            }
            
            // Основные метрики производительности
            Group {
                Text("General Performance")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    MetricCard(
                        title: "Inference Time",
                        value: "\(String(format: "%.2f", metrics.inferenceTime))s",
                        icon: "clock",
                        color: .blue,
                        onCopy: { copyMetric("\(String(format: "%.2f", metrics.inferenceTime))", key: "inference") }
                    )
                    
                    MetricCard(
                        title: "Tokens/Second",
                        value: "\(String(format: "%.1f", metrics.tokensPerSecond))",
                        icon: "speedometer",
                        color: .green,
                        onCopy: { copyMetric("\(String(format: "%.1f", metrics.tokensPerSecond))", key: "tokens") }
                    )
                    
                    MetricCard(
                        title: "Memory Used",
                        value: "\(String(format: "%.1f", metrics.memoryUsed))MB",
                        icon: "memorychip",
                        color: .orange,
                        onCopy: { copyMetric("\(String(format: "%.1f", metrics.memoryUsed))", key: "memory") }
                    )
                    
                    MetricCard(
                        title: "Compression",
                        value: "\(String(format: "%.1f", metrics.compressionRatio * 100))%",
                        icon: "arrow.down.circle",
                        color: .purple,
                        onCopy: { copyMetric("\(String(format: "%.1f", metrics.compressionRatio * 100))%", key: "compression") }
                    )
                }
            }
            
            // Детальные метрики памяти
            Group {
                Text("Advanced Memory Metrics")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 16)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    // Потребление памяти за время выполнения
                    if let runtimeMem = metrics.runtimeMemoryConsumption {
                        MetricCard(
                            title: "Runtime Memory Consumption",
                            value: "\(String(format: "%.1f", runtimeMem))MB",
                            icon: "chart.bar.xaxis",
                            color: .orange,
                            onCopy: { copyMetric("\(String(format: "%.1f", runtimeMem))", key: "runtime_mem") }
                        )
                    }
                    
                    // Пиковое использование памяти
                    if let peakMem = metrics.peakMemory {
                        MetricCard(
                            title: "Peak Memory",
                            value: "\(String(format: "%.1f", peakMem))MB",
                            icon: "waveform.path.ecg",
                            color: .red,
                            onCopy: { copyMetric("\(String(format: "%.1f", peakMem))", key: "peak_mem") }
                        )
                    }
                    
                    // Память на один элемент батча
                    if let memPerItem = metrics.memoryPerBatchItem {
                        MetricCard(
                            title: "Per-item Memory",
                            value: "\(String(format: "%.1f", memPerItem))MB",
                            icon: "square.stack.3d.up",
                            color: .green,
                            onCopy: { copyMetric("\(String(format: "%.1f", memPerItem))", key: "per_item") }
                        )
                    }
                    
                    // Размер батча с пояснением
                    if let batchSize = metrics.batchSize {
                        VStack(alignment: .leading, spacing: 4) {
                            MetricCard(
                                title: batchSize > 1 ? "Parallel Tasks" : "Batch Size",
                                value: "\(batchSize)",
                                icon: batchSize > 1 ? "arrow.triangle.branch" : "square.on.square",
                                color: batchSize > 1 ? .orange : .blue,
                                onCopy: { copyMetric("\(batchSize)", key: "batch_size") }
                            )
                            
                            if batchSize > 1 {
                                Text("Параллельная обработка")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .italic()
                                    .padding(.horizontal, 8)
                            }
                        }
                    }
                    
                    // Тип квантизации
                    if let quantType = metrics.quantizationType {
                        MetricCard(
                            title: "Quantization",
                            value: quantType,
                            icon: "hammer",
                            color: .purple,
                            onCopy: { copyMetric("\(quantType)", key: "quant") }
                        )
                    }
                    
                    // Эффективность использования памяти
                    if let memEfficiency = metrics.memoryEfficiency {
                        MetricCard(
                            title: "Memory Efficiency",
                            value: "\(String(format: "%.1f", memEfficiency))%",
                            icon: "chart.bar",
                            color: .teal,
                            onCopy: { copyMetric("\(String(format: "%.1f", memEfficiency))%", key: "efficiency") }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func copyMetric(_ text: String, key: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        copiedMetric = key
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedMetric = nil
        }
    }
    
    private func copyAllMetrics() {
        var metricLines = [
            "Performance Metrics:",
            "Inference Time: \(String(format: "%.2f", metrics.inferenceTime))s",
            "Tokens/Second: \(String(format: "%.1f", metrics.tokensPerSecond))",
            "Memory Used: \(String(format: "%.1f", metrics.memoryUsed))MB",
            "Compression: \(String(format: "%.1f", metrics.compressionRatio * 100))%"
        ]
        
        // Добавляем расширенные метрики памяти, если они доступны
        metricLines.append("\nAdvanced Memory Metrics:")
        
        if let runtimeMem = metrics.runtimeMemoryConsumption {
            metricLines.append("Runtime Memory Consumption: \(String(format: "%.1f", runtimeMem))MB")
        }
        
        if let peakMem = metrics.peakMemory {
            metricLines.append("Peak Memory: \(String(format: "%.1f", peakMem))MB")
        }
        
        if let memPerItem = metrics.memoryPerBatchItem {
            metricLines.append("Per-item Memory: \(String(format: "%.1f", memPerItem))MB")
        }
        
        if let batchSize = metrics.batchSize {
            metricLines.append("Batch Size: \(batchSize)")
        }
        
        if let quantType = metrics.quantizationType {
            metricLines.append("Quantization: \(quantType)")
        }
        
        if let memEfficiency = metrics.memoryEfficiency {
            metricLines.append("Memory Efficiency: \(String(format: "%.1f", memEfficiency))%")
        }
        
        let allMetrics = metricLines.joined(separator: "\n")
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(allMetrics, forType: .string)
        copiedMetric = "all"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedMetric = nil
        }
    }
}
