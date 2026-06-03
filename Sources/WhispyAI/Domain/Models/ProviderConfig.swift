enum AIProviderKind: String, CaseIterable, Identifiable {
    case custom = "Custom (LiteLLM / Local)"
    case openAI = "OpenAI"
    case anthropic = "Anthropic"
    case gemini = "Gemini"
    case openRouter = "OpenRouter"

    var id: String { rawValue }
}

struct ProviderConfig: Equatable {
    var provider: AIProviderKind
    var model: String
    var apiKeyName: String
}
