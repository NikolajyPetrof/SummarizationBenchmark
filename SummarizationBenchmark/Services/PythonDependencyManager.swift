import Foundation
import Combine

/// Service for managing Python dependencies
public class PythonDependencyManager {
    
    /// Checks if the device is Apple Silicon (ARM)
    static func isAppleSilicon() -> Bool {
        #if arch(arm64)
            return true
        #else
            return false
        #endif
    }
    
    /// Checks for required dependencies
    static func checkDependencies() async -> (success: Bool, message: String) {
        // Check if Python is installed
        guard let pythonPath = PythonEnvHelper.findPythonPath() else {
            return (false, "Python не найден. Установите Python 3.x")
        }
        
        // Run Python to check version
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
        
        // Check for required dependencies
        let torchResult = await checkPackage(name: "torch")
        if !torchResult.success {
            return (false, "PyTorch library is not installed. Please install dependencies from the app menu.")
        }
        
        let transformersResult = await checkPackage(name: "transformers")
        if !transformersResult.success {
            return (false, "Transformers library is not installed. Please install dependencies from the app menu.")
        }
        
        let packagingResult = await checkPackage(name: "packaging")
        if !packagingResult.success {
            return (false, "Packaging library is not installed. Please install dependencies from the app menu.")
        }
        
        // Check MLX on Apple Silicon
        if isAppleSilicon() {
            let mlxResult = await checkPackage(name: "mlx-lm")
            if !mlxResult.success {
                return (false, "MLX-LM not found. Apple Silicon optimization requires MLX. Install dependencies to get MLX support.")
            }
        }
        
        return (true, "All dependencies are installed")
    }
    
    /// Installs required dependencies
    static func installDependencies(
        progressHandler: @escaping (Double) -> Void = { _ in },
        statusHandler: @escaping (String) -> Void = { _ in }
    ) async -> (success: Bool, message: String) {
        
        statusHandler("Checking Python installation...")
        progressHandler(0.1)
        guard let _ = PythonEnvHelper.findPythonPath() else {
            return (false, "Python не найден. Установите Python 3.x")
        }
        
        statusHandler("Checking pip installation...")
        progressHandler(0.15)
        guard let pipPath = PythonEnvHelper.findPipPath() else {
            return (false, "pip not found. Please install pip for Python 3.x")
        }
        
        // Install base dependencies
        statusHandler("Installing packaging...")
        progressHandler(0.2)
        let packagingResult = await installPackage(pipPath: pipPath, packageName: "packaging")
        if !packagingResult.success {
            return (false, "Error installing packaging: \(packagingResult.message)")
        }
        
        statusHandler("Installing PyTorch...")
        progressHandler(0.3)
        let torchResult = await installPackage(pipPath: pipPath, packageName: "torch")
        if !torchResult.success {
            return (false, "Error installing PyTorch: \(torchResult.message)")
        }
        
        // Install latest transformers version from GitHub
        statusHandler("Installing latest Transformers (supports SmolLM3 & Gemma-3)...")
        progressHandler(0.5)
        
        let transformersGitResult = await installPackage(
            pipPath: pipPath,
            packageName: "git+https://github.com/huggingface/transformers.git"
        )
        
        if !transformersGitResult.success {
            statusHandler("Installing Transformers v4.53.0+ from PyPI...")
            let transformersResult = await installPackage(pipPath: pipPath, packageName: "transformers>=4.53.0")
            if !transformersResult.success {
                return (false, "Error installing Transformers: \(transformersResult.message)")
            }
        }
        
        // Install MLX for Apple Silicon
        if isAppleSilicon() {
            statusHandler("Installing MLX for Apple Silicon optimization...")
            progressHandler(0.7)
            
            let mlxResult = await installPackage(pipPath: pipPath, packageName: "mlx")
            if mlxResult.success {
                let mlxLmResult = await installPackage(pipPath: pipPath, packageName: "mlx-lm")
                if !mlxLmResult.success {
                    return (false, "Error installing MLX-LM: \(mlxLmResult.message)")
                }
                statusHandler("MLX installed successfully for Apple Silicon")
            } else {
                return (false, "Error installing MLX: \(mlxResult.message)")
            }
        } else {
            statusHandler("Skipping MLX installation (not on Apple Silicon)")
        }
        
        statusHandler("Dependency installation completed successfully")
        progressHandler(1.0)
        
        return (true, "All dependencies installed successfully")
    }
    
    private static func checkPackage(name: String) async -> (success: Bool, message: String) {
        guard let pipPath = PythonEnvHelper.findPipPath() else {
            return (false, "pip not found")
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pipPath)
        process.arguments = ["show", name]
        
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
    
    private static func installPackage(pipPath: String, packageName: String) async -> (success: Bool, message: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pipPath)
        process.arguments = ["install", "--user", "--upgrade", packageName]
        
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
