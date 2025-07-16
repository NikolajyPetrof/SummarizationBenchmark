import Foundation
import Combine

/// Service for interacting with Python models via CLI
/// Uses helpers for dependency management and script execution
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
    

    
    /// Путь к скрипту суммаризации
    private var summarizePyPath: String {
        let path = pythonScriptsPath + "/summarize.py"
        // Если скрипта нет — записываем его из хэлпера
        if !FileManager.default.fileExists(atPath: path) {
            do {
                // Используем функцию summarizePyScriptContents для получения содержимого скрипта
                try summarizePyScriptContents().write(toFile: path, atomically: true, encoding: .utf8)
                // Устанавливаем права на выполнение
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
    /// - Returns: Summarized text
    func summarizeText(
        _ text: String,
        modelPath: String = "facebook/bart-large-cnn",
        maxTokens: Int = 256,
        temperature: Double = 0.3,
        topP: Double = 0.8
    ) async throws -> String {
        // Обновляем UI статус
        await MainActor.run {
            self.isProcessing = true
            self.statusMessage = "Preparing for summarization..."
            self.progress = 0.1
            self.errorMessage = ""
        }
        
        // Создаем временный файл для текста через хэлпер
        let tempFilePath: String
        do {
            tempFilePath = try FileHelper.createTempFile(withText: text, prefix: "text_to_summarize")
        } catch {
            await MainActor.run { self.isProcessing = false }
            throw PythonModelError.failedToWriteTemporaryFile(error)
        }
        defer { FileHelper.removeFile(atPath: tempFilePath) } // Автоматическая очистка
        
        // Аргументы для скрипта
        let arguments = [
            tempFilePath,
            modelPath,
            String(maxTokens),
            String(temperature),
            String(topP)
        ]
        
        do {
            // Используем PythonExecutionService для выполнения скрипта
            let result = try await PythonExecutionService.executeScript(
                at: summarizePyPath,
                arguments: arguments,
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
            
            // Обновляем UI по завершении
            await MainActor.run {
                self.isProcessing = false
                self.statusMessage = "Суммаризация завершена"
                self.progress = 1.0
            }
            
            return result
        } catch let error as PythonModelError {
            await MainActor.run {
                self.isProcessing = false
                self.errorMessage = error.localizedDescription
                self.fullErrorText = error.localizedDescription
                
                // Если есть дополнительная информация об ошибке, добавляем её
                if case .scriptExecutionFailed(_, let output) = error {
                    self.fullErrorText = "\(error.localizedDescription)\n\nДетали ошибки:\n\(output)"
                }
            }
            throw error
        } catch {
            await MainActor.run {
                self.isProcessing = false
                self.errorMessage = error.localizedDescription
                self.fullErrorText = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Проверяет наличие необходимых зависимостей
    /// - Returns: Результат проверки и сообщение об ошибке (если есть)
    func checkDependencies() async -> (success: Bool, message: String) {
        // Используем PythonDependencyManager для проверки зависимостей
        let result = await PythonDependencyManager.checkDependencies()
        
        // Обновляем статус в UI
        await MainActor.run {
            self.statusMessage = result.success ? "Все зависимости установлены" : "Ошибка: " + result.message
        }
        
        return result
    }
    
    /// Устанавливает необходимые зависимости
    /// - Returns: Результат установки и сообщение об ошибке (если есть)
    func installDependencies() async -> (success: Bool, message: String) {
        // Обновляем UI статус
        await MainActor.run {
            self.isProcessing = true
            self.statusMessage = "Checking and installing dependencies..."
            self.progress = 0.1
            self.errorMessage = ""
        }
        
        // Используем PythonDependencyManager для установки зависимостей
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
        
        // Обновляем UI по завершении
        await MainActor.run {
            self.isProcessing = false
            self.statusMessage = result.success ? "Зависимости успешно установлены" : "Ошибка: " + result.message
            self.progress = result.success ? 1.0 : 0.0
            if !result.success {
                self.errorMessage = result.message
            }
        }
        
        return result
    }
    
}
