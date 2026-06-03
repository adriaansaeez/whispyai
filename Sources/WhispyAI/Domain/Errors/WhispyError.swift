import Foundation

enum WhispyError: Error, Equatable, LocalizedError {
    case permissionsDenied
    case microphonePermissionDenied
    case speechPermissionDenied
    case speechUnavailable
    case noSpeechDetected
    case speechCancelled
    case accessibilityPermissionDenied
    case noFocusedApplication
    case noFocusedElement
    case elementNotSupported
    case insertionFailed
    case missingAPIKey
    case unsupportedProvider
    case notImplemented(String)

    var errorDescription: String? {
        switch self {
        case .permissionsDenied:
            return "Required permissions are not granted."
        case .microphonePermissionDenied:
            return "Microphone access is required for dictation. Enable it in System Settings > Privacy & Security > Microphone."
        case .speechPermissionDenied:
            return "Speech recognition access is required. Enable it in System Settings > Privacy & Security > Speech Recognition."
        case .speechUnavailable:
            return "Speech recognition is not available on this system or language configuration."
        case .noSpeechDetected:
            return "No speech was detected. Please try again and speak clearly."
        case .speechCancelled:
            return "Dictation was cancelled."
        case .accessibilityPermissionDenied:
            return "Accessibility access is required to insert text. Enable it in System Settings > Privacy & Security > Accessibility, and grant permission to the running WhispyAI app (for dev builds: .build/debug/WhispyAI)."
        case .noFocusedApplication:
            return "Could not find the active application."
        case .noFocusedElement:
            return "Could not find a text field or text area in the active application."
        case .elementNotSupported:
            return "The active element does not support text insertion via accessibility."
        case .insertionFailed:
            return "Failed to insert text into the active application."
        case .missingAPIKey:
            return "The selected provider is missing an API key."
        case .unsupportedProvider:
            return "The selected AI provider is not supported yet."
        case let .notImplemented(feature):
            return "\(feature) is not implemented yet."
        }
    }
}
