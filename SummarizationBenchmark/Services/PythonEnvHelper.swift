import Foundation

/// Helper for finding paths to python3 and pip3
public struct PythonEnvHelper {
    static let pythonCandidates = [
        "/usr/bin/python3",
        "/usr/local/bin/python3",
        "/opt/homebrew/bin/python3",
        "/Library/Frameworks/Python.framework/Versions/Current/bin/python3"
    ]
    static let pipCandidates = [
        "/usr/bin/pip3",
        "/usr/local/bin/pip3",
        "/opt/homebrew/bin/pip3",
        "/Library/Frameworks/Python.framework/Versions/Current/bin/pip3"
    ]

    static func findPythonPath() -> String? {
        for path in pythonCandidates {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }

    static func findPipPath() -> String? {
        for path in pipCandidates {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }
}
