import Foundation

struct SettingsStore: @unchecked Sendable {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var hasCompletedOnboarding: Bool {
        defaults.bool(forKey: Keys.hasCompletedOnboarding)
    }

    func load() -> AppSettings {
        var settings = AppSettings()

        if let selectedProvider = defaults.string(forKey: Keys.selectedProvider),
           let provider = AIProviderKind(rawValue: selectedProvider) {
            settings.selectedProvider = provider
        }

        settings.selectedModel = defaults.string(forKey: Keys.selectedModel) ?? settings.selectedModel
        settings.customBaseURL = defaults.string(forKey: Keys.customBaseURL) ?? settings.customBaseURL
        settings.customModel = defaults.string(forKey: Keys.customModel) ?? settings.customModel
        settings.rewritePrompt = defaults.string(forKey: Keys.rewritePrompt) ?? settings.rewritePrompt

        if let workModeRaw = defaults.string(forKey: Keys.defaultWorkMode),
           let workMode = PromptContextKind(rawValue: workModeRaw) {
            settings.defaultWorkMode = workMode
        }

        if defaults.object(forKey: Keys.launchAtLogin) != nil {
            settings.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        }

        if defaults.object(forKey: Keys.showMenuBarIcon) != nil {
            settings.showMenuBarIcon = defaults.bool(forKey: Keys.showMenuBarIcon)
        }

        if defaults.object(forKey: Keys.playStartSound) != nil {
            settings.playStartSound = defaults.bool(forKey: Keys.playStartSound)
        }

        if defaults.object(forKey: Keys.customUseAuth) != nil {
            settings.customUseAuth = defaults.bool(forKey: Keys.customUseAuth)
        }

        let temperature = defaults.double(forKey: Keys.temperature)
        if defaults.object(forKey: Keys.temperature) != nil {
            settings.temperature = temperature
        }

        let maximumTokens = defaults.integer(forKey: Keys.maximumTokens)
        if defaults.object(forKey: Keys.maximumTokens) != nil {
            settings.maximumTokens = maximumTokens
        }

        let timeoutSeconds = defaults.integer(forKey: Keys.timeoutSeconds)
        if defaults.object(forKey: Keys.timeoutSeconds) != nil {
            settings.timeoutSeconds = timeoutSeconds
        }

        return settings
    }

    func save(_ settings: AppSettings) {
        defaults.set(settings.launchAtLogin, forKey: Keys.launchAtLogin)
        defaults.set(settings.showMenuBarIcon, forKey: Keys.showMenuBarIcon)
        defaults.set(settings.playStartSound, forKey: Keys.playStartSound)
        defaults.set(settings.selectedProvider.rawValue, forKey: Keys.selectedProvider)
        defaults.set(settings.selectedModel, forKey: Keys.selectedModel)
        defaults.set(settings.customBaseURL, forKey: Keys.customBaseURL)
        defaults.set(settings.customModel, forKey: Keys.customModel)
        defaults.set(settings.customUseAuth, forKey: Keys.customUseAuth)
        defaults.set(settings.rewritePrompt, forKey: Keys.rewritePrompt)
        defaults.set(settings.defaultWorkMode.rawValue, forKey: Keys.defaultWorkMode)
        defaults.set(settings.temperature, forKey: Keys.temperature)
        defaults.set(settings.maximumTokens, forKey: Keys.maximumTokens)
        defaults.set(settings.timeoutSeconds, forKey: Keys.timeoutSeconds)
    }

    func setHasCompletedOnboarding(_ completed: Bool) {
        defaults.set(completed, forKey: Keys.hasCompletedOnboarding)
    }
}

private extension SettingsStore {
    enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let launchAtLogin = "launchAtLogin"
        static let showMenuBarIcon = "showMenuBarIcon"
        static let playStartSound = "playStartSound"
        static let selectedProvider = "selectedProvider"
        static let selectedModel = "selectedModel"
        static let customBaseURL = "customBaseURL"
        static let customModel = "customModel"
        static let customUseAuth = "customUseAuth"
            static let rewritePrompt = "rewritePrompt"
            static let defaultWorkMode = "defaultWorkMode"
        static let temperature = "temperature"
        static let maximumTokens = "maximumTokens"
        static let timeoutSeconds = "timeoutSeconds"
    }
}
