import Foundation

protocol SpeechRecognizing: Sendable {
    func requestPermissions() async throws
    func startRecording() async throws
    func stopRecording() async throws -> String
    func checkIfRecording() async -> Bool
}
