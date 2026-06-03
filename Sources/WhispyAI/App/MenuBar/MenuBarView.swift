import AppKit
import SwiftUI

struct MenuBarView: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("WhispyAI")
                    .font(.headline)
                Text(statusText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button(dictationButtonLabel) {
                appState.toggleDictation()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(appState.dictationState == .transcribing
                || appState.dictationState == .rewriting
                || appState.dictationState == .inserting)

            if let lastErrorMessage = appState.lastErrorMessage {
                Text(lastErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            Button("Settings") {
                SettingsWindowController.shared.show(appState: appState)
            }

            Button("Quit WhispyAI") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(16)
        .frame(width: 300)
        .onAppear {
            if !appState.hasCompletedOnboarding {
                OnboardingWindowController.shared.show(appState: appState)
            }
        }
    }

    private var dictationButtonLabel: String {
        switch appState.dictationState {
        case .listening:
            return "Stop Dictation"
        case .transcribing, .rewriting, .inserting:
            return "Processing..."
        default:
            return "Start Dictation"
        }
    }

    private var statusText: String {
        switch appState.dictationState {
        case .idle:
            return "Press Option+Space or the Start button to begin dictating."
        case .listening:
            return "Listening for your voice input. Press again to stop."
        case .transcribing:
            return "Turning speech into text locally."
        case .rewriting:
            return "Rewriting text with your AI provider."
        case .inserting:
            return "Inserting text into the active app."
        case .completed:
            return "Last dictation completed successfully."
        case .failed:
            return "The last dictation failed. Review settings and permissions."
        }
    }
}
