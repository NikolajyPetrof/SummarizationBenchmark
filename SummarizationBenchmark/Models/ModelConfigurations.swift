//
//  ModelConfigurations.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.06.2025.
//

import Foundation

struct ModelConfiguration: Identifiable, Hashable {
    let id: String
    let defaultPrompt: String
    let extraEOSTokens: [String]
    let temperature: Float
    let maxTokens: Int
    let topP: Float
    let repetitionPenalty: Float
    let additionalMetadata: [String: String]
    
    /// Default summarization prompt that can be used across all models
    let defaultSummarizationPrompt = """
        Summarize the following text. Provide a concise summary that captures the main points and key information. Respond in the **same language** as the input text. Do not translate the summary.  Do not add commentary.
        """
    
    init(
        id: String,
        extraEOSTokens: [String] = [],
        temperature: Float = 0.6,
        maxTokens: Int = 130,
        topP: Float = 0.9,
        repetitionPenalty: Float = 1.1,
        additionalMetadata: [String: String] = [:]
    ) {
        self.id = id
        self.defaultPrompt = defaultSummarizationPrompt
        self.extraEOSTokens = extraEOSTokens
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.topP = topP
        self.repetitionPenalty = repetitionPenalty
        self.additionalMetadata = additionalMetadata
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equatable conformance
    static func == (lhs: ModelConfiguration, rhs: ModelConfiguration) -> Bool {
        lhs.id == rhs.id
    }
    
    // Utility methods
    func createPrompt(for text: String) -> String {
        return "\(defaultPrompt)\n\n\(text)\n\nSummary:"
    }
    
    var isValid: Bool {
        return !id.isEmpty && !defaultPrompt.isEmpty
    }
}
