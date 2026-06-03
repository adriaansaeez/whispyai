protocol PromptBuilding: Sendable {
    func makePrompt(for text: String, context: PromptContext) -> String
}
