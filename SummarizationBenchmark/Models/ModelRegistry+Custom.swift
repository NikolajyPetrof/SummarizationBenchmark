//
//  ModelRegistry+Custom.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.06.2025.
//

import Foundation
import MLXTransformers

/// A registry of available models with their local paths
public struct ModelRegistry {
    /// Information about a loaded model
    public struct ModelInfo {
        let modelPath: URL
        let tokenizerPath: URL
    }
    
    /// Default directory where models are stored
    private static let defaultModelsDirectory: URL = {
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupportDir.appendingPathComponent("SummarizationModels", isDirectory: true)
    }()
    
    /// Custom models directory (can be set by the user)
    private static var customModelsDirectory: URL?
    
    /// Set a custom directory for model storage
    /// - Parameter directoryPath: Path to the models directory
    public static func setCustomModelDirectory(_ directoryPath: URL) {
        customModelsDirectory = directoryPath
        
        // Ensure the directory exists
        try? FileManager.default.createDirectory(at: directoryPath, withIntermediateDirectories: true)
    }
    
    /// Current active models directory
    public static var modelsDirectory: URL {
        return customModelsDirectory ?? defaultModelsDirectory
    }
    
    /// Get paths for a model by ID
    /// - Parameter modelId: The model ID (e.g., "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B")
    /// - Returns: ModelInfo containing paths to the model and tokenizer
    public static func getModelInfo(for modelId: String) throws -> ModelInfo {
        let modelName = modelId.components(separatedBy: "/").last!
        let modelDir = modelsDirectory.appendingPathComponent(modelName, isDirectory: true)
        
        // Check if the model directory exists
        if !FileManager.default.fileExists(atPath: modelDir.path) {
            throw ModelRegistryError.modelNotFound(modelId)
        }
        
        // Expected file paths
        let modelPath = modelDir.appendingPathComponent("model.mlxmodel")
        let tokenizerPath = modelDir.appendingPathComponent("tokenizer.json")
        
        // Verify files exist
        if !FileManager.default.fileExists(atPath: modelPath.path) {
            throw ModelRegistryError.modelFileMissing(modelPath.path)
        }
        
        if !FileManager.default.fileExists(atPath: tokenizerPath.path) {
            throw ModelRegistryError.tokenizerFileMissing(tokenizerPath.path)
        }
        
        return ModelInfo(
            modelPath: modelPath,
            tokenizerPath: tokenizerPath
        )
    }
    
    /// Check if a model is downloaded and available
    /// - Parameter modelId: The model ID to check
    /// - Returns: True if the model is available
    public static func isModelAvailable(_ modelId: String) -> Bool {
        do {
            _ = try getModelInfo(for: modelId)
            return true
        } catch {
            return false
        }
    }
    
    /// Get the download URL for a model by ID
    /// - Parameter modelId: The model ID
    /// - Returns: URL to download the model files
    public static func getDownloadURL(for modelId: String) -> URL {
        // This is an example URL. In a real app, this would point to a repository
        // that hosts the model files or use the Hugging Face API
        let baseURL = URL(string: "https://huggingface.co")!
        return baseURL.appendingPathComponent(modelId)
    }
}

/// Errors that can occur when working with the model registry
public enum ModelRegistryError: Error, LocalizedError {
    case modelNotFound(String)
    case modelFileMissing(String)
    case tokenizerFileMissing(String)
    case downloadFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .modelNotFound(let modelId):
            return "Model not found: \(modelId)"
        case .modelFileMissing(let path):
            return "Model file missing at path: \(path)"
        case .tokenizerFileMissing(let path):
            return "Tokenizer file missing at path: \(path)"
        case .downloadFailed(let reason):
            return "Model download failed: \(reason)"
        }
    }
}
