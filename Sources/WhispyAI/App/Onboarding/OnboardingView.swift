import AVKit
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

    var body: some View {
        ZStack {
            VideoBackground()

            Color.white.opacity(0.88)

            VStack(spacing: 0) {
                stepContent
                bottomBar
            }
        }
        .frame(width: 600, height: 440)
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
            Image(systemName: "waveform")
                .font(.system(size: 56))
                .foregroundStyle(.blue)
            Text("WhispyAI")
                .font(.system(size: 36, weight: .bold))
            Text("Speak naturally and let AI rewrite your text\nbefore it is inserted where you are typing.")
                .font(.title3)
                .foregroundStyle(.secondary)
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
                .foregroundStyle(.secondary)

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
                .foregroundStyle(.secondary)

            if selectedProvider == .custom {
                TextField("Base URL", text: $customBaseURL)
                    .textFieldStyle(.roundedBorder)

                TextField("Model", text: $customModel)
                    .textFieldStyle(.roundedBorder)

                Toggle("Use API key", isOn: $useAPIKey)
            } else {
                TextField("Model", text: $selectedModel)
                    .textFieldStyle(.roundedBorder)
            }

            if selectedProvider == .custom ? useAPIKey : true {
                SecureField("API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)

                HStack(spacing: 6) {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text("Your API key is stored securely in Apple Keychain and never leaves your device.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                .foregroundStyle(.secondary)

            Picker("Mode", selection: $workMode) {
                ForEach(PromptContextKind.allCases, id: \.self) { kind in
                    Text(kind.onboardingDisplayName).tag(kind)
                }
            }
            .pickerStyle(.radioGroup)
            .padding(.top, 4)

            Text(workMode.description)
                .font(.body)
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.blue.opacity(0.06))
                )
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
                .foregroundStyle(.secondary)

            KeyboardShortcuts.Recorder("Dictation hotkey", name: .toggleDictation)
                .padding(.top, 8)

            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("Default: Option + Space. You can record a custom shortcut above.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            Text("You're all set!")
                .font(.system(size: 30, weight: .bold))
            Text("Press your hotkey to start dictating.\nYou can change these settings anytime from the menu bar.")
                .font(.title3)
                .foregroundStyle(.secondary)
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
                .foregroundStyle(.secondary)
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
                    .fill(index <= currentStep.rawValue ? Color.blue : Color.gray.opacity(0.3))
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

// MARK: - Video Background

private struct VideoBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.controlsStyle = .none
        view.showsFullScreenToggleButton = false

        guard let url = Bundle.main.url(forResource: "onboarding-bg", withExtension: "mp4") else {
            return view
        }

        let player = AVPlayer(url: url)
        player.preventsDisplaySleepDuringVideoPlayback = true
        player.actionAtItemEnd = .none

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }

        view.player = player
        player.play()

        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {}
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
