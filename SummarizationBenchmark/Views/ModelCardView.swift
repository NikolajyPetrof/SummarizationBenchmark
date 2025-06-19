//
//  ModelCardView.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.06.2025.
//

import SwiftUI

struct ModelCardView: View {
    let model: SummarizationModel
    let isLoaded: Bool
    let isSelected: Bool
    let isLoading: Bool
    let loadingProgress: Double
    let hasError: Bool
    let errorMessage: String?
    let generatedSummary: String?
    let metrics: (time: Double, tokensPerSecond: Double, compressionRatio: Double)?
    let onSelect: () -> Void
    let onLoad: () -> Void
    let onUnload: () -> Void
    
    @State private var isShowingSummary = false
    @State private var isShowingError = false
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 6) {
                // Header with name and size
                HStack {
                    Text(model.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(model.size.rawValue)
                        .font(.caption)
                        .padding(4)
                        .background(sizeColor)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                
                // Model ID
                Text(model.modelId)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Memory requirement
                Text("Memory: \(model.memoryRequirement)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                // Loading progress
                if isLoading {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Loading... \(Int(loadingProgress * 100))%")
                            .font(.caption)
                        
                        ProgressView(value: loadingProgress)
                            .progressViewStyle(.linear)
                            .frame(height: 4)
                    }
                    .padding(.top, 2)
                }
                
                // Actions
                HStack {
                    if isLoaded {
                        Button("Unload") {
                            onUnload()
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.mini)
                        .disabled(isLoading)
                    } else {
                        Button("Load") {
                            onLoad()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .controlSize(.mini)
                        .disabled(isLoading)
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                }
                .padding(.top, 4)
                
                // Show summary section if available
                if let summary = generatedSummary, isShowingSummary {
                    VStack(alignment: .leading, spacing: 4) {
                        Divider()
                            .padding(.vertical, 4)
                        
                        Text("Summary:")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.primary)
                        
                        Text(summary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(4)
                            .transition(.opacity)
                        
                        if let metrics = metrics {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading) {
                                    Text("\(String(format: "%.2f", metrics.time))s")
                                        .font(.caption2)
                                        .bold()
                                    Text("Time")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("\(Int(metrics.tokensPerSecond))")
                                        .font(.caption2)
                                        .bold()
                                    Text("Tokens/s")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("\(Int(metrics.compressionRatio * 100))%")
                                        .font(.caption2)
                                        .bold()
                                    Text("Compression")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .animation(.easeInOut, value: isShowingSummary)
                }
                
                // Show error section if available
                if let error = errorMessage, isShowingError {
                    VStack(alignment: .leading, spacing: 4) {
                        Divider()
                            .padding(.vertical, 4)
                        
                        Text("Error:")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.primary)
                        
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(4)
                            .transition(.opacity)
                    }
                    .animation(.easeInOut, value: isShowingError)
                }
                
                // Toggle summary button
                if generatedSummary != nil {
                    Button(action: {
                        withAnimation {
                            isShowingSummary.toggle()
                        }
                    }) {
                        HStack {
                            Text(isShowingSummary ? "Hide Summary" : "Show Summary")
                                .font(.caption)
                            Image(systemName: isShowingSummary ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundColor(.blue)
                        .padding(.top, 2)
                    }
                    .buttonStyle(.borderless)
                }
                
                // Toggle error button
                if errorMessage != nil {
                    Button(action: {
                        withAnimation {
                            isShowingError.toggle()
                        }
                    }) {
                        HStack {
                            Text(isShowingError ? "Hide Error" : "Show Error")
                                .font(.caption)
                            Image(systemName: isShowingError ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundColor(.blue)
                        .padding(.top, 2)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(10)
            .background(cardBackgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? .blue : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var sizeColor: Color {
        switch model.size {
        case .small: return .green
        case .large: return .orange
        }
    }
    
    private var statusColor: Color {
        if isLoading {
            return .yellow
        } else if isLoaded {
            return .green
        } else if hasError {
            return .red
        } else {
            return .gray
        }
    }
    
    private var cardBackgroundColor: Color {
        if isSelected {
            return Color.blue.opacity(0.1)
        } else {
            return Color(NSColor.tertiarySystemFill)
        }
    }
}

#Preview {
    VStack {
        ModelCardView(
            model: SummarizationModel.availableModels[0],
            isLoaded: true,
            isSelected: true,
            isLoading: false,
            loadingProgress: 0,
            hasError: false,
            errorMessage: nil,
            generatedSummary: "This is a sample summary generated by the model. It provides a concise overview of the input text.",
            metrics: (time: 1.23, tokensPerSecond: 45.6, compressionRatio: 0.25),
            onSelect: {},
            onLoad: {},
            onUnload: {}
        )
        
        ModelCardView(
            model: SummarizationModel.availableModels[1],
            isLoaded: false,
            isSelected: false,
            isLoading: true,
            loadingProgress: 0.7,
            hasError: true,
            errorMessage: "An error occurred while loading the model.",
            generatedSummary: nil,
            metrics: nil,
            onSelect: {},
            onLoad: {},
            onUnload: {}
        )
    }
    .padding()
    .frame(width: 300)
}
