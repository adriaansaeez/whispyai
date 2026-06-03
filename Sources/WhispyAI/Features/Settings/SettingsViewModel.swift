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

    var isTestingConnection = false
    var connectionResult: String?

    var hasChanges = false

    private let store = SettingsStore()

    func load() {
        let settings = store.load()
        selectedProvider = settings.selectedProvider
        customBaseURL = settings.customBaseURL
        customModel = settings.customModel
        customUseAuth = settings.customUseAuth
        selectedModel = settings.selectedModel
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
        store.save(settings)

        if !apiKey.isEmpty {
            try? KeychainStore().saveAPIKey(apiKey, for: selectedProvider == .custom ? .custom : .openAI)
        }

        hasChanges = false
    }

    func testConnection() async {
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

        let connectivityService = ProviderConnectivityService()
        let result = await connectivityService.testConnection(
            baseURL: customBaseURL,
            model: customModel,
            useAuth: customUseAuth,
            apiKey: apiKey
        )

        switch result {
        case .success(let modelCount):
            connectionResult = "Conexión OK — \(modelCount) modelo(s) disponibles"
        case .failure(let message):
            connectionResult = "Error: \(message)"
        }

        isTestingConnection = false
    }
}
