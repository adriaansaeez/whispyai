import KeyboardShortcuts
import SwiftUI

struct HotkeySettingsView: View {
    var body: some View {
        Form {
            KeyboardShortcuts.Recorder("Dictation hotkey", name: .toggleDictation)
            Text("Default shortcut: Option + Space")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
