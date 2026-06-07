struct AIProviderRegistry: Sendable {
    private let settingsStore: SettingsStore
    private let keychainStore: KeychainStore
    private let apiClient: APIClient

    init(settingsStore: SettingsStore, keychainStore: KeychainStore, apiClient: APIClient) {
        self.settingsStore = settingsStore
        self.keychainStore = keychainStore
        self.apiClient = apiClient
    }

    func currentProvider() throws -> AIProvider {
        let settings = settingsStore.load()

        switch settings.selectedProvider {
        case .custom:
            let apiKey = settings.customUseAuth
                ? (try keychainStore.readAPIKey(for: .custom) ?? "")
                : nil

            return CustomProvider(
                baseURL: settings.customBaseURL,
                model: settings.customModel,
                apiKey: apiKey,
                temperature: settings.temperature,
                maxTokens: settings.maximumTokens,
                timeoutSeconds: settings.timeoutSeconds,
                apiPath: settings.customAPIPath
            )
        case .openAI:
            guard let apiKey = try keychainStore.readAPIKey(for: .openAI) else {
                throw WhispyError.missingAPIKey
            }

            return OpenAIProvider(apiClient: apiClient, model: settings.selectedModel, apiKey: apiKey)
        case .anthropic, .gemini, .openRouter:
            throw WhispyError.unsupportedProvider
        }
    }
}