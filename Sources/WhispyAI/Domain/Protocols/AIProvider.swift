protocol AIProvider: Sendable {
    func transform(text: String, prompt: String) async throws -> String
}
