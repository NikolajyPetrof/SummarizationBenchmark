//
//  TextInputPanel.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.07.2025.
//

import SwiftUI

struct TextInputPanel: View {
    @ObservedObject var benchmarkVM: BenchmarkViewModel
    @ObservedObject var modelManager: ModelManager
    @State private var selectedPreset = TextPreset.climate
    @State private var customText = ""
    @State private var useCustomText = false
    @State private var selectedBatchSize = 1
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Input Text")
                .font(.title2)
                .bold()
            
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
