struct ProviderMessage: Codable, Equatable {
    let role: String
    let content: String
}

struct OpenAIRewriteRequest: Codable, Equatable {
    let model: String
    let messages: [ProviderMessage]
    let temperature: Double
    let maxTokens: Int

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
    }
}
