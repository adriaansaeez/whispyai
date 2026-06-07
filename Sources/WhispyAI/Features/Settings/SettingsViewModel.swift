import Foundation
import SwiftUI

@Observable
@MainActor
final class SettingsViewModel {
    enum Field: Hashable {
        case customBaseURL
        case customModel
        case apiKey
    }

    var selectedProvider: AIProviderKind = .custom
    var customBaseURL = "http://localhost:4000"
    var customModel = "gpt-4o-mini"
    var customUseAuth = false
    var apiKey = ""
    var selectedModel = "gpt-4o-mini"
    var defaultWorkMode: PromptContextKind = .autodetect

    var availableModels: [String] = []
    var isFetchingModels = false

    var isTestingConnection = false
    var connectionResult: String?

    var hasChanges = false

    private let store = SettingsStore()
    private let connectivityService = ProviderConnectivityService()
    private var modelFetchTask: Task<Void, Never>?
    private var connectionTestTask: Task<Void, Never>?

    func load() {
        let settings = store.load()
        selectedProvider = settings.selectedProvider
        customBaseURL = settings.customBaseURL
        customModel = settings.customModel
        customUseAuth = settings.customUseAuth
        selectedModel = settings.selectedModel
        defaultWorkMode = settings.defaultWorkMode
        hasChanges = false
    }

    func markChanged() {
        hasChanges = true
    }

    func save() {
        var settings = store.load()
        settings.selectedProvider = selectedProvider
        settings.customBaseURL = customBaseURL
        settings.customModel = customModel
        settings.customUseAuth = customUseAuth
        settings.selectedModel = selectedModel
        settings.defaultWorkMode = defaultWorkMode
        store.save(settings)

        if !apiKey.isEmpty {
            try? KeychainStore().saveAPIKey(apiKey, for: selectedProvider == .custom ? .custom : .openAI)
        }

        hasChanges = false
    }

    func cancelAllTasks() {
        modelFetchTask?.cancel()
        modelFetchTask = nil
        connectionTestTask?.cancel()
        connectionTestTask = nil
    }

    func fetchAvailableModels() {
        modelFetchTask?.cancel()
        modelFetchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await self?.performModelFetch()
        }
    }

    private func performModelFetch() async {
        isFetchingModels = true

        let result = await connectivityService.fetchModels(
            baseURL: customBaseURL,
            useAuth: customUseAuth,
            apiKey: apiKey
        )

        guard !Task.isCancelled else { return }

        switch result {
        case .success(let models):
            availableModels = models
            if models.contains(customModel) {
                // keep current selection
            } else if !models.isEmpty {
                customModel = models[0]
            }
        case .failure:
            // keep existing model
            availableModels = []
        }

        isFetchingModels = false
    }

    func testConnection() {
        connectionTestTask?.cancel()
        connectionTestTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await self?.performConnectionTest()
        }
    }

    private func performConnectionTest() async {
        isTestingConnection = true
        connectionResult = nil

        guard !customBaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            connectionResult = "La URL no puede estar vacía"
            isTestingConnection = false
            return
        }

        if customUseAuth, apiKey.isEmpty {
            connectionResult = "La API key no puede estar vacía cuando Use API key está activo"
            isTestingConnection = false
            return
        }

        let result = await connectivityService.testConnection(
            baseURL: customBaseURL,
            model: customModel,
            useAuth: customUseAuth,
            apiKey: apiKey
        )

        guard !Task.isCancelled else { return }

        switch result {
        case .success(let modelCount):
            connectionResult = "Conexión OK — \(modelCount) modelo(s) disponibles"
        case .failure(let message):
            connectionResult = "Error: \(message)"
        }

        isTestingConnection = false
    }
}