import KeyboardShortcuts
import SwiftUI

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case provider
    case configuration
    case workMode
    case hotkey
    case done

    var title: String {
        switch self {
        case .welcome: return ""
        case .provider: return "Choose your AI provider"
        case .configuration: return "Configure your provider"
        case .workMode: return "How should Whispy rewrite your text?"
        case .hotkey: return "Set your dictation hotkey"
        case .done: return ""
        }
    }
}



// MARK: - Main Onboarding View

struct OnboardingView: View {
    @Bindable var appState: AppState
    @State private var currentStep: OnboardingStep = .welcome
    @State private var selectedProvider: AIProviderKind = .custom
    @State private var customBaseURL = "http://localhost:4000"
    @State private var customModel = "gpt-4o-mini"
    @State private var selectedModel = "gpt-4o-mini"
    @State private var apiKey = ""
    @State private var useAPIKey = false
    @State private var workMode: PromptContextKind = .autodetect
    @State private var availableModels: [String] = []
    @State private var isFetchingModels = false
    @State private var didFetchModels = false
    @State private var isTestingConnection = false
    @State private var connectionStatus: ConnectionStatus?
    @State private var modelFetchTask: Task<Void, Never>?
    @State private var connectionTestTask: Task<Void, Never>?

    private let connectivityService = ProviderConnectivityService()

    enum ConnectionStatus {
        case success(modelCount: Int, models: [String])
        case failure(String)
    }

    var body: some View {
        ZStack {
            // Solid blue gradient background
            LinearGradient(
                colors: [AppColors.deep, AppColors.dark, AppColors.mid],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                bottomBar
            }
        }
        .frame(width: 600, height: 440)
        .onChange(of: currentStep) { _, newValue in
            // Cancel any in-flight tasks when leaving configuration step
            if newValue != .configuration {
                cancelInFlightTasks()
            }
            
            if newValue == .configuration && selectedProvider == .custom && !didFetchModels {
                modelFetchTask = Task {
                    await fetchModels()
                    didFetchModels = true
                }
            }
        }
        .onChange(of: currentStep) { _, _ in
            connectionStatus = nil
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .welcome:
            welcomeStep
        case .provider:
            providerStep
        case .configuration:
            configurationStep
        case .workMode:
            workModeStep
        case .hotkey:
            hotkeyStep
        case .done:
            doneStep
        }
    }

