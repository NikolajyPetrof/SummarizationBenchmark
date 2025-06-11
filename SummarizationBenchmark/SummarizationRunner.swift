//
//  SummarizationRunner.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.06.2025.
//

import Foundation
import ArgumentParser
import MLX
import MLXFast
import MLXTransformers

/// Command-line tool for summarization tasks
@main
struct SummarizationRunner: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "summarize",
        abstract: "Run text summarization with MLX models",
        subcommands: [Summarize.self, ListModels.self, BenchmarkModel.self]
    )
    
    /// Set the model directory when the tool is initialized
    static func main() {
        // Allow custom model directory through environment variable
        if let customModelDirPath = ProcessInfo.processInfo.environment["SUMMARIZATION_MODEL_DIR"] {
            let customModelDir = URL(fileURLWithPath: customModelDirPath)
            ModelRegistry.setCustomModelDirectory(customModelDir)
            print("Using custom model directory: \(customModelDir.path)")
        }
        
        // Run the command
        SummarizationRunner.main()
    }
}

// MARK: - Summarize Command
extension SummarizationRunner {
    /// Command to summarize text
    struct Summarize: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "summarize",
            abstract: "Summarize text using a specified model"
        )
        
        @Option(name: .shortAndLong, help: "Model ID to use for summarization")
        var model: String = "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B"
        
        @Option(name: .shortAndLong, help: "Path to input file (if not using stdin)")
        var inputFile: String?
        
        @Option(name: .shortAndLong, help: "Maximum tokens to generate")
        var maxTokens: Int?
        
        @Option(name: .shortAndLong, help: "Temperature for generation (0.1-1.0)")
        var temperature: Float?
        
        @Flag(name: .shortAndLong, help: "Output detailed performance stats")
        var verbose: Bool = false
        
        func run() throws {
            // Load text
            let inputText: String
            if let path = inputFile {
                let fileURL = URL(fileURLWithPath: path)
                inputText = try String(contentsOf: fileURL, encoding: .utf8)
            } else {
                // Read from stdin
                inputText = readStdin()
            }
            
            guard !inputText.isEmpty else {
                throw ValidationError("No input text provided")
            }
            
            // Load pipeline
            print("🔄 Loading model: \(model)...")
            let pipeline = try SummarizationPipeline(modelId: model)
            
            // Run summarization
            print("⏳ Generating summary...")
            let result = try pipeline.summarize(
                text: inputText,
                maxTokens: maxTokens,
                temperature: temperature
            )
            
            // Output summary
            print("\n📝 Summary:")
            print("\n\(result.summary)\n")
            
            // Print performance stats if verbose
            if verbose {
                print("\n📊 Performance Statistics:")
                print("- Model: \(model)")
                print("- Inference time: \(String(format: "%.2f", result.inferenceTime)) seconds")
                print("- Tokens generated: \(result.tokensGenerated)")
                print("- Tokens per second: \(String(format: "%.1f", result.tokensPerSecond))")
                print("- Memory used: \(String(format: "%.1f", result.memoryUsed)) MB")
                print("- Compression ratio: \(String(format: "%.2f", result.compressionRatio * 100))%")
                print("- Original length: \(result.originalText.count) characters")
                print("- Summary length: \(result.summary.count) characters")
            }
        }
        
        /// Read text from standard input
        private func readStdin() -> String {
            var input = ""
            while let line = readLine() {
                input += line + "\n"
            }
            return input
        }
    }
}

// MARK: - List Models Command
extension SummarizationRunner {
    /// Command to list available models
    struct ListModels: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "list-models",
            abstract: "List available summarization models"
        )
        
        @Flag(name: .shortAndLong, help: "Show only available (downloaded) models")
        var onlyAvailable: Bool = false
        
        @Flag(name: .shortAndLong, help: "Show only 1.5B models")
        var small: Bool = false
        
        @Flag(name: .shortAndLong, help: "Show only 8B models")
        var large: Bool = false
        
        func run() {
            var models = SummarizationModel.availableModels
            
            // Filter by size if requested
            if small {
                models = models.filter { $0.size == .small }
            } else if large {
                models = models.filter { $0.size == .large }
            }
            
            print("🤖 Available Models:")
            print("\n| Model Name | Size | Memory | Status |")
            print("| ---------- | ---- | ------ | ------ |")
            
            for model in models {
                let isAvailable = ModelRegistry.isModelAvailable(model.modelId)
                
                // Skip unavailable models if requested
                if onlyAvailable && !isAvailable {
                    continue
                }
                
                let status = isAvailable ? "✅ Downloaded" : "❌ Not Downloaded"
                print("| \(model.name) | \(model.size.rawValue) | \(model.memoryRequirement) | \(status) |")
            }
        }
    }
}

