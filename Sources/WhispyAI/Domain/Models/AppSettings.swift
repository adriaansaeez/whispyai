struct AppSettings: Equatable {
    var launchAtLogin = false
    var showMenuBarIcon = true
    var playStartSound = true
    var selectedProvider: AIProviderKind = .custom
    var selectedModel = "gpt-4o-mini"
    var customBaseURL = "http://localhost:4000"
    var customModel = "gpt-4o-mini"
    var customUseAuth = false
    var rewritePrompt = DefaultPromptEngine.defaultPromptTemplate
    var temperature = 0.2
    var maximumTokens = 300
    var timeoutSeconds = 12
}
