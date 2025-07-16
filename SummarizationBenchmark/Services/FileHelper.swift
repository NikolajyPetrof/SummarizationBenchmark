import Foundation

/// Helper for working with temporary files
struct FileHelper {
    /// Creates a temporary file with the specified text and returns its path
    static func createTempFile(withText text: String, prefix: String = "tmp") throws -> String {
        let tempDir = NSTemporaryDirectory()
        let fileName = "\(prefix)_\(UUID().uuidString).txt"
        let filePath = tempDir + fileName
        try text.write(toFile: filePath, atomically: true, encoding: .utf8)
        return filePath
    }

    /// Removes a file at the specified path
    static func removeFile(atPath path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }
}
