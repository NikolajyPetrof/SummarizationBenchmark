import Foundation
import Combine

/// Service for interacting with Python models via CLI
class PythonModelService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Execution status
    @Published var isProcessing: Bool = false
    
    /// Status message
    @Published var statusMessage: String = ""
    
    /// Error message
    @Published var errorMessage: String = ""
    
    /// Full error text
    @Published var fullErrorText: String = ""
    
    /// Execution progress (0.0 - 1.0)
    @Published var progress: Double = 0.0
    
    // MARK: - Private Properties
    
    /// Path to Python scripts directory
    private var pythonScriptsPath: String {
        let fileManager = FileManager.default
        let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appBundleID = Bundle.main.bundleIdentifier ?? "com.app.SummarizationBenchmark"
        let pythonScriptsDir = appSupportDir.appendingPathComponent(appBundleID).appendingPathComponent("PythonScripts")
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: pythonScriptsDir.path) {
            try? fileManager.createDirectory(at: pythonScriptsDir, withIntermediateDirectories: true)
        }
        
        return pythonScriptsDir.path
    }
    
    /// Path to summarization script
    private var summarizePyPath: String {
        let path = pythonScriptsPath + "/summarize.py"
        // If script doesn't exist, write it from helper
        if !FileManager.default.fileExists(atPath: path) {
            do {
                try summarizePyScriptContents().write(toFile: path, atomically: true, encoding: .utf8)
                // Set execution permissions
                try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: path)
            } catch {
                print("Error writing summarize.py: \(error)")
            }
        }
        return path
    }
    
    // MARK: - Public Methods
    
    /// Summarizes text using a Python model
    /// - Parameters:
    ///   - text: Text to summarize
    ///   - modelPath: Path to model or Hugging Face identifier
    ///   - maxTokens: Maximum number of tokens to generate
    ///   - temperature: Generation temperature (0.0-1.0)
    ///   - topP: Top-p for generation (0.0-1.0)
    ///   - useMLX: Use MLX framework for Apple Silicon
    ///   - verbose: Enable verbose logging
    /// - Returns: Summarized text
    func summarizeText(
        _ text: String,
        modelPath: String = "facebook/bart-large-cnn",
        maxTokens: Int = 256,
        temperature: Double = 0.3,
        topP: Double = 0.8,
        useMLX: Bool = true,
        timeout: Int = 300,
        verbose: Bool = true
    ) async throws -> String {
        // Update UI status
        await MainActor.run {
            self.isProcessing = true
            self.statusMessage = "Preparing for summarization..."
            self.progress = 0.1
            self.errorMessage = ""
            self.fullErrorText = ""
        }
        
        // Create temporary file for text
        let tempFilePath: String
        do {
            tempFilePath = try FileHelper.createTempFile(withText: text, prefix: "text_to_summarize")
        } catch {
            await MainActor.run { self.isProcessing = false }
            throw PythonModelError.failedToWriteTemporaryFile(error)
        }
        defer { FileHelper.removeFile(atPath: tempFilePath) }
        
        // Check if device is Apple Silicon
        let isAppleSilicon = PythonDependencyManager.isAppleSilicon()
        
        // Build arguments for the script
        var arguments = [
            tempFilePath,
            modelPath,
            String(maxTokens),
            String(temperature),
            String(topP)
        ]
        
        // Add MLX flag for Apple Silicon if enabled
        if isAppleSilicon && useMLX {
            arguments.append("--use-mlx")
            await MainActor.run {
                self.statusMessage = "Preparing for summarization with MLX optimization..."
            }
        }
        
        // Add timeout parameter for generation
        arguments.append("--timeout")
        arguments.append(String(timeout))
        
        // Add verbose flag for detailed logging
        if verbose {
            arguments.append("--verbose")
        }
        
        do {
            // Execute script using PythonExecutionService
            let result = try await PythonExecutionService.executeScript(
                at: summarizePyPath,
                arguments: arguments,
                progressHandler: { progress in
                    Task { @MainActor in
                        self.progress = max(0.1, min(0.9, progress))
                    }
                },
                statusHandler: { status in
                    Task { @MainActor in
                        self.statusMessage = status
                    }
                }
            )
            
            // Update UI on completion
            await MainActor.run {
                self.isProcessing = false
                self.statusMessage = "Summarization completed successfully"
                self.progress = 1.0
            }
            
            return result
            
        } catch let error as PythonModelError {
            await MainActor.run {
                self.isProcessing = false
                self.progress = 0.0
                self.errorMessage = self.friendlyErrorMessage(for: error, modelPath: modelPath)
                
                // Store full error details
                if case .scriptExecutionFailed(let code, let output) = error {
                    self.fullErrorText = """
                    Error Code: \(code)
                    
                    Model: \(modelPath)
                    Use MLX: \(useMLX && isAppleSilicon)
                    Apple Silicon: \(isAppleSilicon)
                    Timeout: \(timeout) seconds
                    
                    Full Error Output:
                    \(output)
                    """
                } else {
                    self.fullErrorText = error.localizedDescription
                }
            }
            throw error
            
        } catch {
            await MainActor.run {
                self.isProcessing = false
                self.progress = 0.0
                self.errorMessage = "Unexpected error: \(error.localizedDescription)"
                self.fullErrorText = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Checks for required dependencies
    func checkDependencies() async -> (success: Bool, message: String) {
        let result = await PythonDependencyManager.checkDependencies()
        
        await MainActor.run {
            self.statusMessage = result.success ? "All dependencies are installed" : "Error: " + result.message
        }
        
        return result
    }
    
    /// Installs required dependencies
    func installDependencies() async -> (success: Bool, message: String) {
        await MainActor.run {
            self.isProcessing = true
            self.statusMessage = "Checking and installing dependencies..."
            self.progress = 0.1
            self.errorMessage = ""
        }
        
        let result = await PythonDependencyManager.installDependencies(
            progressHandler: { progress in
                Task { @MainActor in
                    self.progress = progress
                }
            },
            statusHandler: { status in
                Task { @MainActor in
                    self.statusMessage = status
                }
            }
        )
        
        await MainActor.run {
            self.isProcessing = false
            self.statusMessage = result.success ? "Dependencies installed successfully" : "Error: " + result.message
            self.progress = result.success ? 1.0 : 0.0
            if !result.success {
                self.errorMessage = result.message
            }
        }
        
        return result
    }
    
    // MARK: - Private Methods
    
    /// Creates a user-friendly error message based on the error type and context
    private func friendlyErrorMessage(for error: PythonModelError, modelPath: String) -> String {
        switch error {
        case .scriptNotFound:
            return "Python script not found. Please reinstall the application."
            
        case .failedToWriteTemporaryFile:
            return "Failed to create temporary file. Check disk space and permissions."
            
        case .scriptExecutionFailed(let code, let output):
            let errorText = output.lowercased()
            
            // Check for specific error types
            if errorText.contains("does not recognize this architecture") || errorText.contains("keyerror") {
                if modelPath.contains("mlx-community") {
                    return "MLX-community models require MLX framework on Apple Silicon. Install dependencies or select a standard model."
                } else {
                    return "Model architecture not supported. Update dependencies or try a different model."
                }
            }
            
            if errorText.contains("mlx") && errorText.contains("not found") {
                return "MLX framework not found. Install dependencies to use MLX-optimized models."
            }
            
            if errorText.contains("no module named") {
                let missingModule = extractMissingModule(from: output)
                return "Missing Python library: \(missingModule). Install dependencies from the app menu."
            }
            
            if errorText.contains("connection") || errorText.contains("network") {
                return "Network error downloading model. Check internet connection and try again."
            }
            
            if errorText.contains("memory") || errorText.contains("oom") {
                return "Insufficient memory to load model. Try a smaller model or restart the app."
            }
            
            if code == 1 {
                return "Model failed to load or generate summary. Try a different model or check dependencies."
            }
            
            return "Python script failed (exit code \(code)). Check full error details for more information."
            
        case .invalidOutput:
            return "Invalid output from Python script. The model may have failed to generate a summary."
        }
    }
    
    /// Extracts the name of a missing Python module from error output
    private func extractMissingModule(from output: String) -> String {
        // Look for patterns like "No module named 'modulename'"
        let patterns = [
            #"No module named '([^']+)'"#,
            #"ModuleNotFoundError: No module named '([^']+)'"#,
            #"ImportError: No module named ([^\s]+)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: output, options: [], range: NSRange(output.startIndex..., in: output)),
               let range = Range(match.range(at: 1), in: output) {
                return String(output[range])
            }
        }
        
        return "unknown"
    }
}
