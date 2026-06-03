struct PromptContext: Equatable, Sendable {
    let kind: PromptContextKind
    let appName: String?
}

enum PromptContextKind: String, Equatable, Sendable, CaseIterable {
    case autodetect
    case email
    case chat
    case prompt
    case neutral

    var displayName: String {
        switch self {
        case .autodetect:
            return "Autodetect"
        case .email:
            return "Email"
        case .chat:
            return "Chat"
        case .prompt:
            return "Prompt"
        case .neutral:
            return "Neutral"
        }
    }
}
