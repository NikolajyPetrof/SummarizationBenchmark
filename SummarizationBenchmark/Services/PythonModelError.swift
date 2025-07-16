import Foundation

/// Errors when working with Python models
public enum PythonModelError: Error, LocalizedError {
    case scriptNotFound(String)
    case failedToWriteTemporaryFile(Error)
    case scriptExecutionFailed(Int, String)
    case invalidOutput

    public var errorDescription: String? {
        switch self {
        case .scriptNotFound(let path):
            return "Python script not found at path: \(path)"
        case .failedToWriteTemporaryFile(let error):
            return "Failed to create temporary file: \(error.localizedDescription)"
        case .scriptExecutionFailed(let code, let message):
            return "Python script execution failed (code \(code)): \(message)"
        case .invalidOutput:
            return "Failed to read Python script execution result"
        }
    }
}