// MARK: - Benchmark Command
extension SummarizationRunner {
    /// Command to benchmark model performance
    struct BenchmarkModel: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "benchmark",
            abstract: "Benchmark model performance on summarization tasks"
        )
        
        @Option(name: .shortAndLong, help: "Model ID to benchmark")
        var model: String = "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B"
        
        @Option(name: .shortAndLong, help: "Path to JSONL dataset file")
        var dataset: String?
        
        @Option(name: .shortAndLong, help: "Number of dataset entries to process (default: all)")
        var limit: Int?
        
        @Flag(name: .shortAndLong, help: "Output results in JSON format")
        var json: Bool = false
        
        func run() throws {
            // Load model pipeline
            print("🔄 Loading model: \(model)...")
            let pipeline = try SummarizationPipeline(modelId: model)
            
            // Get test samples
            let samples: [DatasetLoader.SummarizationSample]
            if let datasetPath = dataset {
                let datasetURL = URL(fileURLWithPath: datasetPath)
                let loadedDataset = try DatasetLoader.loadDataset(from: datasetURL)
                samples = Array(loadedDataset.samples.prefix(limit ?? loadedDataset.samples.count))
                print("📊 Loaded \(samples.count) samples from dataset: \(loadedDataset.name)")
            } else {
                samples = DatasetLoader.predefinedSamples()
                print("📊 Using \(samples.count) predefined samples")
            }
            
            // Run benchmark
            print("⏳ Running benchmark...")
            var results: [SummarizationResult] = []
            var totalTime: TimeInterval = 0
            var totalTokens: Int = 0
            
            for (i, sample) in samples.enumerated() {
                print("Processing sample \(i+1)/\(samples.count)...")
                
                let result = try pipeline.summarize(text: sample.text)
                results.append(result)
                
                totalTime += result.inferenceTime
                totalTokens += result.tokensGenerated
                
                print("  ✓ Generated summary (\(String(format: "%.2f", result.inferenceTime))s)")
            }
            
            // Calculate aggregate metrics
            let avgTime = totalTime / Double(samples.count)
            let avgTokensPerSecond = Double(totalTokens) / totalTime
            let avgCompressionRatio = results.reduce(0.0) { $0 + $1.compressionRatio } / Double(results.count)
            
            // Output results
            if json {
                // Output as JSON
                let resultData: [String: Any] = [
                    "model": model,
                    "samples_count": samples.count,
                    "total_time": totalTime,
                    "average_time": avgTime,
                    "average_tokens_per_second": avgTokensPerSecond,
                    "average_compression_ratio": avgCompressionRatio,
                    "results": results.map { [
                        "tokens_generated": $0.tokensGenerated,
                        "inference_time": $0.inferenceTime,
                        "tokens_per_second": $0.tokensPerSecond,
                        "compression_ratio": $0.compressionRatio,
                        "memory_used_mb": $0.memoryUsed
                    ] }
                ]
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: resultData, options: .prettyPrinted)
                    if let jsonString = String(data: jsonData, encoding: .utf8) {
                        print(jsonString)
                    }
                } catch {
                    print("Error creating JSON: \(error)")
                }
            } else {
                // Output as text
                print("\n📊 Benchmark Results:")
                print("- Model: \(model)")
                print("- Samples processed: \(samples.count)")
                print("- Total time: \(String(format: "%.2f", totalTime)) seconds")
                print("- Average time per sample: \(String(format: "%.2f", avgTime)) seconds")
                print("- Average tokens per second: \(String(format: "%.1f", avgTokensPerSecond))")
                print("- Average compression ratio: \(String(format: "%.2f", avgCompressionRatio * 100))%")
            }
        }
    }
}