    // MARK: - Step 0: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Spacer()
            LogoShape()
                .fill(.white)
                .frame(width: 80, height: 80)
            Text("WhispyAI")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.white)
            Text("Speak naturally and let AI rewrite your text\nbefore it is inserted where you are typing.")
                .font(.title3)
                .foregroundStyle(AppColors.light)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 60)
    }

    // MARK: - Step 1: Provider

    private var providerStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepTitle(OnboardingStep.provider.title)
            Text("Select the AI service that will rewrite your dictated text. You can change this later in Settings.")
                .foregroundStyle(AppColors.light)

            Picker("Provider", selection: $selectedProvider) {
                ForEach(AIProviderKind.allCases) { provider in
                    Text(provider.rawValue).tag(provider)
                }
            }
            .pickerStyle(.radioGroup)
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 50)
        .padding(.top, 30)
    }

    // MARK: - Step 2: Configuration

    private var configurationStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepTitle(OnboardingStep.configuration.title)
            Text("Enter the connection details for \(selectedProvider.rawValue).")
                .foregroundStyle(AppColors.light)

            if selectedProvider == .custom {
                TextField("Base URL", text: $customBaseURL)
                    .textFieldStyle(.roundedBorder)

                if isFetchingModels {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Fetching models...")
                            .font(.caption)
                            .foregroundStyle(AppColors.light)
                    }
                } else if !availableModels.isEmpty {
                    Picker("Model", selection: $customModel) {
                        ForEach(availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                } else {
                    TextField("Model", text: $customModel)
                        .textFieldStyle(.roundedBorder)

                    Text("Enter model name or fetch from provider above.")
                        .font(.caption)
                        .foregroundStyle(AppColors.light)
                }

                Toggle("Use API key", isOn: $useAPIKey)

                if !customBaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let isAPIKeyMissing = useAPIKey && apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    Button {
                        testConnection()
                    } label: {
                        HStack(spacing: 6) {
                            if isTestingConnection {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text("Probar conexión")
                        }
                    }
                    .disabled(isTestingConnection || isAPIKeyMissing)
                    
                    if isAPIKeyMissing {
                        Text("Enter an API key to test the connection.")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }

                    if let status = connectionStatus {
                        switch status {
                        case let .success(modelCount, models):
                            Text("Conexión OK — \(modelCount) modelo(s) disponibles")
                                .font(.caption)
                                .foregroundStyle(.green)
                            if !models.isEmpty {
                                Picker("Model", selection: $customModel) {
                                    ForEach(models, id: \.self) { model in
                                        Text(model).tag(model)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        case let .failure(message):
                            Text("Error: \(message)")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            } else {
                TextField("Model", text: $selectedModel)
                    .textFieldStyle(.roundedBorder)
            }

            if selectedProvider == .custom ? useAPIKey : true {
                SecureField("API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)

                HStack(spacing: 6) {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(AppColors.bright)
                        .font(.caption)
                    Text("Your API key is stored securely in Apple Keychain and never leaves your device.")
                        .font(.caption)
                        .foregroundStyle(AppColors.light)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 50)
        .padding(.top, 30)
    }

    // MARK: - Step 3: Work Mode

    private var workModeStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepTitle(OnboardingStep.workMode.title)
            Text("Choose how Whispy processes your dictated text. You can switch modes anytime with the hotkey.")
                .foregroundStyle(AppColors.light)

            Picker("Mode", selection: $workMode) {
                ForEach(PromptContextKind.allCases, id: \.self) { kind in
                    Text(kind.onboardingDisplayName).tag(kind)
                }
            }
            .pickerStyle(.radioGroup)
            .padding(.top, 4)

            Text(workMode.description)
                .font(.body)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .animation(.easeInOut(duration: 0.2), value: workMode)

            Spacer()
        }
        .padding(.horizontal, 50)
        .padding(.top, 30)
    }

    // MARK: - Step 4: Hotkey

    private var hotkeyStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepTitle(OnboardingStep.hotkey.title)
            Text("This shortcut will start and stop dictation from anywhere on your Mac.")
                .foregroundStyle(AppColors.light)

            KeyboardShortcuts.Recorder("Dictation hotkey", name: .toggleDictation)
                .padding(.top, 8)

            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .foregroundStyle(AppColors.light)
                Text("Default: Option + Space. You can record a custom shortcut above.")
                    .font(.caption)
                    .foregroundStyle(AppColors.light)
            }

            Spacer()
        }
        .padding(.horizontal, 50)
        .padding(.top, 30)
    }

    // MARK: - Step 5: Done

    private var doneStep: some View {
        VStack(spacing: 20) {
            Spacer()
            LogoShape()
                .fill(.white)
                .frame(width: 80, height: 80)
            Text("You're all set!")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
            Text("Press your hotkey to start dictating.\nYou can change these settings anytime from the menu bar.")
                .font(.title3)
                .foregroundStyle(AppColors.light)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 60)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            if currentStep != .welcome {
                Button("Back") {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentStep = OnboardingStep(rawValue: currentStep.rawValue - 1) ?? .welcome
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppColors.light)
            }

            Spacer()

            stepIndicator

            Spacer()

            if currentStep == .done {
                Button("Start Using WhispyAI") {
                    completeOnboarding()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else if currentStep != .welcome {
                Button("Next") {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentStep = OnboardingStep(rawValue: currentStep.rawValue + 1) ?? .done
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canAdvance)
            } else {
                Button("Get Started") {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentStep = .provider
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 16)
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(1..<OnboardingStep.allCases.count, id: \.self) { index in
                Circle()
                    .fill(index <= currentStep.rawValue ? .white : AppColors.surface)
                    .frame(width: 8, height: 8)
            }
        }
    }

    // MARK: - Helpers

    private var canAdvance: Bool {
        switch currentStep {
        case .provider:
            return true
        case .configuration:
            if selectedProvider == .custom {
                return !customBaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && !customModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            } else {
                return !selectedModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        case .workMode:
            return true
        case .hotkey:
            return true
        default:
            return true
        }
    }

    private func stepTitle(_ text: String) -> some View {
        Text(text)
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
    }

    // MARK: - Save & Complete

    private func completeOnboarding() {
        let store = SettingsStore()
        var settings = store.load()

        settings.selectedProvider = selectedProvider
        settings.customBaseURL = customBaseURL
        settings.customModel = customModel
        settings.selectedModel = selectedModel
        settings.customUseAuth = selectedProvider == .custom ? useAPIKey : !apiKey.isEmpty
        settings.defaultWorkMode = workMode

        store.save(settings)

        if !apiKey.isEmpty {
            try? KeychainStore().saveAPIKey(apiKey, for: selectedProvider)
        }

        store.setHasCompletedOnboarding(true)

        appState.hasCompletedOnboarding = true
        appState.manualContextKind = workMode == .autodetect ? nil : workMode

        OnboardingWindowController.shared.close()
    }

    // MARK: - Model Fetching

    private func fetchModels() async {
        isFetchingModels = true

        var normalizedBaseURL = customBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        while normalizedBaseURL.hasSuffix("/") {
            normalizedBaseURL.removeLast()
        }

        guard !normalizedBaseURL.isEmpty, let baseComponents = URLComponents(string: normalizedBaseURL) else {
            isFetchingModels = false
            return
        }

        // Build endpoint path
        let basePath = baseComponents.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let endpoint = basePath.isEmpty ? "/v1/models" : "\(basePath)/v1/models"

        // Construct final URL
        var finalComponents = URLComponents()
        finalComponents.scheme = baseComponents.scheme ?? "http"
        finalComponents.host = baseComponents.host ?? ""
        finalComponents.port = baseComponents.port
        finalComponents.path = "/\(endpoint)"
        finalComponents.queryItems = baseComponents.queryItems

        guard let url = finalComponents.url else {
            isFetchingModels = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        if useAPIKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard !Task.isCancelled else { return }
            let decoded = try JSONDecoder().decode(ModelsResponse.self, from: data)
            availableModels = decoded.data.map(\.id).sorted()
        } catch {
            guard !Task.isCancelled else { return }
            availableModels = []
        }

        isFetchingModels = false
    }

    // MARK: - Connection Test

    private func testConnection() {
        // Cancel any existing connection test
        connectionTestTask?.cancel()
        
        isTestingConnection = true
        connectionStatus = nil

        let baseURL = customBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !baseURL.isEmpty else {
            connectionStatus = .failure("La URL no puede estar vacía")
            isTestingConnection = false
            return
        }

        connectionTestTask = Task {
            let result = await connectivityService.testConnection(
                baseURL: baseURL,
                model: customModel,
                useAuth: useAPIKey,
                apiKey: apiKey
            )

            guard !Task.isCancelled else {
                isTestingConnection = false
                return
            }

            switch result {
            case let .success(modelCount):
                let models = availableModels.isEmpty ? [] : availableModels
                connectionStatus = .success(modelCount: modelCount, models: models)
            case let .failure(message):
                connectionStatus = .failure(message)
            }

            isTestingConnection = false
        }
    }

    private func cancelInFlightTasks() {
        modelFetchTask?.cancel()
        modelFetchTask = nil
        connectionTestTask?.cancel()
        connectionTestTask = nil
    }
}

// MARK: - PromptContextKind Onboarding Extensions

private extension PromptContextKind {
    var onboardingDisplayName: String {
        switch self {
        case .autodetect: return "Auto"
        case .email: return "Email"
        case .chat: return "Chat"
        case .prompt: return "Prompt"
        case .neutral: return "Neutral"
        }
    }

    var description: String {
        switch self {
        case .autodetect:
            return "Automatically detects the context of your dictation and chooses the best rewriting style."
        case .email:
            return "Rewrites your dictation as a clear, professional email with proper greeting and closing when appropriate."
        case .chat:
            return "Keeps your message casual and concise, perfect for Slack, WhatsApp, or team chats."
        case .prompt:
            return "Structures your dictation into a clear, well-organized technical prompt with sections when useful."
        case .neutral:
            return "Makes minimal changes — fixes grammar and punctuation while preserving your original voice."
        }
    }
}

// MARK: - Onboarding Window Controller

@MainActor
final class OnboardingWindowController: NSObject, NSWindowDelegate {
    static let shared = OnboardingWindowController()

    private var window: NSWindow?

    func show(appState: AppState) {
        let window = window ?? makeWindow(appState: appState)

        if let hostingController = window.contentViewController as? NSHostingController<OnboardingView> {
            hostingController.rootView = OnboardingView(appState: appState)
        } else {
            window.contentViewController = NSHostingController(rootView: OnboardingView(appState: appState))
        }

        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.makeMain()
        window.orderFrontRegardless()
    }

    func close() {
        window?.orderOut(nil)
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return false
    }

    private func makeWindow(appState: AppState) -> NSWindow {
        let hostingController = NSHostingController(rootView: OnboardingView(appState: appState))
        let window = NSWindow(contentViewController: hostingController)
        window.delegate = self
        window.title = "WhispyAI Setup"
        window.styleMask = [.titled]
        window.setContentSize(NSSize(width: 600, height: 440))
        window.isReleasedWhenClosed = false
        window.tabbingMode = .disallowed
        window.center()
        self.window = window
        return window
    }
}