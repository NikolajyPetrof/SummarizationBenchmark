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
    let additionalMetadata: [String: String]
    
    init(
        id: String,
        defaultPrompt: String,
        extraEOSTokens: [String] = [],
        temperature: Float = 0.7,
        maxTokens: Int = 200,
        additionalMetadata: [String: String] = [:]
    ) {
        self.id = id
        self.defaultPrompt = defaultPrompt
        self.extraEOSTokens = extraEOSTokens
        self.temperature = temperature
        self.maxTokens = maxTokens
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

// MARK: - Generation Parameters
struct GenerationParameters {
    let temperature: Float
    let topP: Float
    let repetitionPenalty: Float
    let maxTokens: Int
    
    init(
        temperature: Float = 0.7,
        topP: Float = 0.9,
        repetitionPenalty: Float = 1.1,
        maxTokens: Int = 200
    ) {
        self.temperature = temperature
        self.topP = topP
        self.repetitionPenalty = repetitionPenalty
        self.maxTokens = maxTokens
    }
    
    // Preset configurations
    static let conservative = GenerationParameters(
        temperature: 0.3,
        topP: 0.8,
        repetitionPenalty: 1.2,
        maxTokens: 150
    )
    
    static let balanced = GenerationParameters(
        temperature: 0.7,
        topP: 0.9,
        repetitionPenalty: 1.1,
        maxTokens: 200
    )
    
    static let creative = GenerationParameters(
        temperature: 0.9,
        topP: 0.95,
        repetitionPenalty: 1.05,
        maxTokens: 250
    )
}
