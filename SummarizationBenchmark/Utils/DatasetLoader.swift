//
//  DatasetLoader.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.06.2025.
//

import Foundation

/// Manages loading summarization datasets from JSONL files
public class DatasetLoader {
    /// A sample from a summarization dataset
    public struct SummarizationSample: Codable, Identifiable {
        public let id: String
        public let text: String
        public let summary: String
        public let metadata: [String: String]?
        
        // Computed properties for statistics
        public var textLength: Int { text.count }
        public var summaryLength: Int { summary.count }
        public var compressionRatio: Double {
            guard textLength > 0 else { return 0 }
            return Double(summaryLength) / Double(textLength)
        }
        
        // Custom init to create samples programmatically
        public init(id: String, text: String, summary: String, metadata: [String: String]? = nil) {
            self.id = id
            self.text = text
            self.summary = summary
            self.metadata = metadata
        }
    }
    
    /// A collection of summarization samples
    public struct SummarizationDataset {
        public let name: String
        public let samples: [SummarizationSample]
        public let metadata: [String: String]?
        
        public var count: Int { samples.count }
        
        public var averageTextLength: Double {
            guard !samples.isEmpty else { return 0 }
            let totalLength = samples.reduce(0) { $0 + $1.textLength }
            return Double(totalLength) / Double(samples.count)
        }
        
        public var averageSummaryLength: Double {
            guard !samples.isEmpty else { return 0 }
            let totalLength = samples.reduce(0) { $0 + $1.summaryLength }
            return Double(totalLength) / Double(samples.count)
        }
        
        public var averageCompressionRatio: Double {
            guard !samples.isEmpty else { return 0 }
            let totalRatio = samples.reduce(0.0) { $0 + $1.compressionRatio }
            return totalRatio / Double(samples.count)
        }
    }
    
    /// Loads a dataset from a JSONL file
    /// - Parameters:
    ///   - url: URL of the JSONL file
    ///   - name: Name for the dataset (defaults to filename)
    /// - Returns: A SummarizationDataset containing all samples
    public static func loadDataset(from url: URL, name: String? = nil) throws -> SummarizationDataset {
        let datasetName = name ?? url.deletingPathExtension().lastPathComponent
        
        let fileContents = try String(contentsOf: url, encoding: .utf8)
        let lines = fileContents.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        var samples: [SummarizationSample] = []
        for line in lines {
            guard let jsonData = line.data(using: .utf8) else {
                print("Warning: Could not parse line as data: \(line.prefix(50))...")
                continue
            }
            
            do {
                let sample = try JSONDecoder().decode(SummarizationSample.self, from: jsonData)
                samples.append(sample)
            } catch {
                print("Error decoding sample: \(error.localizedDescription)")
            }
        }
        
        return SummarizationDataset(
            name: datasetName,
            samples: samples,
            metadata: nil
        )
    }
    
    /// Returns a set of predefined sample texts for testing
    public static func predefinedSamples() -> [SummarizationSample] {
        return [
            SummarizationSample(
                id: "sample1",
                text: """
                Artificial intelligence (AI) has evolved significantly over the past decade. Machine learning models, particularly deep neural networks, have revolutionized fields like computer vision, natural language processing, and reinforcement learning. Companies worldwide are integrating AI into their products and services, from recommendation systems to autonomous vehicles. However, concerns about ethics, privacy, and bias in AI systems continue to be important topics of discussion. Researchers are working on making AI models more interpretable and transparent to address these issues. As computational resources become more accessible, we can expect AI to become even more prevalent in our daily lives.
                """,
                summary: "AI has advanced greatly in the last decade with deep learning revolutionizing multiple fields. While companies are implementing AI widely, concerns about ethics and bias remain. Researchers are working on interpretability as AI becomes more prevalent.",
                metadata: ["category": "technology", "difficulty": "medium"]
            ),
            
            SummarizationSample(
                id: "sample2", 
                text: """
                Climate change presents one of the most significant challenges of our time. Rising global temperatures have led to more frequent extreme weather events, including hurricanes, floods, and wildfires. Sea levels are rising due to melting ice caps, threatening coastal communities worldwide. The scientific consensus points to human activities, particularly the burning of fossil fuels and deforestation, as primary contributors to this crisis. International agreements like the Paris Climate Accord aim to limit global warming, but implementation remains challenging. Renewable energy sources such as solar and wind power offer promising alternatives to fossil fuels, but transitioning global infrastructure requires significant investment and political will. Individual actions, while important, must be complemented by systemic changes to effectively address the scale of the problem.
                """, 
                summary: "Climate change is a major challenge causing extreme weather and rising sea levels. Human activities like burning fossil fuels are the main cause. While international agreements exist, implementation is difficult. Both renewable energy adoption and systemic changes are needed alongside individual actions.",
                metadata: ["category": "environment", "difficulty": "hard"]
            ),
            
            SummarizationSample(
                id: "sample3",
                text: """
                The Mediterranean diet is renowned for its health benefits and culinary richness. Originating from countries bordering the Mediterranean Sea, this dietary pattern emphasizes plant-based foods, olive oil, and moderate consumption of fish and poultry. Studies have linked it to reduced risks of heart disease, certain cancers, and cognitive decline. The diet typically includes abundant fruits, vegetables, whole grains, legumes, and nuts. Red meat is limited, while herbs and spices are used generously to enhance flavor without adding sodium. Wine, particularly red wine, is consumed in moderation, usually with meals. Beyond nutrition, the Mediterranean diet represents a lifestyle that values communal eating and physical activity, contributing to its overall health benefits.
                """,
                summary: "The Mediterranean diet, from countries around the Mediterranean Sea, focuses on plant-based foods, olive oil, and moderate fish and poultry consumption. It's linked to reduced heart disease, cancer, and cognitive decline risks. It emphasizes fruits, vegetables, whole grains, and limited red meat, plus moderate wine consumption and a lifestyle of communal eating and physical activity.",
                metadata: ["category": "health", "difficulty": "easy"]
            )
        ]
    }
}
