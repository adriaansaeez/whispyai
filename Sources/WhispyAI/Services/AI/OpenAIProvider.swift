struct OpenAIProvider: AIProvider {
    let apiClient: APIClient
    let model: String
    let apiKey: String

    func transform(text: String, prompt: String) async throws -> String {
        _ = (apiClient, model, apiKey, text, prompt)
        throw WhispyError.notImplemented("OpenAI rewrite")
    }
}
