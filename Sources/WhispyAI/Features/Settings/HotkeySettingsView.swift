import KeyboardShortcuts
import SwiftUI

struct HotkeySettingsView: View {
    @Bindable var appState: AppState
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder("Dictation hotkey", name: .toggleDictation)
                    .foregroundStyle(.white)

                Text("Default shortcut: Option + Space")
                    .font(.footnote)
                    .foregroundStyle(AppColors.light)
            } header: {
                Label("Dictation Hotkey", systemImage: "keyboard")
                    .foregroundStyle(.white)
            }

            Section {
                Picker("Prompt mode", selection: $viewModel.defaultWorkMode) {
                    ForEach(PromptContextKind.allCases, id: \.self) { kind in
                        Text(kind.settingsDisplayName).tag(kind)
                    }
                }
                .foregroundStyle(.white)
                .onChange(of: viewModel.defaultWorkMode) { _, newValue in
                    viewModel.markChanged()
                    appState.manualContextKind = newValue == .autodetect ? nil : newValue
                }

                Text("Determines how your dictation is rewritten. Auto detects the context automatically.")
                    .font(.footnote)
                    .foregroundStyle(AppColors.light)
            } header: {
                Label("Work Mode", systemImage: "arrow.triangle.swap")
                    .foregroundStyle(.white)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
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