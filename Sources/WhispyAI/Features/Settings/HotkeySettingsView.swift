import KeyboardShortcuts
import SwiftUI

struct HotkeySettingsView: View {
    @Bindable var appState: AppState
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("Dictation Hotkey") {
                KeyboardShortcuts.Recorder("Dictation hotkey", name: .toggleDictation)
                Text("Default shortcut: Option + Space")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Work Mode") {
                Picker("Prompt mode", selection: $viewModel.defaultWorkMode) {
                    ForEach(PromptContextKind.allCases, id: \.self) { kind in
                        Text(kind.settingsDisplayName).tag(kind)
                    }
                }
                .onChange(of: viewModel.defaultWorkMode) { _, newValue in
                    viewModel.markChanged()
                    appState.manualContextKind = newValue == .autodetect ? nil : newValue
                }

                Text("Determines how your dictation is rewritten. Auto detects the context automatically.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

private extension PromptContextKind {
    var settingsDisplayName: String {
        switch self {
        case .autodetect: return "Auto"
        case .email: return "Email"
        case .chat: return "Chat"
        case .prompt: return "Prompt"
        case .neutral: return "Neutral"
        }
    }
}
