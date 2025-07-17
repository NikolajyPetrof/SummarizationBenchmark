import Foundation

/// Service for executing Python scripts
public class PythonExecutionService {
    
    /// Executes a Python script with the specified arguments
    /// - Parameters:
    ///   - scriptPath: Path to the script
    ///   - arguments: Arguments for the script
    ///   - progressHandler: Progress handler (0.0-1.0)
    ///   - statusHandler: Status message handler
    /// - Returns: Script execution result (success and output)
    static func executeScript(
        at scriptPath: String,
        arguments: [String],
        progressHandler: ((Double) -> Void)? = nil,
        statusHandler: ((String) -> Void)? = nil
    ) async throws -> String {
        // Check if script exists
        guard FileManager.default.fileExists(atPath: scriptPath) else {
            throw PythonModelError.scriptNotFound(scriptPath)
        }
        
        // Find python using helper
        guard let pythonPath = PythonEnvHelper.findPythonPath() else {
            throw PythonModelError.scriptExecutionFailed(1, "Python not found in any of the standard paths")
        }
        
        // Set initial status
        progressHandler?(0.1)
        statusHandler?("Starting Python script...")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pythonPath)
        
        // Arguments for running Python script
        var processArguments = [scriptPath]
        processArguments.append(contentsOf: arguments)
        process.arguments = processArguments
        
        // Configure environment
        var env = ProcessInfo.processInfo.environment
        let additionalPaths = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        if let path = env["PATH"] {
            env["PATH"] = "\(path):\(additionalPaths)"
        } else {
            env["PATH"] = additionalPaths
        }
        process.environment = env
        
        // Set up output pipes
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Start process
        do {
            try process.run()
            
            // Обновляем статус
            progressHandler?(0.3)
            statusHandler?("Script is running...")
            
            // Wait for process to complete
            process.waitUntilExit()
            
            // Check return code
            if process.terminationStatus != 0 {
                // Get error output
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                
                // Get standard output (may contain additional information)
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let outputMessage = String(data: outputData, encoding: .utf8) ?? ""
                
                // Create full error report
                var fullErrorReport = "Error code: \(process.terminationStatus)\n"
                
                if !errorMessage.isEmpty {
                    fullErrorReport += "\nError message:\n\(errorMessage)"
                }
                
                if !outputMessage.isEmpty {
                    fullErrorReport += "\n\nStandard output:\n\(outputMessage)"
                }
                
                // Add command information
                fullErrorReport += "\n\nExecuted command:\n\(pythonPath) \(processArguments.joined(separator: " "))"
                
                throw PythonModelError.scriptExecutionFailed(Int(process.terminationStatus), fullErrorReport)
            }
            
            // Read output
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: outputData, encoding: .utf8) else {
                throw PythonModelError.invalidOutput
            }
            
            // Обновляем статус
            progressHandler?(1.0)
            statusHandler?("Script completed successfully")
            
            return output.trimmingCharacters(in: .whitespacesAndNewlines)
            
        } catch let error as PythonModelError {
            throw error
        } catch {
            throw PythonModelError.scriptExecutionFailed(0, error.localizedDescription)
        }
    }
    
    /// Executes a command and returns the result
    /// - Parameters:
    ///   - command: Command to execute
    ///   - arguments: Command arguments
    /// - Returns: Command execution result (success and output)
    static func runCommand(command: String, arguments: [String]) async -> (success: Bool, output: String) {
        // For Python and pip, check multiple paths
        if command == "python3" || command == "pip3" {
            let possiblePaths = command == "python3" ? 
                PythonEnvHelper.pythonCandidates : 
                PythonEnvHelper.pipCandidates
            
            // Check each path
            for path in possiblePaths {
                if FileManager.default.fileExists(atPath: path) {
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: path)
                    process.arguments = arguments
                    
                    let pipe = Pipe()
                    process.standardOutput = pipe
                    process.standardError = pipe
                    
                    do {
                        try process.run()
                        process.waitUntilExit()
                        
                        let data = pipe.fileHandleForReading.readDataToEndOfFile()
                        let output = String(data: data, encoding: .utf8) ?? ""
                        
                        if process.terminationStatus == 0 {
                            print("Command \(command) executed at path: \(path)")
                            return (true, output)
                        }
                    } catch {
                        print("Error running \(command) at path \(path): \(error.localizedDescription)")
                    }
                }
            }
        }
        
        // Standard method for other commands via env
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments
        
        // Add paths to environment
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
