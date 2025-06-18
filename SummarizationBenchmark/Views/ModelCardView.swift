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
    let onSelect: () -> Void
    let onLoad: () -> Void
    let onUnload: () -> Void
    
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
            onSelect: {},
            onLoad: {},
            onUnload: {}
        )
    }
    .padding()
    .frame(width: 300)
}
