import Foundation
import Combine

/// Service for managing Python dependencies
public class PythonDependencyManager {
    /// Checks for required dependencies
    /// - Returns: Check result and error message (if any)
    static func checkDependencies() async -> (success: Bool, message: String) {
        // Проверяем наличие Python
        guard let pythonPath = PythonEnvHelper.findPythonPath() else {
            return (false, "Python не найден. Установите Python 3.x")
        }
        
        // Запускаем Python для проверки версии
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.arguments = ["--version"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                return (false, "Failed to get Python version")
            }
            
            if !output.contains("Python 3") {
                return (false, "Python 3.x is required. Installed version: \(output)")
            }
        } catch {
            return (false, "Error running Python: \(error.localizedDescription)")
        }
        
        // Проверяем наличие PyTorch
        let torchResult = await checkPackage(name: "torch")
        if !torchResult.success {
            return (false, "PyTorch library is not installed. Please install dependencies from the app menu.")
        }
        
        // Проверяем наличие Transformers
        let transformersResult = await checkPackage(name: "transformers")
        if !transformersResult.success {
            return (false, "Transformers library is not installed. Please install dependencies from the app menu.")
        }
        
        return (true, "All dependencies are installed")
    }
    
    /// Installs required dependencies
    /// - Parameters:
    ///   - progressHandler: Installation progress handler (0.0-1.0)
    ///   - statusHandler: Status message handler
    /// - Returns: Installation result and error message (if any)
    static func installDependencies(
        progressHandler: @escaping (Double) -> Void = { _ in },
        statusHandler: @escaping (String) -> Void = { _ in }
    ) async -> (success: Bool, message: String) {
        // Проверяем наличие Python
        statusHandler("Checking Python installation...")
        progressHandler(0.1)
        guard let _ = PythonEnvHelper.findPythonPath() else {
            return (false, "Python не найден. Установите Python 3.x")
        }
        
        // Проверяем наличие pip
        statusHandler("Checking pip installation...")
        progressHandler(0.2)
        guard let pipPath = PythonEnvHelper.findPipPath() else {
            return (false, "pip not found. Please install pip for Python 3.x")
        }
        
        // Устанавливаем PyTorch
        statusHandler("Installing PyTorch...")
        progressHandler(0.3)
        let torchResult = await installPackage(pipPath: pipPath, packageName: "torch")
        if !torchResult.success {
            return (false, "Error installing PyTorch: \(torchResult.message)")
        }
        
        // Устанавливаем Transformers
        statusHandler("Installing Transformers...")
        progressHandler(0.6)
        let transformersResult = await installPackage(pipPath: pipPath, packageName: "transformers")
        if !transformersResult.success {
            return (false, "Error installing Transformers: \(transformersResult.message)")
        }
        
        // Завершение
        statusHandler("Dependency installation completed")
        progressHandler(1.0)
        
        return (true, "All dependencies installed successfully")
    }
    
    /// Checks if a Python package is installed
    /// - Parameter name: Package name
    /// - Returns: Check result and command output
    private static func checkPackage(name: String) async -> (success: Bool, message: String) {
        guard let pipPath = PythonEnvHelper.findPipPath() else {
            return (false, "pip not found")
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pipPath)
        process.arguments = ["show", name]
        
        // Добавляем пути к окружению
        var env = ProcessInfo.processInfo.environment
        let additionalPaths = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        if let path = env["PATH"] {
            env["PATH"] = "\(path):\(additionalPaths)"
        } else {
            env["PATH"] = additionalPaths
        }
        process.environment = env
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            return (process.terminationStatus == 0, output)
        } catch {
            return (false, error.localizedDescription)
        }
    }
    
    /// Installs a Python package
    /// - Parameters:
    ///   - pipPath: Path to pip
    ///   - packageName: Package name
    /// - Returns: Installation result and command output
    private static func installPackage(pipPath: String, packageName: String) async -> (success: Bool, message: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pipPath)
        process.arguments = ["install", "--user", packageName]
        
        // Добавляем пути к окружению
        var env = ProcessInfo.processInfo.environment
        let additionalPaths = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        if let path = env["PATH"] {
            env["PATH"] = "\(path):\(additionalPaths)"
        } else {
            env["PATH"] = additionalPaths
        }
        process.environment = env
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            return (process.terminationStatus == 0, output)
        } catch {
            return (false, error.localizedDescription)
        }
    }
}
