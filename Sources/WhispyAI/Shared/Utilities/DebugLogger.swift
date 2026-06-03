import Foundation
import os

enum DebugLogger {
    private static let logger = Logger(subsystem: "WhispyAI", category: "Debug")
    private static let logURL = URL(fileURLWithPath: "/tmp/whispy-debug.log")

    static func log(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "[\(timestamp)] \(message)"

        logger.debug("\(line, privacy: .public)")
        appendToFile(line + "\n")
    }

    private static func appendToFile(_ line: String) {
        let data = Data(line.utf8)

        if FileManager.default.fileExists(atPath: logURL.path) {
            do {
                let handle = try FileHandle(forWritingTo: logURL)
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
                try handle.close()
            } catch {
                logger.error("Failed to append debug log: \(error.localizedDescription, privacy: .public)")
            }
            return
        }

        do {
            try data.write(to: logURL)
        } catch {
            logger.error("Failed to create debug log: \(error.localizedDescription, privacy: .public)")
        }
    }
}
